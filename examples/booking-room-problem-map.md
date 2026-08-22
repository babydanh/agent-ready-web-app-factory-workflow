# Example — Booking Room dùng Problem Catalog

**Feature:** Đặt phòng họp 09:00–10:00  
**Domain:** Booking/reservation  
**Risk tier:** HighRisk  
**Applied cards:** P-02, P-04, P-06, P-07, P-08, P-09, P-10, P-12, P-14, P-15, P-19, P-20, P-21

## 1. Product outcome

Người dùng muốn đặt một phòng còn trống trong một khoảng thời gian. Hệ thống phải đảm bảo không có hai booking active trùng phòng và thời gian, đồng thời người dùng nhìn thấy kết quả rõ ràng nếu phòng vừa bị người khác đặt.

Out-of-scope của change này là recurring booking, thanh toán, external calendar sync hai chiều và automatic room recommendation.

## 2. Domain model và invariant

| Entity | Important fields | Rule |
|---|---|---|
| `rooms` | `id`, `tenantId`, `name`, `capacity`, `status` | Room thuộc đúng tenant và chỉ active room được đặt |
| `bookings` | `id`, `tenantId`, `roomId`, `userId`, `startsAt`, `endsAt`, `status`, `idempotencyKey` | `startsAt < endsAt`; booking active không được overlap cùng room |
| `booking_events` | `eventId`, `bookingId`, `version`, `type` | Mỗi domain event có identity duy nhất |

Source of truth là PostgreSQL. Redis chỉ dùng làm cache danh sách phòng hoặc distributed coordination nếu có lý do; không dùng Redis counter làm invariant duy nhất.

Invariant cốt lõi là: cùng một `tenantId` và `roomId`, không có hai booking ở trạng thái active/pending có thời gian overlap. Invariant phải được enforce ở database bằng exclusion constraint hoặc transaction/lock phù hợp với khả năng của schema; service check trước không đủ chống race.

## 3. API contract

```text
POST /api/v1/rooms/{roomId}/bookings
Headers:
  Authorization: required
  Idempotency-Key: required
Body:
  { "startsAt": "2026-09-01T09:00:00Z", "endsAt": "2026-09-01T10:00:00Z", "purpose": "Team meeting" }
```

Success trả canonical success envelope chứa booking projection, không trả raw database row. Cùng idempotency key và cùng payload trả lại kết quả đã lưu; cùng key khác payload trả `409`. Nếu booking bị người khác tạo trong lúc transaction, trả `409` với Problem Details type ổn định như `booking-conflict`, không trả stack/provider detail.

Các error chính là `401` khi thiếu session, `403` khi room không thuộc scope, `404` theo not-found policy, `409` khi conflict/duplicate, `422` khi time range invalid và `429` khi abuse/booking limit.

## 4. Transaction/concurrency design

```text
authorize user + tenant + room
  → validate time range
  → begin transaction
  → acquire lock/constraint path for room/time range
  → check active overlap
  → insert booking with unique idempotency identity
  → insert outbox event
  → commit
  → send notification/realtime update asynchronously
```

Không gọi email hoặc external calendar provider trong transaction. Nếu client timeout sau commit, retry bằng idempotency key phải replay booking. Nếu notification fail, booking vẫn có state `CONFIRMED` và notification có delivery state riêng để retry/DLQ.

## 5. Failure matrix

| Failure | Expected behavior | Test |
|---|---|---|
| Hai user đặt cùng thời gian | Một thành công, một `409`; invariant không vỡ | `BOOK-CONC-001` |
| Double-click cùng user | Một booking, response replay | `BOOK-IDEM-001` |
| Cùng key khác payload | `409` parameter mismatch; không mutation mới | `BOOK-IDEM-002` |
| Room bị archive trong lúc request | Transaction recheck state; reject | `BOOK-STATE-001` |
| DB deadlock/serialization | Bounded retry nếu safe; không gửi notification hai lần | `BOOK-TX-001` |
| Notification provider timeout | Booking không rollback; outbox retry/DLQ | `BOOK-OUTBOX-001` |
| Cross-tenant room ID | Không lộ data; 403/404 theo policy | `BOOK-AUTHZ-001` |
| User refresh khi realtime event đang gửi | Query/reconnect resync hiển thị đúng booking | `BOOK-RT-001` |
| Export booking report | Scope theo tenant; async nếu lớn; URL expiry | `BOOK-EXPORT-001` |

## 6. UI state mapping

| State | UI behavior |
|---|---|
| Initial | Hiển thị room/date/time picker và policy |
| Loading | Disable submit và show progress; không tạo duplicate request |
| Success | Hiển thị booking ID, thời gian, cancel policy và next action |
| `409` | Thông báo phòng vừa có người đặt; cho chọn giờ/phòng khác |
| `401/403` | Redirect/login hoặc giải thích permission; không mất form ngoài policy |
| `422` | Đánh dấu field time range/purpose bằng field-level errors |
| `429` | Hiển thị retry-after friendly message; không auto-loop |
| Offline/stale | Cho refresh/recheck availability trước khi submit |

## 7. Security/privacy/operations

Room listing, booking details và export đều phải có tenant/object authorization. Purpose có thể chứa PII hoặc confidential information; log chỉ ghi booking ID, tenant hash, actor hash và outcome, không ghi nội dung tự do nếu không cần.

Metrics gồm booking attempt/success/conflict, transaction latency, idempotency replay, outbox age, notification failure và availability query latency. Trace phải nối HTTP request → database transaction → outbox worker → provider call. Runbook cần có cách reconcile booking/outbox khi provider hoặc worker chết.

## 8. Release evidence

Release chỉ được GO khi có migration/constraint review, concurrent test pass, idempotency/authorization negative tests, API fixture validation, UI `409/401/403/422/429/offline` evidence, outbox retry evidence, readiness/smoke check và rollback note. Nếu chưa có database-level overlap enforcement, decision phải là `HOLD` hoặc `GO_WITH_CONDITIONS` với owner và expiry, không đánh dấu pass bằng service check đơn thuần.

## 9. Lessons

Feature booking không phải chỉ là `POST booking`. Bài toán thực sự là time zone, overlap invariant, concurrency, retry, authorization, notification eventual consistency, realtime resync, report scope và operational repair. Đây chính là lý do workflow cần problem catalog thay vì chỉ có CRUD template.
