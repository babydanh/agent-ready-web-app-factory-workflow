# Known Failures — Regression Memory

File này là trí nhớ regression của workflow. Khi feature chạm vào vùng tương ứng, QA phải đưa case vào test plan.

| Khu vực | Lỗi có thể tái diễn | Cổng kiểm soát |
|---|---|---|
| Payment | `isPaid` bị hardcode true hoặc frontend bỏ qua checkout | Test free/paid path và kiểm tra backend state |
| Payment | Frontend gọi webhook | Chỉ backend được xử lý webhook; frontend chỉ mở checkout/result |
| Payment | Webhook gọi đúp | Unique transaction reference + idempotency test |
| Payment | Refund nhảy thẳng sang final state | State machine chỉ cho phép bước được định nghĩa |
| Division | Dùng tournament ID thay cho selected division ID | Contract test và E2E cho từng division |
| Bracket | BYE làm propagate winner null | Test participant count lẻ và empty slot |
| Bracket | Double elimination index out of bounds | Test kích thước bracket 2, 4, 8 và số lẻ |
| Bracket | Regenerate hard delete dữ liệu | Review soft delete/audit và migration |
| Registration | Hai request cùng lấy slot cuối | Transaction/row lock/concurrency test |
| Auth | OTP in-memory mất khi restart | OTP lưu DB, expiry, used state và migration |
| Auth | Refresh token replay | Revoke atomic và revoke all sessions khi phát hiện replay |
| Auth | Rate limit không bao phủ auth endpoints | Test register/login/OTP burst |
| ELO | K-factor hoặc boundary bị định nghĩa nhiều nơi | Một constant/engine chung + unit test |
| ELO | Cập nhật đồng thời làm mất history | Row lock/transaction + concurrency test |
| Frontend | Axios 401 không refresh đúng hoặc retry vô hạn | Interceptor test và expired-session E2E |
| Frontend | Component gọi API trực tiếp, URL hardcode | Architecture review |
| Frontend | `useEffect` tạo cascading render hoặc listener leak | React review + cleanup test |
| Frontend | Loading/empty/error state thiếu | UI state matrix |
| Realtime | CORS wildcard hoặc socket không auth | Gateway security review |
| Runtime | Migration chạy sau backend | Compose dependency/health check |
| Runtime | Tài liệu path/version không khớp code thực tế | `validate-env.ps1` và environment drift review |

## Quy tắc sử dụng

Không copy nguyên lỗi vào production code để “nhớ”. Hãy chuyển lỗi thành một acceptance criterion, test case, lint rule, script check hoặc review item phù hợp. Khi một lỗi mới được phát hiện, thêm một dòng gồm nguyên nhân, cách phát hiện và quality gate ngăn tái diễn.
