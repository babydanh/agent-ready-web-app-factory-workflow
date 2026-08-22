# Remediation Backlog — Sporto Web App

**Nguồn:** `WEB_APP_AUDIT_2026-08-22.md`  
**Trạng thái ban đầu:** Open  
**Nguyên tắc:** Không đóng finding bằng cách tắt scanner, nới rate limit hoặc đánh dấu risk accepted khi chưa có owner, scope, expiry và bằng chứng phê duyệt.

## Wave 0 — Block production

| ID | Owner đề xuất | Việc cần làm | Evidence đóng finding |
|---|---|---|---|
| AUD-001 | Security + Backend | Xây URL fetch policy: HTTPS-only, allowlist, private-IP/DNS-rebinding block, redirect cap, body-byte cap, egress proxy/worker. | SSRF test matrix pass; logs chứng minh blocked requests; positive allowlist test |
| AUD-002 | DevOps + Security | Tách Compose dev/prod; bỏ default secret; production fail-closed; private DB/Redis; firewall review; pin image digest; `NODE_ENV=production`. | Redacted `compose config`; startup-failure tests; port exposure evidence; secret manager record |
| AUD-003 | Security + Backend | Auth/signed upload token, magic-byte validation, media limits, malware scan, quota/rate limit, private delivery và orphan cleanup. | Upload abuse tests; signed URL expiry; quota metrics; cleanup job evidence |
| AUD-004 | DevOps | Upgrade Multer và xlsx qua lockfile; review 31 frontend/10 backend advisories; isolate paths nếu chưa thể upgrade. | `pnpm audit` report; compatibility tests; approved exception có expiry nếu còn CVE |

## Wave 1 — Business integrity

| ID | Owner đề xuất | Việc cần làm | Evidence đóng finding |
|---|---|---|---|
| AUD-005 | Backend + DevOps | Redis-backed limiter cho HTTP/AI/upload/payment; message/connection budget cho WS; staging limits gần production. | Distributed limiter test trên hai instance; 429 headers; abuse dashboard |
| AUD-006 | Backend | Hold key theo payment ID; Lua release-once; chỉ release sau transition thành công; expiry reconciler. | Duplicate webhook/concurrent create-link tests; Redis/DB reconciliation report |
| AUD-007 | Backend | Outbox cho post-payment status/notification; retry/backoff/DLQ; correlation ID và alert. | Crash/retry test; outbox state evidence; notification eventual-consistency test |
| AUD-008 | Backend + Database | Transaction cho payment + pending receipt; provider attach state machine; orphan reconciler. | Transaction failure test; orphan report; reconciliation run |
| AUD-009 | Database + Domain | Composite integrity/unique/check constraints; migration backward-compatible; invariant test. | Migration SQL review; DB constraint tests; cross-tournament negative tests |

## Wave 2 — Release quality

| ID | Owner đề xuất | Việc cần làm | Evidence đóng finding |
|---|---|---|---|
| AUD-010 | Frontend | Bỏ `typescript.ignoreBuildErrors`; build phải chặn type error; giữ `tsc --noEmit` trong CI. | Build fail fixture có type error; build pass evidence sau restore |
| AUD-011 | QA + Frontend | Thêm Playwright desktop/mobile, auth fixture, DB reset/seed, payment/live/chat E2E. | CI trace/video/screenshot; test report; isolation proof |
| AUD-012 | DevOps | Migration fail block deploy; artifact SHA/digest; health-gated rollout; backup/rollback đã thử. | Failed migration stops release; rollback drill; release record |
| AUD-013 | DevOps + Backend | Liveness/readiness, structured logs, request ID, metrics, traces và alert/runbook. | Healthcheck evidence; dashboard; alert test; sampled trace |

## Wave 3 — Hardening

| ID | Owner đề xuất | Việc cần làm | Evidence đóng finding |
|---|---|---|---|
| AUD-014 | AI + Security | Quota/token/concurrency budget; generic errors; runtime output schema; role/resource-scoped tools; SSRF fix. | AI abuse tests; spend/latency metrics; output schema negative tests |
| AUD-015 | DevOps + Security | Exact origin allowlist; trusted proxy list/count; CORS/CSRF matrix; subdomain ownership review. | Origin test matrix; spoofed forwarded-header test; ingress config review |
| AUD-016 | Realtime + DevOps | Redis presence, Socket.IO adapter, heartbeat/TTL, instance broadcast. | Multi-instance presence test; reconnect/last-seen evidence |
| AUD-017 | Realtime + Security | Quyết định guest socket policy; handshake/message budget; token expiry disconnect. | Unauthorized connection test; flood test; expiry test |
| AUD-018 | Database + Domain | Chuẩn hóa status registry và DB check/enum; contract tests. | Invalid status insert rejected; API/UI/worker contract report |
| AUD-019 | Platform | Logger facade redaction, audit event schema, retention/access policy, alert anomaly. | Redaction test; audit-log sample; retention configuration |
| AUD-020 | Frontend + Security | Sandbox xlsx/import; giới hạn rows/formulas; sanitize rich text; upgrade parser. | Large-sheet/zip-bomb/prototype-pollution regression suite |

## Definition of Ready

Một task chỉ được bắt đầu khi có feature/route scope, threat/control hypothesis, file/module impact map, migration cần thiết, test plan và rollback note. Secret thật không được đưa vào issue, Markdown, fixture hoặc commit.

## Definition of Done

Một finding chỉ được đóng khi remediation code/config đã review, negative test đã chạy, evidence được lưu trong release record, scanner không còn finding tương ứng hoặc có risk acceptance có owner và thời hạn, và các consumer liên quan đã được kiểm tra regression.

## Release gates

```text
P0 còn mở                         -> BLOCK
High dependency chưa xử lý       -> BLOCK hoặc risk acceptance có expiry
SSRF/upload/payment integrity    -> BLOCK nếu không có negative test
Build bỏ qua type error          -> BLOCK
E2E không chạy được              -> NEEDS_REVIEW, không được PASS
Readiness/rollback chưa chứng minh -> BLOCK production
```

## Suggested first sprint

1. Xử lý AUD-001 và AUD-002 trước khi expose public production.
2. Patch dependency high và khóa upload surface.
3. Sửa AUD-006 đến AUD-009 để bảo vệ slot/payment/ledger.
4. Bỏ build type bypass và thêm frontend E2E cho auth/payment/live.
5. Thêm readiness, structured logging và release rollback drill.
