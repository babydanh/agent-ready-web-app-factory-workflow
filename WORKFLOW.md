# WORKFLOW — Xây dựng Web App từ A đến Z

## Mục tiêu

Workflow này biến một brief chưa rõ ràng thành một web app có thể chạy, kiểm thử, triển khai và bàn giao. Mỗi phase phải có đầu ra hữu hình và quality gate. Không chuyển phase chỉ vì đã viết code; phải có bằng chứng từ tài liệu, test hoặc lệnh kiểm tra.

## Luồng tổng quát

```text
Brief
  → Problem Catalog + Domain Profile + Failure Hypotheses
  → Product Discovery + Evidence + Decision
  → PRD + Acceptance Criteria
  → Codebase Recon + Impact Map
  → Architecture Review + C4/ADR/Quality Attributes
  → Canonical Data + State Machine
  → Database Architecture + Migration Plan
  → API/Event Contract + Compatibility Review
  → UI/UX Screen Spec + Design QA Plan
  → Environment Bootstrap
  → Vertical Slice
  → Feature Slices
  → QA + Security + Accessibility Review
  → CI/CD + Staging
  → Production + Smoke Test
  → Compliance Evidence + Handoff
```

## Trạng thái chuẩn

```text
INTAKE → SPECIFIED → DESIGNED → IMPLEMENTING → VERIFYING → STAGING → RELEASED
                                  ↓
                               BLOCKED
```

Mỗi feature chỉ được ở một trạng thái chính. Khi bị lỗi, ghi nguyên nhân và bước quay lại trong `project-state.json`; không tự đánh dấu hoàn thành để bỏ qua quality gate.

## Phase 0 — Intake và đóng phạm vi

**Mục tiêu:** Biến yêu cầu tự nhiên thành phạm vi có thể thực hiện.

**Thực hiện:** Đọc `knowledge/WEB_APP_PROBLEM_CATALOG.md` và `knowledge/DOMAIN_ADAPTATION_GUIDE.md`; chọn problem cards/profile, ghi failure hypotheses và đánh dấu card không áp dụng bằng `N/A + rationale`. Sau đó đọc `standards/PRODUCT_DISCOVERY_SPEC.md` và tạo `PRODUCT_DISCOVERY_BRIEF.template.md`. Ghi problem statement không gắn cứng vào solution, user segments/context, current journey, evidence, assumptions, alternatives, outcome/guardrail metrics và quyết định GO/GO_WITH_CONDITIONS/HOLD/STOP. Sau đó ghi tên sản phẩm, vai trò, use case, tính năng ưu tiên, dữ liệu chính, tích hợp, ràng buộc và tiêu chí hoàn thành. Tách rõ MVP, phase sau và out-of-scope. Viết các luồng chính, luồng lỗi và điều kiện bảo mật. Chọn compliance/risk profile từ `standards/AUDIT_COMPLIANCE_SPEC.md` và dùng `standards/COMMERCE_RECOMMENDATION_DASHBOARD_GATES.md` để kích hoạt đúng profile; nếu có Việt Nam hoặc iOS thì tạo scope record ngay từ intake. Nếu có typography/token/theme/light-dark/system hoặc locale/translation/RTL thì kích hoạt Theme/I18N profile và ghi supported modes/locales/direction ngay từ intake.

**Đầu ra:** `PRD.md`, `acceptance-criteria.md`, danh sách persona, route map sơ bộ, permission matrix sơ bộ và compliance scope.

**Gate:** Không có problem/user/outcome, problem cards/profile, tiêu chí chấp nhận, người dùng mục tiêu hoặc failure hypothesis quan trọng thì trạng thái là `BLOCKED`.

## Phase 1 — Recon codebase và kiến trúc

**Mục tiêu:** Hiểu đúng hệ thống trước khi sửa.

**Thực hiện:** Kiểm tra Git status và commit hiện tại; đọc README, current status, các `skills.md` liên quan, Graphify report và tài liệu domain. Đọc `standards/README.md`, `knowledge/WEB_APP_PROBLEM_CATALOG.md` và `knowledge/DOMAIN_ADAPTATION_GUIDE.md`; chọn problem cards/profile rồi tạo impact map chỉ rõ module backend, schema, endpoint, route, component, store, socket event và test có thể bị ảnh hưởng. Load theo signal: commerce → `knowledge/COMMERCE_SYSTEMS_PLAYBOOK.md`; recommendation/search → `knowledge/RECOMMENDATION_SEARCH_RANKING_PLAYBOOK.md`; dashboard → `knowledge/DASHBOARD_ANALYTICS_PLAYBOOK.md`; race/side effect → `knowledge/TRANSACTION_CONCURRENCY_PLAYBOOK.md`; repo/CI → `knowledge/REPOSITORY_CI_PATTERNS_PLAYBOOK.md`; Việt Nam/iOS → compliance profile tương ứng; theme/token/dark mode → `standards/THEME_AND_DESIGN_TOKENS_SPEC.md`; locale/translation/RTL → `standards/I18N_L10N_SPEC.md`. Không đọc mù toàn bộ repository.

**Đầu ra:** `feature-impact-map.md`, architecture map, C4 impact view, Architecture Review/ADR draft, standards profile và danh sách file mục tiêu.

**Gate:** Agent phải giải thích được feature đi qua những lớp nào, source of truth nào áp dụng và nêu được ít nhất các rủi ro tương tác. Thay đổi boundary, dependency, runtime, data flow hoặc quality attribute phải qua `standards/ARCHITECTURE_GOVERNANCE_SPEC.md`; thiếu rationale hoặc rollback là `NEEDS_REVIEW`.

## Phase 2 — Domain, database và API design

**Mục tiêu:** Chốt hợp đồng trước khi code.

**Thực hiện:** Dùng `knowledge/BACKEND_PROBLEM_PLAYBOOK.md` và `standards/PROBLEM_ORIENTED_TEST_MATRIX.md` để nhận diện CRUD, authorization, tenant, transaction/concurrency, idempotency, upload, external API, payment, webhook, notification, realtime, queue, cache, AI và deployment problem áp dụng. Với commerce, chốt `COMMERCE_FLOW_SPEC.template.md`; với race, money, inventory, entitlement, webhook hoặc retry, chốt `TRANSACTION_CONCURRENCY_TEST.template.md`; với recommendation/search, chốt event/candidate/ranking/cold-start trong `RECOMMENDATION_FEATURE_SPEC.template.md`; với dashboard, chốt grain/metric/access/freshness trong `DASHBOARD_ANALYTICS_SPEC.template.md`. Mô hình hóa entity, quan hệ, trạng thái và state transition theo `standards/CANONICAL_DATA_SPEC.md`. Dùng `standards/DATABASE_ARCHITECTURE_SPEC.md` cho bounded context, ownership/tenant, 3NF, FK/unique/check, index, transaction, lock, outbox, migration, rollback, retention và backup. Định nghĩa DTO, response, lỗi, auth guard, role, pagination, filter, idempotency và event payload theo `standards/API_CONTRACT_SPEC.md`; duyệt breaking change/deprecation theo `standards/CONTRACT_GOVERNANCE.md`. Với database, dùng quy trình `schema → migration generate → review SQL → migrate/push → restart backend → verify`. Nếu có theme/token, hoàn thiện `THEME_CONFIG.template.json`; nếu có locale/translation/RTL, hoàn thiện `TRANSLATION_CATALOG.template.json`; cả hai profile dùng `LOCALE_QA_MATRIX.template.md` và gate `THEME_I18N_GATES.md`.

**Đầu ra:** ERD hoặc domain model, state machine, data entity spec, database design, migration plan, API contract, permission matrix và event contract.

**Gate:** Frontend validation phải khớp Backend DTO; tên ID, enum, status, nullability, money/time format và route param phải thống nhất. Thiếu ownership path, invariant hoặc rollback plan là `NEEDS_REVIEW`/`BLOCKED`.

## Phase 3 — Bootstrap môi trường

**Mục tiêu:** Tạo môi trường chạy lặp lại được.

**Thực hiện:** Chuẩn hóa Node version, pnpm version, database image, Redis, storage, OAuth, email, payment sandbox và các biến môi trường. Tạo `.env.example` không có secret thật. Khởi động dependency theo thứ tự: database/Redis healthy → migration → backend → frontend. Áp dụng `standards/SRE_PLATFORM_OPERATIONS_SPEC.md` để ghi service catalog, health/readiness/startup, dependency failure policy, logging/metrics/tracing, SLI/SLO expectation, runbook và cost/capacity assumptions.

**Đầu ra:** `local-setup.md`, `.env.example`, environment matrix và health-check evidence.

**Gate:** Database kết nối được, Redis trả lời, migration sạch, API health check hoạt động, Swagger mở được và frontend gọi đúng API.

## Phase 4 — Vertical slice

**Mục tiêu:** Chứng minh một luồng chạy xuyên suốt.

```text
Use case
  → Data entity/migration
  → Repository
  → Service/domain rule
  → DTO/controller/Swagger
  → Frontend type/API service
  → Hook/store
  → Page/form/component
  → Loading/error/empty/permission state
  → Unit/API/contract/E2E/a11y test
  → Traceability evidence
```

Chọn một luồng nhỏ nhưng có giá trị, ví dụ đăng nhập hoặc tạo giải đấu. Không xây mọi màn hình trước khi có vertical slice. Dùng `standards/contracts/examples/create-tournament.openapi.yaml` và schemas làm ví dụ, không xem placeholder domain là contract production.

**Gate:** Dữ liệu phải đi thật từ UI đến API/database và đọc ngược lại; response/error phải khớp schema; test phải bao phủ happy path, lỗi đầu vào, permission và state UI.

## Phase 5 — Feature slices

Mỗi feature lặp lại chu trình. Khi change có profile domain, phải đặt artifact profile trong change workspace trước implementation: commerce/payment/marketplace thêm commerce flow và transaction test; recommendation/search thêm recommendation spec; dashboard/reporting thêm analytics spec; Việt Nam thêm compliance scope record; iOS thêm Apple release review; theme/token/dark mode thêm theme config; locale/translation/RTL thêm translation catalog và locale QA matrix. Quy tắc commerce nằm trong `standards/COMMERCE_RECOMMENDATION_DASHBOARD_GATES.md`; quy tắc theme/i18n nằm trong `standards/THEME_I18N_GATES.md`.

Mỗi feature lặp lại chu trình:

```text
Spec → Impact Map → Data/DB → API/Event → UI/Design QA → Backend → Frontend
→ Edge Cases → Contract/Unit/E2E/A11y/Security/AI Eval Tests → SRE Observability/Runbook → Audit Evidence → Convergence Review → Docs
```

Với đồ án quản lý giải đấu, thứ tự phụ thuộc khuyến nghị là: foundation; auth/users; categories/venues; tournaments/registration; stages/brackets; matches; live score; rankings/ELO; payments; communities/social; organizer/admin; polish/release. Nếu feature dùng AI, phải thêm task contract, eval dataset/graders, budget, tool policy và offline regression theo `standards/AI_EVALUATION_AND_COST_SPEC.md`. Commerce/payment/recommendation personalization mặc định là `HighRisk`; chỉ dùng tier thấp hơn khi có `profile-risk-waiver.md` với owner, compensating control và expiry. Scope Việt Nam dùng `LEGAL_REVIEW_REQUIRED` khi câu hỏi pháp lý chưa được qualified reviewer quyết định; iOS policy còn cần platform review và không có guarantee approval.

**Gate:** Feature không được hoàn thành nếu thiếu loading, empty, error, permission, accessibility, SRE failure behavior và rollback behavior phù hợp. AI feature còn phải có deterministic/state/safety/cost checks. Nếu thêm field/status/endpoint mà chưa cập nhật source of truth, agent phải `BLOCKED` hoặc `NEEDS_CLARIFICATION`.

## Phase 6 — Frontend implementation

Dùng Next.js App Router và TypeScript strict. Server Component là mặc định; chỉ dùng `'use client'` khi cần hook, event hoặc browser API. Dùng TailwindCSS, UI primitives chung, semantic design tokens, mobile-first và không hardcode style rải rác. Component chỉ render; logic API/state phức tạp nằm trong `features/*/api`, `features/*/hooks` hoặc store.

Áp dụng `standards/UI_UX_DESIGN_SYSTEM_SPEC.md` và `standards/DESIGN_QA_SPEC.md`: map stable error code/status sang screen state; kiểm tra keyboard, focus, contrast, reduced motion, responsive, long text, offline và visual regression. Với Theme profile, dùng semantic/component tokens và kiểm tra light/dark/system, no-flash/hydration, forced colors và theme persistence. Với I18N profile, dùng message key, locale formatter, fallback, plural/select, text expansion, `lang`/`dir`, bidi và logical CSS. Axios instance phải xử lý access token, refresh token và 401 retry. Form dùng React Hook Form + Zod, trim input và map lỗi backend. Socket phải có auth handshake, room/event contract, reconnect behavior và cleanup listener.

## Security gate xuyên suốt

Với feature có authentication, PII, payment, admin, realtime, upload hoặc AI, agent phải đọc `security/README.md`, lập threat/control notes và chọn test từ `security/SECURITY_TEST_MATRIX.md`. Không chờ đến cuối release mới kiểm tra security. Với AI Agent, đọc thêm `standards/AI_AGENT_PROTOCOL.md` và `standards/AI_AGENT_HARNESS_SPEC.md`; task phải có allowed paths, source of truth, stop conditions và evidence output.

Các invariant bắt buộc gồm: backend enforce authentication + authorization + ownership + state; token/reset/verification không lưu raw; cookie mutation có CSRF/Origin policy; OAuth có state/nonce/PKCE phù hợp; WebSocket có Origin và per-message authorization; webhook có signature + idempotency; external side effect có timeout/retry; logs không có secret. P0 không được mở khi merge; P1 phải có remediation hoặc risk acceptance có owner và thời hạn.

## Phase 7 — QA, security và regression

Chọn test cases từ `standards/PROBLEM_ORIENTED_TEST_MATRIX.md` theo risk tier và applied problem cards. Chạy unit test cho domain helper, ELO, bracket, fee và state transition. Chạy API/integration test cho DTO, guard, repository, transaction và webhook. Chạy contract test với JSON Schema/OpenAPI examples và consumer verification khi có client độc lập. Chạy E2E cho các journey chính, accessibility/keyboard/visual regression theo design QA. Với Theme/I18N, chạy locale/theme matrix, pseudo-locale, long text, missing-key, plural, date/number/currency/timezone, SSR/hydration, RTL, reduced-motion và forced-colors khi supported. Với commerce, test duplicate request, price/amount/currency mismatch, inventory race, refund/reconciliation and webhook ordering. Với recommendation/search, test event schema, unauthorized candidates, cold start, safety filter, ranking rollback and segment guardrails. Với dashboard, test metric fixtures, timezone/grain, row-level access, export and stale/partial data. Với AI, chạy smoke/capability/regression/safety eval và kiểm tra transcript, outcome, tool policy, budget và model/prompt version. Chạy SRE checks cho health/readiness, timeout/retry/idempotency, observability, migration/rollback và runbook. Kiểm tra riêng auth bypass, RBAC, token replay, rate limit, CORS, upload, secret leak, webhook gọi đúp và concurrency.

Đối với đồ án này, bắt buộc rà lại payment status, `isPaid`, `divisionId`, bracket BYE, double-elimination index, registration race condition, ELO row lock, refresh session và soft delete. Lưu requirement-to-control-to-code-to-test-to-evidence trong traceability template.

## Phase 8 — CI/CD và staging

Pipeline tối thiểu:

```text
Install với pnpm
  → lint
  → type-check/build
  → unit/integration test
  → schema/contract test
  → E2E + accessibility
  → AI eval (nếu có)
  → security checks + dependency review
  → architecture fitness checks
  → theme/locale/token checks (nếu applicable)
  → review
  → deploy staging
  → migration có kiểm soát
  → health/readiness + smoke test
  → observability/runbook check
  → evidence package
```

Staging phải dùng secret riêng, domain/CORS riêng và dữ liệu seed không nhạy cảm. Ghi lại version image, migration đã chạy, schema/contract version và kết quả health check. Không nuốt lỗi migration hoặc build/type validation để pipeline xanh giả.

## Phase 9 — Production release

Trước release, áp dụng `standards/SRE_PLATFORM_OPERATIONS_SPEC.md` và nếu có Theme/I18N thì xác nhận token/catalog version, supported modes/locales, visual/accessibility evidence, fallback/missing-key telemetry và rollback content. Xác nhận service owner, SLI/SLO/error budget, dashboard/alert, backup/restore evidence, RPO/RTO, migration plan, rollback plan, observability, HTTPS, CORS, rate limit, storage policy, webhook URL, payment mode và admin account. Nếu có AI, xác nhận offline eval, cost budget, tool policy, safety gate và model/prompt rollback. Sau deploy, kiểm tra health/readiness, login, tạo dữ liệu mẫu, realtime, upload, payment sandbox hoặc production mode phù hợp và post-release watch window.

Release decision dùng `PASS`, `PASS_WITH_RISK`, `NEEDS_REVIEW` hoặc `BLOCKED`, kèm reviewer, evidence, open findings, waiver expiry và owner. Với profile mới, dùng thêm `NEEDS_LEGAL_REVIEW` cho scope pháp lý chưa quyết định; hard blockers trong `COMMERCE_RECOMMENDATION_DASHBOARD_GATES.md` và `THEME_I18N_GATES.md` không được che bằng waiver chung. Standards pack không phải chứng nhận pháp lý, Apple approval, payment certification hoặc sector compliance; profile/compliance claim nào cũng cần phạm vi và review phù hợp.

## Phase 10 — Handoff và tri thức

Cập nhật changelog, runbook, API docs, known issues, environment matrix, test evidence, contract changelog và Graphify. Ghi rõ file đã thay đổi, migration, biến môi trường mới, thao tác deploy, cách rollback và người phụ trách. Lưu compliance traceability, screenshots/trace/log redacted và reviewer decision.

## Quy tắc chuyển phase

Mỗi lần chuyển phase phải cập nhật `project-state.json` với `status`, `completed`, `evidence`, `risks`, `next_action` và `updated_at`. Nếu working tree thay đổi bất thường, dừng lại, ghi baseline mới, đọc lại file rồi mới patch tiếp. Không dùng lệnh ghi đè hàng loạt để giải quyết xung đột nếu chưa có yêu cầu rõ ràng.
