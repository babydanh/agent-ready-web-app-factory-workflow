# Screen Spec — [SCREEN_ID]

## 1. Product intent

| Field | Value |
|---|---|
| Screen | `[name/route]` |
| Primary actor | `[persona/role]` |
| User goal | `[measurable goal]` |
| Entry points | `[routes/actions]` |
| Exit/next actions | `[routes/actions]` |
| Data sensitivity | `PUBLIC / PERSONAL / FINANCIAL / ...` |
| API contract | `[operation IDs]` |

## 2. Information architecture

```text
Page
├── Header/navigation
├── Page title + context
├── Primary action
├── Filters/search
├── Main content
└── Secondary/help/error region
```

Ghi content priority trên mobile, hierarchy heading, breadcrumb, navigation state, URL/query state và back behavior.

## 3. Component map

| Region | Component | Props/data | Interaction | Permission |
|---|---|---|---|---|
| `[region]` | `[shared primitive]` | `[view model]` | `[action]` | `[policy]` |

Dùng token và primitive từ design system. Component mới phải có reason, API, keyboard contract và visual states.

## 4. State matrix

| State | UI | User action | API/event mapping |
|---|---|---|---|
| Initial | `[skeleton]` | none | request starts |
| Loading | `[progress/disabled]` | `[allowed]` | pending |
| Success | `[content]` | `[actions]` | 2xx |
| Empty | `[explanation + CTA]` | `[CTA]` | empty data |
| Field error | `[inline + summary]` | edit/resubmit | validation errors |
| 401 | `[session expired]` | login | unauthenticated |
| 403 | `[no permission]` | back/request access | forbidden |
| 404 | `[not found]` | browse/back | not found |
| 409 | `[conflict]` | refresh/resolve | state conflict |
| 429 | `[cooldown]` | wait/retry | Retry-After |
| 5xx/offline | `[fallback]` | retry | service unavailable |
| Realtime stale | `[freshness marker]` | resync | revision gap |

## 5. Form and mutation behavior

- Label, helper, required, autocomplete và input format: `[spec]`.
- Validation timing: `[on blur/submit/server]`.
- Double submit policy: `[disabled/idempotency key]`.
- Dirty/unsaved navigation: `[policy]`.
- Optimistic update/rollback: `[yes/no + reason]`.
- Success feedback: `[inline/toast/redirect]`.
- Sensitive action confirmation: `[copy + re-auth/MFA]`.

## 6. Responsive and accessibility

| Viewport | Layout | Overflow | Touch/keyboard |
|---|---|---|---|
| 360px | `[behavior]` | `[behavior]` | `[behavior]` |
| 768px | `[behavior]` | `[behavior]` | `[behavior]` |
| 1280px | `[behavior]` | `[behavior]` | `[behavior]` |

Acceptance: keyboard-only path, visible focus, semantic headings/labels, screen-reader name/role/value, focus restoration, contrast, reduced motion, zoom/reflow, target size and form recovery.

## 7. Content and localization

| Key | Default text | Error/empty variant | Locale notes |
|---|---|---|---|
| `[message.key]` | `[text]` | `[text]` | `[notes]` |

Không dùng API message làm enum/state logic. Không render untrusted HTML/rich text nếu chưa sanitize.

## 8. Evidence

- Desktop screenshot/trace: `[path]`.
- Mobile screenshot/trace: `[path]`.
- Keyboard/accessibility evidence: `[path]`.
- API fixture/contract test: `[path]`.
- E2E test: `[test ID]`.
- Known limitations/waivers: `[owner + expiry]`.
