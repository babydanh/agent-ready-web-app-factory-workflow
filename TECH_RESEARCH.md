# TECH RESEARCH — Web App Production A–Z

> **Phạm vi:** Nghiên cứu và khuyến nghị kỹ thuật cho web app production dựa trên đồ án Quản lý Giải đấu.
>
> **Ngày rà soát:** 22/08/2026.
>
> **Cách đọc:** Đây là tài liệu quyết định kiến trúc và trade-off. `WORKFLOW.md` quy định trình tự thực hiện; `SKILL.md` quy định luật code; tài liệu này giải thích **vì sao** chọn hoặc không chọn một công nghệ.

## 1. Kết luận kiến trúc

Khuyến nghị cho đồ án hiện tại là **modular monolith trước, service extraction sau khi có bằng chứng về tải hoặc ownership**. Backend NestJS chia module theo domain; frontend Next.js tách route, feature, API client và UI; PostgreSQL là source of truth; Redis/BullMQ dùng cho cache và background jobs; Socket.IO chỉ là lớp truyền sự kiện, không phải kho dữ liệu; storage và payment được tích hợp qua adapter.

```text
Browser
  │
  ├── HTTPS / REST API ───────────────┐
  ├── Socket.IO realtime ─────────────┤
  └── CDN/static assets                │
                                      ▼
                           Next.js Web / BFF boundary
                                      │
                                      ▼
                         NestJS Modular Monolith
              ┌───────────────┼────────────────┐
              ▼               ▼                ▼
        Domain modules    Queue workers     Realtime gateways
              │               │                │
              └───────────────┼────────────────┘
                              ▼
                PostgreSQL/PostGIS = source of truth
                              │
                 ┌────────────┴────────────┐
                 ▼                         ▼
          Redis/BullMQ                 Cloud storage
          cache, jobs                  images/files
                 │
                 ▼
          Observability: logs, metrics, traces
```

### Vì sao chưa chọn microservices?

Microservices tăng boundary, deployment unit, network failure, schema ownership, observability và operational cost. Đồ án có nhiều domain nhưng vẫn có các transaction liên kết như registration–payment–participant và match–ELO–standings. Khi các use case còn phụ thuộc chặt và team nhỏ, modular monolith thường cho tốc độ phát triển và consistency tốt hơn. Chỉ tách service khi có một trong các bằng chứng: module cần scale độc lập, deploy độc lập, có ownership/team riêng, cần isolation bảo mật, hoặc workload khác hẳn như media processing.

> **Decision:** Giữ module boundary chặt ngay từ đầu để việc tách service sau này là lựa chọn khả thi, nhưng không trả chi phí distributed system trước khi cần.

## 2. Decision matrix toàn stack

| Lớp | Khuyến nghị cho project | Lý do | Khi nào đổi |
|---|---|---|---|
| Frontend | Next.js App Router + React + TypeScript | Server/Client boundary, routing, streaming, ecosystem | Cần mobile/native hoặc static-only hoàn toàn |
| UI | TailwindCSS + shared primitives | Consistency, responsive, tốc độ xây UI | Team có design system khác đã chuẩn hóa |
| Backend | NestJS modular monolith | Module/DI/guard/pipes, phù hợp domain nhiều module | Workload/team cần deploy độc lập |
| API | REST + OpenAPI/Swagger | Dễ debug, hợp web/mobile, contract rõ | Graph-shaped read model phức tạp và team đã có GraphQL expertise |
| Database | PostgreSQL + PostGIS | Transaction, relational integrity, spatial query | Workload document/search đặc thù, có evidence rõ |
| ORM | Drizzle ORM | Type-safe, SQL-first, migration rõ | Project đã chuẩn hóa ORM khác |
| Cache | Redis với TTL và invalidation rõ | Giảm read pressure, session/short-lived state | Cần cache layer managed khác |
| Background jobs | BullMQ + Redis | Retry/backoff, scheduled jobs, worker model | Cần durable broker/stream semantics khác |
| Realtime | Socket.IO | Room, client/server events, reconnect tooling | Cần managed pub/sub hoặc protocol khác |
| File storage | Cloudinary/S3 qua adapter | Không lưu blob lớn trong DB, CDN/transform | Compliance yêu cầu object store riêng |
| Auth | JWT/session hybrid theo threat model | Access/refresh, revoke, multi-device | Dùng IdP/OIDC managed hoàn toàn |
| Payment | payOS adapter + backend webhook | Payment link, return URL, HMAC signature | Gateway/business geography thay đổi |
| Forms | React Hook Form + Zod + backend DTO | UX validation và contract parity | Có shared schema generation |
| Testing | Jest/Supertest + Playwright | Unit/API/E2E theo user behavior | Product cần component/visual testing sâu hơn |
| Observability | OpenTelemetry + chosen backend | Vendor-neutral traces/metrics/logs | Platform đã có APM bắt buộc |
| CI/CD | GitHub Actions | Reusable workflow, PR gates, deploy stages | CI platform bắt buộc khác |
| Runtime | Docker Compose local; managed VM/container production | Reproducible dependency order | Scale/operations yêu cầu Kubernetes |

## 3. Frontend architecture

### 3.1 Server và Client boundary

Next.js App Router mặc định layouts và pages là Server Components. Client Components dành cho state, event handlers, lifecycle logic, browser-only APIs và custom hooks; Server Components phù hợp để fetch dữ liệu gần nguồn, dùng secret mà không expose ra browser, giảm JavaScript và stream nội dung.[1]

**Quy tắc workflow:**

1. Đánh dấu route/page là server-first.
2. Chỉ tạo client boundary quanh phần thực sự interactive.
3. Không đưa API key, server token hoặc database access vào client bundle.
4. Chọn data fetching theo tính chất dữ liệu: server fetch cho read ổn định; client hook/store cho tương tác, polling hoặc realtime.
5. Mọi mutation phải có pending, success, validation error, authorization error và retry/conflict behavior.

### 3.2 Feature structure

```text
src/
├── app/                         # routes, layouts, loading, error, not-found
├── components/ui/               # primitives dùng chung
├── components/shared/           # header, guards, widgets
├── features/<feature>/
│   ├── api/                     # endpoint client và response mapping
│   ├── hooks/                   # orchestration của feature
│   ├── components/              # UI feature
│   ├── schemas/                 # Zod schemas
│   └── types/                   # types feature
├── stores/                      # Zustand global state phù hợp
├── lib/                         # axios, socket, config
├── utils/                       # format, error, string, date
└── types/                       # types cross-feature
```

Component nên tập trung render và interaction. Fetch, submit, transform và state orchestration đưa vào hook/API layer. Component vượt ngưỡng phức tạp phải tách nhỏ; không tạo God component.

### 3.3 API client và auth

Axios instance là boundary duy nhất cho REST calls. Request interceptor thêm access token theo policy; response interceptor xử lý 401 bằng refresh một lần, chống retry loop và chuyển user về login khi refresh thất bại. 403 là permission state, không phải lỗi kỹ thuật cần retry. 409 là conflict cần reload hoặc resolution UI.

Không lưu refresh token ở nơi dễ bị XSS nếu threat model yêu cầu cookie HttpOnly; nếu project dùng local storage, phải ghi rõ lý do và mitigation. Đây là quyết định bảo mật, không nên copy từ template mà không review.

## 4. Backend architecture

NestJS tổ chức ứng dụng bằng modules; module encapsulate providers, controller, imports và exports. Feature module giúp boundary rõ; global modules nên hạn chế vì dễ tạo coupling.[2]

```text
src/
├── common/                      # filter, guard, interceptor, decorators
├── config/                      # validated environment config
├── database/                    # connection, schema, migrations
├── modules/
│   ├── auth/
│   ├── users/
│   ├── tournaments/
│   ├── matches/
│   ├── rankings/
│   ├── payments/
│   └── ...
├── workers/                     # queue processors
└── main.ts
```

Mỗi module nên có public interface nhỏ. Controller xử lý transport; service/domain xử lý business rule; repository xử lý persistence; DTO xử lý input boundary; exception map lỗi thống nhất. Không để controller tự chứa transaction logic phức tạp hoặc component frontend tự chứa business rule backend.

### Request lifecycle

```text
HTTP request
  → CORS/helmet/rate limit
  → authentication guard
  → authorization/ownership guard
  → validation pipe
  → controller
  → application service
  → domain rule
  → repository/transaction
  → response interceptor
  → structured log/trace
```

## 5. Database, transaction và concurrency

Drizzle cung cấp transaction API để gom nhiều SQL statement thành một logical unit, hỗ trợ rollback, nested transaction/savepoint và cấu hình PostgreSQL isolation level.[3] PostgreSQL mô tả các vấn đề concurrency như dirty read, nonrepeatable read, phantom read và serialization anomaly; isolation level phải được chọn theo use case, không phải mặc định tăng tối đa cho mọi query.[4]

### 5.1 Schema rules

Mọi entity quan trọng cần có primary key, ownership, lifecycle/status, timestamps và policy xoá. Dùng foreign key, unique constraint, check constraint và index cho invariant mà database có thể bảo vệ. Không dùng application check đơn độc cho điều kiện cạnh tranh.

### 5.2 Transaction map

| Use case | Transaction | Lock/idempotency |
|---|---|---|
| Registration capacity | Tạo participant và cập nhật capacity cùng atomic unit | Row lock hoặc constraint; test last slot |
| Payment webhook | Verify → update payment → participant paid → audit | Unique transaction reference; duplicate test |
| Refund | Validate state → create pending refund → gateway action/log | State machine và idempotency |
| Payout | Tạo request → reserve/validate balance → audit | Lock balance/status |
| ELO update | Read player ranks → calculate → update ranks/history | Row lock hoặc serializable strategy |
| Bracket generation | Create stages/groups/matches cùng logical unit | Prevent duplicate generation |
| Standings | Match completion → standings update | Idempotent event or recompute strategy |

### 5.3 Migration workflow

```text
Edit schema
  → generate migration
  → review SQL manually
  → run on clean database
  → run on representative database
  → migrate staging
  → verify data
  → restart backend if prepared statement/schema cache is relevant
  → record evidence
```

Không sửa trực tiếp database production ngoài migration process. Nếu migration destructive, phải có backup, compatibility window và rollback/forward-fix plan.

## 6. Redis, queue và background processing

Redis/BullMQ phù hợp cho công việc không cần block request như email, notification, image processing, scheduled tournament jobs, AI inference và webhook follow-up. BullMQ hỗ trợ retry với fixed, exponential hoặc custom backoff, attempts và jitter.[6] Redis cũng mô tả job queue là cách offload background work như email, payment processing, image processing, ML inference và webhooks.[7]

### Queue design chuẩn

```text
API request
  → validate and persist intent
  → enqueue job with idempotency key
  → return accepted/result
  → worker consumes
  → external call
  → persist outcome
  → retry transient failure
  → dead-letter/manual review on terminal failure
```

Job handler phải idempotent. Không retry lỗi validation, permission hoặc signature invalid; chỉ retry lỗi tạm thời như timeout, network hoặc provider 5xx với giới hạn và backoff. Ghi attempt count, duration, correlation ID, provider response class và final state. Không đặt toàn bộ business truth trong Redis; dữ liệu quan trọng phải persisted ở PostgreSQL.

## 7. Realtime và live score

Socket.IO bảo đảm message ordering, nhưng mặc định delivery là at-most-once; event bị lỡ ở server khi client disconnect không tự động được replay. Muốn at-least-once server-to-client, ứng dụng phải gán event ID, persist event và gửi offset khi reconnect.[5]

**Kiến trúc khuyến nghị cho live score:**

1. Client gửi mutation qua API hoặc authenticated socket event.
2. Backend authorize và validate match state.
3. Database transaction ghi score/event.
4. Backend phát event có `eventId`, `matchId`, `version` hoặc `sequence`.
5. Client cập nhật optimistic/state store.
6. Khi reconnect, client gọi resync API hoặc gửi offset.
7. Nếu version lệch, client bỏ optimistic state và tải snapshot mới.

Socket không thay thế database. Không dùng event broadcast chưa persist làm source of truth cho score, payment hoặc standings.

## 8. Authentication và application security

OWASP ASVS cung cấp standard để kiểm tra technical security controls của web application và dùng như metric, guidance hoặc procurement basis.[8] Workflow nên biến ASVS thành risk-based checklist thay vì chờ penetration test cuối kỳ.

### Auth/session checklist

- Access token có thời hạn ngắn và refresh token có rotation/revocation policy.
- Logout, logout-all, password reset và email/OTP verification làm invalid session phù hợp.
- Session record có device/IP/user-agent policy nhưng không ghi dữ liệu nhạy cảm quá mức.
- Cookie/token storage, SameSite, Secure, HttpOnly và CSRF strategy phù hợp với kiến trúc.
- Backend kiểm tra role và resource ownership; frontend chỉ cải thiện UX.
- Rate limit cho login, register, OTP, password reset và sensitive actions.
- Không trả password hash, provider secret, internal stack trace hoặc payment checksum.
- IDOR test: user A không đọc/sửa resource của user B bằng cách đổi ID.

OWASP Session Management nhấn mạnh session/token gắn authentication credentials với HTTP traffic và access control; workflow phải kiểm tra timeout, termination, cookie attributes và lifecycle chứ không chỉ test login.[9]

## 9. Payment và webhook

payOS yêu cầu merchant tạo payment link hoặc dùng SDK, xử lý return/cancel URL ở giao diện và xây webhook nhận kết quả đơn hàng.[10] Signature payment-request sử dụng HMAC-SHA256, dữ liệu ký được chuẩn hóa theo key alphabet và checksum key; payout signature có quy tắc khác payment-request.[11]

```text
Player register
  → server creates PENDING payment
  → server creates payOS link
  → browser opens checkout
  → returnUrl is informational/UI path
  → payOS webhook reaches backend
  → verify signature and payload
  → check amount/order/tournament ownership
  → idempotency check
  → DB transaction updates payment + registration + audit
  → queue notification
```

Không đánh dấu paid chỉ vì user quay về `returnUrl`. Không nhận webhook qua frontend. Không log checksum key hoặc raw secret. Webhook response phải nhanh; công việc nặng chuyển vào queue sau khi đã persist intent. Test success, failure, duplicate, invalid signature, mismatched amount, expired link và out-of-order events.

## 10. AI integration

AI chỉ là một dependency có xác suất lỗi và có rủi ro security, không phải nguồn sự thật cho financial/domain state. AI output phải qua schema validation, allowlisted tool, timeout, token/cost budget và human approval khi hành động có tác động bên ngoài.

OWASP LLM guidance khuyến nghị validate/sanitize input, tách instruction khỏi user data, validate output, monitor prompt-injection signs và dùng human-in-the-loop cho thao tác rủi ro cao.[12]

**AI workflow chuẩn:**

```text
Input boundary
  → normalize/limit/classify
  → build structured prompt
  → call model via server-side adapter
  → timeout/retry policy
  → parse structured output
  → validate schema and policy
  → redact unsafe content
  → human approval if high impact
  → persist result and audit
```

Không cho model tự quyết định payment success, quyền admin, xoá dữ liệu hoặc thay đổi bracket nếu không có deterministic validation và approval. Prompt, model, temperature, token usage, latency và refusal/error class nên được ghi ở mức không làm lộ dữ liệu nhạy cảm.

## 11. Testing strategy

Playwright khuyến nghị test user-visible behavior, test isolation, locators có auto-wait/retry, web-first assertions, trace viewer và chạy CI thường xuyên.[13]

### Test pyramid

| Layer | Câu hỏi trả lời |
|---|---|
| Unit | Công thức, rule và transition có đúng không? |
| Integration/API | DTO, guard, transaction, repository và error mapping có đúng không? |
| Contract | Frontend/backend payload có khớp không? |
| E2E | User có hoàn tất journey chính không? |
| Security | Có bypass auth/RBAC/ownership/secret không? |
| Concurrency | Hai request đồng thời có phá invariant không? |
| Operational | Retry, health check, migration và rollback có hoạt động không? |

Locator nên ưu tiên role, label, text hoặc test ID có contract ổn định; tránh selector phụ thuộc CSS layout. Mỗi test phải tạo state riêng hoặc fixture kiểm soát được. Khi fail trong CI, lưu trace, screenshot, video/log phù hợp.

## 12. Observability

OpenTelemetry là framework/toolkit vendor-neutral cho generation/export/collection của traces, metrics và logs; nó không phải backend lưu trữ/visualization.[14]

### Tối thiểu cần đo

| Signal | Ví dụ |
|---|---|
| Logs | request ID, user-safe actor ID, route, status, latency, error class |
| Metrics | request rate, error rate, p95 latency, queue depth, job failure, DB pool |
| Traces | HTTP → DB, HTTP → queue, worker → provider, webhook → transaction |
| Business metrics | registration success, payment success, bracket generation, score update |

Không log access token, password, checksum key, full payment payload hoặc prompt chứa dữ liệu riêng tư. Correlation ID phải đi qua API, job và realtime path khi có thể.

## 13. CI/CD và runtime

GitHub Actions cung cấp workflows, events, jobs, actions và runners để tự động hóa build/test/deploy; workflow có thể trigger theo commit/PR/schedule và tái sử dụng.[15] Pipeline production không chỉ là build image; phải có quality gate, secret boundary, migration plan và smoke test.

```text
Pull Request
  → dependency install with lockfile
  → lint/format/typecheck
  → unit/integration
  → security/dependency scan
  → build
  → E2E on ephemeral/staging environment
  → review/approval
  → deploy application
  → controlled migration
  → health/smoke test
  → monitor and rollback if needed
```

Docker Compose `depends_on` giúp điều khiển thứ tự service nhưng mặc định không chờ service ready; cần `healthcheck` và condition `service_healthy`/`service_completed_successfully` để database ready trước migration và migration xong trước backend.[16]

Với project hiện tại, runtime order là PostgreSQL/Redis healthy → migration → backend → frontend. Production cần tách `.env`, secret store, domain/CORS, backup, HTTPS, image pinning và logs. Kubernetes chỉ nên đưa vào decision record nếu nhu cầu scale/operation thực sự vượt Compose/managed container.

## 14. Technology lifecycle A–Z

| Phase | Research/engineering output | Gate |
|---:|---|---|
| 0 | PRD, personas, acceptance criteria, scope | Không còn câu hỏi blocker |
| 1 | Codebase map, Graphify, impact map | Biết chính xác boundary/file/risk |
| 2 | ADR, ERD, state machine, API/event contract | Contract được review |
| 3 | Environment matrix, env example, local bootstrap | Services ready, migration sạch |
| 4 | Vertical slice xuyên DB/API/UI/test | Journey chạy thật |
| 5 | Feature slices theo dependency | Mỗi feature có edge states |
| 6 | Security threat model, ASVS subset | P0/P1 risk được xử lý |
| 7 | Unit/API/E2E/concurrency evidence | Acceptance + regression pass |
| 8 | CI/CD, staging, migration/rollback | Staging smoke pass |
| 9 | Production release, health, monitoring | Sign-off và rollback ready |
| 10 | Docs, changelog, Graphify, handoff | Người khác có thể tiếp quản |

## 15. Khuyến nghị riêng cho đồ án hiện tại

Đồ án đã có một nền tảng tốt: backend NestJS/Drizzle/PostgreSQL, frontend Next.js, realtime Socket.IO, queue Redis/BullMQ, payment adapter, AI integration, Docker Compose và Playwright. Điểm cần cải thiện không phải thêm thật nhiều thư viện, mà là chuẩn hóa boundary, contract và evidence.

Ưu tiên kỹ thuật nên là:

1. Chốt Node version, PostgreSQL/PostGIS image và canonical path.
2. Chốt API envelope, error format, enum/status và ID naming.
3. Tách organizer manage page thành feature boundaries.
4. Hoàn thiện live score bằng persist-first + resync, không chỉ socket broadcast.
5. Tạo concurrency tests cho registration, payment webhook và ELO.
6. Hoàn thiện granular RBAC và resource ownership tests.
7. Chuyển các retryable task sang queue có idempotency và failed-job handling.
8. Tạo OpenTelemetry/log correlation tối thiểu trước production.
9. Đưa dependency/security scan và migration smoke test vào CI.
10. Chỉ tách microservice sau khi có metrics/ownership evidence.

## 16. Khi nào dùng harness nâng cao?

Harness cấp 1 chỉ chạy validation commands và kiểm tra file. Harness cấp 2 đọc `project-state.json`, xác định phase, chạy gate và dừng khi evidence thiếu. Harness cấp 3 điều phối agent theo role, tạo artifact, chạy test, review output và yêu cầu human approval cho payment/deploy/destructive migration.

Không nên tự động hóa mù các hành động có tác động production. Payment, production deploy, database destructive change, credential access và admin action phải có approval hoặc policy gate riêng.

## References

[1]: https://nextjs.org/docs/app/getting-started/server-and-client-components "Next.js — Server and Client Components"
[2]: https://docs.nestjs.com/modules "NestJS — Modules"
[3]: https://orm.drizzle.team/docs/transactions "Drizzle ORM — Transactions"
[4]: https://www.postgresql.org/docs/current/transaction-iso.html "PostgreSQL — Transaction Isolation"
[5]: https://socket.io/docs/v4/delivery-guarantees "Socket.IO — Delivery Guarantees"
[6]: https://docs.bullmq.io/guide/retrying-failing-jobs "BullMQ — Retrying failing jobs"
[7]: https://redis.io/docs/latest/develop/use-cases/job-queue/ "Redis — Job queues"
[8]: https://owasp.org/www-project-application-security-verification-standard/ "OWASP — Application Security Verification Standard"
[9]: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html "OWASP — Session Management Cheat Sheet"
[10]: https://payos.vn/docs/ "payOS — Bắt đầu"
[11]: https://payos.vn/docs/tich-hop-webhook/kiem-tra-du-lieu-voi-signature/ "payOS — Kiểm tra dữ liệu với signature"
[12]: https://cheatsheetseries.owasp.org/cheatsheets/LLM_Prompt_Injection_Prevention_Cheat_Sheet.html "OWASP — LLM Prompt Injection Prevention"
[13]: https://playwright.dev/docs/best-practices "Playwright — Best Practices"
[14]: https://opentelemetry.io/docs/what-is-opentelemetry/ "OpenTelemetry — What is OpenTelemetry?"
[15]: https://docs.github.com/en/actions/get-started/understand-github-actions "GitHub Actions — Understanding GitHub Actions"
[16]: https://docs.docker.com/compose/how-tos/startup-order/ "Docker Docs — Control startup and shutdown order in Compose"


## 17. Security & Auth pack

Phần security chuyên sâu đã được tách thành thư mục `security/` để dùng như một quality system độc lập. `THREAT_MODEL.md` mô tả tài sản, trust boundary, attacker và risk priority; `AUTH_SECURITY_ARCHITECTURE.md` mô tả cookie/bearer transport, token lifecycle, password/recovery, OAuth, RBAC, CSRF, WebSocket và payment; `AUTH_CURRENT_STATE_REVIEW.md` đối chiếu trực tiếp với codebase hiện tại.

`AUTH_STATE_MACHINES.md` biến account/session/reset/verification/step-up/payment thành transition có thể kiểm thử. `SECURITY_TEST_MATRIX.md` cung cấp negative, concurrency, abuse, WebSocket, payment, AI và upload test cases. `SECURE_CODING_RULES.md` là guardrail cho AI Agent/developer; `SECURITY_CONFIG.template.md` chuẩn hóa environment; `INCIDENT_RUNBOOK.md` chuẩn hóa revoke/rotate/contain/recover.

> **Security gate:** Không được đánh dấu feature Done nếu chưa trả lời tài sản nào thay đổi, auth/permission nào thay đổi, boundary nào thay đổi, negative tests nào đã chạy, secret nào đi qua và rollback thế nào. Không có production secret trong bất kỳ file workflow nào.
