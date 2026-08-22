# Project Context — Quản lý Giải đấu

## Mục tiêu sản phẩm

Nền tảng quản lý giải đấu thể thao cho người chơi, ban tổ chức và quản trị viên. Hệ thống hỗ trợ tạo giải, đăng ký, chia bảng/nhánh, lịch đấu, live score, ELO/ranking, thanh toán, cộng đồng, chat, notification và quản trị.

## Repository layout thực tế

| Thành phần | Đường dẫn thực tế | Vai trò |
|---|---|---|
| Backend API | `HethongBackendApi_QuanlyGiaiDau/` | NestJS modular monolith |
| Frontend Web | `HethongFrontEndWeb_QLgiaidau/` | Next.js App Router |
| Flutter App | `HethongFrontEndApp_QLgiaidau/` | Mobile app; không phải trọng tâm của web workflow |
| Test | `auto-testing/` | Playwright/Excel tooling |
| Tài liệu | `docs/` | Audit, specification, notes |
| Graph | `graphify-out/` | Knowledge graph và report |

> README hoặc Docker Compose có thể chứa tên thư mục cũ. Trước khi chạy automation, luôn xác nhận path canonical bằng filesystem thực tế.

## Backend baseline

NestJS + TypeScript strict, Drizzle ORM, PostgreSQL/PostGIS, Redis/BullMQ, JWT/Passport, bcrypt, Socket.IO, Cloudinary, email service, payment integration, Swagger/Scalar và AI integration. Backend có các vùng domain quan trọng: auth, users, categories, tournaments, matches, rankings, payments, communities, venues, chat, notifications, social, series, admin, regions, audit, upload, AI và challenges.

## Frontend baseline

Next.js App Router + React + TypeScript, TailwindCSS, Zustand, Axios, React Hook Form, Zod, Socket.IO client, Recharts, bracket library, Mapbox, Editor.js và toast. Route chính gồm public tournament/live/leaderboard/community/series, player dashboard/payments, organizer management, admin và auth.

## Quy tắc version cần xác nhận

- Skills/current status yêu cầu Node 20 LTS trở lên; README cũ có chỗ ghi Node 18.
- `current-status.md` mô tả PostgreSQL 16, trong khi Compose hiện tại dùng PostGIS image dựa trên PostgreSQL 15.
- Backend/frontend path trong README và Compose có thể khác path thực tế.
- Không dùng giá trị mặc định yếu trong production cho DB password hoặc JWT secret.

## Quy tắc domain nhạy cảm

Payment phải verify webhook ở backend, dùng transaction ACID, idempotency và audit status. ELO cần lock khi cập nhật đồng thời. Bracket phải xử lý BYE, seed, stage transition và double elimination. Registration cuối chỗ cần transaction/lock. Auth cần access/refresh token, revoke session, rate limit và chống token replay. Các entity chính phải tuân thủ soft delete theo domain.

## File tham chiếu quan trọng

| File | Dùng khi |
|---|---|
| `HethongBackendApi_QuanlyGiaiDau/docs/skills.md` | Backend feature hoặc migration |
| `HethongFrontEndWeb_QLgiaidau/docs/skills.md` | Frontend feature hoặc UI |
| `docs/technical-notes.md` | Regression, lỗi từng gặp, safety notes |
| `docs/audit-issues-report.md` | Security/quality audit |
| `docs/organizer-refactor-plan.md` | Organizer manage page |
| `graphify-out/GRAPH_REPORT.md` | Architecture recon |
| `docker-compose.yml` | Local/runtime dependency order |
