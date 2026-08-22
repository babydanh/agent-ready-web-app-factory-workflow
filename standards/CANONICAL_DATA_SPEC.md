# Canonical Data Specification

## 1. Mục tiêu

Tài liệu này định nghĩa cách biểu diễn dữ liệu thống nhất giữa database, NestJS DTO/service/repository, OpenAPI, Next.js types, realtime event, queue payload và AI tool. Một field chỉ được coi là hoàn thành khi có **định nghĩa nghiệp vụ, kiểu dữ liệu, nullability, validation, serialization, privacy class và test**.

## 2. Quy tắc naming

| Ngữ cảnh | Quy tắc | Ví dụ |
|---|---|---|
| Database column | `snake_case` | `created_at`, `tournament_id` |
| Backend TypeScript | `camelCase` | `createdAt`, `tournamentId` |
| JSON/API | `camelCase`, không viết tắt tùy ý | `providerOrderCode` |
| Enum value | `UPPER_SNAKE_CASE`, ổn định | `REGISTRATION_CLOSED` |
| Boolean | Bắt đầu bằng `is`, `has`, `can`, `should` | `isPaid`, `hasNextPage` |
| ID | Hậu tố `Id` và UUID string | `tournamentId: string` |
| Timestamp | Hậu tố `At`, ISO 8601 UTC | `createdAt: "2026-08-22T10:00:00.000Z"` |
| Date-only | Hậu tố `Date`, `YYYY-MM-DD` | `scheduledDate: "2026-08-22"` |
| URL | Hậu tố `Url`, URL absolute đã validate | `bannerUrl` |
| Money | Không dùng floating point trong domain; API string decimal | `amount: "150000.00"` |
| Count | Số nguyên không âm | `total: 42` |

Không dùng cùng một field cho hai nghĩa. `status` của payment, participant, match và tournament phải là các enum registry khác nhau, không dùng enum tổng quát.

## 3. ID, thời gian và tiền

ID public nên là UUID v4/v7 string hoặc một opaque identifier; không expose sequence nội bộ nếu resource có yêu cầu chống enumeration. DTO phải validate UUID/opaque format trước khi gọi service.

Timestamp phải serialize ISO 8601 có timezone và canonical UTC. Backend lưu `timestamptz`; frontend parse bằng thư viện date có timezone rõ ràng. Không dùng `new Date().toLocaleString()` trong payload API, chỉ dùng ở presentation layer.

Money phải được tính bằng decimal hoặc integer minor unit theo currency. Với VND có thể dùng integer đồng trong domain; nếu dùng PostgreSQL `numeric(12,2)` thì API trả string để tránh mất precision qua JavaScript number. Mọi amount phải có currency và check `>= 0` hoặc `> 0` theo nghiệp vụ.

```json
{
  "amount": "150000.00",
  "currency": "VND"
}
```

## 4. Nullability và field presence

| Tình huống | Quy ước |
|---|---|
| Field luôn tồn tại, có giá trị | Required, non-null |
| Field luôn tồn tại nhưng có thể rỗng | Required nullable, trả `null` |
| Field chỉ xuất hiện theo capability/permission | Optional by projection, phải ghi rõ |
| Field không áp dụng | Trả `null`, không đổi sang empty string |
| Request field không gửi | Optional; server áp dụng default đã document |
| Request muốn xóa giá trị | Dùng `null` nếu contract cho phép; không dùng empty string tùy ý |

Không để frontend suy luận `undefined`, `null`, `[]`, `{}` và `""` là tương đương. Contract phải chỉ rõ từng field.

## 5. Enum và state machine

Mỗi enum phải có registry:

```ts
export const TournamentStatus = {
  DRAFT: 'DRAFT',
  UPCOMING: 'UPCOMING',
  REGISTRATION_OPEN: 'REGISTRATION_OPEN',
  REGISTRATION_CLOSED: 'REGISTRATION_CLOSED',
  IN_PROGRESS: 'IN_PROGRESS',
  COMPLETED: 'COMPLETED',
  CANCELLED: 'CANCELLED',
} as const;
```

Registry phải có label i18n, mô tả, transition hợp lệ, actor được phép chuyển, side effect, HTTP error code và test. Không map label tiếng Việt thành business state. UI chỉ hiển thị label từ message key; API chỉ trao đổi enum value.

Một transition cần mô tả:

```text
subject: tournament
from: REGISTRATION_OPEN
command: closeRegistration
actor: organizer | admin
preconditions: now >= registrationEndDate OR actor has override permission
sideEffects: freezeRoster, emit TournamentRegistrationClosed
idempotency: same command returns current state
failure: TOURNAMENT_STATE_CONFLICT / TOURNAMENT_NOT_OWNER
```

## 6. Pagination, filtering và sorting

Mọi list endpoint phải công bố một kiểu pagination duy nhất trong một bounded context. Chuẩn mặc định của pack là page/limit cho màn hình quản trị và cursor cho feed lớn.

```json
{
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
```

`page` bắt đầu từ 1; `limit` có min/max; sorting phải whitelist field và direction; filter phải có grammar/schema; không nối trực tiếp tên column từ query string vào SQL. Cursor phải opaque, có expiry nếu cần và ổn định khi dữ liệu thay đổi.

## 7. Privacy classification

| Class | Ví dụ | Quy tắc |
|---|---|---|
| PUBLIC | tournament name, public schedule | Có thể trả public nếu visibility cho phép |
| INTERNAL | moderation note, operational IDs | Chỉ staff/owner |
| PERSONAL | email, phone, address, profile | Minimize, authorize, redact log |
| SENSITIVE | password hash, refresh token, bank account, provider token | Không trả API; encrypt/hash/tokenize |
| FINANCIAL | payment, ledger, payout amount | Scope theo owner/admin/audit |

Serializer phải dùng projection allowlist, không trả nguyên row database từ controller. Nếu quyền thay đổi, response projection cũng phải thay đổi rõ ràng và có contract test.

## 8. Canonical data flow

```text
Input JSON
→ DTO/schema validation
→ Normalize (trim, Unicode, timezone, decimal)
→ Authorization + ownership
→ Domain command
→ Transaction / outbox
→ Persistence
→ Response serializer/projection
→ OpenAPI schema validation
→ Frontend typed client
```

AI output cũng đi qua cùng serializer/schema; không coi JSON do model trả về là trusted data. Rich text, URL, filename, custom responses và form schema phải được sanitize/validate ở server.

## 9. Data contract checklist

| Gate | Câu hỏi bắt buộc |
|---|---|
| Identity | ID có opaque/UUID và validate đúng không? |
| Time | Date/time có timezone và format duy nhất không? |
| Money | Có precision/currency/check không? |
| Nullability | Client biết khi nào `null`, optional, empty array không? |
| Enum | Có registry, label i18n và transition không? |
| Privacy | Field có class và projection theo actor không? |
| Integrity | FK, unique, check, transaction và idempotency đã có chưa? |
| Compatibility | Thay đổi có backward-compatible hoặc version/ADR không? |
| Test | Có positive, negative, boundary và serialization test không? |

## References

[1]: [OpenAPI Specification 3.1.0 release](https://www.openapis.org/blog/2021/02/18/openapi-specification-3-1-released)  
[2]: [JSON Schema — Validating OpenAPI and JSON Schema](https://json-schema.org/blog/posts/validating-openapi-and-json-schema)  
[3]: [PostgreSQL Transaction Isolation](https://www.postgresql.org/docs/current/transaction-iso.html)
