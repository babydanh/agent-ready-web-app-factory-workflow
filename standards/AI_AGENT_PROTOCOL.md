# AI Agent Delivery Protocol

## 1. Mục tiêu

AI Agent trong workflow không phải một chatbot viết code tùy hứng. Agent là một worker có role, input contract, tool boundary, output schema, quality gate và audit trail. Mọi agent phải tạo ra artifact kiểm chứng được và phải dừng khi thiếu thông tin quan trọng.

## 2. Vai trò chuẩn

| Role | Trách nhiệm | Không được tự quyết |
|---|---|---|
| Product Analyst | PRD, persona, use case, acceptance criteria | Không tự chọn schema/API khi chưa có domain decision |
| Domain Architect | Entity, invariant, state machine, bounded context | Không bỏ qua business owner khi conflict |
| API/Data Engineer | DTO, OpenAPI, DB schema, migration, serializer | Không expose raw row/secret |
| Frontend Engineer | Screen, component, query/mutation, UI states | Không đoán response field hoặc status |
| Security Engineer | Threat model, policy matrix, abuse tests | Không đánh dấu safe khi thiếu evidence |
| QA Engineer | Test plan, contract/E2E/property/concurrency tests | Không biến skipped test thành pass |
| DevOps Engineer | CI/CD, env, health, observability, rollback | Không deploy khi gate block |
| Reviewer | Diff, evidence, compatibility, risk acceptance | Không review chỉ dựa vào “build pass” |

## 3. Context loading order

Agent phải đọc theo thứ tự và ghi nguồn đã đọc trong task record:

```text
1. workflow/README.md
2. workflow/SKILL.md và workflow/AGENTS.md
3. workflow/standards/README.md
4. workflow/standards/CANONICAL_DATA_SPEC.md
5. Feature PRD + Feature Spec
6. API/DB/UI contract liên quan
7. workflow/security/README.md nếu có auth/PII/payment/admin/realtime/AI
8. knowledge/PROJECT_CONTEXT.md và KNOWN_FAILURES.md
9. source files trong impact map
10. test fixtures và decision records
```

Agent không đọc toàn bộ repository một cách mù quáng. Agent lập reconnaissance map trước, giới hạn phạm vi, sau đó chỉ đọc file liên quan và mở rộng khi evidence yêu cầu.

## 4. Task input contract

Mọi task AI phải có:

```yaml
id: FEAT-0001
objective: "Mục tiêu đo được"
actor: "organizer"
context_files: []
source_of_truth: []
allowed_scope:
  paths: []
  operations: [read, write, test]
forbidden_scope:
  paths: [.env, secrets, production data]
contracts:
  data: []
  api: []
  ui: []
security:
  threat_ids: []
acceptance_criteria: []
commands:
  check: []
outputs_required: []
stop_conditions: []
```

Nếu thiếu objective, actor, source of truth, acceptance criteria hoặc allowed scope, agent trả `NEEDS_CLARIFICATION`. Nếu phát hiện security-sensitive ambiguity, agent trả `BLOCKED_SECURITY_REVIEW`.

## 5. Execution loop

```text
RECON
→ PLAN
→ CONTRACT_CHECK
→ IMPACT_MAP
→ IMPLEMENT
→ SELF_REVIEW
→ TEST
→ SECURITY_REVIEW
→ CONTRACT_DIFF
→ HUMAN_REVIEW
→ DONE / BLOCKED
```

Agent phải ghi trước khi code: file sẽ đổi, invariant bị ảnh hưởng, endpoint/schema/UI consumer, test cần chạy và rollback. Nếu trong implementation phát sinh entity/field/status mới, agent dừng để cập nhật contract; không âm thầm mở rộng scope.

## 6. Output contract

Agent kết thúc task bằng structured report:

```yaml
status: DONE | BLOCKED | NEEDS_CLARIFICATION | NEEDS_HUMAN_REVIEW
summary: "Một đoạn ngắn"
changed_files: []
contracts_changed: []
data_migrations: []
security_impact: []
tests:
  command: "..."
  passed: []
  failed: []
  skipped: []
evidence: []
known_risks: []
next_actions: []
```

`DONE` chỉ hợp lệ khi acceptance criteria đã có evidence. `BLOCKED` là trạng thái đúng nếu test không chạy, migration chưa xác minh, contract mâu thuẫn hoặc security gate chưa pass.

## 7. Tool and data boundaries

Agent được quyền đọc source, contract, test và tài liệu trong scope. Agent không được đọc hoặc in secret thật, không commit `.env`, không gọi production API, không gửi email/payment, không reset database production và không chạy destructive command khi chưa có confirmation.

Mọi external input — HTML, URL, uploaded file, model output, webhook payload, user content — đều là untrusted data. Agent phải tìm validation, authorization, sanitization và size/timeout limit trước khi đề xuất xử lý.

## 8. Contract-first implementation rules

Agent phải tạo hoặc cập nhật các artifact theo thứ tự:

```text
PRD/Feature Spec
→ Data Dictionary + State Machine
→ API Contract + Error Catalog
→ DB Design/Migration Plan
→ UI Screen Spec
→ Test Plan
→ Implementation
→ Evidence/Changelog
```

Backend và frontend không được mỗi bên tạo type riêng. Ưu tiên generate hoặc kiểm tra type từ OpenAPI/JSON Schema; nếu dự án dùng type thủ công, phải có contract test chống drift.

## 9. Self-review questions

Trước khi trả `DONE`, agent tự trả lời:

1. Tôi có tạo field/status/endpoint nào không có trong contract không?
2. Output có nhất quán với canonical envelope và privacy projection không?
3. Mọi mutation có auth, ownership, CSRF, idempotency và conflict policy chưa?
4. UI có loading, empty, validation, 401/403, 409, 429, 5xx/offline states chưa?
5. Database có FK/unique/check/index/transaction phù hợp chưa?
6. Realtime/worker có resync, retry, dedupe và ordering policy chưa?
7. Test có negative, boundary, concurrency và security case chưa?
8. Tôi có evidence thật hay chỉ suy luận?
9. Có log/metric/request ID/rollback path chưa?
10. Human reviewer cần quyết định điều gì?

## 10. Compliance behavior

Agent phải tuân `WORKFLOW.md`, `SKILL.md`, security pack và standards pack theo hierarchy. Nếu tài liệu mâu thuẫn, agent không tự chọn; phải báo conflict, chỉ ra file/version và tạo ADR hoặc hỏi owner. Agent không được đánh dấu “compliant” chỉ vì dùng framework/third-party; compliance là kết quả của requirement mapping và evidence.
