# Security Incident Runbook

> **Mục tiêu:** Phản ứng có kiểm soát khi có dấu hiệu lộ credential, account takeover, token replay, privilege escalation, payment forgery, data exposure hoặc abuse. Không thực hiện thao tác production nguy hiểm nếu chưa có owner/approval phù hợp.

## 1. Nguyên tắc ưu tiên

Ưu tiên bảo vệ người dùng và chặn thêm thiệt hại trước khi tìm nguyên nhân hoàn hảo. Preserve evidence, ghi timeline theo UTC, giảm blast radius, rotate/revoke secret có nguy cơ, thông báo đúng người và chỉ khôi phục sau khi có verification.

## 2. Severity

| Severity | Ví dụ | SLA nội bộ đề xuất | Hành động đầu tiên |
|---|---|---:|---|
| SEV-0 | Provider secret/admin credential lộ, payment forgery đang diễn ra, active account takeover hàng loạt | Ngay lập tức | Incident commander, contain, revoke/rotate |
| SEV-1 | Refresh replay, privilege escalation, PII exposure đáng kể, webhook forgery có impact | Trong giờ | Freeze risky path, preserve logs, remediate |
| SEV-2 | Một user bị abuse, rate-limit bypass, WS unauthorized attempt, lỗi config có mitigation | Trong ngày | Patch/config, monitor, regression test |
| SEV-3 | Hardening gap không có evidence exploit/impact | Theo sprint | Tạo backlog và owner |

## 3. Common first response

1. Ghi incident ID, thời điểm phát hiện, detector, người phát hiện và phạm vi nghi ngờ.
2. Không xóa log, không reset database, không chạy cleanup phá evidence.
3. Xác định hành động chứa rủi ro: login, refresh, reset, role assignment, payment, payout, upload, socket hoặc AI tool.
4. Contain bằng feature flag, route block, revoke session family/all sessions, disable provider integration hoặc rate limit chặt hơn theo approval.
5. Rotate credential đã lộ bằng secret manager/provider console; không paste secret vào ticket/chat.
6. Tìm affected users/resources/events từ audit + structured logs với data minimization.
7. Patch và test negative path; deploy staged; smoke và monitor.
8. Thông báo stakeholder/user/regulator nếu policy yêu cầu.
9. Viết post-incident review: root cause, timeline, impact, missed control, corrective/preventive action.

## 4. Credential/API key leak

**Detect:** secret scanner, log review, client bundle, screenshot, Git history hoặc provider alert.

**Contain:** revoke key/token ngay tại provider; disable integration nếu chưa biết phạm vi; xác định key có production scope không.

**Remediate:** thay secret qua secret manager, purge secret khỏi active branch/artifact/log retention theo policy, kiểm tra usage/billing/audit, add regression secret scan.

**Không làm:** chỉ xóa dòng secret khỏi working tree rồi coi là an toàn; Git history/image/cache/log vẫn có thể chứa bản cũ.

## 5. Refresh-token replay/account takeover

**Detect:** cùng token family xuất hiện ở IP/device bất thường, reuse sau rotation, nhiều refresh failure, login anomaly.

**Contain:** revoke token family hoặc all sessions tùy confidence; force re-auth; tăng monitoring/rate limit; disable risky sensitive actions.

**Remediate:** migrate raw token storage sang hash/encryption policy, atomic rotation/reuse detection, session/device audit, review cookie/storage/XSS/CSRF.

**Evidence:** session ID/hash fingerprint đã redact, timestamps, user-safe actor ID, IP coarse/hashed theo privacy policy, response class, không lưu raw token.

## 6. Password reset/email verification abuse

**Detect:** burst request, token use từ nhiều context, reset success không tương ứng request, token trong logs/referrer.

**Contain:** revoke affected sessions, invalidate outstanding reset/verification token family, tighten rate limit, disable email route tạm thời nếu cần.

**Remediate:** hash token at rest, atomic single-use, attempt limit, generic response, consistent TTL, no third-party resource on token page, no secret logs.

## 7. Privilege escalation/IDOR

**Detect:** 403/404 pattern đổi resource IDs, role mutation audit, admin action bất thường, user A đọc resource B.

**Contain:** disable endpoint/feature flag hoặc role, revoke affected sessions, revert unauthorized state from audit if safe.

**Remediate:** server-side role + ownership + state policy, deny-by-default, remove client-controlled owner fields, add role × resource negative tests, review all sibling routes.

## 8. Payment/webhook incident

**Detect:** invalid signature accepted, duplicate payment transition, amount mismatch, return URL marking paid, provider event out-of-order.

**Contain:** stop fulfillment/participant confirmation/payout side effect; switch integration to pending/manual review; do not delete payment evidence.

**Remediate:** HMAC/signature verify before mutation, exact order/amount/currency/owner checks, idempotency key, state machine, audit, reconciliation with provider and controlled replay.

## 9. WebSocket/Realtime incident

**Detect:** unauthorized Origin/room/message, query token log exposure, socket survives logout/ban, duplicate score mutation.

**Contain:** disable write events or gateway, close affected connections, revoke sessions, turn off query-token compatibility.

**Remediate:** Origin allowlist, auth claims/session validation, per-message authorization, size/rate/nonce/version checks, persist-first and reconnect resync, redacted event logging.

## 10. Recovery and closure

Incident chỉ đóng khi đã có owner sign-off, confirmed containment, affected scope, rotated/revoked credentials, regression evidence, monitoring window và communication decision. Postmortem phải tập trung vào control/system improvement, không đổ lỗi cá nhân.

## 11. Required records

```text
Incident ID:
Severity:
Detected at (UTC):
Detected by:
Affected services:
Suspected assets:
Containment action:
Credentials/tokens revoked or rotated:
Affected users/resources:
Evidence links (redacted):
Patch/release:
Validation tests:
Communication decision:
Owner:
Closed at:
Follow-up actions and due dates:
```

## References

[1]: https://owasp.org/www-project-application-security-verification-standard/ "OWASP ASVS"
[2]: https://cheatsheetseries.owasp.org/cheatsheets/Session_Management_Cheat_Sheet.html "OWASP Session Management"
[3]: https://cheatsheetseries.owasp.org/cheatsheets/WebSocket_Security_Cheat_Sheet.html "OWASP WebSocket Security"
[4]: https://payos.vn/docs/tich-hop-webhook/kiem-tra-du-lieu-voi-signature/ "payOS Signature Verification"
