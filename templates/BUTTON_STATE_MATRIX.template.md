# Button-State Matrix — [Change ID]

## Scope

- Feature/screen: [Tên feature/screen]
- Source of truth: [Contract/state/API/module]
- Owner: [Team/person]
- Status: Draft | Reviewed | Implementing | Verified

## Matrix

| Route/screen | Role | Button/action | Visible when | Disabled when | Loading label/state | Click effect/state transition | Confirmation | Success UI | Error UI | Duplicate click/retry | Keyboard/a11y |
|---|---|---|---|---|---|---|---|---|---|---|---|
| [route] | [role] | [label] | [precondition] | [condition] | [label/spinner] | [state/API/event] | Yes/No + content | [toast/redirect/update] | [inline/toast/fallback] | [lock/idempotency/conflict] | [focus/aria/keyboard] |

## Required negative cases

| Case | Expected behavior | Evidence/test |
|---|---|---|
| Missing/empty data |  |  |
| No permission/ownership |  |  |
| Stale revision/concurrent update |  |  |
| Timeout/offline/reconnect |  |  |
| Double click or repeated request |  |  |
| Unknown server error |  |  |
| Long label/translation expansion |  |  |
| Narrow/mobile viewport |  |  |

## Review questions

1. Có action nào bị ẩn nhầm theo format thay vì preset/role/state không?
2. Nút có hiện nhưng click không có effect vì state update bất đồng bộ không?
3. Nút có bị disabled quá sớm hoặc không disabled khi request đang chạy không?
4. Popup xác nhận có nói rõ side effect và đường hủy không?
5. Success UI có dựa trên server confirmation hay chỉ optimistic state?
6. Lỗi có ánh xạ theo error code/status ổn định không?
7. Keyboard, focus, screen reader, contrast và long text có đủ không?
