# Standards Pack — Canonical Web App Delivery

Bộ tài liệu này biến workflow thành một **hệ thống chuẩn hóa đầu ra**. Mục tiêu là mọi feature, endpoint, màn hình, database change, realtime event và AI Agent đều dùng cùng vocabulary, schema, trạng thái, quy tắc lỗi, design language, security controls và audit evidence.

Trước khi chọn solution, hãy đọc `../knowledge/WEB_APP_PROBLEM_CATALOG.md` để nhận diện bài toán lặp lại và failure mode; dùng `../knowledge/DOMAIN_ADAPTATION_GUIDE.md` để chọn profile theo loại web app; sau đó dùng `../knowledge/BACKEND_PROBLEM_PLAYBOOK.md` và `PROBLEM_ORIENTED_TEST_MATRIX.md` cho feature có backend, side effect, concurrency, queue, realtime hoặc integration. Với commerce, recommender/search, dashboard, transaction, Việt Nam hoặc iOS, chọn profile tương ứng trong `COMMERCE_RECOMMENDATION_DASHBOARD_GATES.md`.

## Đọc theo thứ tự

| Thứ tự | Tài liệu | Khi nào dùng |
|---:|---|---|
| 1 | `PRODUCT_DISCOVERY_SPEC.md` | Trước khi cam kết build feature hoặc thay đổi user journey |
| 1a | `FEATURE_IMPACT_REVIEW_SPEC.md` | Ngay sau discovery; khi feature có route, role, state, button, API/event, realtime, i18n hoặc cross-platform impact |
| 2 | `ARCHITECTURE_GOVERNANCE_SPEC.md` | Khi quyết định boundary, runtime, dependency, data flow hoặc quality attribute |
| 3 | `CANONICAL_DATA_SPEC.md` | Trước khi tạo entity, DTO, database column hoặc frontend type |
| 4 | `DATABASE_ARCHITECTURE_SPEC.md` | Khi thiết kế ERD, constraint, index, transaction, migration, backup hoặc retention |
| 5 | `API_CONTRACT_SPEC.md` | Trước khi tạo hoặc sửa endpoint, webhook, job payload hoặc realtime event |
| 6 | `CONTRACT_GOVERNANCE.md` | Khi duyệt version, breaking change, deprecation, consumer contract hoặc schema drift |
| 7 | `UI_UX_DESIGN_SYSTEM_SPEC.md` | Trước khi tạo page, form, modal, table hoặc interaction |
| 8 | `THEME_AND_DESIGN_TOKENS_SPEC.md` | Khi có typography, semantic tokens, light/dark/system, high contrast, motion hoặc direction-aware layout |
| 9 | `I18N_L10N_SPEC.md` | Khi có locale, translation, plural/select, date/number/currency, timezone, RTL hoặc localized route |
| 10 | `DESIGN_QA_SPEC.md` | Khi review token, component, responsive, visual regression, theme, locale và accessibility |
| 11 | `THEME_I18N_GATES.md` | Khi cần artifact, release blocker hoặc human-review status cho theme/locale |
| 12 | `AI_AGENT_PROTOCOL.md` | Trước khi giao task cho AI Agent |
| 13 | `AI_AGENT_HARNESS_SPEC.md` | Khi chạy task state machine, handoff, retry, approval hoặc evidence |
| 14 | `AI_EVALUATION_AND_COST_SPEC.md` | Khi feature dùng model, tool call, RAG, AI agent hoặc autonomous loop |
| 15 | `SRE_PLATFORM_OPERATIONS_SPEC.md` | Trước staging/production release và khi thay đổi runtime/operations |
| 16 | `AUDIT_COMPLIANCE_SPEC.md` | Trước review, merge, release và audit |
| 17 | `COMMERCE_SYSTEMS_PLAYBOOK.md`, `RECOMMENDATION_SEARCH_RANKING_PLAYBOOK.md`, `DASHBOARD_ANALYTICS_PLAYBOOK.md`, `TRANSACTION_CONCURRENCY_PLAYBOOK.md` | Khi feature có commerce, search/ranking, analytics hoặc race/idempotency |
| 18 | `VIETNAM_WEB_APP_COMPLIANCE_PROFILE.md`, `APPLE_IOS_APP_STORE_POLICY_PROFILE.md` | Khi scope có Việt Nam hoặc iOS/App Store |
| 19 | `COMMERCE_RECOMMENDATION_DASHBOARD_GATES.md` | Khi cần quyết định commerce artifact, release blocker hoặc waiver |
| 20 | `EXTENDED_GATES_CHECKLIST.md`, `PROBLEM_CATALOG_CHECKLIST.md`, `contracts/` và `templates/` | Khi cần gate, problem review, schema/example hoặc tạo spec cho feature cụ thể |

## Chuỗi nguồn sự thật

```text
Problem catalog + domain archetype/profile + failure hypotheses
    ↓
Discovery evidence + problem/user/outcome contract
    ↓
Feature Impact Review + surface/role/state/button/platform decision
    ↓
Architecture baseline + C4/ADR/quality attributes
    ↓
Domain glossary + canonical data model + state machine + privacy class
    ↓
Database architecture + migration/transaction plan
    ↓
OpenAPI/JSON Schema + event/job contracts
    ↓
Checked backend DTO/projection + frontend types
    ↓
UI/UX screen spec + semantic design tokens
    ↓
Unit/API/contract/E2E/a11y/security/AI eval tests
    ↓
SRE service catalog + SLI/SLO + observability + runbook + rollback
    ↓
Audit traceability + release evidence + convergence record
```

Không cho phép một layer tự phát minh lại tên field, status, error code, money/time format hoặc data visibility. Nếu có ngoại lệ, phải tạo ADR và ghi rõ consumer, security impact, migration và expiry.

## Chuẩn áp dụng

| Lớp | Chuẩn hoặc quy ước |
|---|---|
| HTTP API | OpenAPI 3.1-compatible contract, JSON Schema 2020-12 vocabulary khi toolchain hỗ trợ |
| Error response | RFC 9457 Problem Details làm canonical error model; có thể thêm extension có namespace |
| Success response | Envelope nhất quán của dự án với `statusCode`, `message`, `data`, `meta` trong compatibility window |
| Database | 3NF mặc định, FK/unique/check có chủ đích, tenant/ownership scope, expand-contract migration |
| Accessibility | WCAG 2.2 Level AA làm mục tiêu mặc định cho web UI |
| Security | OWASP ASVS và OWASP Cheat Sheets liên quan theo risk profile |
| Observability | Request ID, operation ID, structured logs, metrics, traces và audit event theo criticality |
| Versioning | Semantic version cho contract/package; backward compatibility review cho breaking change |
| Localization | Message key ổn định; locale tách khỏi error code và domain state |
| Theme | Primitive → semantic → component tokens; light/dark/system, contrast và reduced motion |
| Typography | Role/scale/fallback tokenized; locale expansion và numeric alignment phải test |
| Compliance | Risk-based profile và evidence matrix; không tự nhận legal certification |
| Commerce | State/money/inventory/payment/ledger/refund/reconciliation must be explicit |
| Recommendation | Event → candidate → score → re-rank → evaluation → safety/rollback |
| Analytics | Metric dictionary, data grain, access scope, freshness, query budget and export controls |
| Platform policy | Vietnam and Apple profiles require owner/legal/platform review; no approval guarantee |

## Quick-start cho một feature mới

Problem cards/profile phải được chọn trước khi bắt đầu quick-start. Nếu card không áp dụng, ghi `N/A + rationale` trong Problem Map; không bỏ qua silent.

1. Tạo Product Discovery Brief; ghi problem, user evidence, assumptions, alternatives, outcome metrics và decision gate.
2. Tạo Feature Impact Review; liệt kê route/screen/role, state transition, button-state, negative cases, Web/App parity, source of truth, owner và GO/HOLD/STOP decision.
3. Tạo Architecture Review/ADR; xác định C4 impact, quality attributes, boundaries, dependency và rollback.
4. Tạo `DATA_ENTITY_SPEC`, `ENDPOINT_CONTRACT` và `SCREEN_SPEC` từ template; ghi owner, invariants, auth/ownership, state matrix và acceptance criteria. Với Normal/HighRisk, hoàn thiện thêm `BUTTON_STATE_MATRIX`, `SCREEN_STATE_MATRIX` và `CROSS_PLATFORM_MATRIX`.
5. Review database boundary, normalization, constraints, index, transaction, migration và rollback trước khi code.
6. Viết OpenAPI/JSON Schema, examples và error mapping; phân loại breaking/non-breaking và ghi consumer inventory.
7. Map contract vào backend projection/DTO, frontend type, UI components, realtime/job payload và observability.
8. Giao task cho agent bằng `AI_AGENT_TASK_STANDARD.template.md`; nêu allowed paths, source of truth, stop conditions và output schema.
9. Nếu có AI, tạo eval task/dataset, grader, cost budget, tool policy và offline regression baseline.
10. Chạy contract/schema tests, backend/frontend tests, E2E/a11y, security negative tests, concurrency/retry tests, AI eval và migration verification theo risk profile.
11. Tạo service catalog/SLO/runbook cho release phù hợp; kiểm tra health/readiness, observability, rollback và post-release watch.
12. Với commerce, payment, inventory, payout, entitlement, webhook hoặc retry, điền `COMMERCE_FLOW_SPEC.template.md` và `TRANSACTION_CONCURRENCY_TEST.template.md`; với recommendation/search điền `RECOMMENDATION_FEATURE_SPEC.template.md`; với dashboard/reporting điền `DASHBOARD_ANALYTICS_SPEC.template.md`.
13. Nếu có typography/token/theme/light-dark/system/high-contrast, điền `THEME_CONFIG.template.json`; nếu có locale/translation/date-number-currency/timezone/RTL, điền `TRANSLATION_CATALOG.template.json`; với một trong hai profile, luôn điền `LOCALE_QA_MATRIX.template.md` và chạy `THEME_I18N_GATES.md`.
14. Nếu scope có Việt Nam, điền `COMPLIANCE_SCOPE_RECORD.template.md` và ghi `LEGAL_REVIEW_REQUIRED` cho câu hỏi chưa được legal owner quyết định; nếu có iOS, điền `APPLE_IOS_RELEASE_REVIEW.template.md`.
15. Chạy `COMMERCE_RECOMMENDATION_DASHBOARD_GATES.md` hoặc `THEME_I18N_GATES.md` tương ứng, điền `COMPLIANCE_TRACEABILITY.template.md`, `EXTENDED_GATES_CHECKLIST.md`, lưu evidence, review diff/secret/scope và chỉ release khi decision là `PASS` hoặc `PASS_WITH_CONDITIONS` có owner/expiry rõ ràng.

## Điều bộ này không tuyên bố

Standards pack là **framework và evidence system**, không phải bằng chứng rằng codebase hiện tại đã đạt mọi chuẩn. Nó cũng không phải chứng nhận pháp lý, PCI DSS, ISO 27001, SOC 2, GDPR hoặc chứng nhận accessibility. Việc tuyên bố compliance cần owner, phạm vi, phiên bản tiêu chuẩn, evidence và review pháp lý/độc lập phù hợp.

## Contract examples

`contracts/schemas/success-envelope.schema.json` và `contracts/schemas/problem-details.schema.json` là schema mẫu cho response. `contracts/examples/create-tournament.openapi.yaml` minh họa một endpoint tạo giải đấu với cookie auth, CSRF, idempotency, success envelope và Problem Details. `../examples/feature-discovery-to-release.md` minh họa cách ghép discovery, architecture, data/API/UI, security, SRE và AI controls trong một change. Các URL `example.com` chỉ là placeholder; khi áp dụng cần thay bằng server, schema ID và contract thật của dự án.
