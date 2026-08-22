# Problem Catalog Pack Release Evidence — v1.5.0

**Date:** 2026-08-22  
**Scope:** Domain-agnostic web app/backend problem catalog, playbooks, test matrix, templates, examples, workflow gates and harness integration.  
**Safety mode:** Documentation/tooling changes only; no backend/frontend source remediation; no secrets read; no ZIP packaging.

## Delivered artifacts

| Area | Artifact |
|---|---|
| Knowledge | `knowledge/WEB_APP_PROBLEM_CATALOG.md` |
| Backend recipes | `knowledge/BACKEND_PROBLEM_PLAYBOOK.md` |
| Domain reuse | `knowledge/DOMAIN_ADAPTATION_GUIDE.md` |
| Research | `knowledge/WEB_APP_PROBLEM_CATALOG_RESEARCH_2026-08-22.md` |
| Test standard | `standards/PROBLEM_ORIENTED_TEST_MATRIX.md` |
| Execution gate | `standards/PROBLEM_CATALOG_CHECKLIST.md` |
| Feature map | `standards/templates/WEB_APP_PROBLEM_MAP.template.md` |
| Backend design | `standards/templates/BACKEND_FEATURE_DESIGN.template.md` |
| Cross-domain example | `examples/booking-room-problem-map.md` |
| Harness update | `init-workflow.ps1`, `new-change.ps1`, `validate-workflow.ps1` |

## Research basis

The pack synthesizes official material from OWASP ASVS/API Security, RFC 9457, PostgreSQL transaction isolation, Stripe idempotency, Socket.IO delivery guarantees, BullMQ retrying jobs, Docker Compose startup order and OpenTelemetry signals. The final knowledge documents contain direct references and distinguish reference patterns from project-specific implementation decisions.

## Workflow integration

`README.md`, `WORKFLOW.md`, `SKILL.md`, `AGENTS.md`, `standards/README.md` and `MANIFEST.json` now require problem-card/profile selection before discovery and require backend problem playbook/test-matrix use for backend or side-effect features. The manifest is version `1.5.0` and includes the new knowledge, standards, templates and example paths.

The change generator now always creates `00-problem-map.md`; Normal and HighRisk changes additionally receive `02-backend-feature-design.md`. The validator now enforces the problem map for every change, tier-specific discovery/data/API/UI/backend artifacts for Normal/HighRisk, architecture/security artifacts for HighRisk and AI eval artifact when the generated artifact map enables AI.

## Validation evidence

| Check | Result |
|---|---|
| Source workflow manifest/path/JSON validation | PASS |
| Manifest version | `1.5.0` |
| PowerShell parser for harness | PASS |
| Bootstrap dry-run | PASS; no target created |
| Change dry-run | PASS; no target created |
| Unsafe bootstrap child target refusal | PASS |
| Temporary bootstrap integration | PASS |
| Temporary HighRisk + AI change generation | PASS |
| Tier-aware change validation | PASS |
| Temporary integration directory cleanup | PASS after Windows file-lock retry |
| Backend typecheck | PASS |
| Frontend typecheck | PASS |
| Backend unit tests | PASS; 42 suites / 366 tests |

## Known limits

The validator remains intentionally read-only and does not semantic-validate OpenAPI/YAML or Markdown links without pinned external validators. It does not prove that a placeholder has been replaced by real evidence, run an AI benchmark, execute an architecture fitness function or provide a dashboard. Production compliance remains a project-owner/legal/security decision and is not implied by this pack.

## Release decision

**Decision:** `PASS_WITH_CONDITIONS`  
**Conditions:** Run a pilot feature in a real project; add CI fixture; add pinned semantic contract/link validators; and do not mark the web app production-ready while P0 findings in `WEB_APP_AUDIT_2026-08-22.md` remain open.  
**Owner:** `<project owner>`  
**Next action:** Select one feature such as booking/registration and complete its Problem Map plus backend design/test evidence.
