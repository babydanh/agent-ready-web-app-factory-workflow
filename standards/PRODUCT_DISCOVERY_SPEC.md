# Product Discovery Specification

**Version:** 1.0  
**Status:** Required standard for normal and high-risk product work  
**Scope:** Web application features, product initiatives and material changes to an existing service  
**Owner:** Product Owner with UX/Research and Engineering participation

> **Mục đích:** xác định đúng vấn đề, người dùng, bối cảnh, ràng buộc và tiêu chí thành công trước khi cam kết xây dựng giải pháp.

## 1. Vai trò của discovery

Discovery là giai đoạn tìm hiểu vấn đề trước khi cam kết xây dựng service. Cần hiểu user đang cố đạt được gì, bối cảnh vận hành, ràng buộc công nghệ/pháp lý/quy trình, cơ hội tái sử dụng dữ liệu hoặc service, phương án thay thế cho việc xây code và cách đo thành công.[1]

Discovery không phải là giai đoạn để viết code production hoặc chỉ để chứng minh một solution có sẵn là đúng. Nghiên cứu phải được thiết kế để có thể phát hiện giả định sai, kể cả khả năng kết luận **không nên xây** hoặc nên giải quyết bằng quy trình, nội dung, API, đào tạo hay thay đổi vận hành.[1] [2]

## 2. Khi nào bắt buộc chạy discovery

| Tình huống | Mức discovery |
|---|---|
| Typo, bug đã hiểu rõ, không đổi user flow/contract/data | Không cần full discovery; ghi problem statement ngắn |
| Feature mới hoặc thay đổi hành vi user | Lite discovery bắt buộc |
| Thay đổi workflow quan trọng, role, payment, PII, AI, realtime hoặc nhiều team | Full discovery và risk review |
| Sản phẩm/initiative mới hoặc chưa rõ có nên xây hay không | Discovery đầy đủ với go/no-go |
| Incident/hotfix production | Ưu tiên khôi phục dịch vụ; discovery retrospective sau khi ổn định |

Không được dùng “đã có solution từ stakeholder” làm bằng chứng rằng discovery hoàn tất. Solution phải được chuyển thành problem statement và hypothesis có thể kiểm chứng.

## 3. Discovery outcomes

Discovery chỉ được coi là hoàn tất khi team có đủ bằng chứng để trả lời các câu hỏi sau:

| Câu hỏi | Output bắt buộc |
|---|---|
| Ai gặp vấn đề? | User segments/personas, role/ownership và accessibility/context notes |
| Họ đang cố làm gì? | User goal, job/story, current journey và pain points |
| Vấn đề có đáng giải quyết không? | Problem statement, frequency/severity, opportunity sizing hoặc evidence định tính |
| Vì sao vấn đề xảy ra? | Root-cause hypotheses và assumptions register |
| Có ràng buộc nào? | Legal/policy, data, tech, operation, budget, timeline và dependency constraints |
| Có thể giải quyết mà không xây thêm hệ thống không? | Alternatives considered và decision rationale |
| Làm sao biết đã thành công? | Outcome metrics, guardrail metrics, baseline, target và measurement plan |
| Có nên đi tiếp không? | Go / Go with conditions / Hold / Stop decision |

## 4. Quy trình chuẩn

### 4.1 Frame — đặt mục tiêu discovery

Tạo `00-discovery-brief.md` trước khi phỏng vấn hoặc thiết kế giải pháp. Brief phải ghi rõ decision cần đưa ra, phạm vi, ngoài phạm vi, thời gian dự kiến, team tham gia, rủi ro nếu hiểu sai và tiêu chí kết thúc.

```yaml
id: DISC-<slug>
owner: <person-or-team>
decision_to_make: <what must be decided>
problem_area: <domain>
in_scope: []
out_of_scope: []
known_constraints: []
assumptions_to_test: []
research_window: <start/end or timebox>
exit_criteria: []
```

Mục tiêu phải mô tả điều cần học, không mô tả solution đã quyết định. Ví dụ, “hiểu vì sao organizer bỏ dở lúc tạo giải” tốt hơn “xây wizard tạo giải năm bước”.

### 4.2 Understand — hiểu user và context

Phân loại user theo **job, quyền hạn, tần suất, mức độ rủi ro và accessibility needs**, không chỉ theo tên role trong database. Với hệ thống tournament, tối thiểu cần xem xét organizer, participant, referee, admin/moderator, viewer và payment/support operator nếu các nhóm này tồn tại.

Nghiên cứu nên quan sát cách user thực sự hoàn thành công việc, gồm công cụ hiện tại, dữ liệu đầu vào, điểm chuyển giao, workaround, lỗi thường gặp, thời điểm cần trợ giúp và hậu quả của sai sót. User research nên có sự tham gia của team chứ không chỉ nhận lại một slide deck; hướng dẫn GDS khuyến nghị nghiên cứu định tính theo context, gặp nhiều user type và để team trực tiếp quan sát một phần phỏng vấn.[2]

Artifact tối thiểu:

| Artifact | Nội dung |
|---|---|
| `user-segments.md` | Segment, job, quyền, context, frequency, accessibility và confidence |
| `journey-map.md` | Before/during/after, touchpoint, pain, opportunity, owner |
| `research-notes/` | Interview/observation notes đã loại PII không cần thiết |
| `evidence-log.md` | Claim, evidence source, date, confidence, contradiction |

Không lưu raw PII trong workflow package. Nếu cần lưu interview evidence, dùng participant ID giả, consent/status và redaction policy.

### 4.3 Define — viết problem và opportunity

Problem statement chuẩn có cấu trúc:

```text
[User segment] cần [job/outcome] trong [context], nhưng đang gặp [observable problem]
được biểu hiện bởi [evidence]. Điều này gây [impact]. Chưa cam kết solution cụ thể.
```

Mỗi problem phải có **evidence confidence**: `Observed`, `Reported`, `Measured`, `Inferred` hoặc `Unknown`. Claim quan trọng không được chỉ dựa vào `Inferred`.

Không dùng các câu như “user cần dashboard đẹp”, “cần microservice” hoặc “cần AI” làm problem statement. Đó là solution/implementation preference, cần chuyển thành outcome và kiểm chứng.

### 4.4 Hypothesize — quản lý assumptions

Tạo assumption register theo mẫu:

| ID | Assumption | Loại | Evidence hiện tại | Confidence | Risk nếu sai | Cách test | Owner | Status |
|---|---|---|---|---|---|---|---|---|
| A-001 | Organizer cần preview trước khi publish | Behavior | Interview 2 người | Medium | High | Prototype test | Product | Open |

Phân biệt:

- **Desirability:** user có muốn/nhận giá trị không.
- **Usability:** user có hoàn thành được không.
- **Feasibility:** hệ thống, dữ liệu, performance và vận hành có làm được không.
- **Viability:** chi phí, policy, revenue và ownership có hợp lý không.
- **Safety/compliance:** có tạo risk về auth, PII, payment, accessibility hoặc abuse không.

Ưu tiên test assumption theo công thức thực dụng: **impact nếu sai × độ không chắc chắn × chi phí trì hoãn**. Không được chỉ test assumption dễ nhất.

### 4.5 Explore — đánh giá các phương án

Mọi feature normal trở lên phải ghi tối thiểu ba hướng:

| Phương án | Giá trị | Chi phí | Rủi ro | Reuse | Quyết định |
|---|---:|---:|---:|---:|---|
| Không xây, sửa process/content |  |  |  |  |  |
| Thay đổi service hiện tại |  |  |  |  |  |
| Xây feature mới |  |  |  |  |  |

Không chấm điểm giả với độ chính xác không có bằng chứng. Dùng thang `Low/Medium/High`, ghi rationale và link tới evidence. Nếu chọn build, phải nêu rõ vì sao các phương án khác không đủ.

### 4.6 Measure — định nghĩa success

Success metric phải đo **outcome của user/business**, không chỉ output như số endpoint, số component hoặc số story đã đóng.

| Loại metric | Ví dụ | Quy tắc |
|---|---|---|
| Primary outcome | Tỷ lệ organizer publish giải thành công | Có baseline, target, window và owner |
| Quality metric | Tỷ lệ lỗi validation, abandoned step | Theo dõi phân khúc và phiên bản |
| Guardrail | Payment failure, support contact, p95 latency | Không được cải thiện primary bằng cách phá guardrail |
| Adoption | Số organizer dùng flow mới | Định nghĩa active/use rõ |
| Safety | Unauthorized access, duplicate charge | Mục tiêu zero cho violation nghiêm trọng |

Template:

```yaml
metric_id: MET-<slug>
name: <metric name>
type: primary|quality|guardrail|adoption|safety
owner: <team>
baseline: <value or unknown>
target: <value>
window: <measurement window>
segments: []
event_or_query: <how measured>
alert_threshold: <if applicable>
privacy_review: required|not-required|unknown
```

Nếu metric chưa đo được, status phải là `Measurement gap`, không được tự đặt baseline bằng phỏng đoán. Discovery output phải tạo task instrumentation nếu metric là điều kiện go/no-go.

## 5. Decision gate

Discovery review gồm Product, UX/Research, Engineering và Security/Privacy khi có risk trigger. Có thể mời Operations/Support/Finance tùy domain.

| Decision | Điều kiện |
|---|---|
| **GO** | Problem rõ, user/value đủ mạnh, constraints chấp nhận được, có metric và path test |
| **GO WITH CONDITIONS** | Có thể đi tiếp nhưng phải hoàn thành risk/measurement/dependency trước gate tiếp theo |
| **HOLD** | Cần thêm evidence hoặc chờ dependency; không bắt đầu implementation production |
| **STOP** | Không chứng minh được value, không khả thi, hoặc alternative tốt hơn |

Một discovery “STOP” là outcome hợp lệ. Không coi việc dừng là thất bại nếu nó tránh được chi phí xây sai.

## 6. Handoff sang workflow kỹ thuật

Discovery không được tự động biến thành code. Handoff phải gồm:

1. `problem statement` và non-goals.
2. User segments, journeys và accessibility/context findings.
3. Acceptance outcomes và success/guardrail metrics.
4. Assumption/evidence register với các assumption còn mở.
5. Constraints, alternatives và decision.
6. Risk tier, PII/payment/auth/AI triggers.
7. Danh sách câu hỏi cần giải quyết trong architecture/data/API/UI design.

Sau handoff, team tạo tiếp `DATA_ENTITY_SPEC`, `ENDPOINT_CONTRACT`, `SCREEN_SPEC`, threat-model delta và implementation plan theo [standards/README.md](README.md). Nếu một technical decision làm thay đổi problem/value/scope, phải quay lại discovery để reconcile, không chỉ sửa code.

## 7. AI Agent rules cho discovery

AI Agent có thể hỗ trợ tổng hợp notes, nhóm pain points, tạo câu hỏi phỏng vấn, chỉ ra mâu thuẫn và đề xuất experiment. Agent không được bịa participant quote, evidence, metric baseline, legal conclusion hoặc user need chưa được ghi nhận.

Mọi output do agent tạo phải đánh dấu:

```yaml
source_type: observed|reported|measured|inferred|agent_proposed
confidence: low|medium|high
needs_human_verification: true|false
pii_review: pending|passed|not-applicable
```

Agent phải trả `NEEDS_CLARIFICATION` khi thiếu user segment, decision cần đưa ra, evidence source hoặc owner. Agent phải trả `BLOCKED` khi yêu cầu đụng PII chưa được redaction, policy/legal judgement, production data không được phép đọc hoặc hành động ngoài scope.

## 8. Definition of Done cho discovery

- Problem statement không gắn cứng vào solution.
- User segment và context được mô tả bằng evidence.
- Có current journey và pain/opportunity map.
- Assumption register có confidence, risk, test và owner.
- Constraints và alternatives đã được xem xét.
- Primary outcome, guardrail và measurement plan có owner.
- Accessibility, privacy, security và operational concerns đã được screening.
- Decision `GO/GO WITH CONDITIONS/HOLD/STOP` có người duyệt và ngày duyệt.
- Handoff artifact đủ để Architect, Data/API, UI/UX, Security và QA tiếp tục mà không phải đoán.

## References

[1]: https://www.gov.uk/service-manual/agile-delivery/how-the-discovery-phase-works "GOV.UK Service Manual — How the discovery phase works"
[2]: https://userresearch.blog.gov.uk/2015/05/27/doing-user-research-in-the-discovery-phase/ "GOV.UK User Research Blog — Doing user research in the discovery phase"
