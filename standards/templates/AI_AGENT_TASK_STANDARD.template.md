# AI Agent Task — [TASK_ID]

## 1. Objective

```yaml
id: [TASK_ID]
title: [short title]
objective: [measurable outcome]
profile: PUBLIC_WEB | MONEY_MOVING | AI_ENABLED | INTERNAL
actor: [user role]
priority: P0 | P1 | P2 | P3
```

## 2. Context and source of truth

| Artifact | Path/version | Why authoritative |
|---|---|---|
| PRD/feature spec | `[path]` | `[reason]` |
| Data contract | `[path]` | `[reason]` |
| API contract | `[path]` | `[reason]` |
| Screen spec | `[path]` | `[reason]` |
| Security policy | `[path]` | `[reason]` |
| ADR | `[path]` | `[reason]` |

## 3. Allowed scope

```yaml
read_paths: []
write_paths: []
run_commands: []
forbidden_paths:
  - .env
  - secrets/
  - production-data/
forbidden_actions:
  - deploy production
  - send payment/email
  - print secrets
  - destructive database reset
```

## 4. Contract impact

```yaml
data_entities: []
new_fields: []
new_statuses: []
api_operations: []
ui_screens: []
realtime_events: []
jobs/outbox: []
migrations: []
breaking_change: false
```

Nếu `new_fields`, `new_statuses`, `api_operations` hoặc `migrations` khác với source of truth, agent phải dừng và yêu cầu contract update.

## 5. Security and privacy

| Control | Required? | Evidence expected |
|---|---:|---|
| Authentication | yes/no | `[test]` |
| Authorization/ownership | yes/no | `[negative test]` |
| CSRF/CORS | yes/no | `[origin test]` |
| Input/output validation | yes/no | `[schema test]` |
| Idempotency/concurrency | yes/no | `[retry/race test]` |
| PII/financial projection | yes/no | `[redaction test]` |
| Rate limit/abuse | yes/no | `[429/quota test]` |
| Audit/logging | yes/no | `[event evidence]` |

## 6. Acceptance criteria

- [ ] `[criterion 1]`
- [ ] `[criterion 2]`
- [ ] `[criterion 3]`

## 7. Execution plan

1. Read context and source files.
2. Produce impact map and implementation plan.
3. Verify contract and security policy.
4. Implement smallest vertical slice.
5. Run unit/API/contract/UI/security checks.
6. Review diff for scope creep and secrets.
7. Update state/changelog/evidence.

## 8. Required output

```yaml
status: DONE | BLOCKED | NEEDS_CLARIFICATION | NEEDS_HUMAN_REVIEW
summary: [summary]
changed_files: []
contract_changes: []
tests:
  ran: []
  passed: []
  failed: []
  skipped: []
security_findings: []
evidence: []
known_risks: []
next_actions: []
```

## 9. Stop conditions

Agent MUST stop if it encounters missing permission, secret exposure, destructive command, ambiguous ownership, unapproved schema/status, failed migration, flaky test, external side effect or security finding that cannot be assessed within scope.
