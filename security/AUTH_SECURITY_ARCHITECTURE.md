# Authentication & Authorization Architecture

> **Mục tiêu:** Định nghĩa auth/security contract có thể triển khai và kiểm thử cho web app quản lý giải đấu.
>
> **Baseline hiện tại:** Web login/refresh dùng HttpOnly cookie; mobile login trả bearer tokens; frontend dùng Axios `withCredentials`, CSRF header và refresh queue; backend dùng NestJS Passport/JWT, `RolesGuard`, `VerifiedGuard`, `RateLimitGuard`, Socket.IO JWT guard, Google/Apple identity và payOS webhook.
>
> **Nguyên tắc:** Authentication chứng minh “ai”; authorization quyết định “được làm gì trên resource nào trong trạng thái nào”. Frontend guard chỉ là UX. Backend policy, database constraint và audit mới là security boundary.

## 1. Security objectives

| Objective | Requirement |
|---|---|
| Account confidentiality | Không lộ password, token, provider secret, reset token hoặc PII nhạy cảm |
| Session integrity | Token khó đoán, ngắn hạn phù hợp, rotation/revocation và reuse detection |
| Authorization integrity | Deny-by-default, least privilege, role + ownership + state policy ở server |
| Request integrity | HTTPS, validation, CSRF/Origin/CORS đúng với auth transport |
| Recovery safety | Reset/verification single-use, hashed at rest, generic response, audit |
| Operational control | Rate limit, monitoring, incident revoke/rotate và test-like-production |

## 2. Auth transport decision

### 2.1 Web browser

Web browser nên dùng HttpOnly, Secure cookie cho access/refresh token nếu frontend và API có cùng site/trust model. JavaScript không đọc được token; frontend chỉ giữ user/profile state. Vì cookie tự được gửi, mọi state-changing request phải có CSRF strategy và Origin/CORS policy.

```text
Browser
  ├── accessToken: HttpOnly + Secure + SameSite policy + short TTL
  ├── refreshToken: HttpOnly + Secure + SameSite policy + rotation
  └── csrf-token: readable cookie, only if double-submit design is retained
```

`SameSite=Lax/Strict` là defense-in-depth. Không dùng `SameSite` để thay toàn bộ CSRF/Origin control khi threat model có cross-site navigation hoặc cookie configuration phức tạp.

### 2.2 Mobile/API client

Mobile app không nên nhận refresh token qua URL hoặc lưu trong plaintext storage. Trả token trong JSON chỉ là transport; client phải dùng OS secure storage/keystore/keychain. API request dùng `Authorization: Bearer <access-token>` hoặc contract riêng đã được review. Refresh token nên là opaque rotating secret hoặc JWT được bind/revocable bởi session record.

### 2.3 Không trộn hai policy

Cookie web và bearer mobile có threat model khác nhau. CSRF guard có thể bỏ qua Bearer request vì browser không tự gắn Authorization header như cookie, nhưng bearer flow vẫn cần HTTPS, expiry, revocation, rate limit, audience/issuer validation và chống token theft.

## 3. Recommended token model

### Access token

Access token là JWT ngắn hạn, chứa tối thiểu `sub`, `jti`, `iat`, `exp`, `iss`, `aud` và claims tối thiểu cần cho request. Không đưa PII dư thừa, financial data hoặc permission động quá chi tiết vào token. Nếu quyền thay đổi thường xuyên, server phải re-check policy/role hoặc dùng version/revocation signal.

Access token phải verify signature, algorithm allowlist, issuer, audience, expiry và clock skew policy. `jti` hữu ích cho audit/revocation khi cần nhưng không tự biến token thành revocable nếu server không kiểm tra state.

### Refresh token

Khuyến nghị cho project production là **opaque random refresh token + hash at rest**. Database lưu `tokenHash`, không lưu token raw. Session record có `userId`, `tokenHash`, `deviceId`/client type, created/last-used/rotated/revoked/expires timestamps, optional user-agent/IP đã privacy-review và `reuseDetectedAt`.

Nếu tạm tiếp tục JWT refresh, vẫn phải lưu fingerprint/hash của token để đối chiếu với session; không lưu raw JWT. Mỗi refresh hợp lệ phải atomically revoke session token cũ và tạo token mới. Nếu token cũ được dùng lại ngoài grace policy, revoke toàn bộ token family/session family và yêu cầu login lại.

| Token | TTL policy | Storage | Revocation |
|---|---|---|---|
| Access | Ngắn, ví dụ 10–15 phút theo risk | HttpOnly cookie web; secure storage mobile | Expiry, optional denylist/version |
| Refresh | Dài hơn, ví dụ 7 ngày theo risk | Hash trong DB; raw chỉ ở client | Rotation, family revoke, logout, reset password |
| Reset | Một lần, ngắn theo risk | Hash trong DB | Atomic consume + expiry |
| Email verify | Một lần, đủ thời gian người dùng mở mail | Hash trong DB | Atomic consume + expiry |
| CSRF | Theo session/cookie lifecycle | Non-HttpOnly token cookie nếu double-submit | Regenerate on login/refresh/session change |

Thời hạn trên là ví dụ cần chốt bằng risk/UX; không copy máy móc vào production.

## 4. Request lifecycle

```text
Request
  → TLS / proxy trust configuration
  → request ID + safe structured logging
  → CORS / Origin policy
  → app-key admission if applicable
  → rate limit / abuse control
  → authentication guard
  → session/token checks
  → authorization: role + ownership + state
  → DTO/schema validation and normalization
  → use case / transaction
  → audit event
  → response/error mapping
```

Thứ tự có thể thay đổi theo framework, nhưng không được bỏ qua policy. Rate limit cho authentication/recovery có thể cần chạy trước authentication. Error response phải ổn định, không cho attacker biết email tồn tại, role nội bộ, SQL detail hoặc provider verification reason.

## 5. Endpoint contract cho auth

| Endpoint | Public | Auth transport | Rate limit | CSRF | Ghi chú |
|---|---:|---|---:|---:|---|
| `POST /auth/register` | Có | None | IP + normalized email | Không nếu không có cookie auth | Generic duplicate policy, password hash |
| `POST /auth/login` | Có | None | IP + account/email | Không nếu no auth cookie mutation | Generic credential error, session create |
| `POST /auth/refresh` | Có về route | Web cookie hoặc mobile refresh header | Session/IP | Cookie path cần CSRF/Origin policy | Atomic rotation, no query token |
| `POST /auth/logout` | Có thể idempotent | Cookie/session | Nhẹ | CSRF nếu cookie mutation | Revoke current session, clear exact cookie |
| `POST /auth/logout-all` | Không | Access auth | User | Có nếu cookie auth | Re-auth cho risk cao, revoke all |
| `POST /auth/forgot-password` | Có | None | IP + email | Không | Luôn generic response |
| `POST /auth/reset-password` | Có | Reset token | IP + token | Token-bound | Hash token, atomic consume, revoke sessions |
| `POST /auth/verify-email/request` | Không | Access auth | User | Có | Cooldown, queue, no token log |
| `POST /auth/verify-email/confirm` | Có | Verification token | IP + token | Token-bound | Hash token, atomic consume |
| `GET /auth/google` | Có | OAuth browser | IP/session | OAuth state | Exact redirect allowlist |
| `GET /auth/google/callback` | Có | OAuth state/code | IP/session | OAuth state | Validate state/code/issuer/aud |
| `POST /auth/mobile/google` | Có | Provider ID token | IP/device | Không cookie-based | Verify signature, aud, iss, nonce if used |
| `POST /auth/mobile/apple` | Có | Provider ID token | IP/device | Không cookie-based | Verify signature, iss, aud, nonce |

“Public” chỉ có nghĩa route không yêu cầu application JWT trước khi vào; nó không có nghĩa bỏ validation, rate limit, abuse control hay audit.

## 6. Register/login hardening

### Register

Normalize email theo một policy nhất quán; không tự ý biến đổi phần local-part ngoài policy đã chốt. Enforce length/format, accepted ToS timestamp và password policy ở backend. Hash bằng password-hashing algorithm/work factor được chốt; không dùng encryption reversible. Tạo user/profile/role bằng transaction. Role mặc định phải đến từ seed/config an toàn, không cho request chọn `ADMIN`.

Response register không trả password hash, raw token hoặc internal role assignment detail. Nếu auto-login sau register, phải tạo session theo flow login và gửi verification status rõ ràng.

### Login

Sai username/email/password nên trả thông báo generic và thời gian xử lý không tạo enumeration dễ dàng. Check password hash rồi mới check account policy theo thứ tự đã review. Kiểm tra soft-deleted, banned/sanctioned, verified requirement và account state. Tạo session mới với token family và audit event `login_success`/`login_failure` không chứa secret.

Login sensitive như admin panel, bank payout, payment detail hoặc device enrollment nên có re-auth/MFA theo risk.

## 7. Password policy

OWASP khuyến nghị password được bảo vệ bằng hash chậm/memory-hard như Argon2id, bcrypt hoặc PBKDF2, mỗi password có salt riêng; pepper nếu dùng phải nằm ngoài database. Project hiện dùng bcrypt cost 12; phải benchmark trên production-like hardware, ghi policy và có rehash upgrade path.

| Rule | Policy |
|---|---|
| Storage | Hash only; không plaintext/encryption reversible |
| Salt | Do thư viện tạo, unique per password |
| Cost | Benchmark và re-evaluate; không đoán theo máy dev |
| Input | Cho phép Unicode/space theo policy; giới hạn length chống DoS |
| Error | Không nói email/password nào sai chi tiết quá mức |
| Change | Re-auth current credential cho đổi password |
| Reset | Single-use token, revoke sessions, notify user |
| Compromise | Có process force reset/revoke all và incident response |

## 8. Refresh rotation và replay handling

```text
Client sends refresh R1
  → find session by hash(R1)
  → verify token/signature/expiry and session active
  → atomic compare-and-revoke R1
  → create R2 + store hash(R2)
  → return R2 in HttpOnly cookie/secure mobile response

If R1 is presented again
  → distinguish tightly bounded concurrent request only if explicitly designed
  → otherwise mark token family compromised
  → revoke family/all user sessions according to risk
  → audit and notify/re-auth
```

Grace period phải ngắn, được chứng minh bằng concurrent test và không biến token reuse thành quyền lấy token mới. Không truy vấn và revoke bằng raw token nếu schema đã chuyển sang hash. Logout phải revoke current session; logout-all và password reset revoke toàn bộ phù hợp.

## 9. Password reset và email verification

Flow an toàn:

```text
Request
  → normalize identifier
  → always return generic response
  → rate limit/cooldown
  → generate cryptographically random token
  → store only hash + type + user + expiry + usedAt
  → enqueue email
  → consume atomically: hash lookup + unused + unexpired
  → mark used in same transaction as state change
  → revoke sessions if password changed
  → audit and notify
```

Không đặt raw token vào logs, analytics, referrer, screenshot hoặc database plaintext. Link query token có thể xuất hiện trong browser history/logs; dùng HTTPS, short TTL, one-time consume, `Referrer-Policy: no-referrer`, landing-page cleanup và không tải third-party resource trên token page. Email template và code phải có cùng TTL; hiện trạng codebase có dấu hiệu comment/message TTL không thống nhất, cần sửa thành một canonical config.

Forgot-password response không được phân biệt email chưa đăng ký với email đã đăng ký. Email OAuth-only cũng nên trả cùng generic response hoặc một recovery path không tiết lộ account type.

## 10. OAuth/OIDC

### Web redirect flow

```text
Start
  → generate state + nonce + PKCE verifier
  → persist short-lived transaction bound to browser/session
  → redirect to exact provider authorization URL
  → callback validates state, code, issuer, audience, nonce and PKCE
  → fetch verified identity
  → explicit account-link policy
  → create/reuse local user and session
  → rotate/clear OAuth transaction
  → redirect only to exact configured frontend origin/path
```

Không dùng email string đơn độc làm bằng chứng link account nếu provider identity (`iss`, `sub`) chưa được verify. Không cho client chọn provider user ID. Với mobile, verify ID token bằng public keys/discovery chính thức, algorithm allowlist, issuer/audience/nonce policy và clock skew. Không log ID token.

### Admin assignment

Không tự động cấp admin chỉ vì email nằm trong environment list mà không có policy review, audit và secret/config protection. Nếu cần bootstrap admin, dùng one-time controlled process, allowlist đã review và không cấp thêm role ngầm ngoài yêu cầu.

## 11. RBAC + ownership + state policy

Mỗi mutation phải trả lời ba câu hỏi:

1. User có authenticated không?
2. User có permission/role cho action không?
3. User có quyền trên **resource cụ thể**, trong **trạng thái hiện tại** và với **tenant/community/tournament** cụ thể không?

```text
can(user, action, resource, context) =
  authenticated
  AND roleAllows(user.role, action)
  AND ownsOrBelongs(user, resource)
  AND stateAllows(resource.state, action)
  AND notBanned(user, context)
```

`RolesGuard` có re-check active role là tốt hơn chỉ tin JWT claim, nhưng cần policy tương tự cho ownership và tất cả domain mutation. Role change phải invalidate/reduce stale token risk. Admin bypass phải explicit, audited và không ẩn trong `if isMock`/test path.

## 12. CSRF/CORS/Origin

Project hiện dùng double-submit `csrf-token` cookie + `X-CSRF-Token` header cho cookie-auth mutation. Nếu giữ pattern này:

- Generate token bằng CSPRNG; bind lifecycle với login/session policy.
- Compare server-side bằng constant-time compare nếu implementation phù hợp.
- Check `Origin`/`Referer` policy cho sensitive cross-origin cases.
- Allow exact frontend origins per environment; không dùng `*` khi credentials.
- Không bảo vệ GET bằng cách cho GET mutation; mọi state change dùng POST/PUT/PATCH/DELETE.
- Không tắt CSRF toàn bộ ở staging/test; dùng test-like-production flag hoặc explicit test fixture.
- Verify `logout` và refresh cookie path; xoá cookie phải trùng domain/path/options đã set.

Bearer/mobile requests không cần browser CSRF token nhưng vẫn cần HTTPS, auth, rate limit và origin/app policy phù hợp. App key chỉ là admission control, không thay authorization.

## 13. WebSocket auth

Handshake phải validate exact Origin allowlist, token signature/issuer/audience/expiry và account ban/session state. Sau handshake, mỗi message cần schema validation và authorization cho room/resource; không coi authenticated socket là được làm mọi action.

Token query string nên bị tắt mặc định vì có thể vào access logs/referrer. Nếu còn backward compatibility, đặt `allowQueryToken=false` trong production và deprecate client cũ. Khi session expire/logout/password reset/ban, đóng connection; listener/client room phải cleanup. Message quan trọng có nonce/version/idempotency và server persist-first.

## 14. Current codebase hardening backlog

| Priority | Finding | Remediation |
|---|---|---|
| P0 | `sessions.refreshToken` lưu raw token trực tiếp | Thêm `tokenHash`, migrate/rotate sessions, hash lookup, revoke family |
| P0 | `authProviders.accessToken/refreshToken` lưu raw provider token | Không lưu nếu không cần; nếu cần encrypt at rest, key ngoài DB, access audit và rotation |
| P0 | `otp_codes.code` lưu raw reset/verification/OTP code | Lưu hash, atomic consume, `usedAt`, attempts/expiry/index |
| P0 | WS guard cho phép query token theo default và không thấy issuer/audience trong verify | Tắt query token production, validate origin/claims, authorize message |
| P1 | CSRF bypass toàn bộ khi `NODE_ENV=development` | Chỉ bypass explicit test profile; staging phải enforce |
| P1 | In-memory rate limit và rất nới ngoài production | Shared Redis limiter cho multi-instance; test staging policy |
| P1 | Phone OTP code cũ dùng `Math.random()` và log OTP; route hiện đang khóa | Xóa/không hồi quy; dùng CSPRNG + provider + hash + attempt limit |
| P1 | Forgot/reset message và TTL comment/template không đồng nhất | Canonical config, generic response, test expiry/enum |
| P1 | OAuth web callback cần state/nonce/redirect allowlist review | Persist transaction state, exact allowlist, negative tests |
| P2 | `x-app-key` có thể bị hiểu nhầm là auth | Document admission-only, rotate và không dùng thay user auth |

## 15. Security acceptance criteria

Auth/security chỉ đạt PASS khi test chứng minh được:

- Login/register không enumeration quá mức và không lộ secret.
- Access expiry dẫn tới refresh đúng một lần; refresh concurrent không cấp vô hạn token.
- Reuse refresh/reset/verification token bị từ chối và audit.
- Logout, logout-all, password reset và ban có hiệu lực theo policy.
- Role revoke và ownership change không bị bypass bằng stale JWT hoặc đổi ID.
- Cookie mutation thiếu/khác CSRF bị chặn; CORS/Origin ngoài allowlist bị chặn.
- OAuth state/nonce/audience/issuer/PKCE negative cases bị chặn.
- Socket origin/message/room unauthorized bị chặn; session expiry đóng connection.
- Rate limit, lockout/step-up và retry không gây DoS hoặc bypass bằng nhiều instance.
- Password/token/provider secret không xuất hiện trong logs, responses, client bundle, screenshot hoặc Git.

## References

[1]: https://owasp.org/www-project-application-security-verification-standard/ "OWASP ASVS"
[2]: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html "OWASP Authentication Cheat Sheet"
[3]: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html "OWASP Authorization Cheat Sheet"
[4]: https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html "OWASP Password Storage Cheat Sheet"
[5]: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html "OWASP Session Management Cheat Sheet"
[6]: https://cheatsheetseries.owasp.org/cheatsheets/OAuth2_Cheat_Sheet.html "OWASP OAuth2 Cheat Sheet"
[7]: https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html "OWASP CSRF Prevention Cheat Sheet"
[8]: https://cheatsheetseries.owasp.org/cheatsheets/WebSocket_Security_Cheat_Sheet.html "OWASP WebSocket Security Cheat Sheet"
[9]: https://cheatsheetseries.owasp.org/cheatsheets/REST_Security_Cheat_Sheet.html "OWASP REST Security Cheat Sheet"
[10]: https://payos.vn/docs/tich-hop-webhook/kiem-tra-du-lieu-voi-signature/ "payOS Signature Verification"
