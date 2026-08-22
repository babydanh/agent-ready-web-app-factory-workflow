# Locale, Theme and Typography QA Matrix

## 1. Scope

- Change ID:
- Screen/component:
- Owner:
- Supported locales:
- Supported directions:
- Supported themes:
- Reviewer:
- Review date:

## 2. Locale registry

| Locale | Language/region | Direction | Font stack | Fallback chain | Date/timezone | Number/currency | Coverage |
|---|---|---|---|---|---|---|---|
|  |  |  |  |  |  |  |  |

## 3. Test matrix

| Case | Light | Dark | System light | System dark | Default locale | Second locale | Pseudo-locale | RTL |
|---|---:|---:|---:|---:|---:|---:|---:|---:|
| Initial/loading/success |  |  |  |  |  |  |  |  |
| Empty/error/permission |  |  |  |  |  |  |  |  |
| Long text/expanded copy |  |  |  |  |  |  |  |  |
| Large/negative/zero number |  |  |  |  |  |  |  |  |
| Date/timezone boundary |  |  |  |  |  |  |  |  |
| Plural/select/interpolation |  |  |  |  |  |  |  |  |
| Keyboard/focus/screen reader |  |  |  |  |  |  |  |  |
| Zoom/reflow/overflow |  |  |  |  |  |  |  |  |
| Reduced motion/forced colors |  |  |  |  |  |  |  |  |

## 4. Theme evidence

- Token source:
- Raw value scan:
- Contrast report:
- Theme selector and persistence:
- SSR/hydration/no-flash evidence:
- OS theme change evidence:
- Component states reviewed:

## 5. i18n evidence

- Catalog/version:
- Missing-key check:
- Variable/schema check:
- Fallback check:
- Plural/select check:
- Date/number/currency formatter check:
- `lang`/`dir` evidence:
- Translation reviewer:

## 6. Visual and accessibility evidence

- Screenshot/visual diff paths:
- Viewport/device matrix:
- Font loading/fallback:
- Text expansion/overflow:
- RTL logical-layout/bidi:
- Keyboard/focus:
- Screen-reader smoke:
- Reduced-motion/forced-colors:

## 7. Result

- Commands/tests run:
- Failures and defects:
- Waiver/exception:
- Status: `PASS / CONDITIONAL / BLOCKED / NEEDS_HUMAN_REVIEW`:
- Release decision owner/date:
