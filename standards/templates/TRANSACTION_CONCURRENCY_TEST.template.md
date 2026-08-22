# Transaction and Concurrency Test Plan

## 1. Scope

- Change ID:
- Feature/flow:
- Owner:
- Risk tier:
- Database/provider/queue involved:
- Test environment and isolation:

## 2. Invariants

| ID | Invariant | Authority | Failure if violated |
|---|---|---|---|
| INV-001 |  |  |  |
| INV-002 |  |  |  |

## 3. Transaction design

- Transaction boundary:
- Isolation level and rationale:
- Lock/optimistic version strategy:
- Unique/check/FK/exclusion constraints:
- Transaction timeout/deadlock policy:
- External calls inside/outside transaction:

## 4. Idempotency

- Operation:
- Key scope:
- Request fingerprint:
- Persistence/status/response replay:
- Same key/different payload behavior:
- Expiration policy:

## 5. Test scenarios

| ID | Scenario | Setup | Concurrent actions | Expected result | Evidence |
|---|---|---|---|---|---|
| CON-001 | Two requests claim last resource |  |  | Exactly one success |  |
| CON-002 | Retry after response timeout |  |  | No duplicate mutation |  |
| CON-003 | Duplicate webhook |  |  | Idempotent result |  |
| CON-004 | Out-of-order webhook |  |  | No invalid rollback |  |
| CON-005 | Worker redelivery |  |  | No duplicate side effect |  |
| CON-006 | Serialization/deadlock retry |  |  | Bounded retry or explicit fail |  |
| CON-007 | Partial external failure |  |  | Pending/reconciliation state |  |

## 6. Recovery

- Retryable vs non-retryable errors:
- Backoff/jitter/max attempts:
- Dead-letter/manual recovery:
- Reconciliation query/job:
- Repair approval and audit:

## 7. Observability

- Correlation/request/idempotency IDs:
- Lock wait/deadlock metrics:
- Duplicate/conflict metrics:
- Pending/reconciliation age:
- Alert thresholds:

## 8. Result

- Commands run:
- Pass/fail/blocked/skipped:
- Known limitation:
- Reviewer:
- Release decision:
