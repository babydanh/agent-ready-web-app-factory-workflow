# Feature Impact Review — [Change ID]

## 1. Decision

| Field | Value |
|---|---|
| Feature/change | [Name] |
| Owner | [Person/team] |
| Tier/profile | [SmallFix/Normal/HighRisk + profiles] |
| Source of truth | [Domain/API/event/state/schema] |
| Decision | GO / GO_WITH_CONDITIONS / HOLD / STOP |
| Decision owner/reviewer | [Person/team] |
| Blocking questions | [None or list with owner] |
| Rollback/stop trigger | [Condition] |

## 2. Problem and outcome

**Problem:** [User problem, not solution name]

**Desired outcome:** [Observable outcome]

**Non-goals:** [Explicitly out of scope]

**Evidence:** [Issue, screenshot, trace, code path, metric or user report]

**Alternatives considered:** [Alternative A/B and why]

## 3. Affected surface inventory

| Surface/route | Role/audience | Entry point | Data/state shown | Action changed? | Loading/empty/error/permission impact | Owner |
|---|---|---|---|---|---|---|
| [route/page/tab/modal] | [role] | [entry] | [state] | [yes/no] | [states] | [owner] |

## 4. Domain and state impact

```text
[CURRENT] --[action + precondition]--> [NEXT]
                         └──[failure/conflict/rollback]--> [RECOVERY]
```

| Current state | Action | Allowed role | Preconditions/invariants | Next state | Terminal/side effect | Recovery |
|---|---|---|---|---|---|---|
| [state] | [action] | [role] | [rules] | [state] | [effect] | [recovery] |

## 5. Contract and dependency impact

| Layer | Existing source/owner | Read/write | Change? | Compatibility/rollback |
|---|---|---|---|---|
| Database/schema | [path/owner] |  |  |  |
| Backend/service | [path/owner] |  |  |  |
| API/DTO/error | [path/owner] |  |  |  |
| Realtime/socket/job/cache | [path/owner] |  |  |  |
| Frontend Web | [route/component/hook/store] |  |  |  |
| App/Admin/Ops/Public | [path/surface] |  |  |  |
| Tests/docs/Graphify | [path] |  |  |  |

## 6. Risk and negative cases

| Risk/case | Expected behavior | Control/owner | Test/evidence |
|---|---|---|---|
| No permission/ownership |  |  |  |
| Empty/missing data |  |  |  |
| Invalid domain rule |  |  |  |
| Duplicate click/request |  |  |  |
| Timeout/offline/reconnect |  |  |  |
| Stale/concurrent update |  |  |  |
| Partial success/reload |  |  |  |
| Unknown server error |  |  |  |
| Long text/mobile/accessibility |  |  |  |

## 7. Traceability

| Acceptance criterion | Route/screen/button | Code/module | Test | Evidence | Status |
|---|---|---|---|---|---|
| [AC-001] |  |  |  |  | not-started |

## 8. Gate result

- [ ] Source of truth is identified.
- [ ] Affected routes/modules/platforms are listed.
- [ ] Roles/permissions/ownership are listed.
- [ ] State transitions and terminal behavior are explicit.
- [ ] Button-State Matrix is complete when actions change.
- [ ] Screen-State Matrix is complete when UI state changes.
- [ ] Cross-Platform Matrix is complete when multiple clients are affected.
- [ ] Negative cases and evidence are assigned.
- [ ] Decision owner approved GO or conditions have owner/deadline.

**Gate status:** READY / NEEDS_CLARIFICATION / NEEDS_REVIEW / BLOCKED
