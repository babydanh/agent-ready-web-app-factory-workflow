# AI Evaluation and Cost Specification

**Version:** 1.0  
**Status:** Required for any AI-enabled feature; enhanced controls for production/high-risk use  
**Scope:** Prompt/model/tool workflows, AI agents, RAG, classification, extraction, generation and autonomous loops  
**Owner:** AI feature owner with Product, Security and QA review

> **Mục đích:** biến AI từ một black box thành một capability có task definition, evaluation dataset, grader, telemetry, cost budget, safety boundary và quy trình cải tiến có bằng chứng.

## 1. Operating principles

AI feature không được đánh giá chỉ bằng một vài câu trả lời demo hoặc cảm nhận của model. Một evaluation là test có input, success criteria và grading logic; với agent nhiều turn, cần theo dõi cả transcript/trajectory và outcome cuối cùng vì tool calls và intermediate state có thể làm lỗi lan truyền.[1]

Agent harness và model phải được coi là một hệ thống. Evaluation cần kiểm tra cả output, trạng thái môi trường, tool calls, safety policy, latency, token usage, cost và khả năng dừng. Model không được tự làm grader duy nhất cho chính output của nó.

Mỗi AI change phải trả lời được:

| Câu hỏi | Artifact/evidence |
|---|---|
| AI làm nhiệm vụ gì? | Task contract và non-goals |
| Thành công là gì? | Acceptance criteria và outcome checks |
| Có dữ liệu chuẩn nào? | Dataset/version, reference solution/answer |
| Ai/chương trình chấm? | Deterministic, model-based, human graders |
| Agent có thể gọi tool nào? | Tool allowlist, arguments và side effects |
| Chi phí tối đa? | Per-run, daily/monthly budget, alert |
| Lỗi được phát hiện thế nào? | Trace, logs, metrics, feedback |
| Khi model/prompt đổi, làm sao biết không regression? | Capability và regression suite |
| Khi có risk cao, ai duyệt? | Human approval và escalation |

## 2. AI capability risk tiers

| Tier | Ví dụ | Controls |
|---|---|---|
| A0 — Non-production experiment | Prompt playground, synthetic/local data | No production PII/side effect; expiry date |
| A1 — Assistive | Draft text, summarize, classify, suggest | Output review, basic offline eval, cost limit |
| A2 — Operational recommendation | Recommend bracket, detect issue, propose action | Grounding/evidence, audit trail, human decision |
| A3 — Tool-using | Read/write internal state, call API/provider | Tool allowlist, state checks, deterministic guardrails, approval for high impact |
| A4 — High-impact/autonomous | Payment/admin/security/recovery or production mutation | Human approval/step-up, high-risk eval, rollback, continuous monitoring; no unrestricted autonomy |

Risk tier dựa trên blast radius và consequence, không dựa trên tên model. Nếu AI có thể đổi dữ liệu, gửi tiền, thay đổi quyền hoặc tác động đến user state, ít nhất là A3.

## 3. Task contract

Mỗi eval task là một case độc lập, có input, context, allowed tools, success criteria, expected side effects và stop condition.

```yaml
task_id: ai-tournament-001
dataset: tournament-agent-smoke@1.0
category: create|read|classify|extract|recommend|mutate|safety
input:
  user_intent: <sanitized task>
  fixtures: [<fixture ids>]
allowed_tools: [read_tournament, validate_payload]
forbidden_tools: [publish_tournament, process_payment]
expected_behavior:
  - ask_for_missing_field: start_time
  - do_not_invent_status: true
success_criteria:
  deterministic: []
  state_checks: []
  rubric_refs: []
stop_conditions:
  - max_turns: 8
  - max_tool_calls: 12
  - max_cost_usd: 0.10
  - max_duration_seconds: 60
risk: medium
owner: <team>
```

Task phải đủ rõ để hai evaluator độc lập có thể đưa ra cùng một pass/fail verdict. Nếu task fail vì thiếu filepath, field definition, fixture hoặc expected state, sửa task/grader trước khi kết luận model kém.[1]

## 4. Evaluation suite

### 4.1 Smoke suite

Smoke suite nhỏ, chạy nhanh trong local/PR, kiểm tra contract, schema, tool permissions, basic happy path, missing input, malformed input và termination. Mục tiêu là feedback nhanh, không thay thế regression suite.

### 4.2 Capability suite

Capability suite đo capability mới hoặc vùng agent hiện còn yếu. Pass rate ban đầu có thể thấp; mục tiêu là biết agent đang học/cải thiện ở đâu. Khi capability ổn định, task có thể được promote thành regression task.

### 4.3 Regression suite

Regression suite bảo vệ behavior đã đạt. Các task quan trọng nên có pass rate gần 100% theo policy đã thống nhất. Mỗi production failure có impact đáng kể phải được chuyển thành eval case sau khi sanitize.

### 4.4 Adversarial/safety suite

Bao gồm prompt injection, tool misuse, privilege escalation, data exfiltration, PII leakage, ambiguous request, malicious file/URL, infinite loop, over-budget loop, provider failure, duplicate mutation và stale context.

### 4.5 Domain suite cho tournament app

Tối thiểu xem xét: không tự bịa team/player/date/status; từ chối publish khi thiếu permission hoặc invariant; không tạo duplicate registration/payment; không đọc tournament ngoài ownership; xử lý timezone; giữ contract success/error; và dừng khi tool trả conflict hoặc provider timeout.

## 5. Grader hierarchy

Dùng grader phù hợp với loại behavior. Anthropic phân biệt code-based grader nhanh, rẻ, objective và reproducible; model-based grader linh hoạt nhưng nondeterministic/tốn hơn; human grader có chất lượng chuyên gia nhưng chậm và đắt.[1]

| Grader | Dùng cho | Quy tắc |
|---|---|---|
| Schema/contract | JSON shape, types, required fields | Block nếu invalid |
| Unit/integration test | Behavior deterministic | Producer không sửa test để pass |
| State check | DB/event/side-effect cuối | Kiểm tra actual state, không chỉ final text |
| Tool-call check | Tool allowlist, args, order, max calls | Cấm tool ngoài policy |
| Static/security | Secret, dependency, injection, unsafe URL | Severity policy rõ |
| Rubric/model grader | Tone, groundedness, completeness, quality | Calibrate với human sample |
| Human review | High-impact, policy, ambiguous quality | Required theo risk tier |

Mỗi task có thể dùng hybrid scoring. Với mutation/payment/security action, state check và policy check phải là hard gate; điểm rubric cao không bù được side effect sai.

## 6. Transcript và outcome contract

Lưu evaluation record tối thiểu:

```json
{
  "eval_run_id": "eval-2026-0001",
  "task_id": "ai-tournament-001",
  "agent_version": "agent@1.4.0",
  "model_id": "<provider-model-version>",
  "prompt_version": "prompt@3.2.0",
  "tools_version": "tools@2.0.0",
  "fixture_version": "tournament-fixtures@1.1",
  "trial": 1,
  "status": "passed",
  "grader_results": [],
  "tool_calls": 0,
  "turns": 2,
  "latency_ms": 820,
  "input_tokens": 0,
  "output_tokens": 0,
  "estimated_cost_usd": 0,
  "transcript_ref": "<sanitized-store-ref>",
  "outcome_ref": "<state-check-ref>",
  "human_review": "not-required"
}
```

Không lưu raw secret, refresh token, unredacted PII hoặc sensitive prompt context trong transcript mặc định. Transcript storage có retention, access control và redaction policy riêng.

## 7. Metrics

### 7.1 Quality

- `task_pass_rate`: số task đạt tất cả hard gates / số trial.
- `capability_score`: score suite capability theo rubric/version.
- `regression_pass_rate`: task regression không bị fail.
- `groundedness`: claim có evidence hợp lệ nếu feature yêu cầu grounding.
- `tool_policy_violation_rate`: tool call ngoài allowlist hoặc args sai.
- `unsafe_output_rate`: output vi phạm safety policy.
- `state_correctness`: actual state đúng expected state.
- `human_agreement`: mức đồng thuận giữa grader và human calibration sample.

### 7.2 Reliability and experience

- `pass_at_k`: xác suất có ít nhất một trial đúng trong k attempts, phù hợp khi một thành công hợp lệ là đủ.
- `pass_power_k`: xác suất tất cả k trial đều đúng, phù hợp khi cần tính nhất quán.
- `turns_per_task`, `tool_calls_per_task`, `timeout_rate`, `retry_rate`, `fallback_rate`.
- `time_to_first_output`, `time_to_last_output`, `total_latency_ms`.

Hai metrics pass@k và pass^k đo các yêu cầu khác nhau; không dùng pass@k để che giấu agent chỉ thành công không ổn định khi product cần behavior nhất quán.[1]

### 7.3 Cost

Chi phí mỗi run phải tính tối thiểu:

```text
estimated_cost_per_run
  = input_tokens × input_price
  + output_tokens × output_price
  + tool/API calls
  + retrieval/storage/observability cost allocation
```

Nếu provider không cung cấp cost chính xác, ghi `estimated`, nguồn giá và version. Không dùng con số cost 0 chỉ vì billing được xử lý bên ngoài code.

## 8. Offline/online evaluation loop

Offline evaluation chạy trên dataset cố định/sanitized trước release; online evaluation theo dõi traffic thật, user feedback, outcome và model drift sau release. Hai loại phải tạo vòng lặp:

```text
offline eval
  → controlled release
  → online traces/feedback
  → failure clustering and privacy review
  → new sanitized eval cases
  → prompt/model/tool change
  → offline regression + capability eval
```

Microsoft khuyến nghị bắt đầu bằng offline evaluation vì nó kiểm soát dataset và repeatability, nhưng phải cập nhật test set bằng edge cases/production failures; online signals giúp phát hiện tình huống ngoài dataset và model drift.[2]

Online evaluation không được dùng raw production data làm training/eval dataset tự động. Case cần qua privacy review, redaction, access control và retention trước khi promote.

## 9. Model, prompt và tool change governance

Mỗi run phải pin:

| Artifact | Cần pin |
|---|---|
| Model | Provider, model ID, version/snapshot nếu có |
| Prompt | Prompt ID/version và system policy version |
| Tool | Tool schema/version, permission policy |
| Retrieval | Index/dataset/embedding version |
| Fixture | Dataset/fixture version |
| Grader | Code/rubric/model grader version |
| Runtime | Agent harness version, environment, feature flags |

Không thay model/prompt/tool trong production mà không chạy smoke và regression suite phù hợp. Khi thay model lớn, chạy side-by-side/shadow hoặc canary nếu có thể; high-impact action phải có human approval trong rollout.

## 10. Cost-control policy

### 10.1 Budgets

```yaml
budget_id: AI-BUDGET-TOURNAMENT-001
scope: tournament-assistant
per_run_usd: 0.10
daily_usd: 20
monthly_usd: 300
max_turns: 8
max_tool_calls: 12
max_duration_seconds: 60
alert_at_percent: [50, 80, 100]
action_at_limit: stop|fallback|human-review
owner: <team>
```

Budget là control safety, không chỉ là finance metric. Khi vượt limit, agent phải dừng/fallback/escalate theo policy; không retry vô hạn.

### 10.2 Routing, caching và fallback

Có thể route task đơn giản tới model nhỏ/rẻ, task reasoning tới model phù hợp, cache các request đủ an toàn và fallback khi provider lỗi. Mọi optimization phải được chứng minh bằng eval: cost giảm nhưng không làm quality, safety, latency hoặc correctness vượt ngưỡng xấu.

Không cache response chứa user-specific PII, authorization-sensitive state hoặc data freshness thấp nếu cache key/invalidation chưa được chứng minh. Không dùng fallback model làm cách bypass safety policy hoặc tool permission.

### 10.3 Loop controls

Agent loop phải có maximum turns, maximum tool calls, timeout, budget, repeated-action detection, no-progress detection và circuit breaker. Mỗi retry ghi reason; không retry lỗi validation/authorization như thể đó là provider transient failure.

## 11. Observability

AI run nên được trace như một parent trace với child spans cho planning, retrieval, model call, tool call, validation, grader và final state check. OpenTelemetry semantic conventions giúp thống nhất tên và thuộc tính của telemetry giữa codebase, libraries và platforms.[3]

Các field cần cân nhắc: `agent_name`, `agent_version`, `model_id`, `prompt_version`, `task_id`, `tool_name`, `tool_result_status`, `turn_index`, `token_counts`, `estimated_cost`, `risk_tier`, `outcome`, `policy_decision`, `human_approval` và `redaction_status`.

Không gửi raw prompt/transcript vào metrics labels. Dùng reference ID tới controlled store; log claim-sensitive content chỉ khi privacy policy cho phép.

## 12. Human approval matrix

| Action | Default approval |
|---|---|
| Generate draft/read-only summary | No approval after A1 eval |
| Suggest API/data/UI change | Human review before merge |
| Edit source code in branch | Human review + deterministic checks |
| Change database schema/migration | Explicit reviewer; high-risk migration gate |
| Publish tournament/change public state | Human/authorized workflow unless policy explicitly permits |
| Payment/refund/payout | Step-up/human approval; no unrestricted agent |
| Change auth/role/security policy | Security owner approval |
| Production deploy/rollback/restore | Explicit operational approval |

AI Agent không được tự cấp approval cho output do chính agent/agent group tạo nếu policy yêu cầu independent reviewer.

## 13. Evaluation release gate

| Gate | Điều kiện |
|---|---|
| Contract | Output schema và error policy hợp lệ |
| Safety | Không có hard-block policy violation |
| Correctness | State/behavior hard checks đạt threshold |
| Regression | Không giảm dưới baseline đã phê duyệt |
| Cost | Per-run/daily/monthly trong budget |
| Reliability | Timeout/loop/tool error dưới threshold |
| Human calibration | Model grader được calibrate khi dùng rubric |
| Observability | Trace/cost/outcome có thể truy xuất |
| Rollback | Model/prompt/tool version có cách quay lại |
| Approval | Owner/risk approver đã ký |

Chỉ số pass rate không được báo mà không kèm dataset version, trial count, grader version và confidence/limitations. Không so sánh hai model bằng dataset hoặc grader khác nhau mà không ghi rõ.

## 14. Definition of Done

- AI task contract, non-goals, risk tier và stop conditions tồn tại.
- Dataset/fixture và reference outcome có version, privacy review và owner.
- Smoke, capability, regression và safety cases phù hợp đã được chọn.
- Grader gồm hard deterministic checks; model/human grader có calibration khi cần.
- Transcript, tool calls, outcome, latency, tokens và cost có evidence được redacted.
- Model/prompt/tool/retrieval/runtime versions được pin.
- Budget, rate/turn/tool limits, fallback và circuit breaker được kiểm tra.
- Offline eval pass trước release; online monitoring và failure-to-eval loop được định nghĩa.
- High-impact side effects có approval/step-up/rollback.
- Release report nêu pass rate, pass@k/pass^k khi áp dụng, regression, cost, limitations và unresolved risks.

## References

[1]: https://www.anthropic.com/engineering/demystifying-evals-for-ai-agents "Anthropic — Demystifying evals for AI agents"
[2]: https://microsoft.github.io/ai-agents-for-beginners/10-ai-agents-production/ "Microsoft — AI agents in production: observability and evaluation"
[3]: https://opentelemetry.io/docs/concepts/semantic-conventions/ "OpenTelemetry — Semantic Conventions"
