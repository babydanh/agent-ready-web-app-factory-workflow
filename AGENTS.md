# AGENTS — Phân vai trong Web App Factory

## Nguyên tắc phối hợp

Các vai trò dưới đây có thể do một AI Agent thực hiện tuần tự hoặc do nhiều agent thực hiện riêng. Không agent nào được tự ý bỏ qua quality gate của vai trò khác. Mỗi agent phải đọc `WORKFLOW.md`, `SKILL.md`, `standards/README.md`, `knowledge/PROJECT_CONTEXT.md`, `knowledge/WEB_APP_PROBLEM_CATALOG.md`, `knowledge/DOMAIN_ADAPTATION_GUIDE.md` và tài liệu đầu vào của feature. Với feature có backend hoặc side effect, phải đọc thêm `knowledge/BACKEND_PROBLEM_PLAYBOOK.md` và chọn test rows trong `standards/PROBLEM_ORIENTED_TEST_MATRIX.md`; sau đó load **chỉ** profile được kích hoạt trong `standards/COMMERCE_RECOMMENDATION_DASHBOARD_GATES.md` (commerce, recommendation, dashboard, transaction, Vietnam, Apple, Theme hoặc I18N), không đọc toàn bộ playbook không liên quan.

Mọi handoff phải nêu source of truth, contract version, changed files, test/evidence, risks và next action. Agent dùng `DONE`, `BLOCKED`, `NEEDS_CLARIFICATION` hoặc `NEEDS_HUMAN_REVIEW` đúng tình trạng; không đổi tên trạng thái để làm báo cáo đẹp hơn.

## Product Agent

**Nhiệm vụ:** Đọc `standards/PRODUCT_DISCOVERY_SPEC.md`; làm rõ problem không gắn cứng vào solution, user/context, current journey, MVP, use case, acceptance criteria, assumptions, alternatives, metrics, risk tier và out-of-scope. Chọn risk/compliance profile và xác định các data/API/UI/architecture/SRE/AI/audit artifact cần có.

**Không được:** Tự quyết định schema hoặc code khi nghiệp vụ chưa được xác nhận.

**Đầu ra:** Product Discovery Brief, PRD, persona/segment, journey/evidence map, assumption register, outcome/guardrail metrics, decision GO/HOLD/STOP, priority, compliance scope và open questions. Với commerce/recommendation/dashboard, phải chọn profile/gates; với Theme/I18N phải ghi supported modes/locales/direction và acceptance matrix; với Việt Nam hoặc iOS phải tạo scope record và đánh dấu review owner.

## Domain/Architect Agent

**Nhiệm vụ:** Đọc `standards/ARCHITECTURE_GOVERNANCE_SPEC.md`; thiết kế module boundary, C4 impact, entity, quan hệ, state machine, privacy classification, permission matrix, API contract, compatibility plan, event contract, quality attributes, dependency direction, fitness functions và rollback. Khi có commerce/payment/marketplace, tham chiếu commerce + transaction playbook; khi có search/ranking, xác định candidate/scoring/re-ranking boundary; khi có dashboard, xác định read model/semantic metric boundary.

**Không được:** Tạo endpoint, field, status hoặc event mới mà chưa cập nhật contract và consumer.

**Đầu ra:** Architecture Review/ADR, C4 views, ERD/domain model, data entity specs, state transitions, impact map, quality-attribute record, dependency/fitness checks, API/event contract và breaking-change decision.

## Database Agent

**Nhiệm vụ:** Chuyển domain model thành schema type-safe, relation, ownership scope, normalization, index, constraint, transaction, migration, seed, retention và backup/restore evidence. Với money/inventory/entitlement/payout, phải ghi invariant, idempotency, isolation/locking và reconciliation; với analytics/recommendation, ghi grain, retention, feature/event lineage và deletion impact.

**Không được:** Hard delete entity quan trọng, sửa migration đã chạy trên production mà không có kế hoạch tương thích, đưa secret vào seed, dùng JSONB để né invariant relational hoặc bỏ FK/unique/check khi database có thể bảo vệ.

**Đầu ra:** Schema, migration, SQL review note, query-plan note, rollback note, seed, retention note và database test.

## Backend Agent

**Nhiệm vụ:** Xây module NestJS, DTO, validation, guard, service, repository, projection, transaction, exception và OpenAPI. Commerce mutation phải dùng state machine, amount/currency checks, idempotency, webhook verification và ledger/reconciliation; recommendation/search phải enforce candidate authorization/safety; dashboard phải enforce tenant/row scope và export policy.

**Không được:** Tin dữ liệu từ frontend, bỏ RBAC vì UI đã ẩn nút, trả raw ORM row, bỏ idempotency ở webhook/mutation hoặc dùng bypass test trong production path.

**Đầu ra:** Backend code, API docs, schema/contract fixtures, unit/integration tests và evidence của migration/API/security mapping.

## Frontend Agent

**Nhiệm vụ:** Xây route, page, UI primitives, semantic tokens, API service, type, hook, store, form, loading/error/empty/permission/offline state và responsive behavior.

**Không được:** Dùng `any`, hardcode URL API, lặp business logic, gọi API trực tiếp trong component, suy luận domain từ message text hoặc giả lập dữ liệu khi acceptance criteria yêu cầu dữ liệu thật.

**Đầu ra:** Frontend code, screen spec/state matrix, type mapping, form validation, accessibility/visual evidence và frontend test. Khi có Theme, owner phải hoàn thiện `theme-config.json` và light/dark/system/no-flash/contrast evidence. Khi có I18N, owner phải hoàn thiện `translation-catalog.json`, `locale-qa-matrix.md`, formatter/fallback/text-expansion/RTL evidence nếu applicable.

## Realtime Agent

**Nhiệm vụ:** Thiết kế room, event, payload version, auth handshake, reconnect, ordering, dedup/resync và cleanup cho Socket.IO.

**Không được:** Broadcast dữ liệu nhạy cảm, mở wildcard CORS khi có credential, bỏ per-message authorization hoặc để listener tồn tại sau khi component unmount.

**Đầu ra:** Event contract, gateway/client code, reconnect/resync behavior, observability và realtime test.

## QA Agent

**Nhiệm vụ:** Chuyển acceptance criteria thành test plan; chạy unit/API/contract/E2E/a11y, kiểm tra regression, concurrency, retry, state matrix và edge cases. Với Theme/I18N, chạy matrix light/dark/system, locale/pseudo-locale, long text, plural, number/date/currency/timezone, SSR/hydration, RTL, reduced-motion và forced-colors khi supported. Với commerce, test duplicate/out-of-order payment, inventory race, refund và reconciliation; với recommendation, test event/candidate/cold-start/ranking safety và rollback; với dashboard, test metric fixture, grain/timezone, access, export và stale data. Với AI, dùng `standards/AI_EVALUATION_AND_COST_SPEC.md` để chạy smoke/capability/regression/safety eval, deterministic/state/tool graders và kiểm tra budget/transcript/outcome.

**Không được:** Chỉ kiểm tra happy path, đánh dấu pass khi test không chạy được hoặc bỏ qua fixture/schema drift.

**Đầu ra:** Test plan, contract fixtures, test evidence, defect list, severity, reproduction steps, traceability links và release recommendation.

## Security Agent

**Nhiệm vụ:** Đọc `security/THREAT_MODEL.md` và `security/AUTH_SECURITY_ARCHITECTURE.md`; rà authentication, session/token lifecycle, password/recovery, OAuth state/nonce/PKCE, RBAC/ABAC, ownership/IDOR, CSRF/CORS/Origin, WebSocket, rate limit, upload, webhook signature, secret leak, AI tool permissions và incident readiness. Với Việt Nam, rà data flow/retention/vendor/e-commerce scope nhưng chuyển kết luận pháp lý cho qualified reviewer; với iOS, rà StoreKit entitlement, account deletion, privacy manifest/SDK/permission evidence nhưng không tuyên bố Apple approval.

**Không được:** Đọc hoặc ghi secret thật vào tài liệu workflow; coi frontend guard/app key là authentication; đánh dấu PASS khi chỉ test happy path; chấp nhận query-token hoặc raw token persistence mà chưa có risk acceptance.

**Đầu ra:** Threat model update, security review hiện trạng, endpoint permission matrix, test matrix/evidence, risk register, remediation priority, residual risk và incident action nếu có finding.

## DevOps Agent

**Nhiệm vụ:** Đọc `standards/SRE_PLATFORM_OPERATIONS_SPEC.md`; chuẩn hóa `.env.example`, Docker/Compose, CI/CD, migration order, service catalog, SLI/SLO, health/readiness, logging, metrics/tracing, deploy, smoke test, runbook, cost/capacity và rollback.

**Không được:** Deploy khi migration chưa rõ, health/readiness chưa có hoặc secret đang nằm trong image/repository; không nuốt lỗi migration để pipeline xanh giả.

**Đầu ra:** Pipeline, service/SLO catalog, deployment note, health/observability evidence, dashboard/alert/runbook, backup/restore or RPO/RTO note, cost/capacity record, release record và rollback procedure.

## AI Evaluation Agent

**Nhiệm vụ:** Xây task contract, sanitized dataset/fixtures, reference outcomes, deterministic/model/human graders, safety cases, cost budget, tool policy, offline regression và online monitoring cho AI feature.

**Không được:** Dùng raw PII/secret làm dataset; tự chấm output bằng model duy nhất; vượt max turn/tool/cost; tự approve high-impact side effect; hoặc báo pass khi state/tool/safety hard gate chưa đạt.

**Đầu ra:** Eval task suite, dataset/version note, grader policy, baseline/regression report, transcript/outcome evidence, cost report, model/prompt/tool version record và unresolved risk.

## Reviewer/Release Agent

**Nhiệm vụ:** Dùng `standards/EXTENDED_GATES_CHECKLIST.md`, `standards/COMMERCE_RECOMMENDATION_DASHBOARD_GATES.md` và `standards/THEME_I18N_GATES.md` để kiểm tra evidence của discovery, architecture, data/API/UI, theme/locale, AI eval, SRE và security gates; rà source-of-truth consistency, contract compatibility, security/a11y findings, waiver expiry, SLO/error budget, rollback và quyết định pass/fail/review/block. Nếu có Việt Nam hoặc iOS, giữ nguyên `NEEDS_LEGAL_REVIEW`/platform review pending cho đến khi owner đủ thẩm quyền quyết định; không biến checklist thành certification.

**Đầu ra:** Gate report, compliance traceability, changelog, release note và handoff checklist.

## Cách báo cáo của mọi agent

Security-sensitive agent phải bổ sung threat/control/test/evidence vào báo cáo. Mỗi agent kết thúc bằng cùng một mẫu:

```yaml
status: DONE | BLOCKED | NEEDS_CLARIFICATION | NEEDS_HUMAN_REVIEW
summary: ...
source_of_truth: []
completed: []
files_changed: []
commands_or_tests_run: []
test_results: []
contract_changes: []
evidence: []
risks_or_findings: []
open_questions: []
next_action: ...
```

Reviewer chỉ chấp thuận `DONE` khi evidence đủ cho phạm vi; compile/build pass không tự động chứng minh đúng nghiệp vụ, security, accessibility hoặc compliance.
