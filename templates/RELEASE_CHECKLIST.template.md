# Release Checklist — [Version/Release]

## 1. Release metadata

| Trường | Giá trị |
|---|---|
| Version | [vX.Y.Z] |
| Date | [YYYY-MM-DD] |
| Owner | [Tên] |
| Environment | Staging / Production |
| Commit | [SHA] |
| Migration | [Tên migration hoặc none] |

## 2. Before deploy

- [ ] PR đã được review.
- [ ] Changelog/release notes đã cập nhật.
- [ ] Lint, type-check, build và test pass.
- [ ] Acceptance criteria pass.
- [ ] Security findings P0/P1 đã đóng hoặc được phê duyệt.
- [ ] `.env`/secret dùng đúng environment và không nằm trong commit.
- [ ] Backup đã hoàn tất và kiểm tra khả năng restore.
- [ ] Migration order và compatibility đã review.
- [ ] Rollback/forward-fix plan đã ghi.

## 3. Deployment order

```text
Backup
  → Database migration
  → Backend deploy
  → Health check
  → Frontend deploy
  → Smoke test
  → Monitor
```

**Lưu ý:** Với Compose hiện tại, database và Redis phải healthy trước migration; migration thành công trước backend; backend sẵn sàng trước frontend.

## 4. Smoke tests

- [ ] `GET /health` trả về trạng thái healthy.
- [ ] Login/register hoạt động.
- [ ] Route public mở được.
- [ ] Route private và role guard hoạt động.
- [ ] Tạo/đọc/cập nhật một resource mẫu.
- [ ] Realtime event hoạt động nếu có.
- [ ] Upload hoạt động nếu có.
- [ ] Payment sandbox/webhook hoạt động nếu có.
- [ ] Log không có error bất thường.

## 5. Rollback

**Trigger rollback:** [Điều kiện]

**Application rollback:** [Image/commit/version]

**Database rollback:** [Rollback migration hoặc forward fix]

**Data recovery:** [Backup/restore procedure]

**Owner:** [Tên]

## 6. Post-deploy

- [ ] Theo dõi log và health trong [x] phút.
- [ ] Kiểm tra error rate và latency.
- [ ] Cập nhật `project-state.json`.
- [ ] Cập nhật Graphify nếu cấu trúc thay đổi.
- [ ] Ghi known issues.
- [ ] Gửi handoff/release note.

## 7. Sign-off

| Vai trò | Người | Kết quả | Thời gian |
|---|---|---|---|
| Product | [Name] | PASS/BLOCK | [Date] |
| QA | [Name] | PASS/BLOCK | [Date] |
| Security | [Name] | PASS/BLOCK | [Date] |
| DevOps | [Name] | PASS/BLOCK | [Date] |
