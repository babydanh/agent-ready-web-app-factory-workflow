# Phase 02 — Database, API và Backend

## Mục tiêu

Xây backend theo domain boundary, type safety và transaction discipline. Backend là nơi kiểm tra input, auth, role, ownership và invariant; frontend không được thay thế các kiểm tra này.

## Implementation order

```text
Domain rules
  → Drizzle schema/relations/indexes/constraints
  → migration + SQL review
  → repository/query
  → service/use case
  → DTO + validation
  → controller + OpenAPI
  → exception mapping
  → unit/integration tests
```

## Module structure

```text
modules/<feature>/
├── <feature>.module.ts
├── <feature>.controller.ts
├── <feature>.service.ts
├── <feature>.repository.ts
├── dto/
├── exceptions/
├── policies/
└── tests/
```

NestJS module encapsulates providers; chỉ export public interface cần dùng module khác. Không biến mọi thứ thành global để tránh coupling.

## Database discipline

Mọi thay đổi đi qua migration. Dùng FK/unique/check/index cho invariant có thể bảo vệ ở DB. Xác định soft delete, audit và retention. Payment, payout, refund, registration cạnh tranh, ELO update và bracket generation cần transaction boundary rõ.

## API discipline

Contract phải có method/path, auth, role, ownership, request/response, status code, pagination, idempotency và error shape. DTO backend và type/schema frontend dùng cùng vocabulary. Status transition phải reject state không hợp lệ.

## Gate

- [ ] Schema và migration đã review.
- [ ] API contract được chốt.
- [ ] Guard/ownership/validation có test.
- [ ] Transaction/lock/idempotency có test khi cần.
- [ ] Swagger/OpenAPI cập nhật.
- [ ] Lint, test và build backend pass.
