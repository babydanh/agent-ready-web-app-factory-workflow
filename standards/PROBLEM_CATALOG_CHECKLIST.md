# Problem Catalog Execution Checklist

**Feature/change:** `<change-id>`  
**Domain:** `<domain>`  
**Risk tier:** `SmallFix | Normal | HighRisk`  
**Owner:** `<owner>`  
**Reviewer:** `<reviewer>`  
**Status:** `DRAFT | IN_REVIEW | BLOCKED | READY | DONE`

## 1. Discovery and domain

- [ ] User outcome, problem and out-of-scope are confirmed.
- [ ] Actor, role, tenant and ownership boundaries are written.
- [ ] Domain glossary has canonical names and definitions.
- [ ] State machine and terminal/irreversible transitions are defined.
- [ ] Invariants are listed with an enforcement layer and negative case.
- [ ] Applicable problem cards `P-01` through `P-24` are marked `yes` or `N/A + rationale`.
- [ ] Risk/compliance/SRE/AI profiles are selected.

## 2. Data and backend

- [ ] Source of truth is explicit for each important field/counter/state.
- [ ] Entity normalization, JSONB boundary, ownership key and retention are documented.
- [ ] FK, unique, check and composite cross-entity constraints are reviewed.
- [ ] Migration is backward-compatible or has an approved expand/contract plan.
- [ ] Query indexes, stable ordering and query-plan risk are recorded.
- [ ] Transaction boundary and isolation/lock policy are recorded.
- [ ] Concurrency cases are identified and tested.
- [ ] Idempotency key/event/job identity and replay/conflict policy are defined.
- [ ] External provider calls have timeout, retry, circuit and reconciliation policy.
- [ ] Side effects use outbox/inbox or durable state when process loss matters.

## 3. API and security

- [ ] Request/response schema and canonical success envelope are defined.
- [ ] Problem Details/error types cover validation, 401, 403, 404, 409, 429 and 5xx as applicable.
- [ ] Function, object, property and tenant authorization are separately reviewed.
- [ ] Unknown fields/mass assignment and output projection are controlled.
- [ ] Rate limit, quota and expensive-resource budget are defined.
- [ ] CSRF/CORS/origin/session policy is checked for state-changing requests.
- [ ] Upload, URL fetch, HTML/editor, import/export and third-party data risks are checked if applicable.
- [ ] Secrets, tokens, PII and provider payloads are redacted from logs/fixtures.
- [ ] Audit event is defined for sensitive/destructive/payment/admin actions.

## 4. Frontend/realtime

- [ ] Screen has initial/loading/success/empty/validation/401/403/404/409/429/5xx/offline/stale states as applicable.
- [ ] UI uses canonical field/status/error mapping, not message-text inference.
- [ ] Keyboard, focus, contrast, semantics and responsive behavior are checked.
- [ ] Realtime event has version, identity, auth, ordering, ack, dedup and resync policy if applicable.
- [ ] Cache key/invalidation/privacy behavior is defined if cache is used.

## 5. Jobs/integrations/AI

- [ ] Job has version, timeout, attempts, backoff/jitter, concurrency and DLQ/replay policy.
- [ ] Worker side effects are idempotent and safe under duplicate delivery.
- [ ] Webhook signature, timestamp/replay and durable event identity are tested.
- [ ] AI input/output/tool/turn/token/cost limits are hard-bounded if applicable.
- [ ] AI tool is deny-by-default and resource/role-scoped.
- [ ] AI eval includes capability, regression, safety, output schema and cost checks.
- [ ] High-impact AI side effect has human approval.

## 6. Operations and release

- [ ] Request/trace correlation, structured logs, metrics and alerts are defined.
- [ ] Liveness/readiness and dependency failure behavior are tested.
- [ ] SLI/SLO/error-budget impact is recorded for critical paths.
- [ ] Backup/restore, RPO/RTO and data repair path are identified where needed.
- [ ] Smoke test and rollback procedure are written and executable.
- [ ] High/critical dependency findings are patched or risk-accepted with owner/expiry.
- [ ] Required unit/API/contract/negative/concurrency/E2E/a11y/load tests have results.
- [ ] No hard gate is `not-run` or `blocked` without approved waiver.
- [ ] Release evidence links requirement → control → code → test → evidence.

## 7. Decision

| Gate | Result | Evidence | Owner |
|---|---|---|---|
| Product/domain | `PASS/HOLD/BLOCK` |  |  |
| Data/transaction | `PASS/HOLD/BLOCK` |  |  |
| API/compatibility | `PASS/HOLD/BLOCK` |  |  |
| Security/privacy | `PASS/HOLD/BLOCK` |  |  |
| UI/a11y/realtime | `PASS/HOLD/BLOCK` |  |  |
| Jobs/integration/AI | `PASS/HOLD/BLOCK/N/A` |  |  |
| SRE/release | `PASS/HOLD/BLOCK` |  |  |

**Decision:** `GO | GO_WITH_CONDITIONS | HOLD | STOP`  
**Open blockers:** `<list>`  
**Waiver:** `<owner, compensating control, expiry, approver or N/A>`  
**Next action:** `<one concrete action>`
