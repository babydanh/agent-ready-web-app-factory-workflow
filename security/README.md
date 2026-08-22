# Security & Auth Pack

Đây là bộ security/auth chuyên sâu dùng cùng `WORKFLOW.md`, `SKILL.md`, `AGENTS.md` và `TECH_RESEARCH.md`. Security phải được đưa vào discovery/design/code/test/release, không phải một bước kiểm tra cuối cùng.

| Tài liệu | Dùng khi |
|---|---|
| `THREAT_MODEL.md` | Bắt đầu dự án/feature có identity, PII, tiền, admin, realtime hoặc AI |
| `AUTH_SECURITY_ARCHITECTURE.md` | Chọn cookie/bearer, token lifecycle, RBAC, OAuth, CSRF, WS và recovery |
| `AUTH_CURRENT_STATE_REVIEW.md` | Đọc hiện trạng auth của đồ án và lập remediation backlog |
| `AUTH_STATE_MACHINES.md` | Thiết kế transition account/session/reset/payment/step-up |
| `SECURITY_TEST_MATRIX.md` | Viết test âm, concurrency, abuse, E2E và evidence |
| `SECURE_CODING_RULES.md` | Trước và trong lúc code/review PR |
| `SECURITY_CONFIG.template.md` | Chuẩn hóa env, cookie, JWT, OAuth, payment, rate limit và logging |
| `ENDPOINT_POLICY_MATRIX.template.md` | Khai báo policy của từng API route |
| `MFA_AND_STEP_UP.md` | Bảo vệ thao tác admin, payout, payment và recovery |
| `INCIDENT_RUNBOOK.md` | Khi nghi lộ secret, account takeover, IDOR, payment forgery hoặc outage |

## Cách áp dụng nhanh

1. Đọc threat model và current-state review.
2. Chốt auth transport: web cookie hoặc mobile bearer; không trộn policy mù.
3. Chốt state machine, endpoint permission matrix và step-up requirements trước code.
4. Chọn controls theo P0/P1/P2; remediation P0 trước.
5. Viết negative/concurrency tests từ `SECURITY_TEST_MATRIX.md`.
6. Dùng `SECURE_CODING_RULES.md` trong AI task và code review.
7. Chạy config/secret scan và security gates trong CI.
8. Ghi evidence, residual risk và rollback trong release record.

## Mặc định an toàn

Không có production secret trong repo. Không tin frontend, JWT role claim, URL ID, webhook, socket message, upload MIME hoặc prompt. Backend enforce authentication, authorization, ownership và state. Database bảo vệ invariant. External side effect có idempotency. Query-token authentication bị tắt ở production. Payment chỉ hoàn tất từ verified provider event.

## Nguồn chuẩn

Các khuyến nghị dựa trên OWASP ASVS, Authentication, Authorization, Password Storage, Session Management, OAuth2, CSRF, WebSocket và REST Security Cheat Sheets; tài liệu chính thức Socket.IO, payOS và codebase hiện tại. Link chi tiết nằm trong từng tài liệu.
