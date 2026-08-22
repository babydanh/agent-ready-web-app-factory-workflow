# CHECKLIST — Quality Gates cho Web App Factory

## Gate 0 — Intake

- [ ] Tên sản phẩm và vấn đề được mô tả rõ.
- [ ] Persona, vai trò và quyền cơ bản đã xác định.
- [ ] MVP, phase sau và out-of-scope đã tách riêng.
- [ ] Luồng thành công và luồng lỗi đã ghi.
- [ ] Acceptance criteria có thể kiểm thử.
- [ ] Open questions được ghi và có người chịu trách nhiệm trả lời.

## Gate 1 — Codebase Recon

- [ ] Đã kiểm tra Git status và commit baseline.
- [ ] Đã đọc README, current status và skill map liên quan.
- [ ] Đã tham chiếu Graphify report.
- [ ] Đã tạo impact map.
- [ ] Đã xác định file được phép sửa và file cần tránh.
- [ ] Đã ghi các rủi ro regression.

## Gate 2 — Design

- [ ] Entity, quan hệ và state machine đã chốt.
- [ ] API contract có request, response, lỗi và permission.
- [ ] DTO backend và schema validation frontend khớp nhau.
- [ ] Pagination, filter, sort và empty behavior đã xác định.
- [ ] Realtime room/event/payload đã xác định nếu có.
- [ ] Idempotency, transaction và audit trail đã xác định cho nghiệp vụ nhạy cảm.

## Gate 3 — Environment

- [ ] Node và pnpm version đã chốt.
- [ ] Database image/version đã chốt.
- [ ] Redis hoạt động.
- [ ] `.env.example` không chứa secret thật.
- [ ] Migration chạy trên database sạch.
- [ ] Backend health endpoint hoạt động.
- [ ] Swagger/API docs mở được.
- [ ] Frontend gọi đúng API URL và CORS hợp lệ.

## Gate 4 — Backend

- [ ] Module/controller/service/repository đúng boundary.
- [ ] DTO và validation đầy đủ.
- [ ] Guard/auth/role ownership được kiểm tra ở backend.
- [ ] Response không lộ secret hoặc password hash.
- [ ] Transaction và row lock dùng đúng nơi.
- [ ] Status transition không cho phép chuyển sai.
- [ ] Migration đã review và backend đã restart.
- [ ] Unit/integration test pass.

## Gate 5 — Frontend

- [ ] Route và layout đúng App Router.
- [ ] Type mapping khớp API contract.
- [ ] Không dùng `any` hoặc URL API hardcode trong component.
- [ ] Logic API/state nằm ở layer phù hợp.
- [ ] Form dùng RHF + Zod và trim input.
- [ ] Có loading, error, empty, success state.
- [ ] Permission/route guard hoạt động.
- [ ] Responsive và accessibility cơ bản đạt.
- [ ] Socket listener được cleanup nếu có.

## Gate 6 — QA/Security

- [ ] Happy path pass.
- [ ] Validation error pass.
- [ ] Permission denied pass.
- [ ] Not found và conflict pass.
- [ ] Retry/reconnect pass nếu có realtime.
- [ ] Webhook signature/idempotency pass nếu có payment.
- [ ] Race condition quan trọng đã được test.
- [ ] Token replay, rate limit, CORS, upload và secret leak đã rà.
- [ ] E2E journey chính pass.

## Gate 7 — Release

- [ ] Lint pass.
- [ ] Type-check/build pass.
- [ ] Unit/integration/E2E pass hoặc known exception đã được phê duyệt.
- [ ] Staging smoke test pass.
- [ ] Migration/deploy order đã ghi.
- [ ] Backup và rollback plan đã có.
- [ ] Health check, log và monitoring hoạt động.
- [ ] Changelog và release note đã cập nhật.
- [ ] Graphify đã cập nhật sau thay đổi lớn.
- [ ] Handoff checklist đã hoàn tất.

## Lệnh validation mẫu

```bash
# Backend
pnpm lint
pnpm test
pnpm test:e2e
pnpm build

# Frontend
pnpm lint
pnpm i18n:check
pnpm build

# Repository
 git diff --check
```

> Nếu lệnh không tồn tại trong package hiện tại, không tự sửa package script để che lỗi. Ghi `NOT_AVAILABLE` vào evidence và tạo issue bổ sung.
