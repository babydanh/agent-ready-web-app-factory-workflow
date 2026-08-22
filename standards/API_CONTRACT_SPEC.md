# Canonical API Contract Specification

## 1. Mục tiêu

Mọi HTTP endpoint phải có một contract duy nhất được viết trước code. Contract là agreement giữa backend, frontend, mobile, worker, AI Agent, test và tài liệu. Không chấp nhận việc controller trả mỗi module một format khác nhau.

Dự án hiện có success shape gần với:

```ts
interface Response<T> {
  data: T;
  message?: string;
  statusCode: number;
  meta?: Record<string, unknown>;
}
```

Contract mới giữ tương thích ý tưởng này nhưng bắt buộc schema và semantics rõ ràng.

## 2. Success envelope

```json
{
  "statusCode": 200,
  "message": "Tải dữ liệu thành công.",
  "data": {
    "id": "8c5e3b98-8d18-4eb1-bb9e-2e55a4c7c3bb",
    "name": "Giải Sporto Open"
  },
  "meta": {
    "requestId": "req_01J...",
    "dataAsOf": "2026-08-22T10:00:00.000Z"
  }
}
```

Quy tắc:

| Field | Bắt buộc | Quy tắc |
|---|---:|---|
| `statusCode` | Có | Trùng HTTP status; integer 200–299 cho success |
| `message` | Có | Human-readable, localization ở client theo key khi cần |
| `data` | Có | Object/array/null theo schema endpoint |
| `meta` | Tùy endpoint | Không chứa secrets; dùng cho pagination, request ID, version, freshness |

`data` không được lúc là raw array, lúc là `{ data: array }` trong cùng loại endpoint. List dùng `{ items, meta }` bên trong `data` hoặc một convention duy nhất do API version chọn; pack này khuyến nghị `data.items` cho list.

## 3. Error envelope — RFC 9457-compatible

Error phải trả `Content-Type: application/problem+json` khi client yêu cầu hoặc mặc định ở API v2. Shape chuẩn:

```json
{
  "type": "https://api.sporto.asia/problems/validation-error",
  "title": "Request validation failed",
  "status": 400,
  "detail": "Một hoặc nhiều trường không hợp lệ.",
  "instance": "/api/v1/tournaments",
  "code": "VALIDATION_ERROR",
  "requestId": "req_01J...",
  "errors": [
    {
      "pointer": "/name",
      "code": "REQUIRED",
      "message": "Tên giải đấu không được để trống."
    }
  ]
}
```

RFC 9457 định nghĩa problem detail cho HTTP API và obsoletes RFC 7807; `type`, `status`, `title`, `detail`, `instance` là các member chuẩn, còn `code`, `requestId`, `errors` là extension có schema của hệ thống.[1]

Quy tắc security:

- `detail` hướng dẫn client sửa request, không chứa stack trace, SQL, provider error, secret hoặc internal hostname.
- `requestId` dùng để tìm log; không phải authorization token.
- `code` ổn định, machine-readable, không dùng câu tiếng Việt làm condition.
- `errors[].pointer` dùng JSON Pointer hoặc field path đã document.
- 401, 403, 404 không được tiết lộ quá mức sự tồn tại của resource nhạy cảm.
- 409 dành cho state/concurrency conflict; 422 cho semantic validation nếu team chọn dùng; phải thống nhất toàn API.

## 4. HTTP semantics

| Tình huống | Method/status khuyến nghị |
|---|---|
| Tạo resource | `POST` → `201`, trả resource/projection |
| Tạo command async | `POST` → `202`, trả operation ID |
| Đọc resource | `GET` → `200` |
| Cập nhật thay thế | `PUT` → `200` hoặc `204` |
| Cập nhật một phần | `PATCH` → `200` |
| Xóa thành công | `DELETE` → `204` hoặc tombstone response |
| Không có quyền | `403` hoặc privacy-preserving `404` |
| Conflict state/version | `409` |
| Rate limit | `429` + `Retry-After` |
| Lỗi server | `500`/`503`, detail generic |

Không trả HTTP 200 cho business failure. Không dùng `POST` để đọc dữ liệu chỉ vì query dài nếu không có lý do đã ghi ADR.

## 5. Request contract

Mỗi endpoint spec phải khai báo:

```yaml
operationId: Tournament_create
method: POST
path: /api/v1/tournaments
auth:
  required: true
  roles: [ORGANIZER]
  ownership: none
csrf: required-for-cookie-client
rateLimit: tournament-create
idempotency: required
request:
  contentType: application/json
  schema: CreateTournamentRequest
responses:
  '201': TournamentResponse
  '400': ProblemValidation
  '401': ProblemUnauthenticated
  '403': ProblemForbidden
  '409': ProblemStateConflict
  '429': ProblemRateLimited
```

Request schema phải có `additionalProperties: false` cho payload nhạy cảm nếu không có lý do mở rộng. Backend validate lại toàn bộ input; TypeScript type ở frontend chỉ hỗ trợ developer, không phải security boundary.

## 6. API versioning và compatibility

API version nằm trong base path hoặc media type; dự án hiện dùng `/api/v1`. Breaking change gồm đổi field type, đổi semantics, xóa field, đổi status/error code, đổi permission hoặc đổi pagination. Mỗi breaking change phải có ADR, migration plan, dual-read/dual-write nếu cần, deprecation window và consumer inventory.

OpenAPI 3.1 có alignment với JSON Schema 2020-12, nên là baseline phù hợp khi toolchain validator/code generator tương thích.[2] Contract phải được validate trong CI và diff phải phân loại breaking/non-breaking.

## 7. Idempotency và concurrency

Các command tạo payment, registration, invite, payout, webhook hoặc job phải nêu rõ idempotency key. Key được scope theo actor + operation + resource; server lưu kết quả hoặc state đủ lâu để retry an toàn. Duplicate request trả cùng semantics, không tạo side effect thứ hai.

Các mutation có optimistic concurrency phải nhận `expectedRevision` hoặc `If-Match`/ETag; conflict trả 409 với code ổn định và state hiện tại tối thiểu cần thiết. Không giải quyết race bằng cách retry mù ở client.

## 8. Pagination/filter/sort contract

```json
{
  "statusCode": 200,
  "message": "Tải danh sách thành công.",
  "data": {
    "items": [],
    "meta": {
      "page": 1,
      "limit": 20,
      "total": 0,
      "totalPages": 0,
      "hasMore": false,
      "nextCursor": null
    }
  }
}
```

Các filter/sort field phải nằm trong allowlist. API phải trả cùng tên field cho mọi locale; label dịch ở UI. Không trả toàn bộ database row. Query có thể trả `fields`/projection đã khai báo nhưng không cho client tự đọc sensitive field.

## 9. Realtime/event contract

Socket event phải có version, event name, entity ID, `occurredAt`, `sequence` hoặc revision, actor scope và correlation ID:

```json
{
  "event": "match.score.updated.v1",
  "matchId": "uuid",
  "revision": 18,
  "occurredAt": "2026-08-22T10:00:00.000Z",
  "data": { "p1SetsWon": 2, "p2SetsWon": 1 },
  "requestId": "req_01J..."
}
```

Client phải biết khi nào event có thể drop và khi nào phải resync bằng GET. Event không được coi là source of truth thay cho database.

## 10. Contract enforcement

| Gate | Cách kiểm tra |
|---|---|
| Schema | OpenAPI/JSON Schema validate request/response fixtures |
| Type | Generate hoặc diff type với frontend client |
| Error | Contract test status/code/content-type/detail redaction |
| Permission | Endpoint policy matrix + negative tests |
| Compatibility | OpenAPI breaking-change diff |
| Runtime | Sampled response validation ở non-production |
| Docs | Swagger/Scalar khớp endpoint thực tế |
| Observability | Request ID và operationId xuất hiện trong log/trace |

## References

[1]: [RFC 9457 — Problem Details for HTTP APIs](https://www.rfc-editor.org/info/rfc9457/)  
[2]: [OpenAPI Specification 3.1.0 release](https://www.openapis.org/blog/2021/02/18/openapi-specification-3-1-released)  
[3]: [JSON Schema — Validating OpenAPI and JSON Schema](https://json-schema.org/blog/posts/validating-openapi-and-json-schema)
