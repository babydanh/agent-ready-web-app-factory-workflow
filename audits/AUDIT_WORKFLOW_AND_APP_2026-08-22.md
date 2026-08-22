# Read-only Audit — Workflow, Tooling và Web App

**Ngày audit:** 2026-08-22  
**Phạm vi:** `workflow/` hiện tại, bootstrap/change generator, validator, deployment/configuration và các finding source-app đã ghi nhận.  
**Chế độ:** Read-only inspection, parser, dry-run, path checks, typecheck và unit test. Không reset/restore/clean, không đọc `.env`, không sửa backend/frontend source và không đóng gói ZIP.

## 1. Executive conclusion

Workflow hiện đã ở mức **usable reusable framework** và tooling generator đã chạy được end-to-end trong thư mục tạm. Tuy nhiên, nó chưa phải một engineering platform tự động hóa hoàn chỉnh vì validator mới kiểm tra cấu trúc cơ bản, chưa enforce tier-specific gates, chưa semantic-validate OpenAPI/YAML/Markdown links và chưa chạy trong CI.

Web app hiện tại **chưa production-ready** theo baseline audit trước đó. Hai P0 vẫn được xác nhận bằng source/config hiện tại: public URL fetch có SSRF-like surface và Compose có default secret/exposed infrastructure/fail-open environment defaults. P1/P2 liên quan upload, dependency, rate limit, payment integrity, cross-entity integrity, build bypass, E2E, migration, readiness, AI budget/error, CORS/trusted proxy và logging vẫn cần remediation riêng.

## 2. Audit evidence summary

| Check | Result | Evidence |
|---|---|---|
| Workflow manifest parse | PASS | `workflow/MANIFEST.json`, version `1.3.0` |
| Manifest path existence | PASS | Validator: 84 unique registered paths, 0 missing |
| Physical/manifest cross-check | REVIEW | 85 physical files; 1 unregistered file (`MANIFEST.json`, likely intentional metadata); 7 duplicate entries caused by entrypoint/category overlap |
| Empty workflow files | PASS | 0 empty files |
| JSON parse | PASS | 5 JSON files |
| PowerShell parser | PASS | All harness scripts parse successfully |
| Bootstrap dry-run | PASS | Expected 73 files; no target created |
| Change dry-run | PASS | Normal/HighRisk dry-runs create no files |
| Unsafe bootstrap target refusal | PASS | Source child target was refused |
| Bootstrap integration | PASS | Temporary project created and validated |
| HighRisk + AI change integration | PASS | `publish-tournament` workspace created with 14 files and validated |
| Backend typecheck | PASS | `pnpm exec tsc --noEmit --pretty false` |
| Frontend typecheck | PASS | `pnpm exec tsc --noEmit --pretty false` |
| Backend unit tests | PASS | 42 suites, 366 tests |
| Frontend build | BASELINE PASS / POLICY REVIEW | Prior audit build passed in isolated output, but Next config still skips type validation |
| Frontend lint | NOT VERIFIED | Prior run exceeded 240 seconds and was stopped |
| Root Git status | REVIEW | Root reports not a Git repository |
| Backend Git status | CLEAN AT CHECK | No tracked modifications reported |
| Frontend Git status | REVIEW | Existing uncommitted `src/app/sitemap.ts` change: 38 insertions, 1 deletion; not created by this audit |

## 3. Workflow/tooling findings

### WF-001 — Validator does not enforce its own tier gates

**Severity:** P1 — quality gate weakness  
**Status:** Open  
**Evidence:** `workflow/harness/validate-workflow.ps1:106-127` only requires `README.md`, `07-plan.md` through `12-release-evidence.md` and simple Tier/Status regex. It does not require `00-discovery-brief.md` and data/API/UI artifacts for `Normal`, `01-architecture-review.md` and `05-security-delta.md` for `HighRisk`, or `06-ai-eval-task.yaml` when AI is selected.

**Risk:** A generated HighRisk change can pass validation while missing discovery, architecture, security or AI evaluation artifacts. The validator currently proves file shape, not gate completion.

**Recommended upgrade:** Parse tier and artifact map, enforce conditional files, reject placeholder statuses for hard gates, require evidence references and check `PASS`/`BLOCKED` semantics before release.

### WF-002 — No semantic validation for contracts or documentation links

**Severity:** P1 — CI quality weakness  
**Status:** Open  
**Evidence:** `workflow/harness/validate-workflow.ps1` parses JSON and PowerShell only. `workflow/standards/contracts/examples/create-tournament.openapi.yaml` and YAML templates are not passed through an OpenAPI/YAML validator; Markdown links and headings are not checked.

**Risk:** A syntactically present but semantically invalid contract can be treated as valid. Broken references can make agent handoff fail at runtime.

**Recommended upgrade:** Pin a validator in the target project's CI, for example an OpenAPI 3.1 validator plus JSON Schema validator and Markdown link checker. Keep the current validator honest and report `NOT_AVAILABLE` when optional dependencies are absent.

### WF-003 — Bootstrap is not a full-fidelity workflow export

**Severity:** P2 — reuse limitation  
**Status:** Open  
**Evidence:** `workflow/harness/init-workflow.ps1:64-85` copies core files plus `standards/`, `templates/`, `phases/`, `security/` and `harness/`, but omits `examples/`, `audits/`, `decisions/`, and existing research/knowledge content. Lines `172-188` replace the grouped source manifest with a flat `files` inventory and version `bootstrap-1.0.0`.

**Risk:** A new project receives the operational standards but loses useful ADRs, examples, research context and audit history. Consumers that expect grouped manifest sections need an adaptation step.

**Recommended upgrade:** Add profile flags such as `Core`, `Web`, `Security`, `AI`, `Full`; copy selected examples/decisions; generate a grouped manifest preserving source version and profile selection. Keep project-specific audit history excluded by default.

### WF-004 — Manifest inventory semantics are ambiguous

**Severity:** P2 — maintainability  
**Status:** Open  
**Evidence:** Cross-check found 85 physical workflow files, 84 unique registered paths and 7 duplicate entries across entrypoints/category arrays. `MANIFEST.json` itself is not registered as a core path.

**Risk:** It is unclear whether duplicates are intentional views or inventory errors, and a consumer cannot know whether unregistered metadata is allowed.

**Recommended upgrade:** Document `entrypoints` as a view, define `all_files` as canonical inventory, include `MANIFEST.json` explicitly or mark it as implicit, and make validator compare against the canonical list.

### WF-005 — Generated workspace has no automatic completion/evidence enforcement

**Severity:** P2 — process weakness  
**Status:** Open  
**Evidence:** `workflow/harness/new-change.ps1` creates skeletons, while `validate-workflow.ps1` does not inspect placeholder text, test status, release decision, owner or evidence links.

**Risk:** Teams can create a complete-looking workspace without having completed the required engineering work.

**Recommended upgrade:** Add a change-state parser and hard-gate profile. Allow `PASS_WITH_CONDITIONS` only with owner, expiry, compensating control and human approval; block release evidence containing `not-run`, `not-verified` or unresolved P0/P1 without explicit policy.

### WF-006 — No CI wiring or regression test suite for the workflow tools

**Severity:** P1 — automation gap  
**Status:** Open  
**Evidence:** The harness has scripts but no workflow-specific CI job or committed fixture project that runs bootstrap → generate change → validate on every change.

**Risk:** A later edit can break the generators while their documentation continues to claim that they work.

**Recommended upgrade:** Add a small fixture under a test-only path, a CI job for PowerShell parser/dry-run/integration tests, and a policy that generated test output is removed after execution.

## 4. Web app findings re-confirmed or still open

| ID | Severity | Current status | Re-confirmed evidence |
|---|---|---|---|
| AUD-001 | P0 | OPEN | `ai.service.ts:500-525` directly calls `fetch(dto.sourceUrl.trim())`, reads `response.text()`, with no visible host/IP allowlist, private-IP/DNS-rebinding protection, redirect cap or byte cap |
| AUD-002 | P0 | OPEN | `docker-compose.yml:6-10,23-24,35,55-71,113-135` contains default DB/JWT values, exposed DB/Redis/MediaMTX ports, mutable `:latest` images and development default |
| AUD-003 | P1 | OPEN | Prior audit: public upload lacks auth/quota/ownership/magic-byte and private-delivery policy |
| AUD-004 | P1 | OPEN | `frontend/package.json:51` still declares `xlsx` `^0.18.5`; prior audit recorded high dependency findings including Multer/xlsx |
| AUD-005 | P1 | OPEN | Prior audit: in-memory/custom rate limiting and non-production 100000 fallback |
| AUD-006–009 | P1 | OPEN | Prior audit: slot release idempotency, swallowed payment side effects, non-atomic payment/receipt and cross-entity integrity gaps |
| AUD-010 | P1 | OPEN | `frontend/next.config.ts:11-13` still sets `typescript.ignoreBuildErrors: true` |
| AUD-011 | P1 | OPEN | `frontend/package.json:6-11` has no frontend test/E2E script; prior lint run was inconclusive |
| AUD-012 | P1 | OPEN | `deploy.sh:56` still uses `|| echo` after migration; deployment remains mutable/latest and lacks health-gated rollback |
| AUD-013 | P1 | OPEN | Prior audit and `app.controller.ts` baseline show no complete live/ready/metrics/tracing contract |
| AUD-014 | P1 | OPEN | `ai.service.ts:397-400,452-455` returns upstream `error.message`; public AI surface and resource budget remain concerns |
| AUD-015 | P1 | OPEN | Prior audit: wildcard subdomain CORS and unrestricted trust proxy require explicit threat model/config review |
| AUD-016–020 | P2 | OPEN | Prior audit: in-memory presence, anonymous socket policy, free-form status, unstructured logs and import hardening remain planned |

## 5. What passed does and does not mean

Backend typecheck and 42/366 unit tests pass, and the workflow generators pass an isolated integration test. These results show that the checked commands completed successfully; they do not prove production security, complete business correctness, semantic contract validity, accessibility, deployment safety or legal compliance.

The frontend has an existing uncommitted `src/app/sitemap.ts` change. Because the root is not recognized as a Git repository and the frontend file is not authored by this audit, it must be reviewed by the project owner before any commit or release decision. Do not use reset, restore or clean to remove it.

## 6. Upgrade priority

| Priority | Work | Why |
|---|---|---|
| P0 | Remediate AUD-001 and AUD-002 | Current app should remain blocked from public production until SSRF-like fetch and unsafe deployment defaults are closed |
| P1 | Enforce tier-aware validator and add workflow CI fixture | Prevent the workflow from reporting a HighRisk change as structurally valid while required gates are missing |
| P1 | Add pinned semantic contract validation | Protect API/schema interoperability rather than only file existence |
| P1 | Remediate AUD-003/AUD-004/AUD-010/AUD-011/AUD-012 | Upload, dependency, build, E2E and deployment failures remain release risks |
| P1 | Add SRE/AI evidence runners | Turn SLO, rollback, AI safety and cost policy into repeatable evidence |
| P2 | Improve bootstrap profiles and manifest semantics | Make reuse across unrelated web-app domains clearer and higher fidelity |
| P2 | Add dashboard/documentation site | Useful after pilot and CI gates, not a prerequisite for using the framework |

## 7. Audit conclusion

- **Workflow framework:** `PASS_WITH_CONDITIONS` — usable and structurally validated, but validator enforcement and CI integration are incomplete.
- **Workflow tooling:** `PASS_WITH_CONDITIONS` — bootstrap, per-change generation and read-only validation work in tested scenarios; semantic and tier-aware enforcement remain open.
- **Current web app:** `NEEDS_REVIEW / PRODUCTION BLOCKED` — AUD-001 and AUD-002 remain open, and the prior P1/P2 backlog is not closed by this audit.

## References

[1]: [Existing web app audit](WEB_APP_AUDIT_2026-08-22.md)  
[2]: [Existing remediation backlog](REMEDIATION_BACKLOG.md)  
[3]: [Workflow tooling release evidence](WORKFLOW_TOOLING_RELEASE_2026-08-22.md)  
[4]: [Workflow standards release evidence](STANDARDS_PACK_RELEASE_2026-08-22.md)  
[5]: [OWASP SSRF Prevention Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Server_Side_Request_Forgery_Prevention_Cheat_Sheet.html)  
[6]: [OWASP File Upload Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/File_Upload_Cheat_Sheet.html)  
[7]: [OpenAPI Specification](https://spec.openapis.org/oas/latest.html)  
