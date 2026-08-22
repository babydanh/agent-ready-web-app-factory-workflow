# Theme, Typography and i18n Research — 2026-08-22

## Scope

Research này cung cấp nền tảng kỹ thuật cho `THEME_AND_DESIGN_TOKENS_SPEC.md`, `I18N_L10N_SPEC.md` và `THEME_I18N_GATES.md`. Nó không thay thế browser compatibility testing, design review, accessibility conformance assessment, native translation review hoặc legal requirements.

## Findings

### Theme and browser preference

The CSS `prefers-color-scheme` media feature detects whether the user has requested a light or dark theme through operating-system or user-agent preferences [1]. The application should still own semantic tokens and explicit user override; the media feature is an input to `system` mode, not a substitute for a design-token architecture.

The CSS `color-scheme` property indicates which schemes an element can comfortably render. User-agent UI such as canvas, scrollbars and form controls may adapt, while application components still need their own theme rules [2]. Declaring support early, including a root declaration and an appropriate meta hint, can reduce unwanted color flashes; SSR and hydration behavior must be tested in the actual framework.

### Accessibility

WCAG 2.2 defines technology-independent, testable success criteria organized around perceivable, operable, understandable and robust principles [3]. W3C describes conformance through success criteria and recommends using supporting guidance plus a combination of automated and human evaluation. Theme and locale QA therefore cannot be reduced to a pixel screenshot or a single automated scan.

### Internationalization APIs and locale tags

The ECMAScript `Intl` namespace provides locale-sensitive comparison, number/date/time formatting and related constructors such as `Intl.DateTimeFormat`, `Intl.NumberFormat`, `Intl.PluralRules`, `Intl.RelativeTimeFormat`, `Intl.Collator` and `Intl.Locale` [4]. Locale negotiation chooses an appropriate supported locale from requested locales; BCP 47 identifiers can include language, script and region. The workflow therefore keeps locale resolution and business data separate, and requires explicit formatter/timezone/currency contracts.

### Direction-aware layout

CSS logical properties provide direction-aware alternatives to physical left/right/top/bottom assumptions [5]. An RTL-ready UI must address layout, text direction, bidi isolation, directional icons, tables, charts, keyboard order and mixed Latin/Arabic/Hebrew/numeric content; replacing a few margin properties is insufficient.

## Workflow implications

| Finding | Required workflow control |
|---|---|
| System theme is an OS/user-agent preference | Support explicit `light`, `dark` and `system` states with documented precedence |
| Browser UI and application UI have separate responsibilities | Use `color-scheme` plus application semantic/component tokens |
| Accessibility requires testable criteria and human evaluation | Store automated reports and human review in locale/theme evidence |
| Intl supports locale-sensitive formatting and negotiation | Keep API data canonical; resolve locale/timezone/currency in presentation |
| Direction changes more than text alignment | Use logical properties and test RTL/bidi/icon/chart semantics |

## Limitations

These sources are standards/reference documentation, not a guarantee of support for every browser, framework, font, screen reader, locale or assistive technology. The workflow must record actual versions, browser/device matrix, fallback behavior and known exceptions. Translation correctness, financial/legal wording, privacy notices and sector-specific accessibility obligations require qualified domain review.

## References

[1]: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-color-scheme "MDN — prefers-color-scheme"
[2]: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/color-scheme "MDN — color-scheme"
[3]: https://www.w3.org/TR/WCAG22/ "W3C — Web Content Accessibility Guidelines 2.2"
[4]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl "MDN — Intl"
[5]: https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_logical_properties_and_values "MDN — CSS logical properties and values"
