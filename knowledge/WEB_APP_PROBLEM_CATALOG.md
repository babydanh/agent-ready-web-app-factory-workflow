# Web App Problem Catalog — Các bài toán muôn thuở

**Mục đích:** Đây là catalog domain-agnostic cho các bài toán lặp lại trong web app. Không bê nguyên entity của hệ thống giải đấu sang đề tài khác; chỉ tái sử dụng cách nhận diện rủi ro, invariant, pattern, test và evidence.

**Cách dùng:** Khi có feature mới, Product/Architect Agent chọn các problem card liên quan; Backend/Database/Frontend/Security/QA Agent biến card thành contract, implementation task, negative test và release evidence. Nếu một card không áp dụng, phải ghi `N/A` kèm lý do thay vì bỏ qua im lặng.

> Một feature web app hiếm khi chỉ là “thêm một màn hình và một endpoint”. Nó thường là thay đổi đồng thời ở product rule, state machine, data invariant, authorization, API contract, UI state, side effect, retry, observability và release.

## 1. Nguyên tắc nền tảng

Mỗi feature phải trả lời được năm câu hỏi trước khi code:

| Câu hỏi | Artifact cần có |
|---|---|
| Người dùng đang cố đạt outcome nào? | Product Discovery Brief, acceptance criteria, metric |
| Dữ liệu nào là source of truth và invariant nào phải luôn đúng? | Entity spec, state machine, constraint, migration note |
| Request nào được phép làm gì với resource nào? | Endpoint contract, permission/ownership matrix, threat model |
| Điều gì xảy ra khi timeout, retry, duplicate, concurrent request hoặc dependency chết? | Failure matrix, idempotency/retry/transaction design, negative tests |
| Làm sao biết feature đã chạy đúng và có thể vận hành? | Test evidence, logs/metrics/traces, runbook, rollback/release record |

Workflow phải ưu tiên **invariant và failure mode** hơn việc chỉ mô tả happy path. Đối với API, RFC 9457 cung cấp mô hình machine-readable cho problem details với `type`, `status`, `title`, `detail`, `instance` và extension members; endpoint nên giữ HTTP semantics và error contract ổn định thay vì tạo format tùy tiện [1].

## 2. Taxonomy các bài toán thường gặp

| Mã | Nhóm bài toán | Câu hỏi hay bị quên | Control mặc định |
|---|---|---|---|
| P-01 | Product ambiguity | Ai là user, outcome, rule và out-of-scope là gì? | Discovery, evidence, acceptance criteria, open questions |
| P-02 | Entity/lifecycle | Resource được tạo, sửa, publish, archive, delete và restore ra sao? | State machine, owner, invariant, audit trail |
| P-03 | CRUD/validation | Input sai, thiếu, thừa, duplicate và stale data xử lý thế nào? | DTO/schema validation, whitelist, field errors, unique constraint |
| P-04 | API contract | Client biết success, empty, error, pagination và version thế nào? | OpenAPI/JSON Schema, canonical envelope, Problem Details |
| P-05 | Authentication/session | Login, refresh, logout, revoke, recovery, MFA và expiry hoạt động ra sao? | Secure cookie/bearer policy, rotation, CSRF, session state machine |
| P-06 | Authorization/ownership | Có thể đọc/sửa resource của tenant, user, team hoặc role khác không? | Object/property/function authorization; deny-by-default |
| P-07 | Tenant/data isolation | Query có luôn scope đúng tenant/org/project không? | Tenant context, scoped repository, composite keys, negative tests |
| P-08 | Transaction/concurrency | Hai request đồng thời có oversell, double booking, lost update hay invalid state không? | DB constraint, transaction, lock/isolation, retry, concurrency test |
| P-09 | Idempotency/duplicate | Client retry, double click, webhook duplicate hoặc worker retry gây side effect mấy lần? | Idempotency key, event identity, parameter fingerprint, replay result |
| P-10 | List/search/report | Pagination, sort, filter, total, cursor, slow query và export lớn xử lý thế nào? | Stable ordering, bounded page, index/query plan, async export |
| P-11 | File/media/import | File giả, zip bomb, malware, quá lớn, orphan, formula injection và public URL ra sao? | Auth/signed upload, magic bytes, quotas, scan, private delivery, cleanup |
| P-12 | External integration | Provider timeout, schema drift, rate limit, partial success và secret rotation ra sao? | Adapter, timeout, circuit breaker, retry policy, contract fixture, reconciliation |
| P-13 | Payment/ledger | Amount, currency, webhook, refund, receipt và reconciliation có audit được không? | Immutable ledger, provider signature, idempotency, atomic transition, outbox |
| P-14 | Notification | Email/SMS/push duplicate, delayed, bounced hoặc chứa PII thì sao? | Outbox, idempotent message, template version, retry/DLQ, preference |
| P-15 | Realtime | Event có đến không, đúng thứ tự không, reconnect có resync không? | Event ID, version, auth, ack, dedup, persistence/offset nếu critical |
| P-16 | Queue/worker | Job chạy hai lần, treo, poison message hoặc worker crash xử lý thế nào? | Attempts, backoff+jitter, timeout, idempotent handler, DLQ/replay |
| P-17 | Cache/consistency | Cache stale, stampede, cross-user leak và invalidation ra sao? | Key scope, TTL, ownership, invalidation event, no-cache sensitive default |
| P-18 | AI/tool call | Prompt injection, SSRF, PII, cost runaway, tool misuse và output drift ra sao? | Schema output, tool allowlist, quota, egress policy, eval, human gate |
| P-19 | Observability | Khi lỗi xảy ra biết request nào, actor nào, dependency nào và impact bao nhiêu không? | Correlation ID, structured logs, traces, metrics, alert/runbook |
| P-20 | Deployment/migration | Migration fail, startup chưa ready, rollback schema và artifact drift ra sao? | Expand/contract, health/readiness, immutable artifact, smoke/rollback |
| P-21 | Privacy/compliance | Dữ liệu nào là PII/sensitive, retention và deletion thế nào? | Classification, minimization, access audit, retention/deletion, legal owner |
| P-22 | Performance/capacity | Khi 10x traffic/data thì query, memory, queue, provider cost và UI ra sao? | Budget, load test, query plan, rate limit, capacity record |
| P-23 | Supply chain | Dependency vulnerable, build không reproducible hoặc artifact bị thay đổi thì sao? | Lockfile, audit, SBOM/provenance, pinned image, review/exception |
| P-24 | Frontend state/accessibility | Loading/empty/403/409/offline/stale state và keyboard/screen reader ra sao? | State matrix, design tokens, WCAG target, E2E/a11y evidence |

OWASP API Security Top 10 tách riêng object-level, property-level và function-level authorization; đồng thời coi resource consumption, sensitive business flow, SSRF, misconfiguration, inventory và unsafe third-party API consumption là các rủi ro API độc lập [2]. Vì vậy “đã có JWT” không thể được xem là đã giải quyết authorization hoặc abuse.

## 3. Backend request lifecycle chuẩn

Một request mutation nên được phân tích theo chuỗi sau:

```text
Transport
  → request ID / trace context
  → authentication
  → rate limit / quota / abuse control
  → DTO/schema validation
  → authorization: function + object + property
  → tenant/ownership scope
  → transaction + invariant/lock
  → domain state transition
  → durable side effects/outbox
  → projection/cache invalidation
  → canonical response/error
  → audit event + metrics/log/trace
```

Mỗi lớp có một trách nhiệm khác nhau. Validation không thay authorization; authorization không thay database constraint; transaction không thay idempotency; queue retry không thay outbox; và log không thay audit trail. Nếu một lớp được bỏ qua, artifact phải ghi rõ lý do và residual risk.

## 4. Problem cards quan trọng nhất

### P-02 — Entity lifecycle và state machine

**Failure thường gặp:** Dùng string tự do, sửa trạng thái từ nhiều nơi, cho phép transition ngược, hard delete resource đã được tham chiếu hoặc không định nghĩa archive/restore.

**Pattern chuẩn:** Định nghĩa state registry, transition table, actor được phép transition, precondition, side effect, audit event, idempotency và terminal state. State transition phải là operation domain-level; không để controller tự thay string.

**Test bắt buộc:** Mỗi transition hợp lệ; mọi transition không hợp lệ; role sai; stale version; retry cùng transition; concurrent transition; delete/restore sau khi có reference.

### P-03/P-04 — Input và API contract

**Failure thường gặp:** Backend trả raw ORM row, field naming không thống nhất, `null`/missing lẫn lộn, lỗi chỉ có message text, pagination khác nhau giữa endpoint.

**Pattern chuẩn:** Request/response schema rõ; success envelope nhất quán; error có machine code/type và field pointer; data projection riêng; pagination có giới hạn và stable ordering; contract fixture được validate trong CI.

**Test bắt buộc:** Missing/extra/wrong-type/oversized input; 401/403/404/409/422/429/5xx; empty page; stale cursor; unknown field; schema backward compatibility.

### P-06/P-07 — Authorization và tenant isolation

**Failure thường gặp:** UI ẩn nút nhưng API không kiểm; chỉ kiểm role mà quên ownership; một query lấy theo `id` không kèm tenant; property nhạy cảm bị mass assignment.

**Pattern chuẩn:** Mỗi endpoint ghi function permission, object scope, property allowlist, tenant scope và audit requirement. Repository mặc định nhận scope bắt buộc; test cross-user/cross-tenant là negative test đầu tiên.

**Test bắt buộc:** IDOR read/update/delete; role downgrade; revoked user; cross-tenant ID; hidden property write; admin-only route; direct request không qua UI.

### P-08 — Transaction và concurrency

**Failure thường gặp:** Read-then-write không atomic, đếm slot ở Redis nhưng source of truth ở DB, giữ transaction khi gọi provider, chọn isolation mặc định mà không phân tích anomaly.

**Pattern chuẩn:** Xác định invariant; chọn source of truth; dùng unique/check/composite constraint trước khi dùng lock; chốt transaction boundary; chọn row/advisory/distributed lock nếu cần; không gọi network provider trong transaction dài; có retry cho serialization/deadlock.

PostgreSQL ghi rõ Read Committed là mặc định và hai lần đọc trong cùng transaction có thể thấy snapshot khác nhau; Serializable cho bảo đảm mạnh hơn nhưng có thể yêu cầu retry khi serialization failure [3]. Vì vậy mỗi counter, reservation, quota, balance và state transition phải có concurrency design, không chỉ một unit test tuần tự.

**Test bắt buộc:** Hai request đồng thời, duplicate insert, lost update, deadlock/serialization retry, timeout giữa các bước, process crash sau commit trước side effect.

### P-09 — Idempotency

**Failure thường gặp:** Double-click tạo hai order; client retry sau timeout tạo resource thứ hai; webhook lặp làm tăng slot/refund hai lần; worker retry gửi email/payment side effect lặp.

**Pattern chuẩn:** Key có scope theo operation/actor/resource; lưu parameter fingerprint và kết quả; xác định TTL/retention; mismatch trả conflict; xử lý request đang chạy; event provider có unique identity; side effect downstream cũng idempotent.

Tài liệu Stripe mô tả việc lưu status/body của lần đầu theo idempotency key, so sánh tham số khi key được dùng lại và không tạo kết quả idempotent cho validation failure hoặc request chưa bắt đầu thực thi [4]. Đây là pattern tham khảo, không phải lý do để sao chép nguyên implementation.

**Test bắt buộc:** Cùng key cùng payload, cùng key khác payload, retry sau connection loss, concurrent same key, expired key, duplicate webhook, worker replay.

### P-11 — Upload/import/export

**Failure thường gặp:** Chỉ kiểm extension, public upload không quota, lưu private data vào public URL, parse workbook lớn trong request, formula/HTML injection và file orphan.

**Pattern chuẩn:** Mục đích/resource trước upload; auth hoặc one-time signed token; giới hạn bytes/dimensions/duration/rows; kiểm magic bytes và content; scan; private-by-default; asynchronous processing; quarantine; cleanup; export lớn chạy job có download expiry.

**Test bắt buộc:** Wrong magic bytes, polyglot, oversized body, zip bomb, malicious filename/path, formula, HTML/script, abandoned upload, quota exhaustion, signed URL expiry.

### P-12 — External integrations và webhook

**Failure thường gặp:** Provider giữ transaction mở; retry không phân biệt lỗi tạm thời/vĩnh viễn; trust payload chưa verify signature; schema provider đổi; không có reconcile.

**Pattern chuẩn:** Adapter boundary; request timeout; circuit breaker; retry matrix; signature/timestamp/replay protection; provider reference; durable inbound event; outbox; reconciliation job; admin repair path.

**Test bắt buộc:** Timeout, 429, 5xx, malformed payload, invalid signature, duplicate/out-of-order event, provider success but local timeout, local commit but notification fail.

### P-13 — Payment/ledger

**Failure thường gặp:** Tin amount từ client, thanh toán và receipt không atomic, webhook đánh dấu success trước side effects, refund trùng, ledger mutable.

**Pattern chuẩn:** Server tính amount/currency; payment state machine; immutable ledger; provider signature; idempotent event; atomic local transition + outbox; reconciliation cho pending/orphan; audit log và segregation of duties.

**Test bắt buộc:** Amount mismatch, duplicate/out-of-order webhook, partial failure, refund twice, negative amount, concurrent payout, orphan payment, ledger balance invariant.

### P-15 — Realtime

**Failure thường gặp:** “Emit” bị coi là đã giao; reconnect mất event; listener leak; anonymous socket flood; payload không version; multi-instance presence sai.

**Pattern chuẩn:** Event envelope `{eventId,eventType,version,occurredAt,entityId,data}`; auth handshake và per-message authorization; ack/timeout; dedup; reconnect/resync; persistence/offset cho critical event; Redis adapter/presence khi scale.

Socket.IO mặc định là at-most-once; event server bị miss khi client disconnect không tự được replay. Delivery mạnh hơn cần event ID, persistence, client offset và replay application-level [5].

**Test bắt buộc:** Disconnect giữa send, duplicate event, out-of-order, expired token, unauthorized room, reconnect/resync, two tabs, two instances, flood/oversized payload.

### P-16 — Queue/worker

**Failure thường gặp:** Retry mọi lỗi, retry không backoff, side effect không idempotent, poison job quay vô hạn, không có DLQ/repair hoặc worker chết không có alert.

**Pattern chuẩn:** Job schema/version; correlation/idempotency key; timeout; transient/permanent error taxonomy; attempts; exponential backoff+jitter; DLQ; replay with guard; metrics; concurrency limit; graceful shutdown.

BullMQ hỗ trợ fixed/exponential backoff, jitter và custom strategy; custom backoff có thể quyết định job ngừng retry và chuyển failed [6]. Workflow phải yêu cầu chọn policy theo loại lỗi, không đặt `attempts` tùy tiện.

**Test bắt buộc:** Transient success after retry, permanent failure, provider 429, worker crash, duplicate delivery, poison job, DLQ replay, shutdown/restart.

### P-17 — Cache và consistency

**Failure thường gặp:** Cache không scope theo user/tenant, stale permission/data, stampede, cache-aside race, invalidation thiếu sau mutation.

**Pattern chuẩn:** Xác định cacheable data; key gồm tenant/subject/representation; TTL và max size; cache-aside/read-through; invalidation event; stale-while-revalidate chỉ khi chấp nhận; không cache sensitive response mặc định.

**Test bắt buộc:** Cross-user leak, stale after write, concurrent miss, expired entry, Redis unavailable, negative cache, permission revocation.

### P-18 — AI/tool calls

**Failure thường gặp:** Prompt injection, URL fetch SSRF, raw PII trong dataset, tool write không kiểm quyền, model output không schema, token/cost runaway.

**Pattern chuẩn:** Input classification; model output schema; tool registry deny-by-default; resource-scoped permission; egress allowlist; input/output limits; quota and budget; timeout/circuit breaker; transcript redaction; eval suite; human approval cho side effect.

**Test bắt buộc:** Malicious prompt, untrusted document, SSRF/private IP, invalid structured output, tool argument injection, quota exhaustion, upstream 429/5xx, PII redaction, high-impact action approval.

### P-19/P-20 — Observability và deployment

**Failure thường gặp:** Container running nhưng app chưa ready; migration fail vẫn deploy; log không có correlation; không biết queue/payment/provider nào gây lỗi; artifact mutable.

**Pattern chuẩn:** `/health/live` và `/health/ready`; dependency checks có timeout; structured logs; trace context; metrics theo route/status/provider/queue; SLO/error budget; immutable artifact; expand/contract migration; smoke test; rollback rehearsal.

Docker Compose documentation phân biệt container started với service ready và khuyến nghị healthcheck cùng `depends_on.condition` như `service_healthy` hoặc `service_completed_successfully` [7]. OpenTelemetry phân loại traces, metrics, logs và baggage thành các observability signals có thể liên kết [8].

**Test bắt buộc:** DB/Redis down, migration fail, readiness false, old image rollback, alert fire, trace propagation request-to-worker, log redaction, backup restore.

## 5. Decision tree chọn pattern

```text
Feature có side effect hoặc mutation?
  ├─ Không → contract + auth read + pagination/cache/privacy
  └─ Có
      ├─ Có tiền, quota, inventory, slot, booking hoặc unique resource?
      │   └─ transaction + constraint + concurrency test + idempotency
      ├─ Có provider/external API?
      │   └─ adapter + timeout + retry matrix + circuit breaker + reconcile
      ├─ Có webhook/event/queue?
      │   └─ durable identity + outbox/inbox + dedup + replay/DLQ
      ├─ Có file/HTML/URL/user content?
      │   └─ content validation + size/quota + egress/sandbox + privacy
      ├─ Có realtime?
      │   └─ event contract + auth + ordering/delivery/resync
      ├─ Có AI/tool?
      │   └─ output schema + tool policy + budget + eval + human gate
      └─ Luôn có
          └─ error contract + observability + negative tests + rollback note
```

## 6. Definition of Ready cho backend feature

Backend feature chỉ được bắt đầu khi đã xác định resource/tenant scope, state machine, source of truth, invariants, API contract, authorization, transaction/idempotency policy, external dependencies, failure matrix, migration/rollback, observability fields và test plan. `TODO`, “sẽ xử lý sau” hoặc “frontend đã chặn” không được coi là thiết kế hoàn tất.

## 7. Definition of Done cho backend feature

Feature chỉ được coi là done khi unit/API/contract/negative/concurrency tests phù hợp đã chạy; database constraint/migration đã review; error/authorization/ownership evidence tồn tại; external side effects có retry/reconcile; logs/metrics/traces không lộ secret; frontend đã mapping đủ state; và release record có rollback hoặc risk acceptance hợp lệ.

## 8. Cách chọn các card theo đề tài

| Đề tài | Card bắt buộc thường gặp |
|---|---|
| E-commerce | P-02, P-06, P-08, P-09, P-11, P-12, P-13, P-14, P-17, P-20 |
| Booking/reservation | P-02, P-06, P-08, P-09, P-10, P-12, P-14, P-15 |
| CRM/ERP | P-02, P-06, P-07, P-10, P-17, P-19, P-21 |
| LMS/CMS | P-02, P-03, P-06, P-10, P-11, P-14, P-17, P-24 |
| Social/community | P-05, P-06, P-11, P-14, P-15, P-16, P-18, P-21, P-24 |
| SaaS multi-tenant | P-06, P-07, P-08, P-09, P-10, P-17, P-19, P-20, P-21, P-22 |
| AI product | P-06, P-11, P-12, P-16, P-18, P-19, P-21, P-22, P-23 |
| Finance/high-impact | Tất cả card liên quan money, identity, authorization, audit, privacy, reconciliation và human approval; cần owner chuyên môn |

## References

[1]: [RFC 9457 — Problem Details for HTTP APIs](https://www.rfc-editor.org/info/rfc9457/)  
[2]: [OWASP Top 10 API Security Risks — 2023](https://owasp.org/API-Security/editions/2023/en/0x11-t10/)  
[3]: [PostgreSQL — Transaction Isolation](https://www.postgresql.org/docs/current/transaction-iso.html)  
[4]: [Stripe — Idempotent requests](https://docs.stripe.com/api/idempotent_requests)  
[5]: [Socket.IO — Delivery guarantees](https://socket.io/docs/v4/delivery-guarantees)  
[6]: [BullMQ — Retrying failing jobs](https://docs.bullmq.io/guide/retrying-failing-jobs)  
[7]: [Docker Docs — Control startup and shutdown order in Compose](https://docs.docker.com/compose/how-tos/startup-order/)  
[8]: [OpenTelemetry — Signals](https://opentelemetry.io/docs/concepts/signals/)  
