# Commerce Systems Playbook

> Mục tiêu: giúp Product, Database, Backend, Frontend, QA, Security và DevOps thiết kế các hệ thống thương mại có dữ liệu nhất quán, giao dịch an toàn, khả năng hoàn tiền/reconcile và business observability.

**Phạm vi.** Playbook này áp dụng cho storefront, marketplace, booking có thanh toán, subscription, POS, service business và các SaaS có billing. Đây là pattern kỹ thuật và checklist thiết kế; không thay thế tư vấn pháp lý, kế toán, thuế, payment-provider review hoặc fraud/risk review.

## 1. Commerce không phải CRUD sản phẩm

Một hệ thống thương mại thường có nhiều bounded context. Không được gom mọi thứ vào một `OrderService` hoặc một bảng `orders` rồi dùng status tự do. Tối thiểu cần phân biệt catalog, pricing/promotion, cart/checkout, order, inventory/fulfillment, payment/ledger, customer/identity, merchant/marketplace, notification, support/refund và reporting.

| Context | Source of truth | Invariant điển hình | Không nên làm |
|---|---|---|---|
| Catalog | Product/variant tables | SKU duy nhất, trạng thái publish, media hợp lệ | Dùng tên sản phẩm làm identity |
| Pricing | Price list/rule/tax snapshot | Tổng tiền có thể tái tính từ line snapshot | Lấy giá hiện tại để sửa lịch sử order |
| Cart | Cart + line items | Quantity dương, currency thống nhất | Tin giá do client gửi |
| Checkout | Checkout state | Một checkout không capture hai lần | Trộn validation và charge không idempotent |
| Order | Immutable order facts + state machine | Total/line/payment relation nhất quán | Cho phép sửa tùy ý order đã paid |
| Inventory | Stock ledger/reservation | Không oversell, release đúng hạn | Chỉ dùng `quantity` mà không có reservation |
| Payment | Provider intent/transaction + internal ledger | Amount/currency/order match | Coi webhook là nguồn tin duy nhất không verify |
| Fulfillment | Shipment/booking/delivery state | Không ship hai lần, cancel đúng điều kiện | Gắn fulfillment vào UI flag |
| Marketplace | Seller/listing/commission/payout | Seller ownership, commission reconcile | Tin seller ID từ request |
| Reporting | Read model/warehouse | Metric definition và freshness rõ | Query dashboard trực tiếp làm nghẽn OLTP |

Repository Medusa minh họa cách một commerce platform tách commerce modules, integration tests, changesets, packages và docs để mở rộng catalog/order/dashboard mà không coi commerce là một CRUD đơn lẻ [1].

## 2. Order lifecycle và state machine

Thiết kế state machine trước khi viết endpoint. State phải mô tả được điều kiện vào, điều kiện ra, actor được phép chuyển, side effects, retry và terminal state.

```text
DRAFT → PENDING_PAYMENT → PAID → FULFILLING → FULFILLED
   │          │             │          │
   ├──────────┘             ├──────────┘
   ↓                        ↓
CANCELLED                REFUND_PENDING → REFUNDED / PARTIALLY_REFUNDED
```

Một order nên lưu snapshot tại thời điểm chốt: currency, unit price, discount allocation, tax basis, shipping fee, customer address cần thiết cho fulfillment, provider reference và policy version. Lịch sử chuyển trạng thái phải có actor, reason, request/idempotency key, timestamp và correlation ID.

Không dùng một enum `status` cho mọi domain. `payment_status`, `fulfillment_status`, `cancel_status` và `order_status` có thể liên hệ nhưng không đồng nghĩa. Việc tách trạng thái giúp tránh lỗi kiểu “payment đã paid nhưng order bị cancelled” không có policy xử lý.

## 3. Pricing, promotion và money correctness

Mọi amount phải có integer minor units hoặc decimal strategy đã thống nhất; không dùng JavaScript floating point cho tiền. Mọi giá trị tiền cần `amount`, `currency`, `scale` hoặc quy ước minor-unit rõ ràng. Server phải tính lại subtotal, discount, tax, shipping và grand total từ dữ liệu authoritative.

Pricing rule cần xác định precedence khi có nhiều khuyến mại: exclusive vs stackable, priority, max discount, customer segment, time window, inventory constraint và rounding. Persist `pricing_snapshot_version` để order lịch sử không thay đổi khi rule mới được deploy. Khi refund một line, lưu allocation gốc thay vì tính lại từ giá hiện tại.

## 4. Inventory, reservation và oversell

Phân biệt available, reserved, committed, damaged và on-hand. Flow checkout nhiều bước nên dùng reservation có TTL hoặc một cơ chế giữ chỗ tương đương:

```text
AVAILABLE → RESERVED → COMMITTED
     │          │
     └──────────┴──→ RELEASED / EXPIRED
```

Invariant tối thiểu là `available >= 0`, một checkout không tạo nhiều reservation cho cùng một intent, reservation hết hạn được release một lần, và fulfillment không commit vượt reservation. Cần chọn concurrency strategy: row lock, optimistic version, atomic conditional update hoặc serializable transaction. PostgreSQL isolation/concurrency semantics cần được đọc cùng business invariant, không chỉ chọn isolation level theo thói quen.

Load test phải bao gồm hai request mua item cuối cùng đồng thời, retry sau timeout, worker chạy trùng và webhook đến trước response checkout. Đừng chỉ test happy path.

## 5. Payment, ledger, refund và reconciliation

Payment flow nên tách provider-facing payment intent khỏi internal financial record. Một thiết kế tối thiểu:

```text
Order → PaymentIntent → ProviderTransaction → LedgerEntry(s) → Reconciliation
```

Provider event phải được verify signature, lưu raw event metadata an toàn, deduplicate theo provider event ID và xử lý out-of-order. Payment mutation cần idempotency key; Stripe mô tả idempotent request như cơ chế để retry mà không tạo thêm mutation trong trường hợp lỗi mạng [2].

Không đánh dấu `PAID` chỉ vì client quay về từ payment page. Chỉ cập nhật sau khi verify provider response/webhook theo policy. Amount, currency, merchant account, order reference và environment phải match. Refund cần phân biệt requested, submitted, succeeded, failed, reversed; không xóa payment record.

Ledger nên append-only hoặc có reversal entries. Số dư/payout không nên sửa trực tiếp bằng câu lệnh “update balance” mà không có audit trail và reconciliation. Hàng ngày cần đối chiếu internal order/payment/ledger với provider settlement, có tolerance và queue xử lý mismatch.

## 6. Marketplace, seller và payout

Marketplace thêm trust boundary giữa platform, seller và buyer. Cần model seller verification/status, listing ownership, commission rule version, payout eligibility, dispute/hold, refund allocation và seller-level permissions. Mọi query listing/order/payout phải scope theo tenant/seller và không được tin `sellerId` từ client.

Nếu có merchant-generated content, workflow phải thêm moderation, notice/takedown, report/block, evidence retention và abuse rate limits. E-commerce policy ở Việt Nam cần được scope theo mô hình storefront hay intermediary/marketplace; Nghị định 85/2021 sửa quy định về thương mại điện tử, vì vậy không nên áp một checklist duy nhất cho mọi app [3].

## 7. Commerce events và side effects

Core transaction chỉ commit facts cần nhất. Email, notification, search indexing, analytics, webhook outbound và fulfillment dispatch nên đi qua outbox hoặc cơ chế reliable publication. Event cần `eventId`, `eventType`, `schemaVersion`, `aggregateId`, `occurredAt`, `correlationId`, `causationId` và payload classification.

Consumer phải idempotent. Retry policy cần exponential backoff, maximum attempts, dead-letter queue, replay procedure và alert. Không gửi email hoặc charge provider nhiều lần chỉ vì transaction bị retry.

## 8. Business metrics và dashboard

Mỗi metric phải có định nghĩa, grain, timezone, currency, filters, owner, freshness và data source. Commerce baseline gồm conversion funnel, cart abandonment, payment success, refund rate, fulfillment SLA, stockout/oversell, average order value, take rate, seller payout aging và reconciliation mismatch.

Dashboard read model nên tách khỏi OLTP khi query nặng. Apache Superset minh họa dataset-centric visualization, semantic layer, caching, role/auth và API customization [4]. Grafana minh họa cách metric operations nên có dimensions như operation, duration, size và outcome để debug thay vì chỉ đếm request [5].

## 9. Security and abuse controls

Commerce threat model phải bao gồm price tampering, coupon abuse, inventory race, account takeover, card testing, refund abuse, seller collusion, scraping, fake reviews, webhook forgery, replay và PII leakage. Controls cần được gắn vào endpoint policy, database invariant, fraud/risk signal, rate limit, audit log và alert.

Các endpoint mutation cần xác định rõ auth, ownership, CSRF, idempotency, replay window, audit event và rate limit. Các giá trị do client gửi chỉ là intent; server phải re-authorize và re-price.

## 10. Definition of Done cho commerce feature

Một commerce feature chỉ sẵn sàng khi có state machine, entity/ledger design, price/currency policy, concurrency test, idempotency strategy, provider/webhook behavior, failure/retry/dead-letter path, refund/cancel policy, audit evidence, dashboard metric và runbook. Với payment, payout, tax hoặc regulated data, phải có owner chuyên môn review trước production.

## References

[1]: https://github.com/medusajs/medusa "Medusa commerce platform repository"
[2]: https://docs.stripe.com/api/idempotent_requests "Stripe — Idempotent requests"
[3]: https://vanban.chinhphu.vn/default.aspx?pageid=27160&docid=204191 "Nghị định 85/2021/NĐ-CP — Cổng thông tin Chính phủ"
[4]: https://github.com/apache/superset "Apache Superset repository"
[5]: https://github.com/grafana/grafana "Grafana repository"
