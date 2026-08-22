# Example — Vertical Slice đăng ký giải đấu

## Mục tiêu

Player xem giải đang mở, chọn division, đăng ký cá nhân hoặc đội, thanh toán nếu giải có phí và thấy trạng thái đăng ký được cập nhật chính xác.

## Phạm vi

**Làm:** đăng ký, kiểm tra capacity, paid/free path, tạo payment pending, nhận webhook backend, cập nhật paid state, hiển thị trạng thái.

**Chưa làm:** payout organizer, refund tự động nâng cao, invite doubles phức tạp và thông báo marketing.

## Luồng chính

```text
Player mở tournament detail
  → chọn division
  → Frontend tải registration status
  → submit registration
  → Backend auth + ownership + capacity lock
  → free: participant confirmed
  → paid: payment PENDING
  → checkout
  → gateway webhook vào Backend
  → verify signature/idempotency
  → transaction update payment + participant + audit
  → Frontend reload hoặc nhận event
```

## Database impact

| Bảng | Thay đổi |
|---|---|
| `tournament_participants` | Tạo participant, lưu division và paid state |
| `payments` | Tạo payment pending cho entry fee |
| `payment_status_logs` | Ghi mọi status transition |
| `audit_logs` | Ghi thao tác quan trọng nếu policy yêu cầu |

## API contract rút gọn

| Method | Endpoint | Quyền | Kết quả |
|---|---|---|---|
| GET | `/tournaments/:id/divisions/:divisionId/registration` | Public/private theo policy | Registration status |
| POST | `/tournaments/:id/divisions/:divisionId/register` | Auth player | Participant hoặc payment pending |
| POST | `/payments/webhook` | Gateway signature | Payment state transition |
| GET | `/payments/:paymentId` | Owner/admin | Payment status |

## Backend checks

1. Verify tournament/division tồn tại và đang nhận đăng ký.
2. Verify player có đủ điều kiện và chưa đăng ký trùng.
3. Lock resource/capacity trong transaction nếu cần.
4. Nếu entry fee bằng 0, xác nhận registration theo free path.
5. Nếu entry fee lớn hơn 0, tạo payment `PENDING` và không đánh dấu paid.
6. Webhook verify signature và idempotency reference.
7. Transaction update payment, participant paid state, fee và status log.

## Frontend checks

1. `divisionId` lấy từ division đang chọn, không lấy nhầm tournament ID.
2. Zod schema khớp DTO backend và trim input.
3. Hiển thị loading/empty/error/success.
4. Paid path redirect đến checkout; free path không redirect nhầm.
5. Không gọi webhook từ browser.
6. 401 đi qua Axios refresh; 403 dùng toast; 409 reload trạng thái đăng ký.

## Test matrix

| Case | Expected |
|---|---|
| Free tournament | Participant confirmed, không tạo payment |
| Paid tournament | Payment pending, chưa confirmed paid |
| Webhook success | Payment successful, participant paid |
| Webhook duplicate | Không tạo log/update lần hai |
| Full capacity | 409, không thêm participant |
| Concurrent last slot | Chỉ một request thành công |
| Wrong division ID | 404/400 phù hợp, không ghi sai division |
| Unauthenticated | 401 |
| Wrong role/ownership | 403 |
| Gateway failure | Payment failed, participant chưa paid |

## Definition of Done

- [ ] Schema/API contract đã review.
- [ ] Capacity và duplicate registration có transaction/constraint phù hợp.
- [ ] Paid/free path được test riêng.
- [ ] Webhook chỉ chạy ở backend.
- [ ] Idempotency và audit trail hoạt động.
- [ ] Frontend mapping đúng division ID.
- [ ] Unit/API/E2E pass.
- [ ] Docs, changelog và Graphify cập nhật nếu thay đổi lớn.
