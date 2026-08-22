# Endpoint Policy Matrix Template

> Dùng cho từng module/feature. Không đánh dấu route đã an toàn nếu bảng này còn trống.

| Method | Path | Public | Auth | Roles | Ownership/tenant | State precondition | CSRF/Origin | Rate limit | Idempotency | Audit event | Tests |
|---|---|---:|---|---|---|---|---|---|---|---|---|
| `POST` | `/resource` | No | Cookie/Bearer | `ROLE_X` | actor/team/community | `DRAFT` | Required if cookie | user/IP | Required? | `resource.created` | `TBD` |

## Policy questions

### Identity

Actor lấy từ verified auth context hay có field client gửi? Access token cần fresh role/session check không? Route có yêu cầu verified email, MFA hoặc re-auth không?

### Permission

Role nào được gọi? Quyền là RBAC, resource ownership, relationship, attribute hay trạng thái? Có admin override không; nếu có, lý do và audit nào?

### Input and output

Body/query/path/header/cookie/file/event nào là untrusted? DTO/schema, length, enum, normalization và response redaction ở đâu? Có mass-assignment risk không?

### Side effect

Có ghi database, gửi email, payment, payout, upload, socket broadcast, queue hoặc AI tool không? Side effect có transaction/outbox/idempotency/retry/timeout không?

### Abuse

Route bị brute force, enumeration, scraping, body flood hay replay thế nào? Rate key dùng IP/account/device/resource nào? Có shared store không?

### Security evidence

- [ ] Positive role/ownership test.
- [ ] Anonymous/unauthenticated test.
- [ ] Wrong-role test.
- [ ] Cross-resource/IDOR test.
- [ ] Invalid state/conflict test.
- [ ] CSRF/Origin/CORS test nếu cookie.
- [ ] Rate-limit/replay/idempotency test.
- [ ] Secret/error/log redaction review.
- [ ] Audit event và correlation ID evidence.
