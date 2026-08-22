# Backend Feature Design — `<feature-name>`

**Feature/change ID:** `<change-id>`  
**Domain:** `<domain>`  
**Owner:** `<team/person>`  
**Risk tier:** `SmallFix | Normal | HighRisk`  
**Status:** `DRAFT | IN_REVIEW | APPROVED | BLOCKED | DONE`  
**Related problem cards:** `P-..`

## 1. Command/query boundary

**Operation type:** `query | command | event consumer | scheduled job`  
**Actor:** `<user/service/worker/provider>`  
**Resource:** `<resource>`  
**Scope:** `<tenant/org/team/user>`  
**Business outcome:** `<outcome>`  
**Out-of-scope:** `<explicit exclusions>`

## 2. Source of truth and invariants

| ID | Invariant | Source of truth | Enforcement layer | Violation response |
|---|---|---|---|---|
| INV-001 | `<must always be true>` | `DB/service/provider/event` | `constraint/service/worker` | `409/reject/reconcile/alert` |
| INV-002 |  |  |  |  |

**State machine:** `<state diagram/table/link>`

| From | To | Actor | Preconditions | Side effects | Idempotent? |
|---|---|---|---|---|---|
|  |  |  |  |  |  |

## 3. Database design

**Entities/tables:** `<list>`  
**Normalization decision:** `<normalized/JSONB rationale>`  
**Ownership/tenant key:** `<column/scope>`  
**Foreign keys/composite constraints:** `<list>`  
**Unique/check constraints:** `<list>`  
**Indexes/query paths:** `<list>`  
**Migration strategy:** `expand | contract | additive | backfill | none`  
**Rollback/repair:** `<procedure>`  
**Retention/deletion:** `<policy>`

## 4. API contract

**Method/path/version:** `<GET/POST/...>`  
**Authentication:** `<required/optional/public and why>`  
**Function authorization:** `<permission>`  
**Object authorization:** `<ownership/tenant rule>`  
**Property allowlist:** `<writable fields>`  
**Idempotency:** `<key scope, storage, TTL, replay/conflict>`  
**Rate limit/quota:** `<policy>`  
**Success schema:** `<schema/path>`  
**Error types/statuses:** `<400/401/403/404/409/422/429/5xx>`  
**Pagination/cache:** `<policy or N/A>`  
**Compatibility/deprecation:** `<policy>`

## 5. Transaction and concurrency

**Transaction boundary:** `<what is atomic>`  
**Isolation level:** `<default/explicit and rationale>`  
**Lock strategy:** `<none/row/advisory/Redis/Lua and rationale>`  
**Race being prevented:** `<oversell/lost update/duplicate/state regression>`  
**Retry policy:** `<serialization/deadlock/timeout>`  
**External calls inside transaction:** `none | justified with timeout`

## 6. Side effects and dependencies

| Side effect/dependency | Trigger | Delivery | Retryable? | Idempotency | Reconcile/DLQ | Owner |
|---|---|---|---|---|---|---|
|  |  | `sync/outbox/job/realtime` |  |  |  |  |

**Provider/webhook signature:** `<policy>`  
**Timeout/circuit breaker:** `<policy>`  
**Secret/config source:** `<secret manager/env reference, never value>`

## 7. Security/privacy

| Control | Decision/evidence |
|---|---|
| Authentication/session |  |
| Object/property/function authorization |  |
| CSRF/CORS/origin |  |
| Input/output validation |  |
| SSRF/egress/upload/content |  |
| Rate limit/resource budget |  |
| Audit event |  |
| PII classification/minimization |  |
| Logging redaction |  |

## 8. Observability

**Correlation/request ID:** `<field>`  
**Trace/span names:** `<names>`  
**Metrics:** `<counter/histogram/gauge and dimensions>`  
**Structured log events:** `<event names, redacted fields>`  
**Alerts/runbook:** `<links/thresholds>`  
**SLO impact:** `<service indicator/objective>`

## 9. Test matrix

| Scenario | Test type | Expected result | Test ID/command | Evidence |
|---|---|---|---|---|
| Happy path | Unit/API/E2E |  |  |  |
| Invalid input | API |  |  |  |
| Unauthorized/IDOR | Security/API |  |  |  |
| Duplicate/idempotency | Integration |  |  |  |
| Concurrent request | Concurrency |  |  |  |
| Dependency timeout/429/5xx | Integration |  |  |  |
| Partial failure/crash | Integration/chaos |  |  |  |
| Realtime/retry/DLQ | Integration |  |  |  |
| Privacy/logging | Security |  |  |  |
| Performance/query plan | Load/DB |  |  |  |
| Migration/rollback | Deployment |  |  |  |

## 10. Review and release

**Required reviewers:** `Product, Domain, Database, Backend, Frontend, Security, QA, DevOps, AI as applicable`  
**Open blockers:** `<list>`  
**Waiver:** `<owner/reason/control/expiry/approver or N/A>`  
**Decision:** `GO | GO_WITH_CONDITIONS | HOLD | STOP`  
**Release evidence:** `<link>`

## 11. Handoff report

```yaml
status: DONE | BLOCKED | NEEDS_CLARIFICATION | NEEDS_HUMAN_REVIEW
summary: "..."
source_of_truth: []
completed: []
files_changed: []
commands_or_tests_run: []
test_results: []
contract_changes: []
evidence: []
risks_or_findings: []
open_questions: []
next_action: "..."
```
