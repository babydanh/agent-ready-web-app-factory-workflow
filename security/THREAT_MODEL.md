# Threat Model — Tournament Web App

> **Mục tiêu:** Xác định tài sản, trust boundary, attacker path và ưu tiên kiểm soát trước khi triển khai auth/security.
>
> **Phạm vi:** Web Next.js, NestJS API, mobile bearer clients, PostgreSQL/PostGIS, Redis/BullMQ, Socket.IO, payOS, Google/Apple identity, Cloudinary/S3 và AI provider.
>
> **Lưu ý:** Đây là threat model phòng thủ cho phát triển ứng dụng. Các mục “hiện trạng” là điểm quan sát từ codebase và cần remediation/test; không thay thế pentest hoặc security sign-off.

## 1. Tài sản cần bảo vệ

| Tài sản | Confidentiality | Integrity | Availability | Hậu quả nếu bị xâm phạm |
|---|---:|---:|---:|---|
| Credential/password/session | Cao | Cao | Trung bình | Account takeover, privacy breach |
| Role/ownership/admin permission | Cao | Rất cao | Cao | Sửa/xóa dữ liệu trái phép, privilege escalation |
| Payment/order/webhook | Cao | Rất cao | Cao | Ghi nhận thanh toán sai, thất thoát tiền |
| Tournament/bracket/match score | Trung bình | Rất cao | Cao | Sai kết quả, tranh chấp và mất niềm tin |
| Player PII/profile/bank data | Rất cao | Cao | Trung bình | Privacy/identity harm |
| API/app secrets/provider tokens | Rất cao | Rất cao | Cao | Chiếm hệ thống hoặc gọi API tốn phí |
| AI prompts/knowledge/output | Cao | Cao | Trung bình | Data leakage, prompt injection, unsafe action |
| Audit/log/telemetry | Trung bình | Cao | Trung bình | Mất khả năng điều tra và non-repudiation |

## 2. Trust boundaries

```text
Untrusted browser/mobile/user input
        │ HTTPS + auth + validation + rate limit
        ▼
NestJS API boundary
        │ guards + DTO + domain policy + transaction
        ├──────── PostgreSQL/PostGIS
        ├──────── Redis/BullMQ workers
        ├──────── Socket.IO gateway
        ├──────── payOS/Google/Apple/Cloudinary
        └──────── AI provider
```

Mọi boundary đều coi dữ liệu đến là untrusted. JWT payload, role trong token, `id` trên URL, Origin, return URL, webhook body, uploaded MIME, provider email, prompt và queue payload đều phải được kiểm tra tại boundary thích hợp.

## 3. Attacker profiles

| Actor | Khả năng | Mục tiêu thường gặp |
|---|---|---|
| Anonymous bot | Gửi request hàng loạt, thử credential, abuse reset/OTP | Chiếm tài khoản, spam, DoS |
| Authenticated player | Có account hợp lệ, sửa URL/body/headers | IDOR, gian lận registration/score, đọc PII |
| Malicious organizer | Có quyền quản lý một tournament | Leo thang quyền, thay score/bracket, gian lận payment |
| Compromised session | Có access/refresh token hoặc browser cookie | Impersonation, replay, sensitive action |
| Malicious origin | Website khác mở request/socket | CSRF/CSWSH, browser credential abuse |
| Compromised provider/webhook path | Payload giả, duplicate, out-of-order hoặc secret lộ | Ghi payment sai, trigger side effect |
| Prompt attacker | Nhập tài liệu/prompt chứa instruction độc | Data exfiltration, tool misuse |

## 4. Attack paths và controls

| Threat | Attack path | Control bắt buộc | Evidence |
|---|---|---|---|
| Credential stuffing | Login public + password reuse | Rate limit theo IP/account, generic error, monitoring, optional MFA | Auth abuse test, rate-limit log |
| Password compromise | DB dump hoặc log leak | Argon2id/bcrypt policy, unique salt, no plaintext, secret separation | Hash test, log scan |
| Refresh replay | Reuse refresh token sau rotate | Token hash at rest, atomic rotate, session revoke, reuse detection, bounded grace | Concurrent refresh test |
| CSRF | Cookie-auth mutation từ malicious origin | CSRF token/Origin check/SameSite/CORS allowlist | Cross-origin browser test |
| IDOR | Đổi `userId`, `tournamentId`, `paymentId` trên request | Server ownership/policy check, deny-by-default | Matrix role × resource |
| Role escalation | Tin roles từ stale JWT | Server role lookup/policy, short access TTL, revoke strategy | Role removal test |
| Session fixation/theft | Login/reset/device reuse | Rotate session after auth/reset, HttpOnly/Secure cookie, re-auth sensitive actions | Session lifecycle test |
| OAuth account linking | Match provider email không đủ proof | Verify issuer/aud/sub/nonce/state/PKCE, explicit link/confirm | OAuth negative tests |
| Webhook forgery | Fake or duplicate payment callback | HMAC verify, exact order/amount, idempotency, audit | Invalid/duplicate/out-of-order test |
| CSWSH | Malicious site opens socket with cookie | Origin allowlist, handshake auth, per-message authorization, session expiry close | Socket origin/message test |
| Injection | User input reaches SQL/HTML/command/AI | DTO/schema validation, parameterized query, output encoding, tool allowlist | Fuzz/negative tests |
| Upload abuse | Polyglot/oversized/private file | Size/type/magic scan, private access, filename isolation, malware scan | Upload matrix |
| Queue abuse | Replayed or crafted job | Authenticated enqueue boundary, schema, idempotency, retry/dead-letter | Worker tests |
| Secret leakage | Env/token in client/log/repo/image | Secret scanning, redaction, server-only env, rotation runbook | CI scan + log review |
| AI prompt injection | Document/user input overrides instruction | Structured prompt, input/output validation, least-privileged tools, HITL | Injection corpus test |

## 5. Risk ranking

`P0` là rủi ro có thể gây mất tiền, account takeover, admin takeover hoặc phá integrity cốt lõi. `P1` là rủi ro có thể làm lộ PII, tạo privilege escalation có điều kiện, hoặc gây outage đáng kể. `P2` là defense-in-depth và hardening sau khi critical path đã an toàn.

| Priority | Hiện trạng cần review trong codebase | Vì sao ưu tiên |
|---|---|---|
| P0 | Refresh token và OAuth provider token đang được persistence trực tiếp ở auth repository/schema; cần quyết định token-at-rest encryption/hash strategy và migration | DB read exposure có thể biến thành session/provider takeover |
| P0 | Roles nằm trong JWT nhưng RolesGuard có re-check active role; cần áp dụng cùng policy cho mọi resource ownership và stale claims | Role claim có thể stale; UI không phải security boundary |
| P0 | WebSocket guard hiện chấp nhận query token theo default và chỉ verify JWT; cần Origin allowlist, issuer/audience, message authorization và expiry close | Query token có rủi ro access-log/referrer leakage; socket sống lâu |
| P0 | Password reset/email verification lưu `code` trực tiếp và có flow token qua URL; cần hash token, single-use atomic consume, generic response và leakage review | DB/log/browser history compromise có thể dùng token |
| P1 | CSRF guard bỏ qua toàn bộ `development`; cần test-like-production mode và không để dev bypass lọt staging | Security regression bị che khi CI/staging |
| P1 | Rate limit guard chủ yếu in-memory và nới rất lớn ngoài production; cần shared store hoặc giới hạn staging/test theo policy | Multi-instance bypass và abuse dễ xảy ra |
| P1 | OAuth web callback redirect dùng cấu hình frontend; cần allowlist exact origin và state/nonce review | Open redirect/account-linking/session risks |
| P1 | Phone OTP implementation cũ dùng `Math.random()` và log OTP; route hiện khóa nhưng phải cấm hồi quy | Predictable OTP và secret log leakage |
| P1 | Forgot/reset flow có khác biệt message/TTL giữa code và email template; cần thống nhất contract, expiry và generic response | Account enumeration và token usability/security mismatch |
| P2 | App key là request admission layer, không thay JWT/authorization; cần document scope và rotation | Secret lộ không được coi là auth hoàn chỉnh |

## 6. Definition of secure enough

Trước production, không còn P0 mở. P1 phải được sửa hoặc có risk acceptance của owner. Mỗi exception phải ghi lý do, expiry date, compensating control và người chịu trách nhiệm. Security evidence phải gồm test result, log/monitoring, migration note, rollback và link commit; không ghi secret thật.
