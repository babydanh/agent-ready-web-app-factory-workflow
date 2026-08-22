# Web App Audit — Sporto / Quản lý giải đấu

**Ngày audit:** 2026-08-22  
**Phạm vi:** Backend NestJS, frontend Next.js, database schema, realtime, payment, AI integration, upload, Docker/Compose, deployment, dependency và automated tests.  
**Chế độ:** Read-only code audit kết hợp static inspection và các lệnh kiểm tra không sửa source.  
**Kết luận ngắn:** Hệ thống có nền tảng khá tốt về modular backend, validation pipe, transaction cho một số ledger transition, idempotency key và test backend. Tuy nhiên, **chưa nên xem là production-ready** cho đến khi xử lý các finding P0/P1 về SSRF, cấu hình production, upload abuse, dependency CVE, rate limiting, payment side effects, migration/rollback và test coverage.

> Báo cáo này là code/configuration audit, không phải penetration test. Một finding là rủi ro hoặc khoảng trống cần xác minh/remediate; không mặc định rằng hệ thống đã bị khai thác.

## 1. Executive summary

| Mức | Số nhóm chính | Ý nghĩa |
|---|---:|---|
| P0 — Block production | 2 | Có thể dẫn đến truy cập mạng nội bộ hoặc chạy production với secret/default và cổng hạ tầng bị phơi bày. |
| P1 — Remediate trước release đáng tin cậy | 13 | Có thể gây abuse, sai lệch giao dịch/domain, mất tính nhất quán, build/release sai hoặc thiếu khả năng phát hiện sự cố. |
| P2 — Cải thiện có kế hoạch | 5 | Rủi ro thấp hơn hoặc cần hardening/observability/maintenance để giảm residual risk. |

Hai điểm tích cực quan trọng là backend TypeScript noEmit **PASS**, frontend TypeScript noEmit **PASS**, frontend production build trong thư mục cô lập **PASS**, và backend unit test **42 test suites / 366 tests PASS** ở lần chạy audit. Tuy nhiên, build Next.js đã in rõ `Skipping validation of types`, vì `next.config.ts` đang đặt `typescript.ignoreBuildErrors: true`; do đó build pass không thay thế cho typecheck độc lập.

Dependency audit cho backend trả về **10 vulnerabilities: 1 low, 3 moderate, 6 high**, trong đó Multer hiện ở `2.1.1` và advisory yêu cầu bản vá từ `2.2.0`. Frontend trả về **31 vulnerabilities: 16 moderate, 15 high**, với `xlsx` là dependency trực tiếp và advisory hiển thị bản vulnerable `<0.19.3`, bản vá từ `0.19.3`. Cần tạo patch/upgrade plan và kiểm tra compatibility trước khi merge.

## 2. Evidence và phương pháp

Audit đã đọc code thực tế thay vì chỉ suy luận từ README. Các khu vực chính gồm:

| Khu vực | Evidence chính |
|---|---|
| Runtime/global policy | `HethongBackendApi_QuanlyGiaiDau/src/main.ts`, `src/app.module.ts`, `src/config/env.validation.ts`, `src/config/cors.config.ts` |
| Auth/rate limit | `src/common/guards/rate-limit.guard.ts`, `src/common/guards/user-aware-throttler.guard.ts`, auth pack trong `workflow/security/` |
| Payment/accounting | `src/modules/payments/payments.controller.ts`, `payments.service.ts`, `payments.repository.ts`, `src/database/schema/payments.schema.ts` |
| Tournament/match integrity | `src/database/schema/tournaments.schema.ts`, `tournament_divisions.schema.ts`, `matches.schema.ts`, `src/modules/tournaments/registration-lock.service.ts` |
| Realtime | `src/modules/chat/chat.gateway.ts`, `src/common/guards/ws-jwt.guard.ts` |
| AI | `src/modules/ai/ai.controller.ts`, `ai.service.ts`, `ai-tool.router.ts`, `ai-tool.registry.ts` |
| Upload | `src/modules/upload/upload.controller.ts`, `src/providers/storage/storage.service.ts` |
| Frontend | `HethongFrontEndWeb_QLgiaidau/package.json`, `next.config.ts`, `tsconfig.json`, `src/lib/axios.ts`, route/components trong `src/` |
| Delivery | `docker-compose.yml`, `deploy.sh`, backend/frontend Dockerfile |

Các lệnh đã chạy:

| Kiểm tra | Kết quả |
|---|---|
| Backend `pnpm exec tsc --noEmit --pretty false` | PASS |
| Frontend `pnpm exec tsc --noEmit --pretty false` | PASS |
| Frontend `pnpm build` với `NEXT_DIST_DIR=.next-audit` | PASS, nhưng Next.js skip type validation do config |
| Backend `pnpm test -- --runInBand --silent` | 42 suites, 366 tests PASS |
| Frontend `pnpm lint` | Không kết luận: tiến trình vượt 240 giây và được dừng; không dùng kết quả này để đánh dấu pass/fail |
| Backend `pnpm audit --prod --audit-level high` | 10 vulnerabilities, 6 high |
| Frontend `pnpm audit --prod --audit-level high` | 31 vulnerabilities, 15 high |
| Security harness read-only | Parse PASS; báo 12 advisory findings, exit 0 vì script hiện không block advisory |

## 3. P0 — Block production

### AUD-001 — Public URL parser có SSRF-like surface

**Severity:** P0  
**Evidence:** `HethongBackendApi_QuanlyGiaiDau/src/modules/ai/ai.controller.ts:101-116` để `POST /ai/parse-tournament-source` ở `@Public()`; `src/modules/ai/ai.service.ts:497-531` dùng `fetch(dto.sourceUrl.trim())` trực tiếp.

Endpoint công khai nhận URL từ người dùng và để backend tự fetch. Code hiện có timeout 10 giây nhưng chưa có allowlist scheme/host, kiểm tra IP private/link-local/loopback, chặn DNS rebinding, giới hạn `Content-Length`, giới hạn số byte đọc, chính sách redirect hoặc egress proxy. `response.text()` có thể đọc body lớn trong thời gian timeout. URL còn được đưa vào nội dung gửi cho model tại dòng 525.

Trong môi trường production, surface này có thể bị lạm dụng để yêu cầu server truy cập dịch vụ nội bộ, metadata endpoint, Redis/Postgres gateway hoặc host chỉ backend mới thấy. Đây là rủi ro cần block trước khi public feature.

**Remediation bắt buộc:** Chỉ cho phép `https`; allowlist domain nguồn hợp lệ nếu nghiệp vụ cho phép; resolve DNS và chặn mọi địa chỉ private/link-local/loopback/multicast; giới hạn redirect và body bytes; dùng egress proxy có policy; không gửi URL/HTML không tin cậy vào prompt mà không đánh dấu rõ dữ liệu; ghi audit event; rate limit theo account/IP và quota theo ngày. Nên tách parser ra worker/network zone hạn chế.

**Acceptance criteria:** Test được các URL `127.0.0.1`, RFC1918, IPv6 loopback, DNS rebinding, redirect sang private IP, file body lớn, non-HTTPS và redirect chain; tất cả bị từ chối. URL hợp lệ chỉ fetch trong allowlist và mọi lỗi trả message generic.

### AUD-002 — Compose có default secret, expose hạ tầng và có thể chạy sai mode production

**Severity:** P0  
**Evidence:** `docker-compose.yml:5-10,23-31,60-71`; `docker-compose.yml:127-135`; `env.validation.ts:5-19`.

Compose dùng fallback `DB_PASSWORD:-your_password`, `JWT_ACCESS_SECRET:-your-access-secret-key`, `JWT_REFRESH_SECRET:-your-refresh-secret-key`, đồng thời mặc định `NODE_ENV:-development`. Validation backend chỉ kiểm tra các secret là chuỗi bắt buộc, không biết fallback có phải secret thật hay không. Vì vậy một deployment thiếu `.env` có thể vẫn boot với secret mặc định và chính sách non-production.

Postgres publish `5432`, Redis publish `6379`, và MediaMTX publish RTMP/HLS/WebRTC/SRT ports. Nếu VPS firewall/security group không khóa, hạ tầng có thể bị truy cập từ Internet. `DB_SSL` bị đặt `false` trong Compose; trong cùng Docker network có thể có lý do vận hành, nhưng không được dùng mặc định cho môi trường có kết nối qua mạng không tin cậy.

**Remediation bắt buộc:** Xóa mọi fallback secret; production startup phải fail-closed nếu secret không đạt entropy/length; tách `compose.dev.yml` và `compose.prod.yml`; không publish DB/Redis ra host trừ khi có nhu cầu và firewall allowlist; bind internal services vào private network; pin image digest/tag immutable; dùng secret manager; đặt `NODE_ENV=production` trong prod profile; bật TLS phù hợp cho kết nối ngoài trusted network.

**Acceptance criteria:** Deployment thiếu bất kỳ secret production nào bị dừng trước khi tạo container; `docker compose config` production không chứa default secret; external port scan không thấy DB/Redis; production rate-limit profile được xác nhận bằng test.

## 4. P1 — Remediate trước release đáng tin cậy

### AUD-003 — Public upload không có authentication, quota hoặc ownership

**Severity:** P1  
**Evidence:** `src/modules/upload/upload.controller.ts:12-46` đánh dấu `@Public()`, nhận file tối đa 15 MB và upload vào Cloudinary; `src/providers/storage/storage.service.ts:26-44` stream buffer trực tiếp.

`FileTypeValidator` hiện dựa trên danh sách extension-like `.png|jpeg|jpg|webp|pdf|mp4|mov|webm`, nhưng endpoint có tên `image`, nhận cả PDF/video, không có authentication, account quota, per-IP quota, daily budget, ownership binding hoặc cleanup workflow. Kết quả trả `secure_url` và `publicId`, có thể tạo storage abuse, public content abuse và chi phí không kiểm soát. Extension/type validation không thay thế magic-byte/content inspection.

**Remediation:** Bảo vệ route bằng auth cho upload nghiệp vụ; nếu cần public upload thì cấp signed one-time upload token gắn với mục đích/resource; kiểm tra magic bytes và media metadata; giới hạn dimensions/duration/pages; rate limit theo IP/account; quota theo tenant; scan malware; lưu private mặc định và cấp signed delivery URL; có delete/orphan cleanup; không dùng một folder cố định cho mọi loại resource.

### AUD-004 — Dependency CVE cần xử lý trước release

**Severity:** P1  
**Evidence:** `pnpm audit --prod --audit-level high` trong backend báo Multer `2.1.1`, vulnerable range `>=1.0.0 <2.2.0`, patched `>=2.2.0`; frontend báo `xlsx` direct dependency vulnerable `<0.19.3`, patched `>=0.19.3`.

Backend audit báo tổng 10 vulnerabilities, gồm 6 high; frontend báo 31, gồm 15 high. Việc package có mặt không tự chứng minh exploitability trong mọi đường đi, nhưng upload dùng Multer và ứng dụng có thư viện xử lý XLSX nên phải xem đây là release blocker cho các đường đi nhận input không tin cậy.

**Remediation:** Upgrade qua lockfile, kiểm tra compatibility Nest/Express và import paths; nếu package chưa có bản tương thích, thay thế hoặc cô lập usage; chạy unit/API/E2E cho upload/import; rà advisory transitive còn lại; bật dependency review/renovate và policy fail khi high/critical không có risk acceptance.

### AUD-005 — Rate limit không đồng nhất và yếu ở staging/test

**Severity:** P1  
**Evidence:** `src/app.module.ts:68-75` cấu hình default `50,000 req/60s` cho mọi environment; `src/common/guards/rate-limit.guard.ts:14-18` đổi mọi limit non-production thành `100,000` nếu không `forceLimit`; guard lưu counter trong `Map` process-local tại dòng 10. `user-aware-throttler.guard.ts:11-16` skip WS và `/socket.io/`.

Các AI route dùng custom `RateLimitGuard`, còn global Nest throttler dùng policy khác. Custom guard không chia sẻ state giữa replica, có thể bị reset khi restart, và staging gần như không kiểm thử abuse thật. WebSocket bị skip global throttling. IP tracker còn phụ thuộc proxy trust và client ID.

**Remediation:** Dùng Redis-backed limiter có atomic increment/TTL; policy riêng cho login, recovery, AI, upload, payment, webhook và expensive queries; giữ limit gần production ở staging; không dùng 50,000 mặc định làm “chống 429”; giới hạn connection/message cho Socket.IO; cấu hình trusted proxy cụ thể; dashboard theo route/status/subject; test burst, distributed instances và NAT.

### AUD-006 — Registration slot release không idempotent, có thể làm phình số slot Redis

**Severity:** P1  
**Evidence:** `src/modules/tournaments/registration-lock.service.ts:37-63,68-87`; `src/modules/payments/payments.service.ts:252-266`.

Reservation dùng `DECR` aggregate key và tạo `registration:holder:*:${Date.now()`, nhưng holder key không được liên kết với payment/participant và không được đọc lại để bảo đảm ownership. `releaseSlot` chỉ `INCR` aggregate key. Trong nhánh webhook invalid, service gọi `transitionPayment(... PENDING -> CANCELLED ...)` rồi vẫn gọi `releaseSlot` mà không kiểm tra `result.transitioned`. Webhook lặp lại sau khi payment đã CANCELLED có thể tiếp tục increment Redis counter, làm số slot tạm thời lớn hơn số slot thật.

**Remediation:** Gắn hold key với payment ID và trạng thái; release bằng Lua script/check-and-delete một lần; chỉ release nếu state transition thành công; xử lý expiry bằng worker đối soát DB; không dùng `Date.now()` làm identity duy nhất; test duplicate webhook, retry sau timeout, concurrent create-link và process restart.

### AUD-007 — Post-payment side effects bị nuốt lỗi sau khi webhook đã được coi là thành công

**Severity:** P1  
**Evidence:** `payments.service.ts:286-291,594-635`.

Payment transition, receipt finalization và side effects chạy theo chuỗi. `afterPaymentCompleted` bắt lỗi rồi chỉ `console.error` tại dòng 634, trong khi `handleWebhook` vẫn có thể trả completed. Điều này tạo trạng thái payment/ledger đã hoàn tất nhưng tournament status hoặc notification chưa cập nhật. Log console không có correlation ID, retry state, alert hoặc durable outbox.

**Remediation:** Tách domain transition và outbox event trong cùng DB transaction; worker idempotent xử lý notification/status; trạng thái side effect `PENDING/PROCESSING/SUCCEEDED/FAILED`; exponential backoff + dead-letter; metric/alert; webhook response chỉ phản ánh việc evidence đã được ghi nhận, không giả vờ mọi side effect đã hoàn tất.

### AUD-008 — Payment intent và receipt được ghi ở hai operation không atomic

**Severity:** P1  
**Evidence:** `payments.repository.ts:141-170` insert payment trước rồi insert receipt; `payments.service.ts:139-163` tạo intent, attach PayOS link bằng operation riêng.

Nếu insert `paymentReceipts` lỗi, hệ thống giữ payment PENDING nhưng không có receipt. Nếu attach provider order code lỗi hoặc process chết giữa các bước, có payment orphan/khó reconcile. Unique idempotency constraints giúp giảm duplicate nhưng không thay thế transaction hoặc reconciliation.

**Remediation:** Tạo payment intent và pending receipt trong một transaction; attach provider reference theo state machine rõ ràng; có reconciliation job cho PENDING không có provider link; record outbox/retry; expose admin view cho orphan payments; không cho client tự quyết amount/provider reference.

### AUD-009 — Domain schema chưa khóa đủ cross-entity integrity

**Severity:** P1  
**Evidence:** `tournaments.schema.ts:164-206`, `tournaments.schema.ts:208-249`, `matches.schema.ts:44-130`, `tournament_divisions.schema.ts:16-48`.

Một số cột trạng thái là `varchar` không có enum/check constraint. `tournamentParticipants.tournamentDivisionId` có FK tới division nhưng database chưa bảo đảm division thuộc đúng tournament. `groupStandings` chưa có constraint bảo đảm participant thuộc group/tournament. `matches` có `tournamentId`, `stageId`, `groupId`, participant IDs nhưng database chưa khóa các entity này cùng tournament. `matchPlayers` chưa có unique `(matchId, participantId, userId)`. `tournamentStaff` và `tournamentReferees` chưa có unique membership constraint. `tournamentDivisions` thiếu check fee/ELO/date/max participant.

Các invariant hiện dựa nhiều vào service. Đây là điểm nguy hiểm khi có seed, admin route, worker, repair script hoặc migration khác ghi DB.

**Remediation:** Bổ sung composite FK hoặc trigger/service transaction để enforce cùng tenant/tournament; unique membership/indexes; enum/check cho status, direction, fee, ELO, dates; verify migration thực tế đã áp dụng; viết invariant tests và DB-level tests. Mọi constraint mới cần migration backward-compatible và rollback note.

### AUD-010 — Next.js build đang bỏ qua TypeScript errors

**Severity:** P1  
**Evidence:** `HethongFrontEndWeb_QLgiaidau/next.config.ts:11-13` đặt `typescript.ignoreBuildErrors: true`; build output ghi `Skipping validation of types`.

`tsconfig.json` có `strict: true`, và lệnh `tsc --noEmit` đã pass trong audit, nhưng pipeline production hiện cho phép build pass ngay cả khi type errors xuất hiện. Đây là policy nguy hiểm vì một developer có thể chỉ chạy build và bỏ qua compile-time regression.

**Remediation:** Xóa `ignoreBuildErrors`; để `pnpm build` là gate typecheck mặc định; nếu cần isolated verification, giữ `tsc --noEmit` riêng nhưng không dùng nó để biện minh cho build bypass; pin toolchain và kiểm tra generated tsconfig changes.

### AUD-011 — Frontend chưa có test script/E2E gate

**Severity:** P1  
**Evidence:** `HethongFrontEndWeb_QLgiaidau/package.json:6-11` chỉ có `dev`, `build`, `start`, `lint`, `i18n:check`; không có `test`, `test:e2e`, Playwright/Vitest/Jest dependency. Backend có test script và lần audit chạy pass 366 tests.

Các luồng rủi ro cao như login/refresh, payment result, register/join team, organizer operations, live score, chat reconnect, upload và mobile/desktop responsive không có frontend E2E gate được khai báo trong package. Báo cáo cũ đã nêu một số kịch bản cần browser manual test; các kịch bản đó nên được chuyển thành automation có fixture/isolation.

**Remediation:** Thêm Playwright với project desktop/mobile; fixture backend seed/reset; test auth renewal, 403/409, payment return/cancel, duplicate-click, live score sequencing, reconnect/resync, chat SSE, upload failure và i18n. CI cần artifact trace/video/screenshot khi fail; không đánh dấu pass nếu test runner không khởi động.

### AUD-012 — Deploy script nuốt lỗi migration và không có rollback đáng tin cậy

**Severity:** P1  
**Evidence:** `deploy.sh:36-50,53-63`; `docker-compose.yml:34-59,104-111`.

`deploy.sh:56` chạy migration rồi dùng `|| echo` để tiếp tục dù migration có thể thất bại. Script dùng mutable `:latest`, `git pull origin main`, build trực tiếp trên VPS, recreate backend/frontend và prune images. Không có pin commit/image digest, health verification sau deploy, smoke test, release record hoặc rollback image/schema.

Compose mount migration từ path `./backend-api_qlgiaidau/...` trong khi workspace hiện tại có thư mục `HethongBackendApi_QuanlyGiaiDau`; điều này cần được xác minh trên deployment host, không giả định path local giống host.

**Remediation:** Migration fail phải block release; dùng artifact immutable có commit SHA/digest; migration expand/contract; backup/restore check; deploy canary/blue-green hoặc health-gated restart; smoke test API/frontend; giữ previous image; rollback procedure đã thử; không prune image đang là rollback candidate.

### AUD-013 — Không có health/readiness/metrics/tracing đủ cho production

**Severity:** P1  
**Evidence:** `src/app.controller.ts:4-12` chỉ có `GET /` trả hello; `docker-compose.yml` chỉ có healthcheck cho Postgres/Redis tại lines 14-32, không có backend/frontend healthcheck; code search không tìm thấy readiness/liveness/metrics/OpenTelemetry integration tương ứng.

Backend có `Logger` ở một số nơi nhưng cũng có `console.error`/`console.log`, ví dụ payment side effect và registration lock. Không có endpoint readiness kiểm tra DB/Redis/queue, không có correlation/request ID chuẩn, metrics cho webhook/queue/slot/payment, trace hoặc alert policy. Container có thể “running” nhưng app chưa ready.

**Remediation:** Tạo `/health/live` và `/health/ready` không lộ secret; readiness kiểm tra DB/Redis/critical dependencies với timeout; Docker/ingress gọi readiness; structured JSON logs có request ID; metrics latency/error/rate-limit/payment/webhook/queue; traces cho request-to-worker; alert và runbook. OpenTelemetry phù hợp để chuẩn hóa traces/metrics/log correlation.[10]

### AUD-014 — AI endpoint công khai, resource budget và lỗi upstream chưa đủ chặt

**Severity:** P1  
**Evidence:** `src/modules/ai/ai.controller.ts:28-116` để chat và parser ở `@Public()` với optional JWT; `src/modules/ai/ai.service.ts:320-379,381-455,609-699`; `src/common/guards/rate-limit.guard.ts:14-18`.

Tool registry hiện là read-only, có schema args và pagination cap — đây là điểm tốt. Tuy nhiên public AI endpoint vẫn tiêu thụ model budget; custom rate limit non-production là 100,000; parser có SSRF được ghi ở AUD-001; AI response nối `error.message` vào `InternalServerErrorException` tại lines 397-400, 452-454 và 696-699, có thể lộ provider/internal details.

**Remediation:** Tách quota anonymous/authenticated/role; giới hạn token/input/output, concurrency và daily spend; circuit breaker; không trả nguyên `error.message`; redact logs; tool capability phải role/resource-scoped nếu sau này thêm write tool; validate model output bằng schema runtime trước khi trả về; cache hợp lý nhưng không cache dữ liệu cá nhân giữa viewer.

### AUD-015 — CORS wildcard subdomain và `trust proxy` cần threat model rõ

**Severity:** P1  
**Evidence:** `src/config/cors.config.ts:10-43`, `src/main.ts:15-19`.

CORS cho credentialed requests và chấp nhận regex `*.sporto.asia`; `main.ts` đặt `trust proxy=true` cho mọi proxy hop. Nếu một subdomain không cùng mức tin cậy bị takeover, credentialed browser requests có thể mở rộng trust boundary. Nếu app bị expose trực tiếp hoặc proxy chain không được kiểm soát, forwarded IP có thể ảnh hưởng rate-limit/audit.

**Remediation:** Allowlist origin cụ thể theo environment, không wildcard nếu không cần; kiểm kê subdomain ownership/takeover; cookie policy và CSRF test theo origin; cấu hình trusted proxy count/IP thay vì `true`; chỉ tin `X-Forwarded-For` từ ingress đã biết; test direct-to-app và spoofed headers.

## 5. P2 — Cải thiện có kế hoạch

### AUD-016 — Chat presence là in-memory, không nhất quán multi-instance

**Severity:** P2  
**Evidence:** `src/modules/chat/chat.gateway.ts:34-80` dùng static `Map<string, Set<string>>` và `server.emit('chat:user:status')`.

Presence chỉ đúng trong một process. Khi scale backend hoặc restart, user status giữa các instance khác nhau; `checkOnlineUsers` trả kết quả local. Có thể chấp nhận cho single-instance demo nhưng không nên coi là source of truth production.

**Remediation:** Dùng Redis presence với TTL/heartbeat, Socket.IO adapter, instance-aware broadcast và last-seen semantics; test disconnect/reconnect/multiple tabs.

### AUD-017 — Socket connection chưa bị chặn sớm khi anonymous

**Severity:** P2  
**Evidence:** `chat.gateway.ts:45-63` bỏ qua lỗi token trong `handleConnection`; route join/message vẫn kiểm quyền tại handler.

Thiết kế này cho phép socket chưa xác thực tồn tại trước khi join. Các handler nhạy cảm có guard logic, đây là điểm giảm rủi ro, nhưng connection exhaustion và event spam vẫn cần budget. Cần xác định rõ anonymous socket có mục đích product hay không.

**Remediation:** Reject unauthorized connection nếu không có use case guest; nếu cần guest, giới hạn events/connection lifetime và message size; rate-limit handshake/IP; disconnect khi token hết hạn/revoked.

### AUD-018 — Trạng thái domain dùng string tự do quá nhiều

**Severity:** P2  
**Evidence:** `tournaments.schema.ts:60-97`, `matches.schema.ts:63-104`, `payments.schema.ts:33-47`, `tournament_divisions.schema.ts:23-43`.

String status giúp thay đổi nhanh nhưng cho phép typo và trạng thái không hợp lệ từ script/admin/worker. Service state machine có kiểm tra một phần, nhưng database chưa đồng nhất hóa.

**Remediation:** Dùng TypeScript union/constant registry + database check/enum cho trạng thái ổn định; state transition table; contract test giữa API/UI/worker.

### AUD-019 — Logging chưa chuẩn hóa và có nguy cơ lộ dữ liệu nghiệp vụ

**Severity:** P2  
**Evidence:** `registration-lock.service.ts:62,75,87`, `payments.service.ts:634`, `ai.service.ts:280-281,398-399,453-454,697-698`.

Console logs không có structured fields, request ID, actor ID đã hash hoặc event category. Một số lỗi nối message upstream. Audit/payment evidence cần phân biệt log operational, audit trail và provider payload; không được ghi secret/token/PII không cần thiết.

**Remediation:** Logger facade có redaction; event schema; retention/access policy; audit log bất biến cho admin/payment/security actions; alert trên anomaly thay vì chỉ in console.

### AUD-020 — `xlsx`/raw import và public data paths cần kiểm tra semantic validation

**Severity:** P2  
**Evidence:** frontend package có `xlsx`; dependency audit chỉ cho biết package vulnerable, chưa kết luận usage path. Cần inventory nơi đọc workbook, CSV, EditorJS content và external URLs.

**Remediation:** Tách parsing worker/sandbox; giới hạn file size/rows/formulas; sanitize formula/HTML; không đưa file content thẳng vào DOM; test zip bomb/prototype pollution/large sheet; pin safe version hoặc thay parser.

## 6. Điểm đã làm tốt cần giữ lại

Backend đã có `ValidationPipe` toàn cục với `whitelist`, `transform` và `forbidNonWhitelisted` tại `main.ts:24-31`. Global guard chain gồm AppKey, throttler, JWT, ban, roles, verified và CSRF tại `app.module.ts:102-131`; cần tiếp tục kiểm test thứ tự guard thay vì tháo bỏ.

Payment repository đã có transaction cho `transitionPayment`, `createPayoutRequest` và legacy refund; ledger có unique `idempotencyKey`; webhook event có unique `eventKey`; schema có check amount positive và direction valid tại `payments.schema.ts:209-233`. Đây là nền tảng tốt để mở rộng outbox/reconciliation.

AI tool registry giới hạn tool read-only, `requiresAuth`, unknown keys và pagination tại `ai-tool.registry.ts`; cần giữ nguyên nguyên tắc deny-by-default khi thêm tool mới. Frontend Axios có refresh queue, CSRF header, GET dedupe và retry có kiểm soát; cần bổ sung test race/error thay vì nới retry.

## 7. Remediation roadmap

| Wave | Mục tiêu | Findings | Definition of done |
|---|---|---|---|
| Wave 0 — trước public production | Đóng đường nguy hiểm và cấu hình fail-closed | AUD-001, AUD-002, AUD-003, AUD-004 | SSRF tests pass; production env không có default; hạ tầng không expose; upload có auth/quota; high CVE được patch hoặc risk-accepted có bằng chứng |
| Wave 1 — business integrity | Bảo vệ tiền, slot và state | AUD-006, AUD-007, AUD-008, AUD-009 | Duplicate webhook/slot tests pass; payment/receipt atomic; outbox retry; cross-entity invariants enforce ở DB/service |
| Wave 2 — release quality | Không để pipeline báo pass giả | AUD-010, AUD-011, AUD-012 | Build không ignore type errors; frontend E2E chạy CI; migration failure block; artifact immutable; rollback smoke-tested |
| Wave 3 — operations | Phát hiện và phản ứng sự cố | AUD-005, AUD-013, AUD-015, AUD-019 | Redis limiter, readiness, metrics, trace/request ID, alert/runbook, trusted proxy/CORS matrix |
| Wave 4 — scale/hardening | Realtime/AI/domain maintainability | AUD-014, AUD-016, AUD-017, AUD-018, AUD-020 | AI quota/schema/egress policy, Redis presence, socket budget, status constraints, import sandbox |

## 8. Bộ test tối thiểu cần thêm

| Nhóm | Kịch bản bắt buộc |
|---|---|
| SSRF | localhost, RFC1918, IPv6 loopback, DNS rebinding, redirect private, non-HTTPS, oversized body, timeout |
| Upload | anonymous request, quota exhaustion, wrong magic bytes, polyglot, oversized image/video/PDF, orphan cleanup, signed URL expiry |
| Payment | duplicate webhook, out-of-order webhook, amount mismatch, PENDING orphan, provider timeout, failed notification retry, duplicate slot release, concurrent payout |
| Authorization | IDOR giữa user/organizer/admin, cross-tournament division/participant/stage, revoked session, banned user, role downgrade |
| Realtime | invalid handshake, token expiry, join unauthorized room, message flood, multiple tabs, two instances, reconnect/resync, room cleanup |
| Frontend | refresh queue, 401 loop, 429 retry, stale snapshot, payment return/cancel, double-click mutation, live score flush, chat stream disconnect |
| Deployment | missing production env, migration failure, readiness false, old image rollback, DB/Redis unreachable, startup ordering |
| Dependency | high/critical policy, lockfile reproducibility, upload/import regression sau upgrade Multer/xlsx |

## 9. Release recommendation

**Recommendation hiện tại: NEEDS_REVIEW / không duyệt production release nếu chưa xử lý AUD-001 và AUD-002.** Backend unit tests và TypeScript checks đang tốt, nhưng không đủ bù cho SSRF-like URL fetch, default secret/config trong Compose, public upload surface, dependency high findings và release script có thể nuốt migration failure.

Sau Wave 0, cần chạy lại dependency audit, security harness, backend tests, frontend typecheck/build/lint, frontend E2E, migration dry-run, readiness smoke test và external port review. Chỉ chuyển sang `PASS` khi có evidence lưu trong release record, không chỉ dựa vào việc container khởi động hoặc build thành công.

## References

[1]: [OWASP Server-Side Request Forgery Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Server_Side_Request_Forgery_Prevention_Cheat_Sheet.html)  
[2]: [OWASP File Upload Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html)  
[3]: [OWASP REST Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/REST_Security_Cheat_Sheet.html)  
[4]: [OWASP Authorization Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html)  
[5]: [OWASP WebSocket Security Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/WebSocket_Security_Cheat_Sheet.html)  
[6]: [PostgreSQL Transaction Isolation](https://www.postgresql.org/docs/current/transaction-iso.html)  
[7]: [Docker Compose Startup Order](https://docs.docker.com/compose/how-tos/startup-order/)  
[8]: [Playwright Best Practices](https://playwright.dev/docs/best-practices)  
[9]: [GitHub Actions Documentation](https://docs.github.com/en/actions/get-started/understand-github-actions)  
[10]: [OpenTelemetry — What is OpenTelemetry?](https://opentelemetry.io/docs/what-is-opentelemetry/)  
[11]: [OWASP Authentication Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html)  
[12]: [OWASP Session Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html)
