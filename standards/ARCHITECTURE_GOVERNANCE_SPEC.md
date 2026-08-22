# Architecture Governance Specification

**Version:** 1.0  
**Status:** Required standard for normal and high-risk changes  
**Scope:** System architecture, application boundaries, data/API integration, runtime topology and material technical decisions  
**Owner:** Architect; engineering owner remains accountable for implementation evidence

> **Mục đích:** làm cho các quyết định kiến trúc có context, rationale, trade-off, owner và bằng chứng kiểm chứng; ngăn architecture drift mà không biến governance thành thủ tục làm chậm mọi thay đổi.

## 1. Nguyên tắc nền tảng

Architecture governance không phải là quyền phủ quyết chung chung của một cá nhân. Đây là cơ chế để các quyết định có ảnh hưởng đến quality attributes, boundaries, cost, security, operability hoặc long-term maintenance được **nhìn thấy, giải thích, kiểm tra và xem lại khi context thay đổi**.

C4 là mô hình trực quan hóa kiến trúc theo các abstraction và diagram phân cấp: system context, container, component, code; ngoài ra có system landscape, dynamic và deployment diagram.[1] ADR là record cho một architectural decision có rationale, context, trade-offs và consequences; collection của ADR tạo thành decision log của dự án.[2]

Workflow này dùng C4 để trả lời **hệ thống gồm gì và tương tác ra sao**, dùng ADR để trả lời **vì sao chọn cách đó**, dùng quality attributes/fitness functions để trả lời **làm sao biết kiến trúc vẫn nằm trong giới hạn mong muốn**.

## 2. Khi nào phải tạo hoặc cập nhật architecture artifact

| Trigger | Artifact/review bắt buộc |
|---|---|
| Thêm service/module/package hoặc đổi ownership boundary | C4 container/component + boundary review |
| Thêm database, queue, cache, external provider hoặc data store | Context/container/deployment update + ADR |
| Đổi API envelope, event schema, auth flow, payment, AI fetch hoặc upload | ADR + contract/security impact review |
| Migration lớn, partitioning, consistency/locking change | Data architecture decision + migration/rollback review |
| Thay đổi runtime/deployment/region/availability | Deployment diagram + reliability/cost review |
| Thêm dependency có quyền rộng hoặc native/system package | Dependency ADR + supply-chain/security review |
| P0/P1 audit finding hoặc repeated operational incident | Corrective ADR hoặc architecture exception record |
| Refactor nội bộ không đổi boundary/quality attribute | Short decision note; không bắt buộc full C4 |

Nếu không chắc trigger có áp dụng hay không, tạo `NEEDS_REVIEW` và để Architect quyết định; không bỏ qua vì “chỉ là refactor”.

## 3. Architecture baseline

Mỗi project phải có một baseline tối thiểu trong `docs/architecture/` hoặc thư mục tương đương:

```text
docs/architecture/
├── README.md
├── context.md                 # C4 Level 1
├── containers.md              # C4 Level 2
├── components/                # C4 Level 3 khi cần
├── deployment.md              # runtime/deployment view
├── data-flow.md               # trust boundary/data movement
├── quality-attributes.md      # NFR, budgets, SLO/constraints
├── dependency-boundaries.md   # allowed/forbidden dependencies
├── decisions/                 # ADR decision log
└── fitness-functions/         # executable or documented checks
```

Baseline phải ghi `last_verified_at`, `verified_by`, `source_commit` và status `current`, `stale`, `superseded` hoặc `unknown`. Diagram không được coi là current chỉ vì file vẫn tồn tại.

## 4. C4 documentation rules

### 4.1 System context

Context diagram phải thể hiện system of interest, user/persona, external system/provider và các interaction quan trọng. Không đưa class, table hoặc implementation detail vào context level.

### 4.2 Container

Container ở đây là deployable/runnable boundary hoặc application/data store có trách nhiệm rõ, không nhất thiết là Docker container. Với tournament app, có thể mô tả web frontend, backend API, worker, PostgreSQL, Redis, payment provider, object storage, realtime gateway và AI provider nếu chúng thực sự là runtime boundary.

Mỗi container cần có:

| Field | Yêu cầu |
|---|---|
| Name | Tên ổn định, không phụ thuộc hostname ngắn hạn |
| Responsibility | Một câu mô tả trách nhiệm chính |
| Technology | Framework/runtime/data store hiện tại |
| Owner | Team/role chịu trách nhiệm |
| Data handled | Classification và lifecycle |
| Interfaces | HTTP/event/queue/database/SDK |
| Reliability | SLO hoặc expected behavior khi dependency lỗi |
| Security boundary | Authn/authz/trust boundary |

### 4.3 Component

Component diagram chỉ dùng khi giúp quyết định hoặc review; không cần vẽ mọi class. Component phải có responsibility, dependency direction và reason tồn tại. Nếu diagram không giúp người mới hiểu flow hoặc không được dùng trong review, đánh dấu `candidate-for-removal`.

### 4.4 Dynamic và deployment view

Dynamic diagram dùng cho flow quan trọng như registration, payment, webhook, realtime update, AI request hoặc async job. Deployment diagram phải thể hiện process, network/trust zone, data store, ingress, secrets boundary, health/readiness và failure path ở mức cần thiết.

## 5. Quality attributes và architecture drivers

Mỗi normal/high-risk change phải ghi các quality attributes bị tác động:

| Attribute | Câu hỏi bắt buộc | Evidence ví dụ |
|---|---|---|
| Correctness | Invariant và consistency nào phải giữ? | Unit/integration/concurrency test |
| Security | Trust boundary, authz, secret, abuse path nào đổi? | Threat review, negative test, scan |
| Privacy | PII nào đi qua đâu, retention/deletion ra sao? | Data map, redaction/retention evidence |
| Availability | Dependency lỗi thì user thấy gì? | Failure test, runbook, SLO |
| Performance | p95/p99, query budget, page/API budget là gì? | Load/query plan/Web Vitals result |
| Scalability | Bottleneck và growth assumption nào? | Capacity note, queue/backpressure test |
| Operability | Logs, metrics, traces, alert và rollback có đủ không? | Dashboard/runbook/deploy evidence |
| Maintainability | Boundary, coupling, testability và ownership có tốt hơn không? | Dependency check, review, ADR |
| Cost | Runtime, storage, provider/API và AI cost envelope? | Estimate, budget alert, actual usage |
| Accessibility | User impact và assistive technology behavior? | Automated + manual a11y evidence |

Mọi attribute có threshold phải dùng đơn vị, percentile/window và measurement method rõ ràng. “Nhanh”, “an toàn”, “scale tốt” không phải acceptance criteria nếu không có cách kiểm tra.

## 6. ADR standard

Một ADR ghi **một decision**. Có thể link tới các ADR liên quan nhưng không gộp nhiều quyết định độc lập thành một bài viết dài.

```markdown
# ADR-<number>: <decision title>

- Status: proposed | accepted | rejected | deprecated | superseded
- Date: YYYY-MM-DD
- Owners: <people/team>
- Review date: YYYY-MM-DD or not-applicable
- Scope: <system/module>
- Drivers: <functional/non-functional requirements>
- Risk tier: low | medium | high | critical

## Context
<problem, constraints, evidence and current state>

## Decision
<what we will do and what we explicitly will not do>

## Options considered
| Option | Benefits | Costs | Risks | Reason |

## Consequences
### Positive
### Negative / debt
### Operational impact
### Security/privacy impact
### Migration/rollback impact

## Verification
<tests, metrics, diagrams, fitness functions and evidence>

## Revisit triggers
<facts that would invalidate this decision>

## Links
<requirements, contracts, incidents, PRs, evidence>
```

ADR status không đồng nghĩa với code implementation status. `accepted` nghĩa là quyết định đã được chấp thuận; implementation vẫn phải có task và evidence. Khi đổi decision, tạo ADR mới `supersedes: ADR-xxx`, không rewrite lịch sử khiến rationale cũ biến mất.

## 7. Dependency và boundary governance

Mỗi module/container phải có dependency direction. Những rule sau là baseline:

| Rule | Default |
|---|---|
| Domain/business rules gọi trực tiếp provider SDK | Forbidden; dùng adapter/port |
| Controller chứa transaction/business orchestration phức tạp | Review required; chuyển về application/domain service |
| Frontend tự định nghĩa field/status khác API contract | Forbidden |
| Module đọc trực tiếp bảng ownership của module khác | Forbidden; dùng contract/service hoặc approved read model |
| Migration gọi network/provider bên ngoài | Forbidden |
| Test phụ thuộc network thật hoặc production credential | Forbidden |
| Shared utility import ngược vào feature-specific code | Review required |
| Public endpoint không có owner/rate-limit/error policy | Forbidden |
| Cross-service event không có schema/version/consumer policy | Forbidden |

Exception phải có owner, lý do, expiry/review date, risk acceptance và kế hoạch loại bỏ. Exception không được biến thành rule mới ngầm.

## 8. Fitness functions

Fitness function là check lặp lại được để phát hiện kiến trúc vi phạm. Ưu tiên deterministic check rẻ trước semantic review đắt hơn.

| Nhóm | Ví dụ check | Tần suất |
|---|---|---|
| Structure | Import graph không vượt boundary | PR/CI |
| Contract | OpenAPI/JSON Schema/fixture khớp | PR/CI |
| Data | Migration có down/rollback note; FK/index policy | PR/CI/release |
| Security | Không token trong URL; auth guard; dependency advisory | PR/CI/nightly |
| Reliability | Health/readiness, timeout, retry/backoff và idempotency presence | PR/CI |
| Performance | Query plan regression, bundle/API budget | PR/nightly |
| Accessibility | Axe/Playwright checks, focus/keyboard contract | PR |
| Observability | Structured log fields, trace propagation, metric labels | PR/CI |
| Documentation | ADR/C4 links và freshness metadata | PR/monthly |

Fitness function phải có `id`, `purpose`, `scope`, `command`, `pass_condition`, `owner`, `severity`, `false_positive_policy` và `last_run`. Nếu chưa tự động được, viết documented/manual check thay vì giả vờ là automated control.

Ví dụ metadata:

```yaml
id: ARCH-BOUNDARY-001
purpose: Domain modules must not import infrastructure providers directly
scope: backend/src/modules/**
command: pnpm lint:architecture
pass_condition: exit_code == 0
owner: architecture
severity: high
failure_action: block-merge
last_run: <timestamp>
```

## 9. Architecture review flow

### 9.1 Lightweight review

Dùng cho thay đổi không tạo boundary mới. Author cập nhật decision note, impact checklist và test evidence; peer reviewer kiểm tra scope, dependency direction và regression risk.

### 9.2 Standard review

Dùng cho normal feature. Author chuẩn bị context/container/component view liên quan, ADR, quality attributes, data/API/UI/security impact và verification plan. Architect hoặc delegated reviewer duyệt trước implementation; sau implementation phải có convergence review.

### 9.3 High-risk review

Dùng cho auth, payment, PII, public upload, AI fetch, realtime fan-out, migration lớn, new provider, public internet exposure hoặc production infrastructure. Bắt buộc threat-model delta, failure modes, rollback, observability, cost envelope, concurrency/abuse tests và explicit approval. Agent không được tự approve high-risk architecture.

## 10. Architecture drift control

Drift là trạng thái implementation, runtime hoặc documentation không còn khớp với baseline/decision. Drift review phải xem ba mặt:

| Mặt | Kiểm tra |
|---|---|
| Structural drift | Import/module/deployment khác C4 hoặc dependency policy |
| Behavioral drift | API/event/data/security behavior khác contract/ADR |
| Operational drift | Runtime config, SLO, alert, scaling/cost khác assumptions |

Mỗi finding có severity, evidence, owner, due date và remediation link. Không sửa diagram để che drift; nếu implementation đúng hơn baseline thì cập nhật baseline bằng ADR/review.

## 11. Waiver và risk acceptance

Waiver chỉ dành cho exception có thời hạn, không phải cách bỏ qua gate. Record tối thiểu:

```yaml
waiver_id: WAIVER-<id>
control: <fitness-function or rule>
reason: <specific reason>
risk: low|medium|high|critical
mitigations: []
owner: <person/team>
approver: <authorized reviewer>
created_at: <timestamp>
expires_at: <timestamp>
follow_up_issue: <link/id>
status: active|expired|closed
```

P0/P1 security, data loss, unauthorized access, payment integrity hoặc production availability không được waive bởi agent. Nếu chưa có approver hợp lệ, status là `BLOCKED`.

## 12. AI Agent rules

Agent Architect có thể đọc code, tạo diagram/ADR draft, phân tích trade-off và đề xuất fitness functions. Agent không được tự đánh dấu `accepted`, tự gia hạn waiver, tự thay đổi security boundary hoặc tự deploy architecture change.

Agent Implementation phải load architecture baseline, ADR liên quan, dependency rules và fitness functions trước khi sửa code. Nếu phát hiện code cần phá boundary, agent phải tạo `NEEDS_CLARIFICATION` hoặc đề xuất ADR/exception; không silently bypass rule.

Agent Reviewer phải kiểm tra producer output bằng evidence độc lập. Review report phải phân biệt `verified`, `not-run`, `blocked`, `inferred` và `unknown`. “Không thấy vấn đề” không đồng nghĩa với “đã kiểm tra đầy đủ”.

## 13. Definition of Done

- Architecture impact và risk tier đã được xác định.
- C4 view liên quan được cập nhật hoặc ghi rõ không thay đổi.
- ADR tồn tại cho decision architecturally significant.
- Quality attributes có threshold hoặc rationale rõ.
- Data/API/UI/security/operations impact đã được reconcile.
- Dependency boundaries và exception policy được kiểm tra.
- Fitness functions/test/review evidence có trạng thái rõ.
- Rollback/migration/observability được ghi cho thay đổi runtime hoặc data.
- Baseline có owner và `last_verified_at`.
- Convergence review xác nhận code, docs, contract và runtime không drift nghiêm trọng.

## References

[1]: https://c4model.com/ "The C4 model for visualising software architecture"
[2]: https://adr.github.io/ "Architectural Decision Records — ADR GitHub organization"
