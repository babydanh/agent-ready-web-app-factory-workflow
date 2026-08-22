# Web App Problem Map — `<change-id>`

**Feature:** `<feature name>`  
**Domain:** `<domain>`  
**Owner:** `<person/team>`  
**Risk tier:** `SmallFix | Normal | HighRisk`  
**Date:** `<YYYY-MM-DD>`  
**Status:** `DRAFT | IN_REVIEW | BLOCKED | READY | DONE`

## 1. Feature boundary

**User outcome:** `<what the user is trying to achieve>`  
**In scope:** `<explicit scope>`  
**Out of scope:** `<explicit exclusions>`  
**Consumers:** `<frontend/mobile/admin/worker/external provider>`  
**Source of truth:** `<database/service/provider/event>`

## 2. Applied problem cards

| Card | Applies? | Why/N/A rationale | Owner | Evidence link |
|---|---|---|---|---|
| P-02 Entity/lifecycle | `yes/no` |  |  |  |
| P-03 CRUD/validation | `yes/no` |  |  |  |
| P-04 API contract | `yes/no` |  |  |  |
| P-05 Authentication/session | `yes/no` |  |  |  |
| P-06 Authorization/ownership | `yes/no` |  |  |  |
| P-07 Tenant/data isolation | `yes/no` |  |  |  |
| P-08 Transaction/concurrency | `yes/no` |  |  |  |
| P-09 Idempotency/duplicate | `yes/no` |  |  |  |
| P-10 Search/list/report | `yes/no` |  |  |  |
| P-11 File/media/import | `yes/no` |  |  |  |
| P-12 External integration | `yes/no` |  |  |  |
| P-13 Payment/ledger | `yes/no` |  |  |  |
| P-14 Notification | `yes/no` |  |  |  |
| P-15 Realtime | `yes/no` |  |  |  |
| P-16 Queue/worker | `yes/no` |  |  |  |
| P-17 Cache/consistency | `yes/no` |  |  |  |
| P-18 AI/tool call | `yes/no` |  |  |  |
| P-19 Observability | `yes/no` |  |  |  |
| P-20 Deployment/migration | `yes/no` |  |  |  |
| P-21 Privacy/compliance | `yes/no` |  |  |  |
| P-22 Performance/capacity | `yes/no` |  |  |  |
| P-23 Supply chain | `yes/no` |  |  |  |
| P-24 Frontend/accessibility | `yes/no` |  |  |  |

## 3. Invariants and state

| ID | Invariant/state rule | Layer that enforces it | Negative case | Test/evidence |
|---|---|---|---|---|
| INV-001 | `<rule that must always be true>` | `DB/service/API/worker` | `<how it can break>` |  |
| INV-002 |  |  |  |  |

**State machine:** `<link or Mermaid/state table>`

**Allowed transitions:** `<from → to, actor, precondition, side effect>`

**Terminal/irreversible states:** `<list>`

## 4. Cross-layer impact map

| Layer | Files/modules | Contract/artifact | Change required? | Reviewer |
|---|---|---|---|---|
| Database/schema |  | Entity/migration/query plan |  |  |
| Backend/API |  | Endpoint/event/error contract |  |  |
| Queue/worker |  | Job schema/retry/DLQ |  |  |
| Realtime |  | Event version/order/resync |  |  |
| External provider |  | Adapter/webhook/reconcile |  |  |
| Frontend/UI |  | Screen/state/accessibility |  |  |
| Security |  | Threat/control/test |  |  |
| SRE/operations |  | SLI/SLO/alert/runbook |  |  |
| AI |  | Eval task/budget/tool policy |  |  |

## 5. Failure matrix

| Failure/abuse | Expected behavior | HTTP/event/job state | Retry? | Alert/audit? | Test ID |
|---|---|---|---|---|---|
| Duplicate request |  |  |  |  |  |
| Concurrent request |  |  |  |  |  |
| Unauthorized owner/tenant |  |  |  |  |  |
| Dependency timeout |  |  |  |  |  |
| Dependency 4xx/5xx/429 |  |  |  |  |  |
| Process crash/partial commit |  |  |  |  |  |
| Stale cache/reconnect |  |  |  |  |  |
| Malicious/oversized input |  |  |  |  |  |
| Privacy/logging violation |  |  |  |  |  |

## 6. Contracts and compatibility

**API contract:** `<path/version>`  
**Data contract:** `<entity/schema/migration>`  
**Event/job contract:** `<path/version or N/A>`  
**Backward-compatible consumers:** `<list>`  
**Breaking-change decision:** `none | additive | migration | versioned | blocked`  
**Deprecation/rollback:** `<plan>`

## 7. Test and evidence plan

| Test class | Required? | Command/spec | Result | Evidence |
|---|---|---|---|---|
| Unit/domain |  |  | `not-run/pass/fail` |  |
| API/contract/schema |  |  |  |  |
| Authorization/IDOR |  |  |  |  |
| Negative/abuse |  |  |  |  |
| Concurrency/idempotency |  |  |  |  |
| Integration/provider |  |  |  |  |
| Queue/retry/DLQ |  |  |  |  |
| Realtime/reconnect |  |  |  |  |
| Frontend/E2E/a11y |  |  |  |  |
| Performance/load |  |  |  |  |
| Deployment/rollback |  |  |  |  |
| AI eval/safety/cost |  |  |  |  |

## 8. Gate decision

**Open blockers:** `<P0/P1 or missing evidence>`  
**Waiver:** `<owner, reason, compensating control, expiry, approver or N/A>`  
**Decision:** `GO | GO_WITH_CONDITIONS | HOLD | STOP`  
**Reviewer:** `<name/date>`  
**Next action:** `<one concrete action>`

## 9. Agent handoff

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
