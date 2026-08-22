# Transaction and Concurrency Playbook

> Mục tiêu: thiết kế backend không mất dữ liệu, không oversell, không double-charge và không tạo state nửa vời khi có retry, timeout, worker hoặc request đồng thời.

## 1. Start with invariants, not isolation level

Một transaction chỉ có ý nghĩa khi biết invariant cần bảo vệ. Ví dụ:

| Flow | Invariant |
|---|---|
| Create booking | Một resource/time slot không có hai booking confirmed |
| Register tournament | Một user/team không đăng ký trùng cùng tournament |
| Checkout | Tổng line snapshot khớp total; không commit item unavailable |
| Payment | Một business intent không capture hai lần |
| Refund | Refund không vượt captured amount |
| Wallet/ledger | Tổng debit/credit cân bằng theo currency |
| Coupon | Redemption không vượt quota hoặc per-user limit |
| Upload | File metadata chỉ trỏ tới object đã scan/authorized |
| Membership | Một user chỉ có một active membership theo scope |

Nếu chưa viết được invariant bằng câu hoặc constraint, chưa nên chọn transaction pattern.

## 2. Transaction boundary

Transaction nên bao phủ các database writes cần atomic với nhau, nhưng không giữ lock trong lúc gọi network chậm. Không đặt payment provider, email, file upload hoặc HTTP callback ở giữa một DB transaction dài.

```text
Validate intent
  → begin DB transaction
      lock/check authoritative rows
      write state + outbox/event/intention
    commit
  → async external side effect
  → persist result/reconciliation
```

Nếu external side effect phải đồng bộ để trả kết quả, cần explicit state machine, idempotency và recovery path. Không giả định rollback database có thể rollback payment provider.

## 3. Isolation and anomalies

PostgreSQL hỗ trợ nhiều mức transaction isolation; chọn mức dựa trên anomaly và throughput cần kiểm soát, không chọn `serializable` như bùa hoặc mặc định `read committed` mà không test [1]. Cần nhận diện:

| Anomaly | Ví dụ | Control |
|---|---|---|
| Lost update | Hai request ghi đè quantity | Version/conditional update/row lock |
| Dirty read | Đọc dữ liệu chưa commit | Isolation phù hợp |
| Non-repeatable read | Cùng row đổi giữa hai lần đọc | Repeatable read/lock |
| Phantom | Tập rows thay đổi giữa kiểm tra | Predicate/unique constraint/serializable |
| Write skew | Hai row riêng lẻ hợp lệ nhưng tổng invariant sai | Lock scope hoặc serializable |
| Duplicate mutation | Retry tạo record/charge thứ hai | Idempotency + unique key |
| Out-of-order event | Webhook cũ ghi đè state mới | Version/transition guard |

## 4. Concurrency controls

### Pessimistic locking

Dùng row lock khi resource nóng và invariant gắn với row cụ thể. Giữ transaction ngắn, lock theo thứ tự ổn định, timeout rõ, tránh lock chain. Không dùng `SELECT` thường rồi mới `UPDATE` nếu giữa hai câu có race.

### Optimistic concurrency

Dùng `version`, `updatedAt` hoặc ETag/If-Match khi conflict ít và UI có thể retry/merge. Update phải có điều kiện `WHERE id = ? AND version = ?`; affected rows bằng zero là conflict, không coi là success.

### Database constraints

Unique, partial unique, check, foreign key, exclusion/range constraint và not-null thường đáng tin hơn chỉ kiểm tra ở service. Error mapping phải phân biệt duplicate/conflict với generic 500.

### Atomic conditional update

Một câu `UPDATE ... SET ... WHERE condition` có thể bảo vệ quota/stock nếu affected rows được kiểm tra. Không đọc quantity rồi tính trong application nếu không có lock/conditional predicate.

## 5. Idempotency

Idempotency key phải gắn với actor/scope/operation và được lưu với request fingerprint, status, response/reference, expiration và conflict behavior. Stripe dùng idempotent requests để cho phép retry mà tránh tạo mutation mới khi network failure [2].

| Trường hợp | Expected behavior |
|---|---|
| Cùng key + cùng payload đang xử lý | Trả processing hoặc wait policy |
| Cùng key + cùng payload đã success | Replay cùng semantic response |
| Cùng key + payload khác | `409`/problem detail conflict |
| Key hết hạn | Policy rõ; không im lặng mutate |
| Request timeout trước commit | Retry an toàn |
| Worker redelivery | Consumer xử lý nhiều lần không đổi kết quả |

Không dùng idempotency key chỉ ở frontend; server/database phải enforce.

## 6. State transition guards

Mọi transition cần precondition và version check:

```text
transition(order, PAID → FULFILLING)
  require payment_status = PAID
  require version = expectedVersion
  write new state + audit + outbox atomically
```

Transition cũ đến muộn phải bị bỏ qua hoặc đưa vào review, không ghi đè state mới. Tách command (`capturePayment`) khỏi event (`PaymentCaptured`) và projection (`order.paymentStatus`) để dễ retry.

## 7. Outbox, inbox và saga

Outbox transactionally ghi business change và event record cùng DB commit. Publisher gửi event; consumer dùng inbox/dedup record. Event delivery at-least-once nghĩa là duplicate có thể xảy ra; business handler phải idempotent.

Saga dùng khi workflow đi qua nhiều resource/service và không có distributed transaction. Saga phải có compensating action, timeout, manual recovery và reconciliation; compensation không phải lúc nào cũng đảo ngược hoàn hảo.

BullMQ retry/backoff pattern cần đi cùng maximum attempts, idempotent processor, dead-letter/replay và alert [3]. Socket.IO delivery cũng cần explicit acknowledgement/retry/ordering semantics; realtime event không nên là source of truth duy nhất [4].

## 8. External API and webhook safety

External call cần timeout, bounded retry, exponential backoff + jitter, circuit breaker/bulkhead khi phù hợp, request correlation, response validation và redacted error logging. Webhook cần signature verification, timestamp/replay protection, event dedup, out-of-order handling và raw payload retention theo policy.

Không retry lỗi validation/auth/permission. Không retry vô hạn 5xx. Nếu provider timeout sau khi có thể đã charge, chuyển sang `UNKNOWN/PENDING_RECONCILIATION` thay vì tự charge lại.

## 9. Reconciliation and repair

Mọi financial/external mutation cần reconciliation job. Job phải idempotent, incremental cursor hoặc time window, rate-limited, có dry-run, diff report, approval cho repair và audit trail. Không tự động “sửa cho khớp” bằng cách update trực tiếp mà không giữ evidence.

## 10. Concurrency test suite

| Test | Expected |
|---|---|
| Hai request lấy resource cuối | Chỉ một success |
| Hai redemption cùng quota | Không vượt quota |
| Retry sau response timeout | Không duplicate |
| Worker crash sau side effect | Redelivery không duplicate |
| Webhook duplicate | Không đổi kết quả lần hai |
| Webhook out-of-order | State guard không rollback |
| Deadlock order | Retry bounded hoặc fail rõ |
| Serialization failure | Retry transaction an toàn |
| Partial external failure | Pending/reconcile, không mất record |
| Read replica lag | Không dùng stale read cho authorization/mutation |

## 11. Definition of Done

Feature có concurrency impact chỉ đạt DoD khi có invariant, transaction boundary, isolation/lock rationale, database constraints, idempotency, transition guards, side-effect strategy, retry/DLQ, reconciliation, metrics, timeout policy và deterministic/concurrent tests.

## References

[1]: https://www.postgresql.org/docs/current/transaction-iso.html "PostgreSQL — Transaction Isolation"
[2]: https://docs.stripe.com/api/idempotent_requests "Stripe — Idempotent requests"
[3]: https://docs.bullmq.io/guide/retrying-failing-jobs "BullMQ — Retrying failing jobs"
[4]: https://socket.io/docs/v4/delivery-guarantees "Socket.IO — Delivery guarantees"
