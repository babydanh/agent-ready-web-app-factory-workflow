# Extended Gates Checklist

**Dùng cho:** normal feature và high-risk change. Với small fix, chỉ dùng các mục được đánh dấu `Small fix`.

## 1. Product Discovery Gate

| Check | Small fix | Normal | High-risk | Evidence/owner |
|---|---:|---:|---:|---|
| Problem statement không gắn cứng vào solution | Required | Required | Required |  |
| User segment, goal và context rõ | Optional | Required | Required |  |
| Current journey/pain/opportunity có evidence | Optional | Required | Required |  |
| Assumption register có confidence, risk, test, owner | Optional | Required | Required |  |
| Alternatives và do-not-build option đã xem xét | No | Required | Required |  |
| Accessibility/inclusion impact screening | Optional | Required | Required |  |
| Privacy/PII/security/payment/AI screening | Trigger-based | Required | Required |  |
| Primary metric, guardrail, baseline/measurement plan | Optional | Required | Required |  |
| Decision GO/GO_WITH_CONDITIONS/HOLD/STOP có approver | Required | Required | Required |  |
| Open questions không bị agent tự đoán | Required | Required | Required |  |

**Gate rule:** thiếu decision owner, evidence quan trọng hoặc problem definition thì `NEEDS_CLARIFICATION`; không chuyển sang implementation chỉ vì stakeholder đã nêu sẵn solution.

## 2. Architecture Governance Gate

| Check | Small fix | Normal | High-risk | Evidence/owner |
|---|---:|---:|---:|---|
| Risk tier và architecture trigger đã xác định | Required | Required | Required |  |
| C4 impact view đã cập nhật hoặc xác nhận không đổi | No | Required | Required |  |
| ADR cho decision architecturally significant | No | Required | Required |  |
| Quality attributes có threshold/rationale | No | Required | Required |  |
| Dependency direction và module ownership được kiểm tra | Optional | Required | Required |  |
| Data/API/event/security/trust boundary impact | Optional | Required | Required |  |
| Fitness functions/checks được xác định | Optional | Required | Required |  |
| Migration/backward compatibility/rollback | No | Trigger-based | Required |  |
| Observability, health/readiness và runbook | No | Trigger-based | Required |  |
| Exception/waiver có expiry và approver | Trigger-based | Trigger-based | Required |  |
| Convergence review sau implementation | Required | Required | Required |  |

**Gate rule:** agent không được tự mark ADR `accepted`, tự cấp waiver hoặc tự approve high-risk architecture.

## 3. SRE and Platform Release Gate

| Check | Tier 3/experimental | Tier 2 | Tier 1 | Evidence/owner |
|---|---:|---:|---:|---|
| Service catalog có owner, criticality, dependency | Required | Required | Required |  |
| SLI/SLO hoặc internal target rõ | Optional | Required | Required |  |
| Error budget và alert policy | No | Required | Required |  |
| Structured logs có correlation và redaction | Required | Required | Required |  |
| Metrics/traces có naming/cardinality policy | Optional | Required | Required |  |
| Liveness/readiness/startup behavior | Required | Required | Required |  |
| Timeout/retry/backoff/idempotency/failure policy | Trigger-based | Required | Required |  |
| Dashboard và actionable alert | No | Required | Required |  |
| Runbook first-15-minutes | No | Required | Required |  |
| Rollback decision và migration policy | Required | Required | Required |  |
| Backup/restore/RPO/RTO | No | Trigger-based | Required |  |
| Restore drill evidence | No | Periodic | Required |  |
| Cost/capacity budget and alert | Optional | Required | Required |  |
| Post-release watch window | Optional | Required | Required |  |

**Gate rule:** “health endpoint trả 200” không đủ chứng minh service ready; phải kiểm tra critical dependency, migration/config và failure behavior tương ứng.

## 4. AI Evaluation and Cost Gate

| Check | A0/A1 | A2 | A3/A4 | Evidence/owner |
|---|---:|---:|---:|---|
| Task contract, non-goals và stop conditions | Required | Required | Required |  |
| Dataset/fixture/reference outcome có version | Required | Required | Required |  |
| Smoke tests có schema, malformed/missing input | Required | Required | Required |  |
| Deterministic grader/state check | Required | Required | Required |  |
| Tool allowlist và argument constraints | Trigger-based | Required | Required |  |
| Safety/adversarial suite | Optional | Required | Required |  |
| Transcript/outcome/cost/latency evidence | Required | Required | Required |  |
| Model/prompt/tool/retrieval/runtime versions pinned | Required | Required | Required |  |
| Regression suite và baseline | Optional | Required | Required |  |
| Human grader calibration | Trigger-based | Required for rubric | Required |  |
| Per-run/daily/monthly cost limits | Required | Required | Required |  |
| Max turns/tool calls/duration/repeated action | Required | Required | Required |  |
| Offline eval trước release | Required | Required | Required |  |
| Online monitor + failure-to-eval loop | No | Required | Required |  |
| Human approval/step-up cho side effect | No | Trigger-based | Required |  |
| Rollback model/prompt/tool version | Optional | Required | Required |  |

**Gate rule:** output hay không được quyết định một mình bởi model. Với write/payment/admin/security action, state check, policy check và approval là hard gates.

## 5. Release decision

- **PASS:** tất cả hard gates đạt; evidence link truy xuất được.
- **PASS WITH CONDITIONS:** chỉ dùng cho risk thấp/trung bình; mọi condition có owner, due date và không che giấu hard safety/data-integrity failure.
- **BLOCKED:** thiếu approval, environment, dependency, evidence hoặc có P0/P1 risk chưa mitigated.
- **FAIL:** check deterministic hoặc safety/integrity gate không đạt; tạo remediation issue và không promote.

## 6. Evidence record

Mỗi gate record phải ghi:

| Field | Value |
|---|---|
| Change ID |  |
| Commit/artifact identity |  |
| Gate/profile |  |
| Checks run |  |
| Passed/failed/blocked/not-run |  |
| Output references |  |
| Reviewer/approver |  |
| Timestamp/environment |  |
| Known limitations |  |
| Follow-up issue |  |
