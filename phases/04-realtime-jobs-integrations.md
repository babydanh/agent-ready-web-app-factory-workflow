# Phase 04 — Realtime, Jobs và External Integrations

## Mục tiêu

Tích hợp các hệ thống có failure mode riêng mà không làm hỏng source of truth. Mọi external side effect phải có timeout, retry policy, idempotency, audit và cách manual recovery.

## Realtime

Socket.IO đảm bảo ordering nhưng mặc định at-most-once. Với live score, backend phải persist mutation trước, sau đó emit event có `eventId`, `matchId`, `version` hoặc `sequence`. Client reconnect phải resync snapshot từ API hoặc replay event từ offset; không coi socket broadcast là dữ liệu duy nhất.

## Background jobs

Dùng Redis/BullMQ cho email, notification, scheduled tournament tasks, AI processing, image processing và webhook follow-up. Job cần payload nhỏ, idempotency key, attempts, backoff, timeout, concurrency limit và failed-job handling. Retry lỗi network/provider tạm thời; không retry validation, permission hoặc signature invalid.

## Payment

Tách payment link/return UI khỏi webhook backend. Return URL chỉ là UX signal; trạng thái thanh toán chính thức đến từ backend verification. Verify HMAC/signature, đối chiếu order/amount/owner, chống duplicate và update payment/participant/audit trong transaction. Không đưa checksum key vào client hoặc log.

## Storage/upload

API kiểm tra MIME/type/size/quota và quyền trước khi upload. Lưu metadata/URL/reference ở DB; blob ở Cloudinary/S3. Thiết kế delete/retention, private/public access, resize/transform và cleanup file orphan.

## AI

AI gọi qua server-side adapter. Structured prompt tách instruction khỏi user data; input có giới hạn và sanitize; output parse theo schema rồi validate policy. Tool của agent phải allowlist theo role. Tác vụ ảnh hưởng payment, admin, delete hoặc bracket cần deterministic check và human approval.

## Gate

- [ ] Event có persistence/resync strategy.
- [ ] Worker có timeout/retry/backoff/idempotency.
- [ ] Payment signature/amount/order/status test pass.
- [ ] Upload có validation và access control.
- [ ] AI output có schema/policy validation và budget.
- [ ] External integration failure không làm mất transaction intent.
- [ ] Logs có correlation ID nhưng không lộ token/secret/private payload.
