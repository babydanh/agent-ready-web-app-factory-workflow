# MFA và Step-Up Authentication

> MFA/step-up là lớp bảo vệ cho hành động rủi ro cao; không nên bật tùy tiện mà không có recovery, audit và UX policy.

## 1. Khi nào cần step-up

| Action | Suggested control |
|---|---|
| Đổi password/email/phone | Re-auth current credential; MFA nếu risk cao |
| Payout/bank details/refund | Re-auth + MFA + confirmation/audit |
| Gán admin/organizer role | Admin step-up + dual approval nếu phù hợp |
| Xóa tournament/participant/data | Re-auth + typed confirmation/approval |
| Thêm trusted device | Re-auth + MFA + notification |
| Account recovery/password reset | Revoke sessions; challenge/re-auth ở lần nhạy cảm tiếp theo |
| Suspicious login/device/IP | Adaptive challenge hoặc block |

## 2. Step-up contract

```text
POST /auth/step-up/start
  → create short-lived challenge bound to user/session/action

POST /auth/step-up/verify
  → verify password/MFA/WebAuthn/OTP
  → issue scoped step-up grant

POST /sensitive-action
  → require valid grant for exact action/resource
  → consume grant or expire quickly
  → persist audit
```

Grant phải có `userId`, `sessionId`, `action`, optional resource ID, issued/expiry/consumed time và assurance level. Không dùng step-up grant như access token tổng quát.

## 3. MFA choices

TOTP hoặc WebAuthn/security key thường phù hợp hơn SMS cho assurance cao; SMS có rủi ro SIM swap và delivery dependency. Nếu dùng email/phone OTP cho UX, phải có CSPRNG, hashed code, expiry, attempt limit, cooldown, replay protection và không log code. Recovery codes phải hash at rest, one-time và có regenerate/revoke.

## 4. Enrollment/recovery

MFA enrollment cần authenticated session và re-auth. Hiển thị secret/QR một lần qua secure channel; verify một code trước khi active. Notify user khi enable/disable/recovery. Không cho disable MFA chỉ bằng password đã có dấu hiệu compromise; cần step-up/recovery policy.

Recovery flow phải chống enumeration, rate limit, audit và có manual support path. Không xây “master code” trong production.

## 5. Risk signals

Risk signal có thể gồm device chưa từng thấy, IP/ASN bất thường, nhiều failure, password reset, provider account change, bank/payout change hoặc session age. Không coi IP một mình là identity tuyệt đối; dùng nó như signal cùng account/device/session và privacy policy.

## 6. Test matrix bổ sung

| ID | Scenario | Expected |
|---|---|---|
| MFA-001 | Enable MFA without re-auth | Reject |
| MFA-002 | Wrong/expired/used code | Reject and count attempt |
| MFA-003 | Replay verified challenge | Reject |
| MFA-004 | Step-up for action A used on action B | Reject |
| MFA-005 | Step-up for resource A used on resource B | Reject |
| MFA-006 | Logout/reset/ban after step-up | Grant invalidated |
| MFA-007 | Recovery code reused | Reject |
| MFA-008 | Too many attempts | Rate limit/temporary block |
| MFA-009 | Disable MFA | Requires policy-defined step-up and audit |
| MFA-010 | Provider/device changed | Notify and risk challenge |

## References

[1]: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html "OWASP Authentication Cheat Sheet"
[2]: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html "OWASP Session Management Cheat Sheet"
