# Problem-Oriented Test Matrix — Web App/Backend

**Mục đích:** Dùng failure mode làm trung tâm thay vì chỉ liệt kê unit/API/E2E. Mỗi feature chọn các dòng áp dụng trong `WEB_APP_PROBLEM_MAP.template.md`, gắn test ID, fixture, command và evidence.

## 1. Risk tier minimum

| Test family | SmallFix | Normal | HighRisk |
|---|---:|---:|---:|
| Unit/domain happy path | MUST | MUST | MUST |
| Input/schema/contract | MUST | MUST | MUST |
| Authorization/object ownership | If protected | MUST | MUST |
| 401/403/404/409/422/429/5xx mapping | If applicable | MUST | MUST |
| Duplicate/idempotency | If mutation | MUST for mutation | MUST |
| Concurrency/transaction | If shared state | MUST for shared invariant | MUST |
| External timeout/429/5xx | If integration | MUST if integration | MUST |
| Queue retry/DLQ | If async | MUST if async | MUST |
| Realtime reconnect/resync | If realtime | MUST if realtime | MUST |
| Upload/import abuse | If file input | MUST if file input | MUST |
| Privacy/redaction | MUST if PII | MUST | MUST |
| Frontend E2E/state/a11y | Screen change | MUST | MUST |
| Performance/query plan | If hot path | SHOULD | MUST for critical path |
| Deployment/migration/rollback | If schema/config | SHOULD | MUST |
| AI safety/eval/cost | If AI | MUST if AI | MUST |

## 2. Authentication/session

| ID | Scenario | Expected assertion | Evidence |
|---|---|---|---|
| AUTH-001 | Wrong password repeated | Generic response, rate limit/lock policy, no enumeration |  |
| AUTH-002 | Expired access token | 401 canonical error; client refresh policy bounded |  |
| AUTH-003 | Refresh token replay | Reuse detected/revoked according to policy |  |
| AUTH-004 | Revoked/banned session | Protected endpoint denied even with valid-looking token |  |
| AUTH-005 | Recovery token reused/expired | Single-use/expired token rejected |  |
| AUTH-006 | CSRF/wrong origin | State-changing cookie request rejected |  |
| AUTH-007 | OAuth callback mismatch | State/nonce/PKCE/callback policy rejects attack |  |

## 3. Authorization/tenant isolation

| ID | Scenario | Expected assertion | Evidence |
|---|---|---|---|
| AUTHZ-001 | User A reads User B object ID | 403/404 according to concealment policy |  |
| AUTHZ-002 | User A updates User B object | No mutation occurs |  |
| AUTHZ-003 | Normal user calls admin function | Function-level denial |  |
| AUTHZ-004 | Cross-tenant filter/query | No cross-tenant row or aggregate |  |
| AUTHZ-005 | Mass assignment of protected property | Property ignored/rejected |  |
| AUTHZ-006 | Role downgrade during session | New permission takes effect according to policy |  |
| AUTHZ-007 | Hidden UI action called directly | Backend remains authoritative |  |

## 4. Data integrity/concurrency/idempotency

| ID | Scenario | Expected assertion | Evidence |
|---|---|---|---|
| DATA-001 | Two requests consume last slot | At most one succeeds; invariant holds |  |
| DATA-002 | Same mutation retried with same key | One durable side effect; replay/conflict policy |  |
| DATA-003 | Same key with different payload | Conflict; no second mutation |  |
| DATA-004 | Duplicate webhook | One event effect; duplicate recorded/ignored |  |
| DATA-005 | Out-of-order event | State transition policy prevents regression |  |
| DATA-006 | Lost update/stale version | Conflict or optimistic retry, no silent overwrite |  |
| DATA-007 | DB deadlock/serialization failure | Bounded safe retry, no duplicate side effect |  |
| DATA-008 | Crash after DB commit before side effect | Outbox/reconcile eventually handles side effect |  |
| DATA-009 | Invalid cross-entity relation | DB/service rejects relation |  |
| DATA-010 | Soft delete/archive reference | Referential/domain policy holds |  |

## 5. API and contract

| ID | Scenario | Expected assertion | Evidence |
|---|---|---|---|
| API-001 | Extra/unknown input field | Rejected or intentionally ignored per contract |  |
| API-002 | Wrong type/format/range | 422/400 Problem Details with field pointer |  |
| API-003 | Empty result | Canonical success envelope and empty semantics |  |
| API-004 | Invalid cursor/sort/filter | Bounded, allowlisted error |  |
| API-005 | Rate limited request | 429, retry metadata and no unsafe automatic replay |  |
| API-006 | Provider/internal exception | Generic client error; no secret/stack/provider detail |  |
| API-007 | Deprecated field/version | Compatibility/deprecation behavior is explicit |  |
| API-008 | Contract fixture drift | CI fails before merge |  |

## 6. File/import/export/content

| ID | Scenario | Expected assertion | Evidence |
|---|---|---|---|
| FILE-001 | Wrong magic bytes with allowed extension | Rejected |  |
| FILE-002 | Oversized body/dimensions/rows | Rejected before unbounded processing |  |
| FILE-003 | Zip bomb/polyglot/malicious archive | Quarantined/rejected and audited |  |
| FILE-004 | Formula/HTML/script content | Sanitized or rejected; no execution |  |
| FILE-005 | Aborted upload/orphan object | Cleanup/reconciliation occurs |  |
| FILE-006 | Unauthorized download URL | Denied or signed URL expires |  |
| FILE-007 | Public upload abuse/quota exhaustion | Auth/token/quota/rate limit works |  |
| FILE-008 | Large export | Async job, scope check, expiry and audit |  |

## 7. External provider/payment/webhook

| ID | Scenario | Expected assertion | Evidence |
|---|---|---|---|
| EXT-001 | Provider timeout with unknown outcome | Reconcile; no unsafe duplicate |  |
| EXT-002 | Provider 429 | Backoff/Retry-After/budget policy |  |
| EXT-003 | Provider 5xx | Bounded retry and final state |  |
| EXT-004 | Invalid signature/timestamp | Reject; alert/audit |  |
| EXT-005 | Duplicate/out-of-order webhook | Durable identity and monotonic transition |  |
| EXT-006 | Provider schema drift | Critical fields fail closed/quarantine |  |
| PAY-001 | Amount/currency tamper | Server-derived value wins; request rejected |  |
| PAY-002 | Duplicate refund/payout | One ledger effect, unique idempotency |  |
| PAY-003 | Payment success/receipt failure | Atomic local record or reconcile state |  |
| PAY-004 | Ledger invariant violation | Transaction/constraint blocks mutation |  |

## 8. Queue/realtime/cache

| ID | Scenario | Expected assertion | Evidence |
|---|---|---|---|
| JOB-001 | Transient worker failure | Retry with bounded backoff/jitter |  |
| JOB-002 | Permanent/poison job | No infinite retry; DLQ/alert/repair path |  |
| JOB-003 | Duplicate job delivery | Idempotent handler |  |
| JOB-004 | Worker crash during side effect | Safe replay/reconciliation |  |
| RT-001 | Client disconnects during event | Ack/resync/replay policy |  |
| RT-002 | Duplicate/out-of-order event | Event ID/version/dedup policy |  |
| RT-003 | Unauthorized room/message | Denied per message/resource |  |
| RT-004 | Multi-instance reconnect | Adapter/presence/source-of-truth policy |  |
| CACHE-001 | Cross-user/tenant cache key | No data leak |  |
| CACHE-002 | Read after mutation | Staleness/invalidation policy holds |  |
| CACHE-003 | Cache stampede | Bounded load and fallback |  |
| CACHE-004 | Redis unavailable | Safe degraded behavior |  |

## 9. AI/resource abuse/observability

| ID | Scenario | Expected assertion | Evidence |
|---|---|---|---|
| AI-001 | Prompt injection/untrusted document | Instruction/data boundary holds |  |
| AI-002 | Tool called outside role/resource scope | Denied; no side effect |  |
| AI-003 | Invalid model structured output | Runtime schema rejects/quarantines |  |
| AI-004 | Token/turn/daily budget exceeded | Hard stop and user-safe error |  |
| AI-005 | URL/private IP/redirect abuse | Egress policy blocks |  |
| AI-006 | Provider 429/5xx/slow response | Timeout/circuit/retry policy |  |
| AI-007 | PII/secret in transcript/log | Redaction test passes |  |
| OBS-001 | Request-to-worker trace | Correlation context preserved |  |
| OBS-002 | High error/latency threshold | Metric and alert fire |  |
| OBS-003 | Logs contain secret/token | Redaction scanner/test fails build |  |
| OBS-004 | Audit event missing for sensitive action | Release gate blocks |  |

## 10. Deployment/recovery

| ID | Scenario | Expected assertion | Evidence |
|---|---|---|---|
| DEP-001 | Missing production secret | Startup/deploy fails closed |  |
| DEP-002 | Dependency process running but not ready | Readiness blocks dependent app |  |
| DEP-003 | Migration fails | Release stops; no false success |  |
| DEP-004 | Backward-compatible expand migration | Old/new app versions coexist safely |  |
| DEP-005 | Rollback after bad artifact | Previous artifact restored and smoke passes |  |
| DEP-006 | DB/Redis unavailable | Health/readiness/alert behavior |  |
| DEP-007 | Backup restore | RPO/RTO and integrity evidence |  |

## 11. Test reporting rules

Mỗi test row phải có `not-run`, `pass`, `fail` hoặc `blocked`; không được bỏ trống. `not-run` không được chuyển thành `pass` bằng cách diễn giải. Test bị skip vì environment phải có lý do, owner, thời hạn và risk decision. HighRisk feature không được release khi một hard gate là `not-run` hoặc `blocked` nếu chưa có human-approved waiver có expiry.

Test evidence cần lưu command/version, fixture/data setup, timestamp, result, artifact khi fail và link ngược tới requirement/control/endpoint/entity/screen. Không lưu secret, raw production PII hoặc provider token.
