# Current Auth Security Review — Project Baseline

> **Phạm vi reviewed:** Auth controller/service/repository, user/OTP schema, JWT strategies, guards, frontend Axios và auth store. Đây là review tĩnh để định hướng hardening; mọi finding cần được xác nhận bằng test và code review trước khi sửa production.

## 1. Điểm đang làm đúng hoặc có nền tảng tốt

| Area | Observed baseline | Ý nghĩa |
|---|---|---|
| Password | Backend dùng bcrypt với cost hiện tại 12 | Không lưu plaintext password |
| Registration | User/profile/role tạo trong transaction ở repository | Giảm partial user creation |
| Web tokens | Controller đặt access/refresh vào HttpOnly cookie và xóa token khỏi JSON body | Giảm token exposure qua JS/response |
| Frontend token state | Zustand chỉ persist user/isAuthenticated, không persist raw access/refresh token | Token không nằm trong persisted auth store |
| Refresh race | Refresh có atomic revoke và có logic xử lý concurrent request/reuse | Đã nhận diện vấn đề rotation race |
| CSRF | Có double-submit cookie/header cho cookie-auth mutation | Có defense layer cho browser cookie |
| RBAC | RolesGuard đọc role trong token và re-check active role trong DB | Không hoàn toàn tin stale role claim |
| Verification | VerifiedGuard và rate limit cho nhiều auth routes | Có verification/abuse control baseline |
| OAuth | Google ID token verify audience; Apple verify key/issuer/audience/nonce path | Có provider identity verification baseline |
| Reset | Reset password transaction update password + consume token + revoke sessions | Đúng hướng về atomic state change |

## 2. Findings cần xử lý

### AUTH-F-001 — Raw refresh token trong database — P0

`users.schema.ts` định nghĩa `sessions.refreshToken` là text unique; `auth.repository.ts` create/find/revoke bằng raw token; `auth.service.ts` cũng query/revoke trực tiếp token. Nếu database snapshot/log/query output bị đọc, attacker có thể dùng token còn hạn.

**Remediation:** thêm `refreshTokenHash`, lưu SHA-256/HMAC fingerprint phù hợp policy, lookup bằng hash, chuyển migration và invalidate/rotate toàn bộ sessions cũ. Lý tưởng hơn dùng opaque refresh token. Nếu vẫn JWT refresh, verify JWT và bind với session hash. Không log raw token.

### AUTH-F-002 — Raw OAuth provider token trong database — P0

`authProviders.accessToken` và `refreshToken` được lưu trực tiếp khi provider trả về. Nếu ứng dụng không cần gọi provider thay user, bỏ lưu. Nếu cần, encrypt at rest bằng key ngoài database/secret manager, giới hạn access, audit và rotation.

### AUTH-F-003 — Raw reset/email/OTP code — P0

`otp_codes.code` là text và service dùng raw token để lookup. Email verification/reset link đưa token vào URL. Với DB/log/browser history compromise, token có thể bị dùng.

**Remediation:** lưu hash(code), thêm `usedAt`, `attemptCount`, `requestedAt`, expiry/type index; consume bằng atomic update `WHERE hash = ? AND used_at IS NULL AND expires_at > now() RETURNING`; token page không tải third-party resources và làm sạch URL sau khi nhận token.

### AUTH-F-004 — WebSocket query token được bật mặc định — P0/P1

`ws-jwt.guard.ts` thử `handshake.query.token` khi `allowQueryToken` không truyền hoặc khác false. Query token có nguy cơ đi vào access log/referrer/observability.

**Remediation:** production default deny query token; migrate clients sang `handshake.auth` hoặc cookie/Authorization theo client policy; redact legacy logs; validate exact Origin, issuer/audience, account/session state; authorize từng message/room.

### AUTH-F-005 — CSRF bypass toàn bộ ở development — P1

`csrf.guard.ts` return true khi `NODE_ENV === 'development'`. Nếu staging hoặc local profile không giống production, regression có thể bị che.

**Remediation:** dùng explicit `SECURITY_PROFILE=test` cho fixture; enforce CSRF ở staging; giữ một CI suite chạy cookie-auth như production; thêm test đảm bảo không bypass chỉ vì NODE_ENV.

### AUTH-F-006 — Rate limit process-local và nới ngoài production — P1

`rate-limit.guard.ts` dùng memory của process; advisory của project ghi limits ngoài production có thể rất cao trừ khi force. Multi-instance có thể bypass limit bằng cách chuyển process.

**Remediation:** Redis-backed limiter với key policy IP/account/device/route; set explicit limits cho dev/staging; test `Retry-After`, burst, distributed behavior và reset window. Không dùng user-provided header làm identity duy nhất.

### AUTH-F-007 — Password reset response/message và TTL chưa canonical — P1

`forgotPassword` có nhánh trả lỗi khi user/email không tồn tại trong khi response cuối có generic wording; code token expiry 120 giây nhưng email HTML nói hiệu lực 15 phút. Sai lệch này vừa tạo enumeration risk vừa làm UX/security inconsistent.

**Remediation:** mọi request trả cùng generic response; canonical config cho TTL; test known/unknown/OAuth account, expiry, resend cooldown và token replay.

### AUTH-F-008 — Phone OTP code cũ dùng random không phù hợp và log OTP — P1

Trong service có implementation cũ dùng `Math.random()` và logger chứa số điện thoại/OTP mock; controller hiện khóa route. Route bị khóa không đủ nếu code hồi quy hoặc được gọi từ module khác.

**Remediation:** xóa hoặc cô lập code mock; dùng CSPRNG, hash OTP, attempt limit, cooldown và provider abstraction; không log OTP/phone raw.

### AUTH-F-009 — JWT verify thiếu explicit issuer/audience ở một số path — P1

`jwt.strategy.ts`, refresh strategy và `WsJwtGuard` verify secret/expiry nhưng code review cần xác nhận issuer/audience/algorithm policy nhất quán. Access/refresh secret tách riêng là tốt nhưng chưa đủ cho mọi deployment boundary.

**Remediation:** chốt claims `iss`, `aud`, `typ`, `jti`; algorithm allowlist; verify access/refresh token đúng purpose; test token confusion, wrong audience/issuer/secret và stale claims.

### AUTH-F-010 — OAuth account linking cần policy rõ — P1

`oauthLogin` match provider identity và normalized email; có logic system admin dựa trên `SYSTEM_ADMINS`. Cần review explicit linking, account takeover prevention, email verification semantics và admin bootstrap audit.

**Remediation:** identity key là `(iss, sub/provider, providerUserId)`; email chỉ là signal; account link cần logged-in confirmation/re-auth; system-admin bootstrap có one-time controlled process và audit.

### AUTH-F-011 — App key không phải authentication — P2

`x-app-key` là lớp request admission cho API, không chứng minh identity hoặc quyền resource. Nếu secret lộ, mọi route được skip/allow phải được phân loại rõ.

**Remediation:** document route scope, exact allowlist, rotation, no client-secret expectation và ensure JWT/ownership vẫn enforced.

## 3. Remediation order

```text
1. Prevent new leakage: logs/client responses/query tokens/provider-token persistence
2. Rotate/revoke exposed secrets and invalidate old sessions/tokens
3. Hash refresh/reset/verification tokens and add atomic consume/rotation
4. Fix auth claim validation, OAuth state/linking and resource ownership
5. Move rate limits to shared store and enforce test-like-production CSRF
6. Add negative/concurrency/security tests and CI gates
7. Add monitoring/alert and incident runbook evidence
```

Không chạy migration hash token mà không có migration/rollback plan. Token hiện có dạng raw không thể khôi phục hash ngược; migration cần invalidate hoặc xử lý compatibility có thời hạn rồi bắt buộc đăng nhập lại.

## 4. Review commands/evidence

```text
git diff --check
git status --short
pnpm --dir HethongBackendApi_QuanlyGiaiDau test -- auth
pnpm --dir HethongBackendApi_QuanlyGiaiDau test -- security
pnpm --dir HethongFrontEndWeb_QLgiaidau lint
pnpm --dir HethongFrontEndWeb_QLgiaidau build
pnpm exec playwright test --grep "auth|permission|security"
```

Các command cần điều chỉnh theo scripts thực tế; không đánh dấu PASS nếu test selector không tồn tại hoặc command bị skip. Không chạy hoặc commit secret thật.

## References

[1]: https://owasp.org/www-project-application-security-verification-standard/ "OWASP ASVS"
[2]: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html "OWASP Authentication"
[3]: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html "OWASP Authorization"
[4]: https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html "OWASP Password Storage"
[5]: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html "OWASP Session Management"
[6]: https://cheatsheetseries.owasp.org/cheatsheets/WebSocket_Security_Cheat_Sheet.html "OWASP WebSocket Security"
[7]: https://cheatsheetseries.owasp.org/cheatsheets/OAuth2_Cheat_Sheet.html "OWASP OAuth2"
