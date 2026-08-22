# Design QA Specification

## 1. Purpose

Design QA bảo đảm UI không chỉ giống mockup mà còn nhất quán, accessible, responsive, resilient với data thật và khớp API state. UI review là một quality gate liên kết product intent, design tokens, component contract, screen state matrix và evidence.

## 2. Token governance

Mọi màu, spacing, radius, typography, elevation, motion và breakpoint dùng semantic token thay vì hard-coded value trong screen. Primitive token mô tả giá trị nền; semantic token mô tả ý nghĩa như `surface-primary`, `text-muted`, `action-danger`, `focus-ring` và được map theo theme.

| Token group | Required considerations |
|---|---|
| Color | Contrast, dark/light theme, semantic status, color-blind redundancy |
| Typography | Font fallback, scale, line height, locale expansion, numeric alignment |
| Spacing | Consistent rhythm, dense data table, touch target and responsive collapse |
| Motion | Reduced-motion preference, duration budget, no essential information by animation |
| Focus | Visible keyboard focus, high contrast, not obscured by sticky UI |
| Breakpoints | Content-driven behavior, no horizontal overflow, mobile-first fallback |

Token changes require visual diff review and impact list. New one-off value needs a documented reason or should be rejected.

## 3. Component inventory and contract

Mỗi shared component có owner, purpose, states, props/input contract, keyboard behavior, accessible name/role, loading/error behavior, responsive behavior and usage examples. Primitive components include Button, Input, Select, Dialog, Toast, Table, Pagination, Tabs, Card, EmptyState, ErrorState, Skeleton, FormField and PermissionGate.

Domain components must compose primitives and must not reimplement focus, disabled, loading, error or form semantics inconsistently. A component is not considered shared until two screens use it or the design owner explicitly marks it as foundational.

## 4. Screen QA matrix

Mỗi screen verifies at least: initial, loading, success, empty, field validation, 401, 403, 404, 409, 429, 5xx, offline, stale realtime, slow network, long text, large number, timezone/date format and permission-hidden actions. Each state has copy, retry/recovery action, telemetry and screenshot/evidence where practical.

## 5. Accessibility baseline

Target WCAG 2.2 Level AA for web UI, subject to documented exceptions and human review. Automated checks do not prove conformance. Review keyboard-only navigation, focus order/visibility, semantic headings/landmarks, labels, error association, screen-reader announcements, contrast, target size, zoom/reflow, reduced motion and dynamic updates.

| Layer | Example check |
|---|---|
| Static | eslint/a11y rules, token lint, forbidden raw colors |
| Component | Storybook interaction and accessibility test |
| Browser | Playwright keyboard, axe scan, responsive viewport |
| Human | Screen reader/focus/zoom and content clarity review |
| Regression | Visual snapshot at agreed viewport/theme/locale/state, including pseudo-locale when applicable |
| Theme | Light, dark, system resolution, contrast, focus, forced colors and no-flash evidence |
| Locale | Catalog keys, fallback, variables, plural/select, formatters and missing-key telemetry |
| Direction | `lang`/`dir`, CSS logical properties, bidi isolation and directional icon review |

## 6. Visual regression

Snapshots use deterministic fixtures, stable locale/timezone, masked dynamic IDs and controlled fonts. Review diffs by category: intentional token change, layout regression, content/state regression or rendering/environment noise. Do not approve a snapshot merely because pixel diff is small; inspect overflow, clipping, focus and error state.

## 7. API-to-UI mapping

UI maps HTTP status and stable problem `code` to domain state, not free-form message text. Mapping defines retryability, sign-in redirect, permission explanation, conflict resolution, rate-limit countdown and offline queue behavior. Unknown error codes fall back safely to generic error state and emit telemetry with requestId.

## 8. Responsive and internationalization QA

Test mobile, tablet and desktop widths plus browser zoom/reflow. Verify long tournament/team names, empty lists, RTL readiness if relevant, Vietnamese/English copy, pluralization, date/timezone and number/currency formatting. Layout must not depend on a specific sample string length.

When the change adds or claims a theme, locale or direction capability, apply `THEME_I18N_GATES.md` and attach the relevant `theme-config.json`, `translation-catalog.json` and `locale-qa-matrix.md` artifacts. A locale/theme change must include SSR/client parity, fallback, text expansion, font fallback and visual evidence rather than only a toggle screenshot.

## 9. Design review evidence

A screen can PASS when its intent, tokens, component usage, full state matrix, accessibility checks, responsive screenshots and API mapping are attached to the review. Missing error/empty/loading states, unlabelled controls, keyboard trap, contrast failure or horizontal overflow is at least `P1` if it blocks a critical flow; otherwise `P2` until triaged. A broken declared locale, incorrect currency/timezone meaning, missing critical translation or theme hydration mismatch is `P1` at minimum; an unreviewed legal/privacy/payment translation is `NEEDS_HUMAN_REVIEW`, not PASS.
