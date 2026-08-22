# Compliance Traceability — [FEATURE_ID]

## Scope

| Field | Value |
|---|---|
| Feature/release | `[id/version]` |
| Profile | `MVP_INTERNAL / PUBLIC_WEB / MONEY_MOVING / AI_ENABLED / ...` |
| Owner | `[name/team]` |
| Reviewer | `[name/team]` |
| Audit date | `[YYYY-MM-DD]` |
| Commit/build | `[hash/artifact]` |

## Requirement-to-evidence matrix

| Requirement ID | Requirement | Risk/control | Artifact | Code/route/screen | Test ID | Evidence | Status |
|---|---|---|---|---|---|---|---|
| REQ-001 | `[user outcome]` | `[control]` | `[PRD/API/UI]` | `[path]` | `[test]` | `[report/trace]` | Open |
| DATA-001 | `[field/invariant]` | `[validation/FK]` | `[data spec]` | `[schema/service]` | `[test]` | `[migration/test]` | Open |
| API-001 | `[endpoint behavior]` | `[auth/error/idempotency]` | `[contract]` | `[route]` | `[contract test]` | `[fixture]` | Open |
| UI-001 | `[screen behavior]` | `[accessibility/state]` | `[screen spec]` | `[page/component]` | `[E2E/a11y]` | `[trace]` | Open |
| SEC-001 | `[security objective]` | `[threat/control]` | `[threat model]` | `[guard/service]` | `[negative test]` | `[report]` | Open |
| OPS-001 | `[operational objective]` | `[health/backup/rollback]` | `[runbook]` | `[deploy]` | `[drill]` | `[release record]` | Open |

## Waiver register

| Finding/control | Reason | Compensating control | Owner | Expiry | Approval |
|---|---|---|---|---|---|
| `[ID]` | `[reason]` | `[control]` | `[owner]` | `[date]` | `[approver]` |

No waiver may remove a P0/P1 control without explicit human risk acceptance, expiry and follow-up task.

## Final decision

```yaml
status: PASS | PASS_WITH_RISK | NEEDS_REVIEW | BLOCKED
blocking_findings: []
open_p2_p3: []
known_limitations: []
rollback_verified: false
reviewer: [name]
reviewed_at: [timestamp]
```
