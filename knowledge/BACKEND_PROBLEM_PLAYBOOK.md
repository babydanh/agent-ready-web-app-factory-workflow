# Backend Problem Playbook — Quy trình xử lý các bài toán lặp lại

**Mục đích:** Cung cấp recipe có thể áp dụng cho nhiều web app/backend. Đây là playbook thiết kế và kiểm chứng, không phải code copy-paste. Mỗi recipe phải được điều chỉnh theo domain, stack, data classification và risk tier.

## 1. Cách đọc playbook

Mỗi flow được mô tả bằng năm phần: **khi nào dùng**, **source of truth**, **sequence chuẩn**, **failure cases**, và **evidence tối thiểu**. Nếu feature có từ hai flow trở lên, phải ghép các control lại. Ví dụ “đặt vé có thanh toán và email” đồng thời là mutation/concurrency, payment/webhook và notification/outbox.

Không gọi external provider trong một database transaction dài nếu không cần thiết. Không coi retry là phương án sửa consistency. Không để controller tự quyết domain state. Không trả raw database row. Không dùng frontend guard để thay server authorization.

## 2. Recipe A — CRUD resource chuẩn

### Khi nào dùng

Dùng cho resource có create/read/update/archive/delete và chưa có invariant phức tạp như tiền, quota hoặc booking.

### Sequence

```text
Request
  → request ID / auth / rate limit
  → DTO/schema validation
  → function + object + property authorization
  → tenant/owner scope
  → service command
  → transaction nếu có nhiều ghi
  → database constraint
  → projection/DTO mapping
  → canonical success/error response
  → audit/metrics/log
```

### Thiết kế bắt buộc

| Thành phần | Quyết định cần ghi |
|---|---|
| Identity | ID format, public/private identifier, not-found behavior |
| Ownership | Owner/tenant/team scope và cross-scope policy |
| State | Draft/published/archived/deleted; transition actor và precondition |
| Input | Required/nullable/immutable/derived fields; unknown field policy |
| Update | Full replace hay PATCH; optimistic version/ETag nếu cần |
| Delete | Soft delete, archive, retention và restore |
| Output | DTO projection; không trả secret/internal columns |
| Audit | Actor, action, resource, outcome, correlation ID |

### Failure cases và test

Phải test unknown field, wrong type, duplicate, missing owner, cross-tenant IDOR, update immutable field, stale version, deleted resource, repeated mutation, concurrent update và database constraint violation. `404` và `403` cần có policy rõ để tránh lộ existence không cần thiết.

### Evidence tối thiểu

Entity spec, endpoint contract, permission matrix, migration/constraint note, unit/API tests, negative authorization evidence và screen state mapping nếu có frontend.

## 3. Recipe B — Booking/reservation/slot/quota

### Khi nào dùng

Dùng khi một tài nguyên hữu hạn có thể bị nhiều actor giữ hoặc tiêu thụ: ghế, slot, phòng, suất, coupon, registration, inventory hoặc quota.

### Source of truth

Chọn một source of truth chính. Thông thường database giữ invariant lâu dài; Redis chỉ giữ hold ngắn hạn/cache nếu có cơ chế reconcile. Không để DB và Redis cùng được xem là số lượng chính mà không có reconciliation.

### Sequence chuẩn

```text
Idempotency key
  → authenticate + authorize resource
  → begin transaction
  → lock/read current version hoặc dùng atomic conditional update
  → kiểm tra state/expiry/capacity
  → tạo hold/booking với unique key
  → cập nhật counter trong cùng invariant boundary
  → commit
  → outbox event
  → notification/cache/realtime side effects
```

### Pattern

Dùng conditional update kiểu “chỉ trừ khi remaining > 0”, unique constraint cho `(resource_id, subject_id, active_state)` và hold có `expires_at`. Release phải idempotent: chỉ tăng lại quota nếu hold/booking chuyển state thành công lần đầu. Không dùng timestamp đơn độc làm identity. Nếu dùng Redis hold, cần TTL, owner/payment key, atomic Lua/check-and-delete và worker đối soát DB.

### Failure cases và test

Hai request đồng thời không được oversell; duplicate click không tạo hai booking; retry sau timeout trả kết quả cũ hoặc conflict đúng policy; expired hold được release một lần; process crash không làm counter sai; cancellation/release không tăng quota nhiều lần; cross-tenant/resource ID bị chặn.

### Evidence tối thiểu

Invariant table, DB constraint/lock note, transaction/isolation decision, idempotency policy, concurrency test report, expiry/reconciliation evidence và metrics cho remaining/hold/failed.

PostgreSQL mô tả Read Committed là mặc định và concurrent commands có thể chờ rồi re-evaluate row sau commit; lựa chọn isolation/locking phải được thiết kế cùng negative concurrency test [1].

## 4. Recipe C — Payment/order/ledger

### Khi nào dùng

Dùng cho payment intent, order, invoice, payout, refund, wallet, credit hoặc mọi operation có giá trị tiền.

### Sequence chuẩn

```text
Client mutation with idempotency key
  → server recomputes amount/currency/line items
  → create local payment intent + pending receipt in one transaction
  → call provider outside long DB transaction
  → persist provider reference/state
  → verify signed webhook + timestamp/replay
  → durable inbound event identity
  → atomic local state transition + ledger/outbox
  → async notification/status update/reconcile
```

### Invariants

Amount và currency phải do server tính từ catalog/order snapshot. Ledger entry nên immutable; điều chỉnh bằng reversal/refund entry, không sửa lịch sử tùy tiện. Payment state transition phải monotonic theo policy và có xử lý out-of-order. Receipt, payment intent, provider reference và idempotency key cần unique/index phù hợp.

### Failure cases và test

Test amount mismatch, invalid signature, duplicate/out-of-order webhook, provider success nhưng local timeout, local commit nhưng receipt/notification fail, refund twice, concurrent payout, pending orphan, provider 429/5xx và database rollback. Webhook trả success chỉ khi inbound evidence đã được ghi durable theo policy; side effect eventual phải có retry/DLQ/alert.

Stripe mô tả idempotency bằng cách lưu status/body của kết quả đầu tiên theo key, kiểm tra parameter reuse và phân biệt validation/concurrent-conflict với endpoint execution [2]. Đây là reference pattern; retention, storage và response replay phải được chọn theo hệ thống.

### Evidence tối thiểu

Payment state machine, ledger invariant, provider contract, signature/replay test, idempotency/retry test, reconciliation report, audit trail, alert/runbook và rollback/repair procedure.

## 5. Recipe D — External API integration

### Khi nào dùng

Dùng khi backend gọi payment, email, SMS, map, storage, identity, AI, shipping hoặc bất kỳ provider nào bên ngoài process.

### Adapter contract

```text
Domain command
  → validate provider input
  → adapter with timeout/deadline
  → classify response: success / retryable / permanent / unknown
  → persist provider reference and attempt
  → retry only according to matrix
  → reconcile unknown outcome
```

Mỗi adapter cần tách credential/config, request/response DTO, timeout, retry/backoff/jitter, circuit breaker, rate limit, redaction, provider status mapping và contract fixture. Không đưa provider error message nguyên văn ra client.

### Failure matrix

| Tình huống | Mặc định |
|---|---|
| Timeout/connection reset | Có thể retry nếu operation idempotent; nếu outcome unknown thì reconcile |
| 429 | Tôn trọng `Retry-After` nếu hợp lệ; áp dụng global budget |
| 5xx | Exponential backoff+jitter, giới hạn attempts |
| 4xx validation | Không retry tự động; sửa input hoặc đánh failed |
| Invalid signature | Reject, audit và alert |
| Schema drift | Fail closed ở field critical, quarantine/alert |
| Provider success/local crash | Reconcile bằng provider reference/idempotency key |

### Evidence tối thiểu

Adapter contract, provider sandbox fixture, timeout/retry tests, secret rotation note, circuit-breaker metrics, reconciliation path và redacted logs.

## 6. Recipe E — Webhook/inbox/outbox

### Khi nào dùng

Dùng khi một service nhận event bên ngoài hoặc phát event cho worker/service khác.

### Inbox sequence

```text
Receive request
  → verify signature/timestamp
  → derive provider event ID
  → insert inbox event with unique provider/source key
  → commit quickly
  → acknowledge according to durable-receipt policy
  → process asynchronously
  → transition event state
  → retry/DLQ/replay/reconcile
```

### Outbox sequence

```text
Domain transaction
  → write domain state + outbox row in same DB transaction
  → worker claims outbox row
  → publish/send side effect
  → mark succeeded or retryable/failed
  → alert/DLQ/repair
```

Không phát event “sau commit” chỉ bằng memory vì process crash tạo gap. Consumer phải deduplicate và xử lý event version. Outbox không tự làm handler idempotent; hai lớp đều cần.

### Evidence tối thiểu

Event schema/version, inbox/outbox table, unique event key, state machine, replay command có approval, crash/retry test, DLQ evidence và alert.

## 7. Recipe F — File upload/import/export

### Upload sequence

```text
Authorize purpose/resource
  → signed one-time token hoặc authenticated upload
  → enforce byte/content quotas
  → inspect magic bytes/metadata
  → quarantine/scan
  → persist private object metadata
  → async transform/index
  → signed delivery URL
  → orphan cleanup/retention
```

Không tin extension/MIME do client gửi. Không lưu public-by-default nếu dữ liệu chứa PII hoặc nghiệp vụ. Filename phải được canonicalize; object key không dựa trực tiếp vào input. Import lớn nên chạy worker; export nhạy cảm phải có expiry/audit.

### Failure cases và test

Wrong magic bytes, polyglot, oversized body, zip bomb, malicious filename/path, macro/formula, HTML/script, image decompression bomb, aborted upload, orphan object, expired signed URL, quota exhaustion và malware scan unavailable.

### Evidence tối thiểu

Upload policy, file-type/content test, quota metrics, scan result, private delivery proof, cleanup job, retention note và import/export fixture.

## 8. Recipe G — Search/list/filter/report

### List contract

```text
Validate filter/sort fields
  → authorize scope before query
  → apply stable deterministic ordering
  → use bounded page/cursor
  → select projection, not raw row
  → return canonical pagination meta
```

Sort/filter field phải là allowlist. Cursor nên encode đủ ordering key và scope, không nhận SQL fragment. Total count chỉ trả khi chi phí cho phép; report lớn chuyển thành async export. Query plan cần được kiểm tra trên data volume gần production.

### Failure cases và test

Cross-tenant filter bypass, unstable pagination khi insert giữa trang, cursor tamper, unbounded page, expensive wildcard, N+1, slow count, stale cache và export permission leak.

### Evidence tối thiểu

Endpoint contract, index/query-plan note, page-size policy, authorization test, large-data/load test và export job evidence.

## 9. Recipe H — Notification/email/SMS/push

### Sequence

```text
Domain event/outbox
  → apply user preference/consent
  → render versioned template with sanitized data
  → deduplicate by business event + channel
  → send via provider adapter
  → classify bounce/retry/permanent error
  → persist delivery status
```

Không gửi raw sensitive data nếu không cần. Không retry vô hạn. Template cần version và localization. Người nhận phải được scope đúng tenant/actor.

### Test và evidence

Test duplicate event, provider timeout, 429, bounce, unsubscribe, wrong recipient, localization, PII redaction, template injection, DLQ/replay và delivery metrics.

## 10. Recipe I — Realtime event

### Event contract

```json
{
  "eventId": "evt_01...",
  "eventType": "resource.updated",
  "version": 1,
  "occurredAt": "2026-08-22T00:00:00Z",
  "entityId": "res_01...",
  "scope": "tenant_01",
  "data": {}
}
```

Ghi rõ ordering scope, delivery guarantee, ack/timeout, auth handshake, per-message authorization, deduplication, reconnect/resync và persistence. Với dữ liệu critical, không được coi Socket emit là durable delivery. Socket.IO mặc định at-most-once; delivery mạnh hơn cần application-level ID, persistence, offset và replay [3].

### Test và evidence

Disconnect giữa send, duplicate event, out-of-order, expired token, unauthorized room, oversized message, flood, multiple tabs, reconnect/resync và multi-instance broadcast.

## 11. Recipe J — Queue/worker

### Job contract

```yaml
jobType: send-notification
version: 1
jobId: unique-business-operation
correlationId: req_...
attempts: 5
backoff: exponential+jitter
timeoutMs: 30000
sideEffects: idempotent
permanentFailure: dead-letter-and-alert
```

Worker phải phân biệt transient/permanent/unknown error. Job handler cần safe khi chạy lại. Attempts, backoff, jitter, concurrency, timeout, DLQ, replay approval và shutdown policy phải nằm trong contract. BullMQ hỗ trợ fixed/exponential backoff, jitter và custom retry strategy [4].

### Test và evidence

Transient success after retry, permanent failure, worker crash, duplicate delivery, poison job, DLQ replay, graceful shutdown, Redis outage, timeout và job version mismatch.

## 12. Recipe K — Cache

### Quyết định

Trước khi cache, ghi data có stale tolerance, key scope, TTL, invalidation trigger, max size, behavior khi Redis down và privacy policy. Key phải bao gồm tenant/user/role nếu representation phụ thuộc viewer. Không cache permission-sensitive data dùng chung nếu chưa proof.

### Failure cases

Cross-user leak, stale after mutation, stampede, cache poisoning, negative cache, Redis outage, invalidation race và unbounded value. Test bằng hai actor/tenant và mutation giữa các reads.

## 13. Recipe L — Authentication và account recovery

### State machine

```text
unregistered → pending-verification → active → suspended/banned → closed
session: issued → rotated → revoked/expired
recovery: requested → verified → consumed/expired
```

Thiết kế rõ cookie/bearer, refresh rotation, reuse detection, CSRF/origin, password policy, MFA/step-up, OAuth state/nonce/PKCE, session revocation, rate limit và audit. Recovery token/OTP phải có TTL, single-use, entropy và không lưu raw token nếu không cần.

### Test và evidence

Credential stuffing, enumeration, refresh replay, session fixation, revoked session, CSRF, wrong origin, OAuth callback mismatch, recovery replay, OTP brute force, role downgrade và step-up bypass.

## 14. Recipe M — AI/tool call

### Sequence

```text
Classify user/document input
  → enforce auth/quota/budget
  → build bounded context
  → call model with versioned prompt
  → validate structured output
  → authorize every tool/resource
  → redact transcript/log
  → human approval for high-impact side effect
  → record eval/cost/latency/outcome
```

URL fetch phải có egress policy; tool registry deny-by-default; model output không được xem là trusted command; input/output/token/turn/tool limits cần hard gate. Test prompt injection, untrusted document, SSRF/private IP, malformed output, unauthorized tool, cost exhaustion và provider outage.

## 15. Recipe N — Deployment/migration/rollback

### Release sequence

```text
Build immutable artifact
  → verify provenance/config policy
  → backup/restore precondition
  → expand migration
  → deploy health-gated app
  → readiness/smoke check
  → observe error budget
  → contract/feature activation
  → contract migration/cleanup later
```

Migration failure phải block release; không dùng `|| echo` để biến failure thành success. Schema rollback thường không phải `down migration` đơn giản; dùng expand/contract, backward-compatible code và tested restore. Docker Compose phân biệt service started với service ready và khuyến nghị healthcheck/condition [5].

### Evidence tối thiểu

Artifact digest, migration log, backup/restore test, readiness output, smoke result, rollback drill, release decision và known residual risk.

## 16. Backend review checklist theo mutation

| Kiểm tra | Có/Không/N/A | Evidence |
|---|---|---|
| Source of truth và invariant đã ghi |  |  |
| DTO/schema validation và unknown field policy |  |  |
| Function/object/property authorization |  |  |
| Tenant/ownership query scope |  |  |
| Transaction boundary và isolation/lock |  |  |
| Unique/check/composite constraints |  |  |
| Idempotency/duplicate policy |  |  |
| External timeout/retry/reconcile |  |  |
| Outbox/inbox hoặc side-effect state |  |  |
| Error/status/Problem Details contract |  |  |
| Metrics/log/trace/audit event |  |  |
| Negative/concurrency/retry tests |  |  |
| Migration/rollback/readiness |  |  |
| Privacy/retention/redaction |  |  |

## References

[1]: [PostgreSQL — Transaction Isolation](https://www.postgresql.org/docs/current/transaction-iso.html)  
[2]: [Stripe — Idempotent requests](https://docs.stripe.com/api/idempotent_requests)  
[3]: [Socket.IO — Delivery guarantees](https://socket.io/docs/v4/delivery-guarantees)  
[4]: [BullMQ — Retrying failing jobs](https://docs.bullmq.io/guide/retrying-failing-jobs)  
[5]: [Docker Docs — Control startup and shutdown order in Compose](https://docs.docker.com/compose/how-tos/startup-order/)  
