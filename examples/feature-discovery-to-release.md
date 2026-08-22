# Example: Organizer Publish Tournament — Discovery to Release

> Đây là ví dụ minh họa cách ghép các standards thành một change. Số liệu và tên người bên dưới là giả lập; không dùng làm production evidence.

## 1. Intake

- **Change ID:** `CHG-2026-001-publish-tournament`
- **Request:** Organizer muốn đưa giải đấu từ draft sang trạng thái public sau khi hoàn tất thông tin.
- **Initial solution idea:** Thêm nút “Publish”.
- **Risk tier:** High, vì đổi public state, ảnh hưởng participant discovery, authorization, invariant và realtime event.
- **Out of scope:** Payment collection, bracket generation và marketing campaign.

## 2. Discovery decision

### Problem statement

Organizer cần kiểm tra và công khai một giải đấu đã đủ thông tin để participant có thể tìm thấy và đăng ký, nhưng hiện chưa có một bước kiểm tra rõ ràng trước publish; lỗi thiếu dữ liệu hoặc publish nhầm có thể tạo support work và ảnh hưởng niềm tin participant.

### Evidence cần thu thập

| Claim | Evidence | Status |
|---|---|---|
| Organizer không biết trường nào bắt buộc trước publish | Interview/observation | To verify |
| Participant chỉ nên thấy tournament đủ điều kiện | Domain rule/current API review | Observed |
| Publish phải là action idempotent | State transition analysis | Inferred → design review |

### Hypotheses

| ID | Hypothesis | Test |
|---|---|---|
| A-001 | Checklist trước publish giúp organizer giảm lỗi thiếu field | Prototype/usability test |
| A-002 | Server-side invariant bắt buộc dù UI đã validate | Contract/integration test |
| A-003 | Duplicate click/retry không tạo hai publish event | Concurrency/idempotency test |

### Success/guardrail

| Metric | Type | Target/example |
|---|---|---|
| Publish success rate for valid drafts | Primary | ≥ 99% over 28d |
| Missing-field publish errors | Quality | Downward trend after baseline |
| Unauthorized publish | Safety | 0 |
| Duplicate publish side effect | Safety | 0 |
| Publish API p95 | Reliability | Defined in service SLO |

### Discovery outcome

`GO_WITH_CONDITIONS`: tiếp tục design/implementation khi đã chốt canonical state transition, owner/role policy, required fields, idempotency key, event semantics, rollback/repair runbook và instrumentation.

## 3. Data and architecture contract

### State transition

```text
DRAFT → PUBLISHED
DRAFT → ARCHIVED
PUBLISHED → ARCHIVED
```

Server phải kiểm tra actor ownership/role, required data, current state và optimistic concurrency/version. Không cho phép UI tự quyết định state hợp lệ.

### Architecture impact

- C4 container không đổi; backend API, PostgreSQL và Socket.IO flow bị tác động.
- Tạo ADR cho publish command, state transition và event ordering.
- Database giữ invariant bằng enum/check/constraint phù hợp; migration phải backward-compatible.
- Publish command ghi state và outbox/event record trong cùng transaction hoặc cơ chế đã được phê duyệt.

### API contract

```http
POST /api/v1/tournaments/{tournamentId}/publish
Idempotency-Key: <client-generated-key>
If-Match: <version-or-etag>
```

Success dùng success envelope hiện tại của project; error mới phải map được sang Problem Details compatibility layer. Các response không được tự tạo field/status ngoài `API_CONTRACT_SPEC.md`.

### UI contract

Screen phải có các state: initial, loading, validation errors, forbidden, not found, conflict/stale version, success, server error, offline/retry và realtime stale. Nút publish bị disable khi đang submit nhưng server vẫn phải enforce idempotency.

## 4. Security and abuse controls

- Endpoint yêu cầu authenticated organizer/admin theo endpoint policy matrix.
- Ownership phải kiểm tra ở server; không tin `organizerId` từ client.
- CSRF/idempotency policy phải khớp transport.
- Không phát tán draft data ra public list trước khi transaction/event hoàn tất.
- Rate limit publish action và audit log actor, target, outcome, request/correlation ID.
- Không để event chứa PII không cần thiết.

## 5. Test plan

| Test | Expected |
|---|---|
| Valid organizer publishes draft | 2xx, state becomes PUBLISHED, one audit/outbox result |
| Missing required field | 4xx structured validation error, state unchanged |
| Non-owner publishes | 403/Problem Details, no state change |
| Unknown tournament | 404/Problem Details, no information leak |
| Already published | Idempotent success or explicit conflict by contract |
| Two concurrent publish requests | One valid transition; no duplicate side effect |
| Stale version | 409 conflict, UI asks refresh/reconcile |
| DB/event failure | Transaction/repair policy works; no false success |
| Realtime consumer disconnected | Event replay/refresh policy preserves correctness |
| Repeated malicious requests | Rate limit and audit evidence |

## 6. SRE and AI controls

- Service catalog entry: `tournament-api`.
- SLI: valid publish requests that complete with correct state transition / eligible requests.
- SLO: target and window must be approved before release; do not invent baseline.
- Dashboard: publish success/error/conflict/latency, outbox lag, audit failures.
- Runbook: rollback/repair for partial event failure and stale read model.
- If AI assistant helps organizer draft metadata, it may suggest fields but must not call publish without an approved A3/A4 flow, deterministic validation and human/authorized approval.
- AI eval tasks cover missing fields, permission, no invented status, malformed dates/timezones, duplicate publish and provider/tool failure.

## 7. Implementation sequence

1. Complete discovery brief and confirm `GO_WITH_CONDITIONS` conditions.
2. Create/update ADR, C4 dynamic flow and data/API/UI contracts.
3. Write failing contract/unit/concurrency tests.
4. Implement minimal backend transition and transaction/outbox behavior.
5. Implement frontend state matrix and accessibility behavior.
6. Add audit/realtime/observability instrumentation.
7. Run quality, security, contract, E2E, accessibility and AI eval suites if AI is in scope.
8. Perform adversarial review and convergence against every acceptance criterion.
9. Release behind feature flag/canary if risk requires it; monitor SLO/error budget.
10. Archive change artifacts and record follow-up/remediation.

## 8. Convergence record

| Requirement | Code/contract | Test/evidence | Result |
|---|---|---|---|
| Only authorized actor can publish | Endpoint policy + service | Authz negative tests | `verified/not-run` |
| Required fields enforced server-side | Data/API contract | Validation tests | `verified/not-run` |
| No duplicate side effect | Idempotency/outbox design | Concurrency test | `verified/not-run` |
| UI exposes all failure states | Screen spec | Playwright/a11y/manual | `verified/not-run` |
| Observability and repair available | SRE catalog/runbook | Dashboard/smoke/restore evidence | `verified/not-run` |

Release status chỉ được `PASS` khi các hard gates có evidence. Các mục `not-run`, `blocked` hoặc unresolved P0/P1 phải làm release `BLOCKED` hoặc `PASS_WITH_CONDITIONS` theo policy; không báo hoàn tất chỉ vì build pass.
