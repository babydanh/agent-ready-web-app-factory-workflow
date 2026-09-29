# SKILL — Quy tắc cho AI Agent trong Web App Factory

## Vai trò

Agent phải hoạt động như một kỹ sư phần mềm có trách nhiệm: hiểu context trước khi sửa, thay đổi trong phạm vi nhỏ, xác nhận bằng test và ghi lại tri thức sau khi hoàn thành. Agent không được đoán kiến trúc chỉ từ tên file hoặc tự coi việc build thành công là bằng chứng nghiệp vụ đúng.

## Quy trình đọc bắt buộc

Trước khi code, agent phải đọc README, trạng thái dự án, skill map của phần liên quan, Graphify report và tài liệu domain. Agent phải đọc `standards/README.md`, `knowledge/WEB_APP_PROBLEM_CATALOG.md` và `knowledge/DOMAIN_ADAPTATION_GUIDE.md`, chọn problem cards/profile phù hợp, phân loại change tier, chọn Product Discovery/Architecture/Data/Database/API/UI spec phù hợp, rồi lập Feature Impact Review và impact map. Feature Impact Review phải trả lời route/screen nào bị ảnh hưởng, role/permission nào bị ảnh hưởng, state transition/invariant nào đổi, button nào hiện/ẩn/disabled/loading, error/empty/conflict/retry ra sao, Web/App/Admin/Ops có lệch semantics không, source of truth/contract owner là ai, test/evidence nào chứng minh và quyết định GO/GO_WITH_CONDITIONS/HOLD/STOP.
Normal/high-risk feature phải có discovery/architecture artifact trước implementation; feature có backend/side effect phải đọc `knowledge/BACKEND_PROBLEM_PLAYBOOK.md` và chọn rows trong `standards/PROBLEM_ORIENTED_TEST_MATRIX.md`. Load domain pack theo signal thay vì đọc hết: commerce → `knowledge/COMMERCE_SYSTEMS_PLAYBOOK.md`; recommendation/search → `knowledge/RECOMMENDATION_SEARCH_RANKING_PLAYBOOK.md`; dashboard → `knowledge/DASHBOARD_ANALYTICS_PLAYBOOK.md`; race/payment/webhook/queue → `knowledge/TRANSACTION_CONCURRENCY_PLAYBOOK.md`; repo/CI → `knowledge/REPOSITORY_CI_PATTERNS_PLAYBOOK.md`; Việt Nam → `standards/VIETNAM_WEB_APP_COMPLIANCE_PROFILE.md`; iOS → `standards/APPLE_IOS_APP_STORE_POLICY_PROFILE.md`; typography/token/light-dark/system/high-contrast → `standards/THEME_AND_DESIGN_TOKENS_SPEC.md`; locale/translation/date-number-currency/timezone/RTL → `standards/I18N_L10N_SPEC.md`. Không grep/cat mù toàn bộ repository, chỉ đọc các file được Graphify hoặc impact map xác định là liên quan.

Trước task có external side effect hoặc high-risk change, agent phải đọc `standards/AI_AGENT_PROTOCOL.md`, `standards/AI_AGENT_HARNESS_SPEC.md`, `standards/AI_EVALUATION_AND_COST_SPEC.md` nếu có AI và `standards/SRE_PLATFORM_OPERATIONS_SPEC.md` nếu có runtime/release impact. Task phải có source of truth, allowed paths, forbidden actions, stop conditions và output/evidence schema. Nếu thiếu contract, discovery decision hoặc acceptance criteria, dùng `NEEDS_CLARIFICATION`, không tự suy đoán. Với profile Việt Nam, `COMPLIANCE_SCOPE_RECORD` và `LEGAL_REVIEW_REQUIRED` là review controls, không phải legal conclusion; với Apple, review artifact không phải approval.

Sau feature lớn, thay đổi module hoặc thay đổi luồng dữ liệu, phải cập nhật Graphify và kiểm tra import edge. Convergence Review phải đối chiếu implementation với Feature Impact Review; nếu phát sinh route, button, state, field, endpoint, event hoặc side effect mới thì cập nhật FIR trước khi tiếp tục.
Nếu Graphify không chạy được, ghi lỗi vào state và không giả vờ rằng graph đã cập nhật.

## Contract-first và standards rules

`knowledge/WEB_APP_PROBLEM_CATALOG.md` là catalog các bài toán lặp lại và failure modes; `knowledge/DOMAIN_ADAPTATION_GUIDE.md` là chuẩn chọn archetype/profile; `knowledge/BACKEND_PROBLEM_PLAYBOOK.md` là recipe cho CRUD, booking, payment, external API, webhook/outbox, upload, search, notification, realtime, job, cache, auth, AI và deployment. `standards/PROBLEM_ORIENTED_TEST_MATRIX.md` là ma trận chuyển failure mode thành test/evidence. `standards/PRODUCT_DISCOVERY_SPEC.md` là chuẩn cho problem, user/context, evidence, assumption, alternatives, outcome metrics và go/no-go. `standards/ARCHITECTURE_GOVERNANCE_SPEC.md` là chuẩn cho C4, ADR, quality attributes, dependency boundaries, fitness functions, waiver và drift review. `standards/CANONICAL_DATA_SPEC.md` là chuẩn cho tên field, ID, nullability, enum, money, time, privacy và state. `standards/DATABASE_ARCHITECTURE_SPEC.md` là chuẩn cho ownership, normalization, constraint, index, transaction, migration, retention và backup. `standards/API_CONTRACT_SPEC.md` cùng `CONTRACT_GOVERNANCE.md` là chuẩn cho success/error envelope, OpenAPI/JSON Schema, idempotency, pagination, realtime/job payload, compatibility và deprecation. `standards/UI_UX_DESIGN_SYSTEM_SPEC.md` cùng `DESIGN_QA_SPEC.md` là chuẩn cho token, component, state matrix, responsive và WCAG 2.2 AA. `standards/THEME_AND_DESIGN_TOKENS_SPEC.md` là chuẩn cho primitive/semantic/component token, typography, light/dark/system, SSR/no-flash, contrast, forced colors, reduced motion và direction-aware layout. `standards/I18N_L10N_SPEC.md` là chuẩn cho locale registry, fallback, message catalog, plural/select, date/number/currency/timezone, translation review, text expansion, bidi và RTL. `standards/THEME_I18N_GATES.md` là source of truth cho artifact và release blockers của hai profile. `standards/SRE_PLATFORM_OPERATIONS_SPEC.md` là chuẩn cho service catalog, SLI/SLO, observability, incident, backup/restore, deployment và rollback. `standards/AI_EVALUATION_AND_COST_SPEC.md` là chuẩn cho dataset, graders, safety, model/prompt/tool version, cost budget và offline/online eval. `knowledge/COMMERCE_SYSTEMS_PLAYBOOK.md` và `knowledge/TRANSACTION_CONCURRENCY_PLAYBOOK.md` là chuẩn nhận diện money/inventory/payment/ledger/payout/idempotency/reconciliation controls. `knowledge/RECOMMENDATION_SEARCH_RANKING_PLAYBOOK.md` là chuẩn cho event/candidate/scoring/re-ranking/cold-start/evaluation/safety. `knowledge/DASHBOARD_ANALYTICS_PLAYBOOK.md` là chuẩn cho metric/data grain/access/freshness/query/export. `knowledge/REPOSITORY_CI_PATTERNS_PLAYBOOK.md` là chuẩn cho repo boundary, CODEOWNERS, CI tiers, cache và supply-chain evidence. `standards/COMMERCE_RECOMMENDATION_DASHBOARD_GATES.md` là source of truth cho profile activation, required artifacts, blockers và waiver.

Không thêm field, status, error code, endpoint, event hoặc UI state ngoài source of truth mà không cập nhật contract và consumer impact. Không trả raw ORM row. Không để UI suy luận domain state từ message text. Không coi schema example hoặc TypeScript compile là đủ nếu chưa có runtime contract/negative evidence.

## Quy tắc stack của đồ án mẫu

| Khu vực | Chuẩn |
|---|---|
| Backend | NestJS modular monolith, TypeScript strict |
| Database | PostgreSQL/PostGIS + Drizzle ORM |
| Cache/queue | Redis + BullMQ |
| Auth | JWT, Passport, bcrypt, RBAC |
| Realtime | Socket.IO với auth handshake, room và cleanup |
| Frontend | Next.js App Router, React, TypeScript |
| UI | TailwindCSS, shared UI primitives, mobile-first |
| State | Zustand cho global/transient state phù hợp |
| HTTP | Axios instance và interceptor tập trung |
| Form | React Hook Form + Zod |
| Test | Jest, Supertest, Playwright |
| Package | pnpm; không dùng npm/yarn trong repository này |

Khi dùng bộ workflow cho dự án khác, phải thay bảng trên bằng stack thật của dự án trước khi code. Không áp dụng máy móc công nghệ của đồ án mẫu.

## Backend rules

Mỗi feature phải có module, controller, service và repository phù hợp. DTO phải validate toàn bộ input; response không được lộ password hash hoặc secret. Lỗi phải theo format thống nhất và lỗi domain nên nằm tại module tương ứng.

Thay đổi schema phải đi theo chu trình `schema → migration generate → review SQL → migrate/push → restart backend → test`. Tiền, payout, refund và ELO phải nằm trong transaction phù hợp. Webhook phải verify signature, có idempotency key và audit trail. Payment/payout/entitlement/inventory mutations phải có transaction/concurrency plan, duplicate/out-of-order tests và reconciliation path. Commerce/payment/recommendation personalization mặc định là HighRisk; tier thấp hơn chỉ được dùng với explicit profile-risk-waiver có approver, compensating control và expiry. Trạng thái nghiệp vụ phải được mô hình hóa thành state machine; không dùng status mới nếu chưa cập nhật toàn bộ consumer.

Bảng chính dùng soft delete nếu domain yêu cầu. Khi có nguy cơ race condition, dùng transaction và row lock phù hợp. Không hardcode bypass dành cho test vào production path.

## Frontend rules

Không dùng `any`, JavaScript, Pages Router, CSS Modules/SASS hoặc URL API rải trong component nếu chúng trái với convention của repository mẫu. Type API phải mapping chính xác với backend DTO. Logic API, fetch, submit và state phức tạp phải tách khỏi component.

Dùng Server Component mặc định. Chỉ thêm `'use client'` khi cần hook, event hoặc browser API. Mọi form phải có loading, error, success và validation feedback. Chuỗi nhập phải trim theo utility chung. Không dùng `alert()`; dùng error helper và toast theo convention.

Socket listener phải được cleanup. Các component lớn phải tách nhỏ. Animation dùng wrapper chung thay vì tạo hiệu ứng rải rác. UI phải có responsive, empty state, loading state, error state, permission state và accessibility cơ bản. Khi có Theme profile, chỉ dùng semantic/component tokens và test light/dark/system/no-flash/contrast/reduced-motion. Khi có I18N profile, không hardcode text, phải dùng message key, locale formatter, fallback, text expansion và logical CSS/RTL nếu hỗ trợ. State mapping phải dựa trên HTTP/status/error code ổn định và có fallback cho error chưa biết.

## Quy định Chuẩn hóa Đa ngôn ngữ (VI / EN Localization & Parity Standards)

1. **Nguyên tắc cốt lõi (Core Invariant)**:
   - Toàn bộ giao diện người dùng (UI texts, tiêu đề, nút bấm, nhãn trạng thái, thông báo lỗi, empty state, validation, modal, tooltip, share payload) PHẢI hỗ trợ 100% cả 2 ngôn ngữ: **Tiếng Việt (`vi`)** và **Tiếng Anh (`en`)**.
   - **Tuyệt đối KHÔNG hardcode chuỗi text trần** trong bất kỳ component/widget nào. Mọi văn bản hiển thị phải được lấy từ hệ thống từ điển i18n/l10n.

2. **Web Frontend (`HethongFrontEndWeb_QLgiaidau` - `next-intl`)**:
   - Mọi key dịch thuật phải được khai báo đồng thời và đối xứng ở cả 2 file `messages/vi.json` và `messages/en.json`.
   - Kiểm tra đúng cấu trúc Namespace khi gọi `useTranslations('Namespace')` hoặc `getTranslations('Namespace')` để tránh hoàn toàn lỗi `MISSING_MESSAGE: Namespace.key`.
   - Các định dạng số, tiền tệ, ngày giờ phải theo chuẩn locale hiện tại thông qua `formatDate`, `formatCurrency`, `Intl.DateTimeFormat(locale, ...)`.

3. **Mobile App (`HethongFrontEndApp_QLgiaidau` - Flutter `AppLocalizations`)**:
   - Mọi chuỗi dịch thuật phải được khai báo đầy đủ trong cả 2 file ARB: `lib/l10n/app_vi.arb` và `lib/l10n/app_en.arb`.
   - Trong Widget, luôn sử dụng `final l10n = AppLocalizations.of(context)!;` hoặc extension `context.l10n`.
   - Khi thêm key mới, phải cập nhật đồng bộ cả 2 file ARB và xác thực `flutter analyze`.

4. **Chuẩn hóa Thuật ngữ Thể thao Thống nhất (Sports Terminology Parity)**:
   - Quán quân $\rightarrow$ `Champion`
   - Á quân $\rightarrow$ `Runner-up`
   - Đồng hạng 3 / Hạng 3 $\rightarrow$ `Third Place` / `Joint 3rd Place`
   - Vòng loại trực tiếp $\rightarrow$ `Knockout Stage`
   - Vòng bảng $\rightarrow$ `Group Stage`
   - Vòng nhánh thua $\rightarrow$ `Losers Bracket`
   - Đang diễn ra $\rightarrow$ `Live` / `In Progress`
   - Đã kết thúc $\rightarrow$ `Completed`
   - Sắp diễn ra $\rightarrow$ `Upcoming`
   - Vô thẳng $\rightarrow$ `BYE` / `Walkover`

## Quy định Chuẩn hóa Vibe Màu Sắc & Typography (Brand Design Tokens & Typography Standards)

1. **Bảng màu cốt lõi SportO (SportO Brand Colors)**:
   - **Primary Blue (`rgb(29, 142, 248) / #1D8EF8`)**: Màu nhận diện thương hiệu chủ đạo từ Web (`globals.css`) đồng bộ sang Mobile App. Dùng cho:
     - Toàn bộ nút chính (Primary buttons, CTA, Apply/Save actions)
     - Thanh điều hướng chính (Active Bottom Nav tab icon & label, Active Tab underline/pill, Top bar branding)
     - Tiêu đề chính, Link điều hướng quan trọng ("Xem tất cả" / "View all", Breadcrumbs)
     - Chỉ số active carousel (Pagination dot indicator active), Ring avatar active.
   - **Primary Hover (`#0B76D8` / `#002461`)**: Trạng thái hover/pressed của các thành phần Primary.
   - **Primary Light / Tint (`#B2CFFD`)**: Background của chip/badge trạng thái active, container sáng, selected list row.
   - **Logo Navy (`#002E7C`)**: Màu logo navy và các mảng accent đậm.
   - **Secondary Cyan Accent (`#3AB5F6`)**: Dùng cho điểm nhấn phụ trợ, sub-brand highlights, hoặc biểu đồ/icon phụ.
   - **Neutral Slate Palette**: Slate 900 (`#0F172A`) cho title/body text đậm; Slate 600 (`#475569`) cho subtitle/secondary text; Slate 400 (`#94A3B8`) cho muted/inactive icon; Slate 200 (`#E2E8F0`) cho border/divider lines; Slate 50 (`#F8FAFC`) cho background surfaces.
   - **Status Colors**: Success (`#16A34A`), Warning (`#D97706`), Danger/Live Pulse (`#DC2626`).

2. **Quy tắc Thiết kế Giao diện Tinh Tế & Chống Màu Đậm Nặng Mắt (Taste & Anti-Slop UI Standards)**:
   - **Tuyệt đối không dùng màu đậm đặc (Solid Dark/Heavy Color) cho toàn bộ ô hover/active**:
     - Cấm bọc cả khối bằng nền xanh đậm chói chang (`bg-blue-600` bọc cả ô to, menu flyout hoặc button thường).
     - Trạng thái Hover / Active phải dùng tông **Light Tint hoặc Outline mềm mại**:
       * Nền active/selected: dùng `bg-blue-50/70` hoặc `bg-slate-100/80` kết hợp chữ/icon `text-blue-600` và viền mảnh nhẹ (`ring-1 ring-blue-500/20` hoặc `border-blue-200/80`).
       * Nền hover thông thường: dùng `hover:bg-slate-100/70` kết hợp chữ `text-slate-900`.
   - **Giảm tải thị giác (Visual Weight Reduction)**:
     - Giữ không gian thoáng, shadow nhẹ nhàng (`shadow-sm` hoặc `shadow-slate-900/5`), góc bo chuẩn mực (`rounded-xl` / `rounded-2xl`).
     - Không lạm dụng badge đậm màu hoặc icon đảo màu âm bản (`brightness-0 invert`) khi không cần thiết; ưu tiên monochrome hoặc icon màu gốc tinh gọn.

3. **Chuẩn hóa Typography (Font Hierarchy & Weights)**:
   - **Font Family**: Inter, SF Pro, Roboto, system-ui (Không dùng font lạ gây vỡ layout).
   - **Hệ thống cấp bậc chữ (Hierarchy)**:
     - `Heading 1 / Screen Title`: 20px - 24px, Bold (`FontWeight.w800` / `font-bold`), letter-spacing: `-0.02em`.
     - `Section Title`: 16px - 18px, Bold (`FontWeight.w700` / `font-bold`).
     - `Card Title / Match Title`: 14px - 15px, SemiBold (`FontWeight.w600` / `font-semibold`).
     - `Body / Normal Text`: 13px - 14px, Regular (`FontWeight.w400` / `font-normal`), line-height: `1.5`.
     - `Caption / Subtext / Badge`: 11px - 12px, Medium/Bold (`FontWeight.w500` hoặc `FontWeight.w600`).
     - `Nav Item / Micro Label`: 10px - 11px, Bold khi active (`FontWeight.w700`), Medium khi inactive (`FontWeight.w500`).

3. **Quy định Chuẩn hóa Animation & Motion Mượt mà (Flutter Motion & Interaction Standards)**:
   - **Accordion / Expand & Collapse**:
     - Tuyệt đối không toggle trạng thái UI đột ngột bằng `if (expanded) ...[]` gây giật layout (layout jank).
     - Phải sử dụng `AnimatedCrossFade` hoặc `AnimatedSize` với duration từ `200ms - 300ms` và curve mượt mà (`Curves.fastOutSlowIn` hoặc `Curves.easeInOutCubic`).
     - Icon mũi tên / chevron toggle phải kết hợp `AnimatedRotation` (turns: `0.5` / `0.0`, duration `250ms`) để xoay mềm mại đồng bộ với nội dung mở rộng.
   - **Touch & Press Feedback**:
     - Mọi interactive item, card, hàng danh sách phải bọc trong `InkWell` với `borderRadius` tương ứng để tạo ripple effect tự nhiên của hệ điều hành.
   - **List Transitions & Micro-interactions**:
     - Danh sách thay đổi trạng thái hoặc lọc dữ liệu cần hỗ trợ chuyển cảnh mượt (`AnimatedSwitcher` hoặc `FadeTransition`).
     - Tránh animation quá dài (> 400ms) gây cảm giác chậm chạp cho người dùng.

## Security rules

Không ghi API key, password, refresh token, cookie, private key hoặc dữ liệu production vào file workflow, log, commit hay screenshot. Chỉ commit `.env.example` với placeholder. Không copy credential thật sang template. Mọi route ghi dữ liệu phải kiểm tra authentication và authorization ở backend.

Không tin input từ frontend, query string, webhook hoặc file upload. Validate ở boundary, kiểm tra quyền sở hữu resource và xử lý idempotency. Không dùng CORS `*` khi có credential.

Trước feature có identity, PII, tiền, admin, realtime hoặc AI, agent phải đọc `security/THREAT_MODEL.md`, `security/AUTH_SECURITY_ARCHITECTURE.md` và phần tương ứng trong `security/SECURITY_TEST_MATRIX.md`. Khi phát hiện token/secret/session/permission risk, không tự đánh dấu Done; phải cập nhật `security/AUTH_CURRENT_STATE_REVIEW.md`, risk register hoặc ADR với remediation/evidence.

## Gate selection

Dùng `standards/EXTENDED_GATES_CHECKLIST.md`, `standards/COMMERCE_RECOMMENDATION_DASHBOARD_GATES.md` và `standards/THEME_I18N_GATES.md` để chọn gate theo risk tier/profile. Small fix không bị ép qua full discovery/architecture; normal feature phải có contract/evidence; high-risk change phải có human approval, threat/control review, rollback và operational/AI evidence tương ứng. Commerce/payment/marketplace, personalized recommendation và iOS commerce không được silently chạy tier thấp. Không dùng `PASS_WITH_CONDITIONS` để che giấu P0, data-integrity failure, unauthorized action, unresolved legal/platform review hoặc thiếu approval bắt buộc.

## Audit and evidence rules

Mọi claim “pass” phải trỏ tới command, report, test, screenshot, trace, schema diff hoặc reviewer record. Claim về button, state, parity hoặc runtime phải có evidence tương ứng; compile/build pass không được dùng thay cho UI/runtime evidence.
Traceability nối requirement → control → code/route/screen → test → evidence. P0/P1 không được che bằng waiver chung; waiver phải có owner, compensating control, expiry và human approval. `NEEDS_LEGAL_REVIEW` và platform review pending phải được giữ nguyên, không đổi thành PASS bằng AI. Standards pack không phải legal certification, Apple approval, PCI/payment certification hoặc sector compliance.

## Working tree rules

Trước mỗi batch, ghi `git status --short`, commit hiện tại và danh sách file mục tiêu. Không sửa file ngoài phạm vi. Nếu file thay đổi trong lúc xử lý, dừng, đọc lại bản mới nhất và áp dụng patch tối thiểu. Không dùng reset, restore, clean hoặc rewrite hàng loạt để xóa thay đổi của người dùng.

Sau mỗi batch, chạy `git diff --check`, kiểm tra status và chạy validation phù hợp. Không format hoặc đổi tên hàng loạt file chỉ để làm đẹp.

## Definition of Done

Một feature chỉ Done khi có đặc tả phù hợp tier, discovery/architecture decision khi cần, code, type mapping, validation, permission, error/loading/empty state, migration nếu cần, test, tài liệu, evidence, contract compatibility review, theme/locale artifacts và visual/accessibility evidence khi applicable, SRE/AI evaluation evidence khi applicable và Graphify update nếu thay đổi đủ lớn. Báo cáo cuối phải nêu rõ phần đã làm, phần chưa làm, lệnh đã chạy, test đã pass, eval/cost/SLO result nếu có, rủi ro, waiver nếu có và cách rollback.
