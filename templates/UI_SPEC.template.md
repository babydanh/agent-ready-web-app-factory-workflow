# UI Spec — [Tên màn hình]

## 1. Screen metadata

| Trường | Giá trị |
|---|---|
| Route | `/[route]` |
| Persona | [Player/Organizer/Admin] |
| Auth | Public / Authenticated / Role restricted |
| Primary goal | [Mục tiêu chính] |
| Data source | [API/store/socket] |

## 2. Layout

```text
[Header]
  [Navigation]
[Main]
  [Primary content]
  [Secondary content]
[Footer/Action bar]
```

## 3. UI states

| State | Expected UI | User action |
|---|---|---|
| Initial/loading | [Skeleton/spinner] | [None/retry] |
| Empty | [Empty message/CTA] | [CTA] |
| Success | [Content] | [Actions] |
| Validation error | [Field errors] | [Fix and retry] |
| API error | [Toast/inline error] | [Retry/back] |
| Unauthorized | [Login/redirect] | [Login] |
| Forbidden | [Permission message] | [Back/contact admin] |
| Not found | [Not-found screen] | [Back/search] |
| Conflict | [Stale/conflict message] | [Reload/resolve] |

## 4. Components

| Component | Responsibility | Client component? | Shared or feature |
|---|---|---:|---|
| `[Component]` | [Render/interaction] | Yes/No | Shared/Feature |

## 5. Interaction rules

- [ ] Primary action có loading và disabled state.
- [ ] Destructive action có confirmation.
- [ ] Error hiển thị gần nơi xảy ra và có toast nếu cần.
- [ ] Click outside/escape hoạt động cho modal hoặc widget.
- [ ] Keyboard focus và tab order hợp lý.
- [ ] Realtime update không làm mất dữ liệu user đang nhập.

## 6. Responsive

| Breakpoint | Behavior |
|---|---|
| Mobile | [Layout/action behavior] |
| Tablet | [Layout/action behavior] |
| Desktop | [Layout/action behavior] |

## 7. Accessibility and content

- [ ] Label/form association.
- [ ] Alt text cho ảnh.
- [ ] Contrast đủ.
- [ ] Focus visible.
- [ ] Không chỉ dùng màu để biểu đạt status.
- [ ] Date, currency và bản dịch theo locale.

## 8. UI acceptance

- [ ] Screenshot/evidence desktop.
- [ ] Screenshot/evidence mobile.
- [ ] Loading/empty/error đã kiểm tra.
- [ ] Không có layout overflow.
- [ ] Không có console error nghiêm trọng.
