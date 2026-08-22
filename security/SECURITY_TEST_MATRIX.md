# Security Test Matrix

> **Mục tiêu:** Chuyển security requirements thành test case có input, expected result, evidence và severity. Test defensive trên local/staging được cô lập; không dùng credential production.

## 1. Test metadata

Mỗi test ghi `ID`, `risk`, `precondition`, `actor`, `request`, `expected`, `evidence` và `owner`. Test fail không được đánh dấu pass vì “đã chạy command”; phải chứng minh response/state/log phù hợp.

| ID | Area | Risk | Actor | Expected |
|---|---|---:|---|---|
| AUTH-001 | Register password | P0 | Anonymous | Password hash khác plaintext; response không có hash/token |
| AUTH-002 | Login wrong email/password | P1 | Anonymous | Generic auth error, không enumerate rõ, rate counter tăng |
| AUTH-003 | Login banned/deleted | P0 | Banned/deleted user | Không cấp session/access |
| AUTH-004 | Access expiry | P1 | Auth user | Expired access không vào protected route; refresh theo policy |
| AUTH-005 | Refresh rotation | P0 | Auth user | R1 → R2; R1 bị revoke; R1 reuse bị reject/revoke family |
| AUTH-006 | Concurrent refresh | P0 | Same session x2 | Kết quả bounded theo grace policy; không tạo vô hạn session |
| AUTH-007 | Logout | P1 | Auth user | Current session revoke; exact cookies clear; protected call fail sau expiry/recheck |
| AUTH-008 | Logout all | P0 | Auth user | All sessions revoke; other device must re-auth |
| AUTH-009 | Password reset | P0 | Anonymous | Generic request response; token one-time; all sessions revoke after reset |
| AUTH-010 | Verify email | P1 | Anonymous/auth | Token hash/expiry/used-once; repeat rejected |
| AUTH-011 | OTP brute force | P1 | Anonymous/user | Attempts/rate limit; no unbounded guesses |
| AUTH-012 | OAuth state | P0 | Attacker | Mismatched/reused/expired state rejected |
| AUTH-013 | OAuth issuer/aud | P0 | Attacker | Wrong issuer/audience/alg rejected |
| AUTH-014 | OAuth nonce/PKCE | P0 | Attacker | Mismatch/downgrade/code reuse rejected |
| AUTH-015 | Auth provider link | P0 | Auth user | Same email alone cannot hijack identity; explicit link policy |
| AUTH-016 | Provider token | P0 | DB/log reader | Token encrypted/not stored/never logged per policy |
| AUTH-017 | Secret scan | P0 | CI | Secret fixture fails scan; placeholder `.env.example` passes |
| AUTH-018 | Re-auth | P1 | Auth user | Password/payment/admin/device action requires step-up where specified |

## 2. Authorization matrix

Tạo fixture tối thiểu `anonymous`, `playerA`, `playerB`, `organizerA`, `organizerB`, `admin`, `banned`, `deleted`, `unverified` và resources thuộc các owner/tournament khác nhau.

| ID | Scenario | Expected |
|---|---|---|
| AUTHZ-001 | Player A đọc resource của A | Allow nếu policy cho phép |
| AUTHZ-002 | Player A đọc/sửa resource của B bằng đổi path ID | Deny; không leak existence nếu policy yêu cầu |
| AUTHZ-003 | Organizer A sửa tournament của B | Deny |
| AUTHZ-004 | Player gọi organizer/admin endpoint | Deny server-side dù UI ẩn nút |
| AUTHZ-005 | Role bị revoke nhưng JWT cũ còn hạn | Deny theo active-role/revocation policy |
| AUTHZ-006 | Banned user gọi protected route | Deny |
| AUTHZ-007 | Unverified user gọi verified route | Deny; mock exception chỉ có trong explicit non-prod fixture |
| AUTHZ-008 | User đổi `userId` trong body/query | Server lấy actor từ auth context và ownership check |
| AUTHZ-009 | Admin bypass | Chỉ allow action trong explicit policy; audit actor/reason |
| AUTHZ-010 | Cross-community/tenant access | Deny nếu không có relationship/permission |
| AUTHZ-011 | Status bypass | Cannot update resource from invalid state |
| AUTHZ-012 | Mass assignment | Unknown/protected fields ignored/rejected; role/owner không do client set |

## 3. Cookie, CSRF, CORS và HTTP

| ID | Request | Expected |
|---|---|---|
| WEB-001 | Cookie-auth POST thiếu `X-CSRF-Token` | 403 |
| WEB-002 | Cookie/header CSRF khác nhau | 403 |
| WEB-003 | Cookie-auth mutation từ Origin ngoài allowlist | Rejected hoặc policy challenge |
| WEB-004 | Valid same-site cookie + CSRF header | Pass nếu auth/permission pass |
| WEB-005 | GET có mutation intent | Không tồn tại hoặc bị reject |
| WEB-006 | CORS credential request từ arbitrary origin | Không được trả allow-origin wildcard |
| WEB-007 | Bearer mobile mutation không có browser CSRF | Pass CSRF layer nhưng vẫn auth/permission/rate limit/HTTPS |
| WEB-008 | Logout cookie path/domain mismatch | Test browser xác nhận cookie bị clear đúng |
| WEB-009 | Error response | Không có stack, SQL, token, hash, secret hoặc provider detail |
| WEB-010 | Security headers/HTTPS | HSTS/CSP/frame/content sniff/referrer policy theo deployment policy |

## 4. WebSocket/realtime

| ID | Scenario | Expected |
|---|---|---|
| WS-001 | Handshake missing token | Reject |
| WS-002 | Invalid/expired/ wrong issuer/aud JWT | Reject |
| WS-003 | Origin ngoài allowlist | Reject |
| WS-004 | Query token in production | Reject; `allowQueryToken=false` |
| WS-005 | Auth socket joins unauthorized room | Reject |
| WS-006 | Auth socket sends message for other match | Reject per-message |
| WS-007 | Oversized/malformed message | Reject/close; no crash |
| WS-008 | Replay same score event | Idempotency/version prevents duplicate mutation |
| WS-009 | Session expires/logout/ban | Connection closed or revalidated and denied |
| WS-010 | Disconnect during score update | DB state is authoritative; reconnect resyncs |
| WS-011 | Sensitive event to wrong room | No delivery |
| WS-012 | WS log | Auth/deny/close metadata logged without token/full payload |

## 5. Payment/webhook/integration

| ID | Scenario | Expected |
|---|---|---|
| PAY-001 | Valid payOS signature | Accepted only after exact verification |
| PAY-002 | Invalid signature | Reject; no payment/participant mutation |
| PAY-003 | Valid signature but wrong amount/order | Reject and audit |
| PAY-004 | Duplicate webhook | Idempotent; one state transition/side effect |
| PAY-005 | Out-of-order event | State machine rejects or safely reconciles |
| PAY-006 | Return URL says success but webhook absent | UI remains pending/unverified |
| PAY-007 | Provider timeout | Intent persisted; retry job; no double charge state |
| PAY-008 | Webhook flood | Rate/queue control; no unbounded worker growth |
| PAY-009 | Gateway secret in client/log | CI/log scan fails |
| PAY-010 | Refund/payout invalid transition | Reject; no balance/payment corruption |

## 6. Password/reset/OTP specifics

| ID | Scenario | Expected |
|---|---|---|
| REC-001 | Reset token copied from DB/log fixture | Cannot derive/use if only hash stored |
| REC-002 | Reset token expired | Reject |
| REC-003 | Reset token used twice concurrently | Exactly one succeeds; one fails |
| REC-004 | Reset password | All existing sessions revoked; notification/audit created |
| REC-005 | Forgot unknown email | Same externally visible response as known email |
| REC-006 | Request reset spam | Cooldown/daily limit, distributed policy in staging/prod |
| REC-007 | OTP wrong attempts | Bounded attempts and temporary lock/expiry |
| REC-008 | OTP generated | CSPRNG, not `Math.random()` |
| REC-009 | OTP log | No OTP/phone/email sensitive detail beyond policy |
| REC-010 | Email link page | Referrer/third-party leakage mitigated; token removed after consume |

## 7. AI and upload

| ID | Scenario | Expected |
|---|---|---|
| AI-001 | Prompt says ignore system rules | Treated as data; no tool escalation |
| AI-002 | User input requests secret | No secret in output |
| AI-003 | Model returns invalid JSON/schema | Reject/retry/fallback; no unsafe mutation |
| AI-004 | Model attempts payment/admin/delete tool | Denied or human approval required |
| AI-005 | Tool payload references other tournament | Ownership/policy denies |
| AI-006 | Prompt/output logging | Redacted and bounded |
| FILE-001 | Oversized upload | Reject before provider call |
| FILE-002 | Wrong MIME/magic number | Reject |
| FILE-003 | Private resource URL guessed | Access denied/signed URL required |
| FILE-004 | Filename/path traversal | Safe generated key; no filesystem escape |
| FILE-005 | Orphaned upload | Cleanup/retention job exists |

## 8. Abuse and resilience

| ID | Scenario | Expected |
|---|---|---|
| ABUSE-001 | Login credential spray | Rate limit, telemetry and generic response |
| ABUSE-002 | Reset/verification spray | Per-IP/account/device limits and cooldown |
| ABUSE-003 | Multi-instance rate limit | Shared store or documented limitation; no process-local bypass |
| ABUSE-004 | Queue retry storm | Backoff/jitter/cap/dead-letter |
| ABUSE-005 | Huge JSON/body | Body limit and fast rejection |
| ABUSE-006 | Slow client/connection flood | Proxy/socket limits and cleanup |
| ABUSE-007 | DB pool exhaustion | Timeout, circuit/backpressure and alert |
| ABUSE-008 | Repeated 401 refresh | One controlled refresh; no infinite loop |

## 9. Evidence standard

Mỗi test suite đính kèm command, commit, environment profile, fixture version, result, trace/log/screenshot nếu cần và defect link. Security test không được upload token thật, email thật, bank data thật hoặc payment secret.

### References

[1]: https://owasp.org/www-project-application-security-verification-standard/ "OWASP ASVS"
[2]: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html "OWASP Authentication"
[3]: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html "OWASP Authorization"
[4]: https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html "OWASP Password Storage"
[5]: https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html "OWASP CSRF Prevention"
[6]: https://cheatsheetseries.owasp.org/cheatsheets/WebSocket_Security_Cheat_Sheet.html "OWASP WebSocket Security"
[7]: https://payos.vn/docs/tich-hop-webhook/kiem-tra-du-lieu-voi-signature/ "payOS Signature Verification"
[8]: https://playwright.dev/docs/best-practices "Playwright Best Practices"
