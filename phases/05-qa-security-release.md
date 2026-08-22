# Phase 05 — QA, Security, Observability và Release

## Mục tiêu

Chứng minh hệ thống đúng về nghiệp vụ, an toàn, có thể quan sát và có thể rollback. “Build pass” chỉ là một phần của gate.

## Test layers

| Layer | Nội dung |
|---|---|
| Unit | Domain rules, ELO, bracket, fee, parser, state transition |
| Integration/API | DTO, guards, ownership, repository, transaction, webhook |
| Contract | API response/type/event payload giữa backend và frontend |
| E2E | User-visible journeys bằng isolated fixtures và stable locators |
| Concurrency | Last slot, duplicate webhook, ELO update, conflicting writes |
| Security | ASVS subset, IDOR, RBAC, token/session, upload, CORS, secret |
| Operational | Migration, health, retry, reconnect, queue failure, rollback |

Playwright nên test user-visible behavior, dùng isolated tests, locator có auto-wait và web-first assertions; CI nên lưu trace khi fail.

## Security verification

Chọn ASVS controls theo risk. Tối thiểu phải kiểm tra auth/session termination, RBAC/ownership, input validation, injection, CSRF strategy nếu cookie, secure headers, secret handling, upload, rate limit, audit và webhook signature. Không đưa security thành một checklist cuối release; mỗi feature cần threat notes từ design.

## Observability

Instrument HTTP request, database boundary, worker/job, external provider và realtime connection. Log structured với request/correlation ID; metric request rate/error/latency, queue depth/job failure, DB pool; trace nối API → DB/queue/provider. Không log access token, password, checksum key hoặc private prompt.

## CI/CD

```text
PR
  → install lockfile
  → lint/typecheck
  → unit/integration
  → dependency/security scan
  → build
  → E2E/staging
  → review approval
  → controlled migration
  → deploy
  → health/smoke
  → monitor/rollback
```

Tách secret deploy khỏi PR jobs. Pin action/image versions theo policy. Production migration phải có compatibility và backup.

## Release gate

- [ ] Acceptance criteria pass.
- [ ] P0/P1 issue đã đóng hoặc có phê duyệt rõ.
- [ ] Migration/backup/rollback đã review.
- [ ] Health check và smoke test pass.
- [ ] Log, metrics, trace và alert đủ cho critical path.
- [ ] Changelog, runbook, Graphify và handoff cập nhật.

## Handoff

Người khác phải có thể clone, cấu hình, chạy local, chạy test, deploy staging, kiểm tra health, xem log, rollback và tiếp quản known issues mà không cần hỏi người viết ban đầu.
