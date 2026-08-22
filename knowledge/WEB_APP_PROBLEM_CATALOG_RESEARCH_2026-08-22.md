# Research Notes — Web App/Backend Problem Catalog

## Phạm vi

Nghiên cứu này dùng để xây dựng problem catalog domain-agnostic cho web app/backend. Mục tiêu không phải đưa ra một framework duy nhất, mà rút ra các invariant, failure mode và evidence pattern có thể áp dụng lại cho nhiều đề tài.

## Nguồn và pattern chính

| Nguồn | Điều rút ra | Ứng dụng vào workflow |
|---|---|---|
| OWASP ASVS | Security controls cần có thể kiểm chứng; dùng như metric, guidance và verification basis | Mỗi feature có security control, negative test và evidence; không claim certification chỉ vì có checklist |
| OWASP API Security Top 10 | Object/property/function authorization, resource consumption, sensitive business flow, SSRF, misconfiguration, inventory và unsafe API consumption là các nhóm độc lập | Endpoint policy matrix phải tách từng lớp authorization, abuse budget, external API trust và route inventory |
| RFC 9457 | Error response machine-readable dùng `type`, `status`, `title`, `detail`, `instance` và extensions; media type `application/problem+json` | Canonical error contract, field-level validation pointers, stable problem type và compatibility migration |
| PostgreSQL Transaction Isolation | Read Committed là mặc định; concurrent operations có thể chờ/re-evaluate; Serializable mạnh hơn nhưng có thể cần retry | Mọi counter/booking/quota/balance/state transition phải có isolation/lock/constraint và concurrency test |
| Stripe Idempotent Requests | Retry-safe mutation cần key, result replay, parameter comparison, entropy, TTL và conflict semantics | Tách idempotency từ transaction; áp dụng cho POST/payment/webhook/worker mutation |
| Socket.IO Delivery Guarantees | Ordering không đồng nghĩa delivery; default at-most-once; stronger delivery cần event ID, persistence, offset và replay | Realtime contract phải có auth, ack, dedup, reconnect/resync và persistence cho critical event |
| BullMQ Retry Guide | Fixed/exponential backoff, jitter, attempts và custom stop-retry policy | Job contract phải phân biệt transient/permanent, timeout, idempotent handler, DLQ/replay và alert |
| Docker Compose Startup Order | Container running không đồng nghĩa service ready; healthcheck/depends_on condition giúp kiểm readiness | Deployment có liveness/readiness, dependency order, migration completion và smoke test |
| OpenTelemetry Signals | Traces, metrics, logs và baggage là các tín hiệu observability khác nhau | Chuẩn hóa correlation, request-to-worker trace, metrics theo route/provider/job và structured redacted logs |

## Tổng hợp principle

1. Validation, authorization, database constraints, transaction, idempotency, retry, outbox, observability và audit là các control khác nhau; không dùng một control để thay control khác.
2. Mọi shared invariant phải được phân tích dưới concurrency, duplicate, timeout, crash và out-of-order event, không chỉ happy path.
3. External provider outcome có thể unknown; cần provider reference, reconciliation và side-effect state.
4. Realtime “emit” không phải durable delivery; queue “retry” không phải idempotency.
5. API contract cần machine-stable fields và HTTP semantics, không dựa vào message text.
6. Security review phải cover object/property/function authorization và resource/cost abuse, không chỉ authentication.
7. Production readiness cần evidence của readiness, migration failure, rollback, backup/restore, alert và redaction.

## References

[1]: [OWASP Application Security Verification Standard](https://owasp.org/www-project-application-security-verification-standard/)  
[2]: [OWASP Top 10 API Security Risks — 2023](https://owasp.org/API-Security/editions/2023/en/0x11-t10/)  
[3]: [RFC 9457 — Problem Details for HTTP APIs](https://www.rfc-editor.org/info/rfc9457/)  
[4]: [PostgreSQL — Transaction Isolation](https://www.postgresql.org/docs/current/transaction-iso.html)  
[5]: [Stripe — Idempotent requests](https://docs.stripe.com/api/idempotent_requests)  
[6]: [Socket.IO — Delivery guarantees](https://socket.io/docs/v4/delivery-guarantees)  
[7]: [BullMQ — Retrying failing jobs](https://docs.bullmq.io/guide/retrying-failing-jobs)  
[8]: [Docker Docs — Control startup and shutdown order in Compose](https://docs.docker.com/compose/how-tos/startup-order/)  
[9]: [OpenTelemetry — Signals](https://opentelemetry.io/docs/concepts/signals/)  
