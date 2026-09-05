# Screen-State Matrix — [Change ID]

## Screen metadata

- Route/page/tab/modal: [Tên và route]
- Audience/roles: [anonymous/player/organizer/referee/admin/etc.]
- Entry points: [navigation/deep-link/notification]
- Source of truth: [API/store/socket/local state]
- Responsive targets: [mobile/tablet/desktop]

## State matrix

| State | Trigger/data condition | UI structure/copy | Primary action | Secondary action | Permission behavior | Data freshness/realtime | Evidence |
|---|---|---|---|---|---|---|---|
| Loading |  |  |  |  |  |  |  |
| Empty |  |  |  |  |  |  |  |
| Ready |  |  |  |  |  |  |  |
| Blocked by rule |  |  |  |  |  |  |  |
| Unauthorized/forbidden |  |  |  |  |  |  |  |
| Not found/expired |  |  |  |  |  |  |  |
| Submitting |  |  |  |  |  |  |  |
| Success/updated |  |  |  |  |  |  |  |
| Conflict/stale |  |  |  |  |  |  |  |
| Offline/reconnect |  |  |  |  |  |  |  |
| Error/unknown |  |  |  |  |  |  |  |

## UX and accessibility review

| Concern | Expected behavior | Evidence/test |
|---|---|---|
| Focus on load/error/modal |  |  |
| Keyboard order and Enter/Escape |  |  |
| Screen reader labels/live region |  |  |
| Contrast/focus indicator |  |  |
| Reduced motion |  |  |
| Long translation/text expansion |  |  |
| Mobile/narrow viewport |  |  |
| Refresh/back/deep-link behavior |  |  |

## State transition notes

```text
[CURRENT] --[action/precondition]--> [NEXT]
                         └── error/conflict/rollback --> [RECOVERY]
```

List every terminal state and whether the transition is reversible. Do not infer state from display text; use stable status/error fields.
