# SRE and Platform Operations Specification

**Version:** 1.0  
**Status:** Required before production release; lightweight subset for development  
**Scope:** Runtime, deployment, reliability, observability, incident response, backup/restore, cost and operational ownership  
**Owner:** DevOps/SRE with Product and Engineering owners

> **Mục đích:** biến “đã deploy” thành một service có owner, health signal, SLO, runbook, rollback, backup/restore và bằng chứng vận hành có thể kiểm tra.

## 1. Operating model

SRE bắt đầu từ câu hỏi **user và business thực sự quan tâm behavior nào**, sau đó định nghĩa SLI, SLO và cách phản ứng khi không đạt. Google SRE phân biệt SLI là chỉ số định lượng, SLO là target/range được đo bởi SLI, còn SLA là agreement có consequence nếu không đạt; không nên chọn quá nhiều chỉ số hoặc chọn target chỉ vì đó là performance hiện tại.[1]

Mỗi service production phải có:

| Thành phần | Câu hỏi cần trả lời |
|---|---|
| Service owner | Ai chịu trách nhiệm cuối cùng? |
| Dependency map | Service phụ thuộc DB, queue, provider, storage nào? |
| SLI/SLO | Behavior nào quan trọng và target là gì? |
| Error budget | Chấp nhận bao nhiêu miss và hành động khi cạn budget? |
| Observability | Có log, metric, trace và dashboard nào? |
| Failure behavior | Dependency lỗi thì timeout/fallback/degrade ra sao? |
| Runbook | Người trực cần làm gì trong 15 phút đầu? |
| Recovery | Rollback, restore, RTO/RPO và owner là gì? |
| Security | Secret, access, audit và incident escalation ra sao? |
| Cost | Chi phí chính và budget alert là gì? |

## 2. Service catalog

Tạo `docs/operations/services/<service-id>.yaml`:

```yaml
service_id: tournament-api
name: Tournament Management API
owner_team: backend
technical_owner: <person-or-team>
business_owner: <person-or-team>
criticality: tier-1|tier-2|tier-3
environments: [local, test, staging, production]
entrypoints: [https://api.example.com]
dependencies:
  - id: postgres
    mode: synchronous
    failure_policy: fail-closed
  - id: redis
    mode: async-or-cache
    failure_policy: degrade
sli_slo_refs: [SLO-API-001]
runbook: docs/operations/runbooks/tournament-api.md
last_reviewed: YYYY-MM-DD
```

Không dùng “backend” hoặc “frontend” làm service ID nếu repository có nhiều deployable boundary. Service catalog phải phản ánh cách hệ thống chạy, không chỉ cách thư mục được tổ chức.

## 3. SLI/SLO standard

### 3.1 SLI definition

Mỗi SLI phải ghi rõ:

| Field | Yêu cầu |
|---|---|
| `sli_id` | Stable identifier |
| `service` | Service catalog ID |
| `user_journey` | Journey/endpoint/job được đo |
| `event` | Good/bad event hoặc denominator |
| `measurement_point` | Client/server/worker/provider |
| `aggregation_window` | 1m, 5m, 1h, 28d… |
| `aggregation` | Rate, percentile, count, age, throughput |
| `exclusions` | Maintenance/test traffic và lý do |
| `query/source` | Metric/log/trace/query cụ thể |
| `owner` | Người chịu trách nhiệm |

OpenTelemetry khuyến nghị semantic conventions để dùng tên chung cho traces, metrics, logs, profiles và resources; workflow này áp dụng nguyên tắc đó cho telemetry naming để dữ liệu có thể so sánh giữa codebase, library và platform.[2]

### 3.2 Baseline SLI library

| SLI | Công thức/định nghĩa baseline | Dùng cho |
|---|---|---|
| Availability | Good requests / eligible requests | HTTP/API, UI action |
| Error rate | Failed requests / total eligible requests | API/provider/worker |
| Latency | p50/p95/p99 duration của eligible requests | API, page, job |
| Throughput | Successful units / time | Queue, import, notification |
| Freshness | Age của dữ liệu/event mới nhất | Realtime/read model |
| Queue age | Tuổi item chưa xử lý | BullMQ/background jobs |
| Durability | Successful write/read-back hoặc restore verification | Data/backup |
| Correctness | Domain invariant/test pass ratio | Payment, registration, bracket |
| Recovery | Time to restore service/data | Incident/DR |

Không dùng average latency làm signal duy nhất khi tail latency quan trọng; SRE guidance khuyến nghị nhìn distribution và percentile để không che khuất nhóm request chậm.[1]

### 3.3 SLO record

```yaml
slo_id: SLO-API-001
service: tournament-api
journey: create-tournament
sli: availability
objective: ">= 99.5%"
window: 28d
eligibility: authenticated POST /tournaments with valid request
exclusions: [synthetic-test-traffic]
error_budget: "0.5%"
alert_policy: burn-rate
owner: backend
reviewed_at: YYYY-MM-DD
```

Không đặt 100% làm mục tiêu mặc định. SLO phải thể hiện trade-off product/business và cho phép error budget; error budget là input cho rollout/release priority, không phải con số chỉ để đưa vào dashboard.[1]

## 4. Reliability tiers

| Tier | Ví dụ | Operational minimum |
|---|---|---|
| Tier 1 | Auth, payment, tournament publish, core API | SLO, alert, runbook, rollback, restore drill, on-call/escalation |
| Tier 2 | Registration, bracket, notifications, realtime read model | SLO hoặc internal target, dashboard, failure test, rollback note |
| Tier 3 | Admin report, import/export, background utility | Owner, logs, retry policy, manual recovery note |
| Experimental | Prototype/AI experiment | No production data by default; explicit expiry and budget |

Criticality phải được chọn theo impact nếu service lỗi, không theo độ nổi tiếng của module.

## 5. Observability contract

### 5.1 Correlation

Mỗi request/job/event phải cố gắng duy trì:

```text
trace_id
span_id
request_id
correlation_id
service.name
service.version
environment
actor_id (pseudonymous where possible)
route/template, not raw secret-bearing URL
```

Không đưa access token, refresh token, OTP, password, payment secret, raw PII hoặc toàn bộ request body vào log mặc định. ID user phải được masking/pseudonymization theo privacy classification.

### 5.2 Structured logs

Log production phải là structured event với `timestamp`, `level`, `event_name`, `service`, `environment`, correlation fields, outcome và error classification. Mỗi event cần biết có phải security, business, operational hay debug event.

```json
{
  "event_name": "tournament.publish.completed",
  "level": "info",
  "service": "tournament-api",
  "environment": "production",
  "trace_id": "<trace-id>",
  "tournament_id": "<public-id>",
  "actor_type": "organizer",
  "duration_ms": 184,
  "outcome": "success"
}
```

### 5.3 Metrics

Metrics phải có tên, unit, type, labels được giới hạn cardinality và owner. Không đưa raw user ID, URL đầy đủ hoặc input tự do vào label. Dùng counters cho event, histograms cho latency/size, gauges cho trạng thái hiện tại và queue depth.

### 5.4 Traces

Trace cho các journey quan trọng: request vào API, DB query aggregate, queue publish/consume, payment request/webhook, object storage, AI provider và realtime broadcast. Span name phải ổn định theo route/operation template, không tạo một tên mới cho từng ID.

## 6. Health, readiness và graceful degradation

Phân biệt:

| Check | Ý nghĩa | Không được làm |
|---|---|---|
| Liveness | Process còn chạy và event loop/responding | Không query dependency nặng mỗi lần |
| Readiness | Service đủ dependency để nhận traffic | Không báo ready nếu DB/migration/config critical chưa sẵn sàng |
| Startup | Service đã hoàn tất init/migration/config load | Không mở traffic trước khi startup condition đạt |
| Dependency health | Trạng thái DB/Redis/provider riêng | Không gộp mọi lỗi thành “healthy” |

Endpoint health không được leak secret, connection string hay topology nhạy cảm. Health check phải có timeout và budget. Khi dependency optional lỗi, service phải nêu rõ degraded state; khi dependency bắt buộc lỗi, fail closed với error contract nhất quán.

Mỗi dependency cần failure policy: `fail-closed`, `fail-open`, `degrade`, `queue`, `fallback` hoặc `manual-recovery`. Không dùng retry vô hạn; retry phải có timeout, backoff, jitter, maximum attempts và idempotency strategy.

## 7. Deployment and release operations

### 7.1 Environment promotion

Artifact được build một lần và promote qua environments; không build lại bằng source khác ở từng environment. Mỗi environment có config contract, secret source, migration policy, health/readiness check và rollback procedure.

### 7.2 Release checklist

| Gate | Evidence |
|---|---|
| Build artifact reproducible | Commit SHA, build log, artifact digest |
| Tests passed | Unit/integration/E2E/contract/a11y/security result |
| Migration reviewed | Forward/backward compatibility, lock estimate, rollback note |
| Config validated | Non-secret config diff, secret presence without value disclosure |
| Health/readiness | Smoke result and dependency status |
| Observability | Dashboard/alert/runbook link |
| Rollback | Tested command/decision criteria |
| Approval | Reviewer and timestamp |
| Post-release | SLO/error budget watch window |

### 7.3 Rollback policy

Rollback decision phải biết đang rollback code, config, migration hay data. Không tự động rollback migration destructive chỉ vì application rollback được. Migration phải ưu tiên expand/contract, backward-compatible deploy sequence và có restore plan trước khi xóa dữ liệu/cột.

## 8. Incident management

### 8.1 Severity

| Severity | Impact | Response |
|---|---|---|
| SEV-0 | Data loss, active compromise, broad outage, payment integrity threat | Immediate escalation, freeze risky changes, incident commander |
| SEV-1 | Core journey unavailable or materially unsafe | Coordinated response, frequent updates, rollback/mitigation |
| SEV-2 | Degraded feature, limited users, workaround exists | Owner-led response and tracked remediation |
| SEV-3 | Minor defect, cosmetic/low-impact | Normal backlog with evidence |

Severity là impact hiện tại, không phải blame cho team. Incident channel/ticket phải ghi timeline, detection, hypotheses, actions, decision, customer impact, recovery, follow-up owners và links tới evidence.

### 8.2 First 15 minutes

Runbook phải hướng dẫn: xác định scope/impact; kiểm tra dashboard và recent deploy; bảo toàn evidence; giảm blast radius; quyết định rollback hoặc mitigation; thông báo owner/stakeholder; không chạy command phá dữ liệu nếu chưa rõ target/environment.

### 8.3 Postmortem

Postmortem không đổ lỗi và phải phân biệt trigger, contributing factors, detection gap, containment, recovery và systemic actions. Mỗi action có owner, priority, due date, verification method và liên kết tới backlog/ADR/fitness function.

## 9. Backup, restore và disaster recovery

Mỗi data store Tier 1/2 phải có:

| Field | Ý nghĩa |
|---|---|
| RPO | Mất tối đa bao nhiêu dữ liệu có thể chấp nhận |
| RTO | Khôi phục service trong bao lâu |
| Backup frequency | Tần suất và retention |
| Encryption/access | Ai được tạo/đọc/restore |
| Restore procedure | Command/runbook có version |
| Restore verification | Cách xác nhận data usable/correct |
| Cross-region/offsite | Có cần hay không và vì sao |
| Last drill | Ngày test gần nhất, kết quả, gaps |

Backup chưa được restore test không được coi là evidence của recoverability. Restore drill phải dùng sanitized/test environment nếu có thể; production restore cần approval và change record.

## 10. Cost and capacity

Service owner phải biết cost driver chính: compute, database, storage, network, queue, observability, provider/API, AI token/call và support load. Mỗi service có budget hoặc alert threshold; nếu chưa có số liệu thì ghi `unknown` và tạo instrumentation task.

Capacity note phải ghi growth assumption, bottleneck, load test result, scaling trigger, backpressure và graceful degradation. “Scale horizontally” không phải kế hoạch nếu chưa xác định state, database contention, queue semantics và cost.

## 11. AI Agent rules

Agent DevOps có thể đọc config non-secret, tạo runbook draft, chạy local validation và tổng hợp telemetry. Agent không được đọc/hiển thị secret, deploy production, xóa data, restore production hoặc thay đổi alert/SLO mà không có approval.

Agent incident response phải ưu tiên containment và evidence preservation. Không tự kết luận root cause từ một log; report phải tách `observed`, `hypothesis`, `verified`, `unknown`. Autonomous remediation chỉ được phép khi action idempotent, blast radius giới hạn, rollback rõ và policy đã phê duyệt.

## 12. Definition of Done

- Service catalog có owner, criticality, dependencies và runbook.
- SLI/SLO có metric definition, query/source, window, owner và error budget.
- Logs/metrics/traces có correlation, naming và redaction policy.
- Health/readiness/startup và degraded/failure behavior được kiểm tra.
- Deployment có artifact identity, migration plan, rollback và post-release watch.
- Incident severity, escalation, timeline và postmortem flow tồn tại.
- Backup/restore có RPO/RTO và restore drill evidence cho tier phù hợp.
- Cost/capacity assumption và alert có owner.
- Production change có release evidence; chưa đạt thì status là `BLOCKED` hoặc `GO_WITH_CONDITIONS`, không báo ready giả.

## References

[1]: https://sre.google/sre-book/service-level-objectives/ "Google SRE Book — Service Level Objectives"
[2]: https://opentelemetry.io/docs/concepts/semantic-conventions/ "OpenTelemetry — Semantic Conventions"
