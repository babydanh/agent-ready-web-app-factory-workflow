# Theme, Typography and Internationalization Gates

## 1. Purpose

Tài liệu này biến `THEME_AND_DESIGN_TOKENS_SPEC.md` và `I18N_L10N_SPEC.md` thành release gates có thể áp dụng cho từng change. Gate kiểm tra artifact, evidence và trạng thái review; gate không tự chứng minh WCAG conformance, bản dịch đúng ngữ nghĩa hoặc mọi locale đã được hỗ trợ.

## 2. Profile activation

| Signal trong change | Profile | Required standards | Required artifacts |
|---|---|---|---|
| New color, font, spacing, component token hoặc design-system change | `Theme` | Theme and Design Tokens + UI/UX + Design QA | `theme-config.json`, `locale-qa-matrix.md` |
| Light/dark/system/high-contrast/reduced-motion | `Theme` | Theme and Design Tokens + Design QA | `theme-config.json`, `locale-qa-matrix.md` |
| New language, locale, translation catalog, localized route/content | `I18N` | I18N/L10N + UI/UX + Design QA | `translation-catalog.json`, `locale-qa-matrix.md` |
| Date/number/currency/timezone/plural formatting change | `I18N` | I18N/L10N + Canonical Data | `translation-catalog.json`, `locale-qa-matrix.md` |
| RTL, Arabic/Hebrew, bidi or direction-aware layout | `I18N` | I18N/L10N + Theme/Design QA | `translation-catalog.json`, `locale-qa-matrix.md` |
| Shared primitive used by multiple locales/themes | `Theme,I18N` | Both specifications | All three artifacts |
| Existing screen only receives copy fix | `I18N` if locale/catalog changes | I18N/L10N | Catalog and locale QA evidence as scoped |

A change with theme or locale impact must not remain a `SmallFix`. `new-change.ps1` should create at least a `Normal` workspace so discovery, screen spec, contract and test plan can record the impact.

## 3. Required artifact content

| Artifact | Minimum completion |
|---|---|
| `theme-config.json` | Token source, semantic light/dark values, selector, system resolution, persistence, typography, breakpoints, reduced motion, forced colors, contrast evidence and owner |
| `translation-catalog.json` | Source locale, supported locales, fallback chain, direction, key/variable schema, critical-copy review policy, reviewer and version |
| `locale-qa-matrix.md` | Theme/locale/viewport matrix, long text, number/date/currency/plural, SSR/hydration, direction, accessibility and visual evidence |

Placeholders are not evidence. A generated artifact remains `not-started` until its owner, decision, test result and evidence path are filled.

## 4. Executable gate matrix

| Gate | Deterministic check | Required human evidence | Release result |
|---|---|---|---|
| Token source | No raw semantic color/font/spacing/z-index in feature code, or ADR exists | Token owner confirms meaning and impact | `BLOCKED` on unexplained raw values |
| Theme mapping | Every supported semantic role has light/dark mapping | Contrast/focus/disabled/overlay review for both modes | `BLOCKED` if a supported mode is incomplete |
| Theme resolution | `light`, `dark`, `system` precedence and persistence are documented | SSR/no-flash/hydration evidence and OS switch test | `BLOCKED` on mismatch/flash that harms usability |
| Typography | Font/fallback/size/line-height/weight roles are tokenized | Vietnamese/English/pseudo-locale and long-copy screenshots | `BLOCKED` if text loses meaning or action |
| Contrast | Text, control, focus, border and chart states checked in each theme | Automated report plus human review | `BLOCKED` for critical contrast/focus failure |
| Reduced motion | Motion has reduced/no-motion alternative | User preference test | `BLOCKED` if meaning/progress only exists in animation |
| Forced colors | Controls/focus/boundaries remain perceivable or exception is recorded | High-contrast/forced-colors evidence | `NEEDS_HUMAN_REVIEW` when unsupported |
| Catalog schema | Key, variables, format and locale coverage validate | Product/domain/native review | `BLOCKED` for missing variables or invalid message |
| Locale resolution | URL/account/cookie/browser/default precedence is deterministic | SSR/client parity and fallback evidence | `BLOCKED` on hydration or locale mismatch |
| Formatting | Date/timezone/number/currency/plural fixtures pass | Domain owner confirms meaning/rounding/timezone | `BLOCKED` for financial/legal semantic error |
| Text expansion | Pseudo-locale and long strings do not clip or overflow | Visual review at mobile/tablet/desktop | `BLOCKED` if action/content is inaccessible |
| RTL/bidi | Logical properties, `lang`, `dir`, bidi isolation and directional icon review | Native/RTL reviewer or documented unsupported status | `BLOCKED` when claimed RTL support is broken |
| Accessibility | Keyboard, screen reader, reflow, focus, contrast and labels | Human review in at least one supported theme/locale | `NEEDS_HUMAN_REVIEW` until human evidence exists |
| Observability | Missing-key/fallback/error metrics exist where production relevant | Alert owner and dashboard/evidence link | `PASS_WITH_CONDITIONS` only with explicit owner |
| Release | Catalog/theme version, migration and rollback documented | Release owner accepts known locale/theme gaps | `BLOCKED` for unowned critical copy gaps |

## 5. Status policy

| Status | Meaning |
|---|---|
| `PASS` | Artifacts complete, automated checks pass and required human review is recorded |
| `PASS_WITH_CONDITIONS` | Non-critical gap has owner, expiry, fallback and monitoring; no critical copy/accessibility/data meaning is affected |
| `NEEDS_HUMAN_REVIEW` | Native/domain/accessibility/design review is required before release decision |
| `BLOCKED` | Missing contract, broken layout, missing locale, unsafe fallback, semantic formatting error, critical contrast issue or unresolved SSR mismatch |
| `NOT_APPLICABLE` | Scope explicitly excludes theme/locale feature with rationale, not merely because it was forgotten |

No waiver may convert an untranslated legal/privacy/payment/safety message, incorrect amount/timezone, broken keyboard path or inaccessible critical action into `PASS`.

## 6. Recommended check commands

Commands depend on the stack, but the change must record concrete equivalents:

```powershell
# Workflow/artifact validation
.\workflow\harness\validate-workflow.ps1 -ProjectRoot . -ChangeId <change-id> -Strict

# Examples to adapt to the project toolchain
pnpm lint
pnpm test
pnpm test:i18n
pnpm test:visual -- --theme=light --theme=dark --locale=vi-VN --locale=en-US
pnpm test:a11y
```

If a command does not exist, record `NOT_AVAILABLE`, the alternative check and the resulting residual risk. Do not invent a green result.

## 7. Review questions

The reviewer should be able to answer yes to the following questions before release:

1. Can the same screen render in every declared theme without hard-coded semantic values?
2. Can a user choose light, dark or system without a flash, hydration mismatch or lost preference?
3. Do translations preserve meaning, variables, plural rules, legal/payment wording and accessibility labels?
4. Do long strings, large numbers, dates around timezone boundaries and pseudo-locales remain usable?
5. If RTL is declared, do layout, icons, charts, tables and mixed-direction text behave correctly?
6. Are missing translations, fallback events and known gaps observable and owned?
7. Are screenshot, visual-diff, keyboard and human-review paths linked from the change evidence?

## 8. References

[1]: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-color-scheme "MDN — prefers-color-scheme"
[2]: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/color-scheme "MDN — color-scheme"
[3]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl "MDN — Intl"
[4]: https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_logical_properties_and_values "MDN — CSS logical properties and values"
[5]: https://www.w3.org/TR/WCAG22/ "W3C — Web Content Accessibility Guidelines 2.2"
