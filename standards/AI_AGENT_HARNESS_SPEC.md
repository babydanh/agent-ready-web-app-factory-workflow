# AI Agent Harness Specification

## 1. Purpose

Harness là lớp điều phối biến AI Agent từ người viết code tự do thành một worker có context, quyền hạn, state, output schema, reviewer và evidence. Harness không thay thế CI/CD, authorization hoặc human approval; nó làm cho hành vi của agent có thể lặp lại, kiểm tra và audit.

## 2. Task state machine

```text
QUEUED → CONTEXT_LOADING → PLANNED → AWAITING_APPROVAL → EXECUTING
  → VERIFYING → REVIEWING → DONE
                         ↘ BLOCKED
                         ↘ NEEDS_CLARIFICATION
                         ↘ FAILED_RETRYABLE → EXECUTING
```

`AWAITING_APPROVAL` bắt buộc với migration destructive, auth/payment/recovery, public exposure, production action, contract breaking change hoặc bất kỳ external side effect nào. `BLOCKED` không được tự chuyển thành `DONE`; cần input hoặc decision mới.

## 3. Persistent task record

```yaml
id: task_20260822_001
parentTaskId: null
state: CONTEXT_LOADING
role: backend | frontend | qa | security | architect | reviewer
goal: measurable outcome
allowedPaths: []
forbiddenPaths: [.env, secrets, production-data]
sourceOfTruth: []
contractVersion: null
attempt: 1
maxAttempts: 2
startedAt: null
updatedAt: null
artifacts: []
evidence: []
blockingReasons: []
```

Task state phải được lưu trước/sau các bước lớn để resume an toàn. Không lưu secret, access token, raw PII hoặc production payload vào state/log.

## 4. Role and tool boundary

| Role | Allowed primary work | Mandatory handoff |
|---|---|---|
| Architect | Context map, ADR, impact map | Approved design/contract |
| Backend | Schema, service, API, migration | Tests, contract diff, security impact |
| Frontend | Screen, components, state mapping | Screenshots/a11y/type evidence |
| QA | Test plan, fixtures, E2E, regression | Repro steps and severity |
| Security | Threat model, abuse cases, negative tests | Findings and release recommendation |
| DevOps | Environment, health, migration/runbook | Rollback/observability evidence |
| Reviewer | Scope, contract, evidence, risks | PASS/REQUEST_CHANGES/BLOCKED |

Least privilege applies to paths and commands. A role may request a handoff rather than editing outside its scope. Tools that can post, pay, deploy, delete or change production require explicit human approval.

## 5. Execution loop

1. Load only relevant project state, standards, source-of-truth artifacts and focused code paths.
2. Build an impact map and list assumptions.
3. Validate contract, privacy, security and dependency constraints.
4. Return `NEEDS_CLARIFICATION` when a field, status, ownership or acceptance rule is unspecified.
5. Implement a small vertical slice with evidence-friendly changes.
6. Run targeted checks, then broader gates proportional to risk.
7. Self-review for secrets, scope creep, raw ORM exposure, unsafe logs, missing states and contract drift.
8. Handoff to independent reviewer/role; update state and evidence.

## 6. Retry and failure policy

Retry only deterministic/transient failures such as network timeout, temporary lock or unavailable test service, with bounded attempts and backoff. Do not retry validation, authorization, contract ambiguity, migration failure, security finding or destructive action blindly. Each retry records error class, changed conditions and whether side effects may have occurred.

When a command times out, preserve logs and stop broadening the command. Narrow the scope, use deterministic timeout and ask for human direction after the retry budget is exhausted.

## 7. Review-pair pattern

The implementing agent cannot be the sole approver for high-risk changes. At minimum, contract-breaking, auth/payment/recovery, database migration, public AI fetch/upload and production config changes require an independent reviewer plus evidence. Reviewer checks diff, tests, threat controls, rollback and consumer impact—not only whether the code compiles.

## 8. Context and Graphify refresh

Use a compact context pack: project map, current state, relevant contract, domain rules, security policy, changed files, failing evidence and next decision. Refresh the pack after a contract change, failed verification, handoff, phase boundary or when assumptions become stale. Do not inject the whole repository or `.env` into model context.

## 9. Output and evidence contract

Every run returns `DONE`, `BLOCKED`, `NEEDS_CLARIFICATION` or `NEEDS_HUMAN_REVIEW`, with summary, changed files, commands, test outcomes, contract changes, security findings, limitations, evidence paths and next action. A green output without command/evidence references is invalid.

## 10. Safe completion criteria

Agent may report `DONE` only when acceptance criteria, relevant contract checks, tests, security review and documentation/state updates pass. Otherwise it must use the more honest non-DONE state. Harness completion is not production compliance; release owner still decides deployment against the audit/compliance profile.
