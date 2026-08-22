# Phase 03 — Frontend Product Implementation

## Mục tiêu

Biến API contract thành trải nghiệm UI nhất quán, có type safety và xử lý đủ trạng thái. Frontend không chỉ là màn hình happy path; phải thể hiện loading, empty, error, forbidden, not-found, conflict và success.

## Implementation order

```text
Route map
  → UI spec
  → shared primitives
  → API types/service
  → feature hook/store
  → server/client boundary
  → page and components
  → form validation
  → responsive/accessibility
  → UI tests/E2E
```

## Next.js rules

App Router, Server Component mặc định. Dùng Client Component khi cần state, event, lifecycle, browser API hoặc custom hook. Đặt boundary nhỏ để giảm client bundle và giữ secret ở server. Data fetching phải chọn theo freshness, caching, mutation và realtime needs.

## Data and state

API URL và endpoint nằm trong API layer, không rải trong component. Type mapping phải khớp DTO. Zustand chỉ giữ global state hoặc state cần chia sẻ; state cục bộ giữ trong feature/component. Axios interceptor phải xử lý 401 refresh một lần, 403 permission và 409 conflict.

## Form and UX

React Hook Form + Zod cho form. Trim và normalize input bằng utility chung. Field error nằm gần input; lỗi tổng quát dùng toast/inline state. Destructive action có confirm. Realtime update không được làm mất text user đang nhập.

## UI quality

TailwindCSS và shared primitives; mobile-first; không dùng CSS/animation rải rác trái convention. Có loading skeleton, empty CTA, retryable error, not-found, forbidden và success state. Kiểm tra keyboard, focus, label, alt text, contrast và không dùng màu là tín hiệu duy nhất.

## Gate

- [ ] UI spec và route map pass.
- [ ] Server/client boundary có lý do.
- [ ] API/types/schema mapping pass.
- [ ] Form validation khớp backend.
- [ ] Loading/empty/error/success/permission/conflict có đủ.
- [ ] Responsive desktop/mobile pass.
- [ ] Không có `any`, hardcode API URL hoặc console error nghiêm trọng.
- [ ] Lint, i18n check và build frontend pass.
