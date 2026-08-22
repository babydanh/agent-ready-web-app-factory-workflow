# Database Design — [Tên feature]

## 1. Entities

| Table | Purpose | Primary key | Soft delete | Audit |
|---|---|---|---:|---:|
| `[table]` | [Purpose] | UUID | Yes/No | Yes/No |

## 2. Columns

| Table | Column | Type | Null | Default | Constraint | Index |
|---|---|---|---:|---|---|---|
| `[table]` | `[column]` | [Type] | Yes/No | [Default] | [Rule] | [Index] |

## 3. Relations

| From | Relation | To | On delete/update |
|---|---|---|---|
| `[table]` | 1:N / N:M | `[table]` | [Behavior] |

## 4. State and constraints

```text
[STATE_A] → [STATE_B] → [STATE_C]
```

- [ ] Enum/status chỉ có một nguồn định nghĩa.
- [ ] CHECK constraint cho giá trị số, amount hoặc boundary.
- [ ] UNIQUE constraint cho dữ liệu không được trùng.
- [ ] FK và self-reference đã kiểm tra.
- [ ] `deleted_at` và filter soft delete đã xác định.
- [ ] Index phục vụ query thật, không tạo index tùy tiện.

## 5. Migration plan

1. [Tạo/sửa schema]
2. [Generate migration]
3. [Review SQL]
4. [Test trên database sạch]
5. [Test migration từ database gần production]
6. [Push/migrate]
7. [Restart backend]
8. [Verify API và dữ liệu]

**Migration compatibility:** [Backward compatible?]

**Rollback:** [Cách rollback hoặc forward fix]

## 6. Transaction and locking

**Transaction boundary:** [Các thao tác phải atomic]

**Lock/version strategy:** [FOR UPDATE, optimistic version, unique key...]

**Idempotency:** [Key/reference và hành vi request lặp]

## 7. Seed and test data

- [ ] Seed data không chứa secret.
- [ ] Có fixture cho happy path.
- [ ] Có fixture cho empty/error/conflict.
- [ ] Có dữ liệu kiểm thử concurrency nếu cần.

## 8. Review checklist

- [ ] Schema type-safe.
- [ ] Relations không tạo cycle ngoài chủ ý.
- [ ] Migration SQL đã đọc.
- [ ] Production data không bị hard delete ngoài chủ ý.
- [ ] Query chính có index phù hợp.
- [ ] API response không phụ thuộc vào dữ liệu seed đặc biệt.
