# Domain Rules — Quản lý Giải đấu

## Actors

| Role | Quyền tổng quát |
|---|---|
| `PLAYER` | Xem giải, đăng ký, tham gia trận, xem ELO và cộng đồng |
| `ORGANIZER` | Tạo/quản lý giải, division, lịch, score, payout theo scope |
| `ADMIN` | Duyệt, moderation, dispute, payment, payout và hệ thống |

Role ở frontend chỉ phục vụ UX. Backend luôn là nơi quyết định quyền.

## Tournament lifecycle

```text
DRAFT → OPEN → FULL/LOCKED → IN_PROGRESS → COMPLETED
  ↓         ↓          ↓             ↓
CANCELLED  CLOSED   CANCELLED     CANCELLED
```

Trước khi lock, organizer có thể cấu hình trong phạm vi quyền. Sau khi lock, các thay đổi ảnh hưởng bracket, participant hoặc fee phải có rule riêng, audit và có thể cần admin approval.

## Registration

Đăng ký giải có phí phải tạo payment ở trạng thái `PENDING`; không đánh dấu paid ở frontend và không dùng bypass hardcode. Chỉ sau khi webhook/mock verification được backend xác thực và transaction thành công thì participant mới được đánh dấu đã thanh toán.

Đăng ký ở giới hạn cuối phải dùng transaction và lock phù hợp để không vượt capacity. Doubles registration phải truyền đúng `divisionId`, không lấy nhầm tournament ID thay thế.

## Payment

```text
PENDING → SUCCESSFUL
   ├── FAILED
   ├── EXPIRED
   └── REFUND_PENDING → REFUNDED
```

Webhook phải được xử lý ở backend, verify signature, dùng `transaction_reference`/idempotency và ghi `payment_status_logs`. Payment, participant paid state, fee calculation và audit phải nằm trong transaction phù hợp. Payout cần quy trình organizer request → admin review → approved/rejected → paid/failed.

## Match and score

Match đi từ scheduled đến in progress rồi completed hoặc cancelled. Score update phải kiểm tra quyền, trạng thái trận và người chơi thực tế. Khi hoàn tất, event có thể kích hoạt ELO và broadcast realtime; các thao tác này phải tránh double processing.

## Bracket

Round robin tạo lịch và standings; single elimination dùng `next_match_id`; double elimination cần `loser_next_match_id`. BYE không được đẩy một winner `null` vào trận tiếp theo. Seeding và stage transition phải xác định trước khi generate. Regenerate bracket phải tuân thủ soft delete/audit, không xóa mù dữ liệu production.

## ELO

ELO chỉ cập nhật cho match hợp lệ ở trạng thái completed. Công thức và K-factor phải lấy từ một implementation/constant chung. Khi nhiều trận hoàn thành cùng lúc, lock rank row hoặc cơ chế tương đương để không ghi đè. Mỗi thay đổi phải ghi history với previous value, new value và reason.

## Realtime

Mỗi match có room `match:{matchId}`; chat có room `chat:{roomId}`. Event phải có payload version rõ ràng, xác thực connection và cleanup client listener. Không gửi payload vượt quyền của người nhận. Client cần xử lý reconnect và trạng thái stale.
