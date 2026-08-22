# Knowledge Base — Web App Factory

Thư mục này chứa tri thức tái sử dụng và context cần xác nhận cho từng project. `standards/` quy định chuẩn và artifact; `knowledge/` giải thích các bài toán lặp lại, domain context, failure patterns và nghiên cứu nguồn. Agent phải load theo profile áp dụng, không đọc toàn bộ corpus một cách máy móc.

## Thứ tự đọc nền tảng

| Thứ tự | File | Mục đích |
|---:|---|---|
| 1 | `PROJECT_CONTEXT.md` | Stack, runtime, owner, source locations và constraints của project |
| 2 | `DOMAIN_RULES.md` | Business rules đã được xác nhận, không suy đoán từ UI |
| 3 | `DOMAIN_ADAPTATION_GUIDE.md` | Chọn archetype/profile và tránh copy domain model sai |
| 4 | `WEB_APP_PROBLEM_CATALOG.md` | Nhận diện problem cards P-01…P-24 và failure mode |
| 5 | `BACKEND_PROBLEM_PLAYBOOK.md` | Recipe cho CRUD, booking, payment, integration, queue, realtime, cache, auth, AI và deployment |
| 6 | `KNOWN_FAILURES.md` | Failure thực tế của project và control phòng ngừa |

## Domain packs — chỉ load khi signal áp dụng

| Signal | Knowledge cần đọc | Artifact/standards đi kèm |
|---|---|---|
| Commerce/storefront/marketplace/order/inventory/payment/payout | `COMMERCE_SYSTEMS_PLAYBOOK.md` | Commerce flow + transaction/concurrency test |
| Search/ranking/recommendation/personalization/feed | `RECOMMENDATION_SEARCH_RANKING_PLAYBOOK.md` | Recommendation feature spec |
| KPI/reporting/analytics/admin dashboard/export | `DASHBOARD_ANALYTICS_PLAYBOOK.md` | Dashboard analytics spec |
| Race/idempotency/retry/webhook/queue/shared resource | `TRANSACTION_CONCURRENCY_PLAYBOOK.md` | Transaction/concurrency test |
| Monorepo/repository/CI/dependency/cache/release | `REPOSITORY_CI_PATTERNS_PLAYBOOK.md` | Repository/CI evidence |
| Vietnam launch, Vietnamese users/data, B2C/e-commerce | `../standards/VIETNAM_WEB_APP_COMPLIANCE_PROFILE.md` + `COMMERCE_RECOMMENDATION_POLICY_RESEARCH_2026-08-22.md` | Compliance scope + human legal review |
| iOS/App Store/StoreKit/account deletion/privacy SDK | `../standards/APPLE_IOS_APP_STORE_POLICY_PROFILE.md` | Apple iOS release review |
| Typography/token/light/dark/system/high contrast/motion | `../standards/THEME_AND_DESIGN_TOKENS_SPEC.md` | Theme config + locale QA matrix |
| Locale/translation/date-number/currency/timezone/RTL | `../standards/I18N_L10N_SPEC.md` | Translation catalog + locale QA matrix |

## Research and external patterns

| File | Scope |
|---|---|
| `WEB_APP_PROBLEM_CATALOG_RESEARCH_2026-08-22.md` | Nguồn và pattern cho generic problem knowledge pack |
| `COMMERCE_RECOMMENDATION_POLICY_RESEARCH_2026-08-22.md` | Research snapshot cho Google recommendation, Apple policy/StoreKit, Việt Nam legal sources và repo patterns |
| `THEME_I18N_RESEARCH_2026-08-22.md` | Nguồn MDN/W3C cho color scheme, Intl, BCP 47, logical properties và WCAG |
| `EXTERNAL_WORKFLOW_PATTERNS_RESEARCH_2026-08-22.md` | Pattern học từ các engineering/AI workflow bên ngoài |

## Quy tắc sử dụng

Knowledge domain-specific phải có source/owner/status. Nếu chưa xác nhận, ghi `draft` hoặc `open question`; không biến assumption thành rule. Không lưu secret, raw production PII, token, password hoặc provider payload nhạy cảm.

Problem catalog không thay thế Product Discovery, Architecture Review, Data/API/UI spec hoặc Security Review. Nó là lớp nhận diện rủi ro trước khi tạo các artifact đó. Mỗi feature phải đánh dấu card áp dụng hoặc `N/A + rationale` trong Problem Map.

Backend, commerce, recommendation, dashboard và transaction playbooks phải được chuyển thành contract, executable test và release evidence. Chúng không phải bằng chứng rằng một implementation cụ thể đã đúng.

Research và policy snapshot chỉ là nguồn định hướng tại thời điểm ghi nhận. Luật, policy platform, provider behavior và repository upstream có thể thay đổi; profile phải có owner và ngày review lại. Nội dung pháp lý/platform là checklist hỗ trợ scoping, không phải tư vấn pháp lý, certification hoặc cam kết App Review approval.
