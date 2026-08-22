# Agent-Ready Web App Factory

A reusable, profile-aware workflow for building web applications with AI coding agents. It combines repository instructions, A-to-Z delivery phases, engineering standards, domain playbooks, templates, PowerShell generators, validation gates and release evidence.

> **The workflow is a development governance system, not an application framework and not an autonomous production bot.** It helps an agent plan, implement, validate and report changes consistently. The host project still owns its code, infrastructure, credentials, legal decisions and release approvals.

## What this repository provides

| Capability | What is included |
|---|---|
| Agent onboarding | `AGENTS.md`, agent bridge adapters and profile-aware context routing |
| A-to-Z delivery | Intake, discovery, architecture, data, API, UI, implementation, QA, security, SRE, release and handoff phases |
| Canonical contracts | Data naming, nullability, enums, money, time, privacy, API envelopes and compatibility rules |
| UI system | Components, state matrices, semantic design tokens, typography, responsive behavior and accessibility expectations |
| Theme and i18n | Light/dark/system themes, contrast, reduced motion, locale catalogs, fallback, formatting, text expansion, RTL and bidi QA |
| Domain packs | Commerce, marketplace, payment, recommendation, search, ranking, dashboard, analytics and transaction/concurrency playbooks |
| Compliance profiles | Vietnam scoping profile and Apple iOS/App Store release profile, with explicit review limitations |
| AI engineering | Agent task protocol, evaluation, safety, cost, tool and evidence controls |
| Operational quality | SRE, observability, incident, migration, rollback, CI and repository patterns |
| Harness | Bootstrap, one-command agent attachment, per-change workspace generation and read-only validation |

## What this is not

This repository does not certify an application as secure, legally compliant, WCAG-conformant, PCI-compliant or App Store approved. It does not replace qualified legal, security, accessibility, design, platform or domain review. It also does not remediate findings in a host application unless an agent is explicitly instructed and authorized to change that application.

## 60-second quick start

### Option A: Use this as a standalone workflow repository

Clone this repository, create or choose a host application directory, and attach the workflow to it:

```powershell
New-Item -ItemType Directory -Force C:\work\my-web-app | Out-Null
Set-Location C:\work\agent-ready-web-app-factory-workflow
.\harness\attach-workflow.ps1 `
  -ProjectRoot C:\work\my-web-app `
  -WorkflowRoot (Get-Location).Path `
  -ProjectName "My Web App" `
  -Bootstrap `
  -Agent All
```

The command bootstraps `C:\work\my-web-app\workflow\` and creates or updates managed instruction blocks in `AGENTS.md`, `.github/copilot-instructions.md`, `CLAUDE.md` and `.cursor/rules/workflow.mdc`.

### Option B: Use it embedded in an existing repository

If this repository is copied as `workflow/` inside the host project, run from the host project root:

```powershell
.\workflow\harness\attach-workflow.ps1 `
  -ProjectRoot . `
  -Agent All
```

Use `-DryRun` before writing files:

```powershell
.\workflow\harness\attach-workflow.ps1 `
  -ProjectRoot . `
  -Agent All `
  -Profile Theme,I18N `
  -DryRun
```

The standalone repository uses paths such as `harness/README.md`; the embedded form uses the same paths prefixed with `workflow/`.

## Attach the right profile

Profiles are context routing and artifact requirements. They do not grant approval or remove human review.

| Product signal | Profile(s) | Primary standards | Required change artifacts |
|---|---|---|---|
| Catalog, cart, order, inventory, payment, marketplace, payout | `Commerce` | Commerce and transaction playbooks | Commerce flow and transaction/concurrency test |
| Search, feed, personalization, ranking, recommendation | `Recommendation` | Recommendation/search/ranking playbook | Recommendation feature spec |
| KPI, reporting, analytics, admin dashboard, export | `Dashboard` | Dashboard/analytics playbook | Dashboard analytics spec |
| Money, stock, entitlement, webhook, retry, queue or shared resource | `Commerce` or domain profile + transaction | Transaction/concurrency playbook | Transaction/concurrency test |
| Vietnam launch, Vietnamese data, B2C or e-commerce | `VietnamCompliance` | Vietnam compliance profile | Compliance scope record and legal-review status |
| iOS, App Store, StoreKit, account deletion or privacy SDK | `AppleIOS` | Apple iOS/App Store profile | Apple iOS release review |
| Color tokens, typography, light/dark/system, contrast or motion | `Theme` | Theme and design tokens specification | `theme-config.json` and locale QA matrix |
| Locale, translation, date/number/currency, timezone or RTL | `I18N` | Internationalization/localization specification | `translation-catalog.json` and locale QA matrix |

Commerce and Recommendation changes default to `HighRisk`. Theme and I18N changes must use at least a `Normal` change workspace so the UI, contract and QA impact is recorded. A `SmallFix` cannot silently omit required domain, theme or locale artifacts.

## Create a change workspace

Every feature should have a bounded change workspace. From an embedded host project:

```powershell
.\workflow\harness\new-change.ps1 `
  -ProjectRoot . `
  -ChangeId theme-i18n-foundation `
  -Title "Theme and localization foundation" `
  -Tier Normal `
  -Profile Theme,I18N
```

From the standalone workflow repository, point `-ProjectRoot` at the host application and use the workflow copy inside that host application after bootstrapping:

```powershell
.\harness\new-change.ps1 `
  -ProjectRoot C:\work\my-web-app `
  -ChangeId checkout-marketplace `
  -Title "Marketplace checkout" `
  -Tier HighRisk `
  -Profile Commerce,VietnamCompliance
```

The generator creates a `changes/<change-id>/` workspace containing a problem map, discovery, architecture, data, backend, API, UI, security, plan, tasks, test plan, implementation log, convergence review and release evidence. Profile selection adds the exact domain artifacts required by the selected profile.

## Agent operating protocol

An agent should follow this sequence:

```text
User brief
  → Read repository instructions
  → Select problem cards and profiles
  → Create changes/<change-id>/
  → Complete discovery and source-of-truth contracts
  → Review architecture, data, API and UI impact
  → Implement bounded tasks
  → Run tests, security, accessibility, concurrency and AI checks as applicable
  → Record evidence and unresolved risks
  → Run workflow validation
  → Request human review or release
```

The agent must load only the relevant profile-specific material. A commerce feature normally loads Commerce, Transaction, Security, SRE and any applicable Vietnam or Apple profile. A recommendation feature normally loads Recommendation, Dashboard if metrics are involved, Security and AI Evaluation if a model is used. A theme or localization feature loads the Theme or I18N specification and the Theme/I18N gates.

The agent must stop with `NEEDS_CLARIFICATION`, `BLOCKED` or `NEEDS_HUMAN_REVIEW` when a business rule, contract, security control, translation review, accessibility review, legal decision or platform decision is missing. A successful build is not proof of business correctness or production readiness.

## Validate the workflow and change

Run the read-only package validator from an embedded host project:

```powershell
.\workflow\harness\validate-workflow.ps1 -ProjectRoot . -Strict
.\workflow\harness\validate-workflow.ps1 -ProjectRoot . -ChangeId theme-i18n-foundation -Strict
```

From a standalone workflow checkout, use the equivalent path:

```powershell
.\harness\validate-workflow.ps1 -ProjectRoot C:\work\my-web-app -Strict
```

The validator checks manifest paths, empty files, JSON parseability, PowerShell syntax and profile artifact presence. It does not validate semantic OpenAPI/YAML correctness, visual fidelity, translation quality, WCAG conformance, model fairness, legal compliance, payment certification or App Store approval.

## Theme, typography and localization workflow

For a theme change, complete `standards/templates/THEME_CONFIG.template.json`. It records token source, semantic light/dark values, `light|dark|system` resolution, persistence, SSR/no-flash behavior, typography roles, breakpoints, reduced motion, forced colors and contrast evidence.

For a locale change, complete `standards/templates/TRANSLATION_CATALOG.template.json`. It records source and supported locales, BCP 47 identifiers, fallback, direction, message keys, variables, plural/select format, review status and critical-copy policy.

For either change, complete `standards/templates/LOCALE_QA_MATRIX.template.md`. Test theme, locale, viewport, long text, pseudo-locale, number/date/currency/timezone, plural/select, keyboard, screen reader, zoom/reflow, reduced motion, forced colors and RTL when supported. Run `standards/THEME_I18N_GATES.md` before release.

## Commerce and high-risk workflow

Commerce changes must model catalog, pricing, cart, order, inventory, payment, ledger, refund, payout, reconciliation and fraud boundaries. Money, inventory, entitlement, payment, webhook, retry and queue behavior must have invariants, idempotency, duplicate/out-of-order tests, failure recovery and reconciliation evidence.

Recommendation changes must define events, candidate sources, ranking stages, cold-start behavior, privacy/fairness controls, evaluation metrics, search safety and rollback. Dashboard changes must define metric grain, access scope, freshness, query budget, export policy and stale/partial behavior.

Vietnamese and Apple profiles provide scoping and evidence checklists. They are not legal opinions, platform certifications or guarantees of App Review approval. Sector-specific tax, e-invoice, financial, payment-network, healthcare, gambling, children, advertising and cross-border obligations require separate review.

## Repository layout

```text
.
├── README.md
├── MANIFEST.json
├── WORKFLOW.md
├── SKILL.md
├── AGENTS.md
├── CHECKLIST.md
├── standards/       # Canonical specifications, gates, contracts and templates
├── knowledge/       # Problem catalog, domain playbooks and research
├── phases/          # Phase-level A-to-Z guidance
├── security/        # Threat model, auth, security tests and incident runbook
├── decisions/       # Architecture Decision Records
├── examples/        # End-to-end examples and problem maps
├── harness/         # Bootstrap, attach, change generation and validation scripts
├── audits/          # Audit reports and release evidence
└── templates/       # Generic project templates
```

## Core entry points

| File | Purpose |
|---|---|
| `WORKFLOW.md` | End-to-end lifecycle and phase gates |
| `SKILL.md` | Technical, safety and agent operating rules |
| `AGENTS.md` | Agent roles, handoff and reporting contract |
| `MANIFEST.json` | Canonical package inventory and version |
| `standards/README.md` | Standards reading order and quick-start |
| `knowledge/README.md` | Profile-aware knowledge index |
| `harness/attach-workflow.ps1` | One-command agent onboarding |
| `harness/init-workflow.ps1` | Bootstrap a workflow copy into a host project |
| `harness/new-change.ps1` | Generate a bounded per-change workspace |
| `harness/validate-workflow.ps1` | Read-only package and change validation |

## Safety rules

Do not read, print, commit or copy `.env`, credentials, tokens, private keys, production PII or provider secrets. Keep production credentials outside this repository. Do not use `reset`, `restore`, `clean` or mass formatting to resolve conflicts. Treat generated artifacts as incomplete until placeholders are replaced and evidence is attached.

## Version and status

Current package version: **1.9.0**. The package has passed its workflow-level validation with conditions. The package itself is not a statement that any host application is production-ready. Host projects must run their own build, test, security, accessibility, legal, platform and operational checks.

## Contributing

Changes to standards should explain the problem, affected profiles, compatibility impact, required artifact changes, validation evidence and migration guidance. New rules should prefer a reusable contract, template or executable gate over prose alone. Keep examples sanitized and never commit real credentials or production data.

## License

Choose and add an open-source license before accepting external contributions or granting reuse rights. The repository currently does not make a license claim on behalf of the author.

## References

The workflow follows broadly adopted repository-instruction and accessibility patterns, including [AGENTS.md](https://agents.md/), [GitHub Copilot repository custom instructions](https://docs.github.com/en/copilot/customizing-copilot/adding-repository-custom-instructions-for-github-copilot), [VS Code custom instructions](https://code.visualstudio.com/docs/copilot/customization/custom-instructions), [WCAG 2.2](https://www.w3.org/TR/WCAG22/), [MDN `prefers-color-scheme`](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/At-rules/@media/prefers-color-scheme), [MDN `color-scheme`](https://developer.mozilla.org/en-US/docs/Web/CSS/Reference/Properties/color-scheme) and [MDN `Intl`](https://developer.mozilla.org/en-US/docs/Web/JavaScript/Reference/Global_Objects/Intl).
