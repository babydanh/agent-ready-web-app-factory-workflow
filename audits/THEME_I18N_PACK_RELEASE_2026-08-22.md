# Theme, Typography and i18n Pack Release Evidence — v1.9.0

**Ngày:** 2026-08-22  
**Phạm vi:** Bổ sung chuẩn hóa typography, semantic design tokens, light/dark/system theme, high contrast, reduced motion, internationalization, localization, formatting, text expansion, RTL/bidi và locale QA cho Web App Factory.  
**Chế độ:** Workflow/documentation/harness only; không sửa backend/frontend business source, không đọc secret và không tạo ZIP.

## 1. Artifact inventory

| Nhóm | Artifact |
|---|---|
| Theme/design system | `standards/THEME_AND_DESIGN_TOKENS_SPEC.md` |
| i18n/l10n/RTL | `standards/I18N_L10N_SPEC.md` |
| Executable gates | `standards/THEME_I18N_GATES.md` |
| Theme config | `standards/templates/THEME_CONFIG.template.json` |
| Translation catalog | `standards/templates/TRANSLATION_CATALOG.template.json` |
| Locale QA | `standards/templates/LOCALE_QA_MATRIX.template.md` |
| Research | `knowledge/THEME_I18N_RESEARCH_2026-08-22.md` |
| Existing standards integrated | `UI_UX_DESIGN_SYSTEM_SPEC.md`, `DESIGN_QA_SPEC.md`, `WORKFLOW.md`, `SKILL.md`, `AGENTS.md` |
| Harness integration | `new-change.ps1`, `validate-workflow.ps1`, `init-workflow.ps1`, `attach-workflow.ps1`, harness README |
| Index/manifest integration | Root README, knowledge/README, standards/README, `MANIFEST.json` |

## 2. Coverage delivered

The Theme specification defines primitive → semantic → component token layers, naming/ownership, color roles, light/dark/system resolution, SSR/no-flash/hydration behavior, persistence, typography roles/fallbacks, locale/script expansion, spacing/radius/elevation/motion/z-index, forced colors, reduced motion, direction-aware layout, component state rules and evidence.

The I18N specification defines locale registry, BCP 47 identifiers, deterministic resolution/fallback, SSR/client parity, URL/account/cookie policy, message catalog schema, variable validation, plural/select, date/number/currency/timezone/unit formatting, translation lifecycle, text expansion, pseudo-localization, RTL/bidi, logical CSS, directional icons/charts/tables, missing-key telemetry and critical-copy human review.

The gate document maps Theme and I18N signals to exact artifacts and release blockers. A `Theme` profile generates `theme-config.json` plus `locale-qa-matrix.md`; an `I18N` profile generates `translation-catalog.json` plus `locale-qa-matrix.md`; using both generates all three. Theme/I18N profiles require Normal or HighRisk and cannot silently run as SmallFix.

## 3. Harness and agent behavior

`new-change.ps1` accepts `Theme` and `I18N` profiles and writes selected profile metadata to the change README. `validate-workflow.ps1` requires the corresponding artifacts based on that metadata. `init-workflow.ps1` copies the Theme/I18N standards, templates and research into a new workflow bootstrap. `attach-workflow.ps1` routes agents to the Theme and I18N specifications when those profiles are selected.

The root adapters (`AGENTS.md`, `.github/copilot-instructions.md`, `CLAUDE.md` and `.cursor/rules/workflow.mdc`) were re-attached so new agent sessions can discover the expanded profile routing. The adapter remains a short bridge; detailed knowledge stays in the versioned workflow package.

## 4. Validation evidence

| Check | Result |
|---|---|
| `MANIFEST.json` parse | PASS; version `1.9.0` |
| Strict workflow validator | PASS; `registered_paths=124`, `json_files=7`, no change selected |
| Physical workflow ↔ manifest cross-check | PASS; 124 physical files, 124 registered, 0 unregistered, 0 missing |
| Bootstrap integration | PASS; new bootstrap received Theme/I18N standards, gate, templates and research; 111 files created |
| Theme/I18N change generation | PASS; Normal Theme + I18N workspace generated 16 files |
| Theme/I18N change validation | PASS; profile artifact requirements enforced |
| SmallFix profile rule | PASS; Theme profile on SmallFix was rejected as expected |
| Attach DryRun/real run | PASS; planned 4 adapters and updated 4 adapters on current project |
| Temporary helper/workspace cleanup | PASS; test helper and temporary project removed |
| Source application build/test | NOT RUN; no application source code was changed |
| Visual/locale/browser QA | NOT RUN for current app; this release adds standards/templates/gates, not a product UI implementation |

## 5. Limitations

The validator checks manifest paths, JSON parseability, PowerShell syntax, selected profile metadata and required artifact presence. It does not prove token contrast, visual fidelity, browser compatibility, SSR behavior, hydration correctness, translation quality, plural grammar, financial formatting correctness, RTL usability, screen-reader behavior or WCAG conformance. Those require project-specific automated checks and human review recorded in the locale QA matrix.

A supported locale must be reviewed by a native/domain owner where meaning is important. Legal, privacy, payment, refund, safety, moderation and App Store copy cannot be marked approved solely because a translation exists. `PASS_WITH_CONDITIONS` requires an owner, expiry and compensating control; critical accessibility, formatting or semantic failures remain `BLOCKED` or `NEEDS_HUMAN_REVIEW`.

## Decision

**Decision:** `PASS_WITH_CONDITIONS`.

**Conditions:** Apply the relevant profile to a real feature, complete all generated placeholders, run stack-specific theme/locale/visual/accessibility tests, obtain design/native/domain review and keep unsupported locales/modes explicit. This pack improves the workflow and does not remediate the existing application audit P0/P1 backlog or make the current app production-ready.

## References

[1]: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-color-scheme "MDN — prefers-color-scheme"
[2]: https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/color-scheme "MDN — color-scheme"
[3]: https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl "MDN — Intl"
[4]: https://developer.mozilla.org/en-US/docs/Web/CSS/CSS_logical_properties_and_values "MDN — CSS logical properties and values"
[5]: https://www.w3.org/TR/WCAG22/ "W3C — Web Content Accessibility Guidelines 2.2"
