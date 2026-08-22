# API Contract — [Tên feature]

## 1. Endpoint summary

| Method | Path | Auth | Roles | Purpose |
|---|---|---|---|---|
| GET | `/api/v1/[resource]` | Yes/No | [Roles] | [Purpose] |
| POST | `/api/v1/[resource]` | Yes/No | [Roles] | [Purpose] |
| PATCH | `/api/v1/[resource]/:id` | Yes | [Roles] | [Purpose] |
| DELETE | `/api/v1/[resource]/:id` | Yes | [Roles] | [Purpose] |

## 2. Request contract

### `POST /api/v1/[resource]`

```json
{
  "field": "value"
}
```

| Field | Type | Required | Constraints | Trim/normalize |
|---|---|---:|---|---|
| `field` | string | Yes | [Min/max/enum] | Yes |

## 3. Response contract

### Success

```json
{
  "data": {},
  "message": "Success",
  "statusCode": 200,
  "meta": {}
}
```

### Error

```json
{
  "statusCode": 400,
  "message": "Validation failed",
  "error": "Bad Request",
  "details": [],
  "timestamp": "2026-01-01T00:00:00.000Z",
  "path": "/api/v1/[resource]"
}
```

## 4. Status and errors

| HTTP | Business condition | Frontend behavior |
|---:|---|---|
| 400 | Payload invalid | Hiển thị lỗi dưới field |
| 401 | Token thiếu/hết hạn | Refresh rồi retry một lần hoặc đưa về login |
| 403 | Không đủ quyền | Toast + giữ nguyên màn hình |
| 404 | Resource không tồn tại | Empty/not-found state |
| 409 | Conflict/duplicate/concurrent update | Hiển thị conflict message và reload dữ liệu |
| 422 | Business validation | Hiển thị hướng dẫn sửa |
| 500 | Unexpected error | Toast tổng quát + log correlation ID |

## 5. Authorization

- [ ] Route public/private đã xác định.
- [ ] Guard xác thực được áp dụng.
- [ ] Role được kiểm tra ở backend.
- [ ] Ownership/resource scope được kiểm tra.
- [ ] Frontend chỉ là lớp UX, không phải lớp bảo mật duy nhất.

## 6. Idempotency and transaction

**Idempotency key/reference:** [Tên field hoặc header nếu cần]

**Transaction boundary:** [Những update nào phải cùng transaction]

**Audit trail:** [Bảng/log cần ghi]

## 7. Frontend mapping

| API field | Frontend type | UI field | Transform |
|---|---|---|---|
| `[field]` | `[Type]` | `[Component]` | `[format/trim]` |

## 8. Contract tests

- [ ] DTO validation.
- [ ] Success response shape.
- [ ] 401/403/404/409 behavior.
- [ ] Pagination/filter/sort nếu có.
- [ ] Idempotency/concurrency nếu có.
- [ ] Frontend type mapping.
