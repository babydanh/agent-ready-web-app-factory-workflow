# Audit and Compliance Specification

## 1. Mục tiêu

Audit không phải là chạy một scanner rồi ghi PASS. Audit là quy trình chứng minh **requirement → control → implementation → test → evidence → owner**. Mỗi kết luận phải có phạm vi, thời điểm, version, phương pháp và giới hạn.

## 2. Compliance profile

Mỗi dự án chọn profile trước khi code:

| Profile | Khi dùng | Gates tối thiểu |
|---|---|---|
| `MVP_INTERNAL` | Prototype/nội bộ, dữ liệu không nhạy cảm | Contract, basic auth, unit/API, backup/dev recovery |
| `PUBLIC_WEB` | Web app có user public | API contract, OWASP risk review, rate limit, WCAG 2.2 AA target, E2E, observability |
| `MONEY_MOVING` | Payment/payout/ledger | Idempotency, signature, transaction, reconciliation, audit log, rollback, incident drill |
| `AI_ENABLED` | Có LLM/external URL/tool | Prompt/data boundary, SSRF/egress, quota, output schema, redaction, abuse tests |
| `REGULATED_OR_HIGH_RISK` | PII/health/finance hoặc policy contract | Legal/privacy owner, data retention, access review, formal threat model, pen test as required |

Profile không phải chứng nhận pháp lý. Compliance với một standard cụ thể phải được owner xác định phạm vi, version và applicable requirement.

## 3. Requirement traceability matrix

Mỗi feature tạo matrix:

| Requirement ID | Risk/control | Artifact | Code location | Test/evidence | Owner | Status |
|---|---|---|---|---|---|---|
| REQ-001 | User can register | PRD/API/UI | route/service/screen | API + E2E | Backend/QA | Open |
| SEC-001 | Only owner can edit | Threat model/policy | guard/service/query | IDOR negative test | Security | Open |
| A11Y-001 | Form keyboard accessible | UI spec | component/page | keyboard trace | Frontend/QA | Open |
| OPS-001 | Failed payment retried | ADR/runbook | outbox/worker | failure drill | DevOps | Open |

Không được đóng feature nếu còn requirement critical không có test/evidence hoặc có finding P0/P1 chưa có risk acceptance.

## 4. Audit order

```text
Scope & asset inventory
→ Data classification
→ Threat model
→ Contract/schema review
→ Authorization/ownership review
→ Code review
→ Dependency/config scan
→ Unit/API/contract tests
→ E2E/browser/accessibility review
→ Concurrency/load checks
→ Deployment/readiness/rollback drill
→ Findings severity/owner/deadline
→ Re-test and close
```

Audit phải ghi những gì **không** được kiểm tra, ví dụ chưa có production credentials, chưa chạy external DAST, chưa có load test hoặc chưa verify restore. Không biến skipped thành pass.

## 5. Evidence standard

Evidence hợp lệ phải có:

- commit/hash hoặc working tree snapshot;
- file path và line/route/test ID;
- command/tool version và timestamp;
- input fixture hoặc test scenario;
- output/screenshot/trace/report;
- scope và limitation;
- reviewer/owner.

Evidence không được chứa password, API key, refresh token, payment secret, PII không cần thiết hoặc production payload nguyên bản. Redact trước khi lưu.

## 6. Severity model

| Severity | Tiêu chí | Release rule |
|---|---|---|
| P0 | Remote/internal compromise, secret/default production, payment forgery hoặc data destructive path | Block |
| P1 | Unauthorized access/IDOR, reliable abuse, integrity race, high CVE, migration/release loss | Block public release hoặc risk acceptance có expiry |
| P2 | Limited impact, defense gap, availability/observability/maintainability issue | Plan and monitor |
| P3 | Cosmetic/documentation/low residual risk | Fix opportunistically |

Severity phải dựa vào exploitability, affected assets, exposure, prerequisites, blast radius và detectability. CVSS có thể tham khảo nhưng không thay thế context của ứng dụng.

## 7. Contract audit gates

| Gate | Pass condition |
|---|---|
| Data | Canonical field/type/nullability/privacy/status registry được duyệt |
| API | OpenAPI/JSON Schema request/response/error fixtures validate |
| Error | HTTP status, `code`, problem type, detail redaction và localization ổn định |
| Auth | Authn, role, ownership, tenant scope, CSRF/session policy có negative tests |
| Mutation | Idempotency, conflict/version, retry/rollback đã định nghĩa |
| Realtime | Event schema, sequence/revision, resync và permission đã test |
| UI | Screen state matrix và API mapping không đoán theo message |
| Accessibility | Keyboard, screen reader names, contrast, focus, reflow được kiểm tra |
| Ops | Health/readiness, logs, metrics, alerts, backup/restore và rollback có evidence |

## 8. AI Agent audit gates

AI Agent chỉ được phép trả `DONE` khi:

1. task input có source of truth, allowed scope và acceptance criteria;
2. agent report liệt kê changed files và contract changes;
3. output được validate bằng schema hoặc test;
4. security-sensitive code có Security Agent review;
5. migration có rollback/compatibility note;
6. test command thực sự chạy, không bị skip/timeout giả;
7. findings chưa giải quyết được gắn owner và trạng thái `BLOCKED`/`NEEDS_HUMAN_REVIEW`;
8. agent không đọc/in secret hoặc gọi production side effect.

## 9. Accessibility audit

Mục tiêu mặc định là WCAG 2.2 AA. WCAG 2.2 là Recommendation của W3C, có bốn nguyên tắc perceivable, operable, understandable và robust, với success criteria có thể kiểm thử; W3C cũng nêu rằng đánh giá cần kết hợp automated testing và human evaluation.[1]

Accessibility report phải ghi browser/viewport, keyboard path, assistive technology nếu có, automated rules, false positive/waiver và human findings. Không claim “WCAG compliant” chỉ vì điểm Lighthouse.

## 10. Security and privacy audit

Security review phải xem auth, authorization, input validation, output encoding, secrets, dependency, SSRF, upload, CSRF, CORS, WebSocket, rate limit, webhook signature, log redaction, data retention và incident response. Privacy review phải ghi data inventory, purpose, minimization, access, retention, deletion/export và third-party processors khi applicable.

## 11. Release decision

```text
PASS                 = gates pass + no blocking finding + evidence complete
PASS_WITH_RISK       = residual P2/P3 + owner/deadline/monitoring documented
NEEDS_REVIEW         = incomplete evidence, skipped critical test, or P1 pending
BLOCKED              = P0, unsafe production configuration, failed migration/rollback, or auth/integrity unproven
```

Reviewer phải ký release decision và nêu rõ những việc chưa làm. Không dùng chữ “100% secure”, “fully compliant” hoặc “production-ready” nếu không có scope và evidence tương ứng.

## References

[1]: [W3C Web Content Accessibility Guidelines (WCAG) 2.2](https://www.w3.org/TR/WCAG22/)  
[2]: [OWASP Application Security Verification Standard](https://owasp.org/www-project-application-security-verification-standard/)  
[3]: [RFC 9457 — Problem Details for HTTP APIs](https://www.rfc-editor.org/info/rfc9457/)
