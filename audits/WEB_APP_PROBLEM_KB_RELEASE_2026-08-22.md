# Web App Problem Knowledge Base Release Evidence — v1.6.0

**Ngày:** 2026-08-22  
**Phạm vi:** Knowledge base và playbook domain-agnostic cho các bài toán web app/backend phổ biến.  
**Chế độ:** Documentation/tooling only; không sửa source backend/frontend và không đóng gói ZIP.

## Artifact inventory

| Nhóm | Artifact |
|---|---|
| Knowledge index | `knowledge/README.md` |
| Problem catalog | `knowledge/WEB_APP_PROBLEM_CATALOG.md` |
| Backend playbook | `knowledge/BACKEND_PROBLEM_PLAYBOOK.md` |
| Domain adaptation | `knowledge/DOMAIN_ADAPTATION_GUIDE.md` |
| Research | `knowledge/WEB_APP_PROBLEM_CATALOG_RESEARCH_2026-08-22.md` |
| Test matrix | `standards/PROBLEM_ORIENTED_TEST_MATRIX.md` |
| Execution checklist | `standards/PROBLEM_CATALOG_CHECKLIST.md` |
| Feature problem map | `standards/templates/WEB_APP_PROBLEM_MAP.template.md` |
| Backend feature design | `standards/templates/BACKEND_FEATURE_DESIGN.template.md` |
| Cross-domain example | `examples/booking-room-problem-map.md` |

## Coverage

Catalog gồm 24 problem cards từ product ambiguity, lifecycle, CRUD, API, auth/session, authorization, tenant isolation, transaction/concurrency, idempotency, list/search, upload/import/export, external integration, payment/ledger, notification, realtime, jobs, cache, AI, observability, deployment, privacy, performance, supply chain và frontend state/accessibility.

Backend playbook có recipe cho CRUD, booking/reservation, payment/ledger, external API, inbox/outbox, upload/import/export, search/list/report, notification, realtime, queue/worker, cache, authentication/recovery, AI/tool call và migration/rollback. Test matrix chuyển failure modes thành scenarios theo SmallFix/Normal/HighRisk.

Domain adaptation guide định nghĩa lớp khung dùng chung, lớp technical standards và lớp domain model phải thiết kế lại; có archetype/profile cho e-commerce, booking, SaaS multi-tenant, CRM/ERP, LMS, CMS, social, marketplace, media/live, AI và high-impact systems.

## Integration

`README.md`, `WORKFLOW.md`, `SKILL.md`, `AGENTS.md`, `standards/README.md` đã yêu cầu chọn problem cards/profile trước discovery; feature có backend/side effect phải đọc backend playbook và chọn test rows. `init-workflow.ps1` copy knowledge index/catalog/playbook/domain guide/research, examples và decisions. `new-change.ps1` luôn tạo `00-problem-map.md` và Normal/HighRisk tạo thêm `02-backend-feature-design.md`. `validate-workflow.ps1` enforce các artifact theo tier và AI flag.

## Validation

| Check | Result |
|---|---|
| Manifest JSON/path validator | PASS |
| Manifest version | `1.6.0` |
| Physical workflow files cross-check | PASS; 0 unregistered non-manifest files |
| Empty files | PASS; 0 |
| JSON files | PASS; 5 parsed |
| PowerShell harness parser | PASS |
| Bootstrap dry-run | PASS; no target created |
| HighRisk + AI change integration | PASS |
| Tier-aware change validation | PASS |
| Backend typecheck | PASS |
| Frontend typecheck | PASS |
| Backend unit tests | PASS; 42 suites / 366 tests |
| New artifact secret-like scan | PASS; 0 hits for checked patterns |

## Research basis

The catalog references OWASP ASVS/API Security, RFC 9457, PostgreSQL Transaction Isolation, Stripe idempotent requests, Socket.IO Delivery Guarantees, BullMQ retrying jobs, Docker Compose startup order and OpenTelemetry Signals. These references support patterns and verification questions; they do not certify any project as secure, reliable or legally compliant.

## Known limitations

The current validator does not semantic-validate OpenAPI/YAML/Markdown links without pinned dependencies, does not execute the full problem-oriented test matrix, and does not prove placeholders are completed. AI evaluation runner, architecture fitness runner, SRE evidence runner and dashboard remain future upgrades. A real pilot feature is still required to measure whether the process is efficient in practice.

## Decision

**Decision:** `PASS_WITH_CONDITIONS`  
**Conditions:** Use the knowledge base on one real feature, record missing/extra cards, add CI fixture and semantic validators before treating the workflow as a fully automated engineering platform. Keep P0/P1 application findings separate from workflow readiness.
