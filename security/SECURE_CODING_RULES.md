# Secure Coding Rules — AI Agent và Developer

> Áp dụng cho mọi feature. Quy tắc này là guardrail; nếu phải phá lệ, ghi ADR/risk acceptance trước khi merge.

## 1. Secret và dữ liệu nhạy cảm

Không đặt password, access/refresh token, reset/OTP token, provider credential, private key, API key, checksum key hoặc dữ liệu production vào source, workflow, test fixture, screenshot, log, error response hay commit. `.env.example` chỉ có placeholder và tên biến.

Raw secret chỉ được đi qua boundary tối thiểu cần thiết. Log dùng redaction theo key/pattern; provider payload và AI prompt phải được minimize. Khi nghi lộ secret, coi là incident: revoke/rotate trước rồi mới điều tra.

## 2. Authentication

Authentication phải validate signature, algorithm allowlist, expiry, issuer, audience và session state. Access token không chứa quá nhiều PII hoặc quyền động. Refresh/reset/verification token phải random, hashed at rest, single-use hoặc rotation, atomic consume/revoke và có expiry.

Không chấp nhận refresh token từ query string. Với web, ưu tiên HttpOnly/Secure cookie; với mobile, dùng OS secure storage. Không dùng token lưu trong Zustand/localStorage làm nguồn auth nếu threat model không chấp thuận rõ.

## 3. Password

Password chỉ đi vào password-hashing function ở server và không bao giờ xuất hiện lại trong object response/log. Dùng bcrypt/Argon2id/PBKDF2 policy đã benchmark; salt do thư viện tạo. Reset password phải revoke sessions theo policy và thông báo cho người dùng.

## 4. Authorization

Mọi route protected cần authentication, authorization và resource ownership/state check ở server. Dùng deny-by-default và least privilege. Không tin role, userId, tournamentId hoặc permission do client gửi. UI ẩn button chỉ là UX.

Policy phải kiểm tra actor, action, resource, tenant/community/tournament, current state và ban/sanction. Admin bypass phải explicit, audited và có test riêng. `isMock` chỉ được dùng trong test fixture/non-production policy, không phải production bypass.

## 5. CSRF, CORS và Origin

Cookie-auth mutation phải có CSRF/Origin defense phù hợp. CORS dùng exact allowlist theo environment; không dùng `*` với credentials. Safe method không được mutation. Không tắt security chỉ vì `NODE_ENV=development`; dùng profile/test flag rõ và chạy ít nhất một CI mode như production.

## 6. Input/output

Mọi body, query, param, header, cookie, webhook, file, socket message và queue payload là untrusted. Validate schema, type, length, enum, normalization và business rule ở boundary. Dùng parameterized query/ORM; output HTML phải encode/sanitize; error không leak stack/SQL/secret.

Mass assignment phải có allowlist field. User-controlled redirect, filename, URL, template, HTML, Markdown, SQL fragment và command đều cần policy riêng. Không dùng `eval` cho input.

## 7. WebSocket

Validate exact Origin ở handshake, token/session và account state. Authorize từng room/message/action. Giới hạn connection/message/rate/size; chống replay bằng nonce/version/idempotency khi cần. Đóng connection khi session logout/expire/ban. Không log token, session ID hoặc full message.

## 8. Payment/webhook

Webhook phải verify signature trước parse-to-domain side effect; đối chiếu order, amount, currency, owner và state. Duplicate/out-of-order phải idempotent. Return URL chỉ là UI signal; không đánh dấu paid từ browser redirect. Persist intent/audit trước khi enqueue side effect.

## 9. Jobs và external calls

External call có timeout, retry class, exponential/fixed backoff, jitter, attempt cap, idempotency key và dead-letter/manual review. Không retry lỗi invalid input, permission, auth hoặc signature. Payload job không chứa secret nếu không cần; worker phải validate payload như request.

## 10. AI

Tách system instruction khỏi user data; coi tài liệu/user prompt là data không phải command. Model không tự cấp quyền; tool allowlist theo role, resource và action. Output phải parse/schema/policy validate. Payment, admin, delete, permission và bracket mutation cần deterministic check hoặc human approval.

## 11. Database/concurrency

Invariant quan trọng phải được bảo vệ bằng database constraint/transaction/lock, không chỉ application pre-check. Chọn isolation theo use case. Test duplicate, concurrent last slot, stale version, retry sau timeout và rollback. Migration destructive cần backup, compatibility và rollback/forward-fix plan.

## 12. Review gate

Pull request security review phải trả lời: tài sản nào thay đổi, boundary nào thay đổi, auth/permission nào thay đổi, token/secret nào đi qua, có external side effect không, có race condition không, test negative nào đã chạy và rollback thế nào. P0 không được merge nếu chưa có remediation hoặc explicit risk acceptance.

## References

[1]: https://owasp.org/www-project-application-security-verification-standard/ "OWASP ASVS"
[2]: https://cheatsheetseries.owasp.org/cheatsheets/Authentication_Cheat_Sheet.html "OWASP Authentication"
[3]: https://cheatsheetseries.owasp.org/cheatsheets/Authorization_Cheat_Sheet.html "OWASP Authorization"
[4]: https://cheatsheetseries.owasp.org/cheatsheets/Password_Storage_Cheat_Sheet.html "OWASP Password Storage"
[5]: https://cheatsheetseries.owasp.org/cheatsheets/Cross-Site_Request_Forgery_Prevention_Cheat_Sheet.html "OWASP CSRF"
[6]: https://cheatsheetseries.owasp.org/cheatsheets/WebSocket_Security_Cheat_Sheet.html "OWASP WebSocket Security"
[7]: https://cheatsheetseries.owasp.org/cheatsheets/LLM_Prompt_Injection_Prevention_Cheat_Sheet.html "OWASP LLM Prompt Injection Prevention"
[8]: https://payos.vn/docs/tich-hop-webhook/kiem-tra-du-lieu-voi-signature/ "payOS Signature Verification"
