# External Workflow Patterns Research — 2026-08-22

> **Mục tiêu:** khảo sát các repository và tài liệu công khai có workflow phát triển web app/AI-assisted software engineering rõ ràng, sau đó chọn pattern có thể bổ sung cho `workflow/` của dự án Quản lý Giải đấu.

## 1. Kết luận điều hành

Không có một repository duy nhất bao phủ hoàn hảo toàn bộ bài toán **product discovery, database, API, UI/UX, security, testing, deployment, AI Agent và audit/compliance**. Các nguồn tốt thường chuyên sâu ở một lát cắt khác nhau.

Cấu trúc phù hợp nhất cho workflow hiện tại là mô hình kết hợp: giữ `workflow/` làm **governing backbone** cho A–Z, security và audit; mượn lifecycle **Spec → Plan → Tasks → Implement → Verify → Converge** từ GitHub Spec Kit; mượn progressive context, readiness gate và retrospective từ BMAD; mượn change folder nhẹ, brownfield-friendly từ OpenSpec; mượn Red → Green → Refactor từ hướng dẫn TDD của VS Code; và mượn instruction boundaries, path-specific rules, deterministic commands, bounded autonomy từ GitHub Copilot/AI Development Patterns.

Nói cách khác, không nên sao chép nguyên xi một framework. Nên xây một **local operating system cho engineering** có ba mức thực thi:

| Mức | Khi dùng | Artifact tối thiểu |
|---|---|---|
| **Small fix** | Typo, bug nhỏ, refactor cục bộ, không đổi contract/schema | Task brief, test evidence, short review |
| **Normal feature** | Thêm nghiệp vụ, endpoint, màn hình hoặc thay đổi data flow | Brief/spec, data entity, endpoint contract, screen spec, plan, tasks, tests, review |
| **High-risk change** | Auth, payment, upload, AI, migration lớn, realtime, infra, PII | Toàn bộ artifact normal feature + threat model delta, migration/rollback, abuse/concurrency tests, approval và compliance evidence |

## 2. Các nguồn đã khảo sát

### 2.1 GitHub Spec Kit

Repository: [github/spec-kit](https://github.com/github/spec-kit)

Tài liệu chính thức: [Spec Kit Documentation](https://github.github.com/spec-kit/)

Spec Kit đặt **Spec-Driven Development** làm trung tâm. Flow cốt lõi là **Spec → Plan → Tasks → Implement**, mỗi phase sinh ra Markdown artifact làm context có cấu trúc cho phase sau. Tài liệu cũng nhấn mạnh quality checklist, cross-artifact analysis, command scaffolding, integrations, extensions, presets và bundles. Repo này mạnh ở khả năng biến ý định thành chuỗi artifact có thể lặp lại và hỗ trợ bước converge/re-audit sau implementation.

**Nên học:** constitution/governing rules trước feature; spec trước plan; task dependency order; implementation có kiểm tra; convergence để phát hiện phần chưa hoàn tất; bundle/preset để tái sử dụng.

**Không nên bê nguyên:** slash command UX, phase gates nặng cho mọi bug nhỏ, hoặc giả định framework riêng của Spec Kit phù hợp với mọi tool.

### 2.2 BMAD Method

Repository: [bmad-code-org/BMAD-METHOD](https://github.com/bmad-code-org/BMAD-METHOD)

Tài liệu: [BMAD Method](https://docs.bmad-method.org/) và [Workflow Map](https://github.com/bmad-code-org/BMAD-METHOD/blob/main/docs/reference/workflow-map.md)

BMAD tổ chức context tiến dần qua các nhóm: phân tích ý tưởng/nghiên cứu/product brief; PRD/UX/spec; architecture/epics/stories/readiness; build/code review/course correction/retrospective. Mỗi document làm input cho bước tiếp theo. BMAD hỗ trợ đường đi ngắn cho thay đổi nhỏ và đường đi đầy đủ cho initiative lớn, thay vì bắt mọi việc qua cùng một quy trình.

**Nên học:** progressive disclosure; tách product intent, UX, architecture, stories; readiness gate trước implementation; course correction khi yêu cầu đổi; retrospective có acceptance verdict; project context được kiểm chứng.

**Không nên bê nguyên:** bộ agent/command quá rộng nếu dự án solo chưa cần; không biến mọi task thành waterfall nhiều tài liệu.

### 2.3 OpenSpec

Repository: [Fission-AI/OpenSpec](https://github.com/Fission-AI/OpenSpec)

OpenSpec dùng một **change folder** gồm proposal, requirements/scenarios, design và tasks; sau implementation thì verify và archive/update spec. Nó nhẹ hơn Spec Kit, linh hoạt hơn với brownfield, cho phép explore trước khi propose, quay lại sửa artifact và hỗ trợ nhiều coding assistant. OpenSpec cũng có ý tưởng shared store cho yêu cầu dùng chung giữa nhiều repository.

**Nên học:** mỗi change có thư mục riêng; requirement viết bằng scenario cụ thể; proposal/design/tasks được review trước code; archive để giữ lịch sử; hỗ trợ brownfield và cross-repo contract.

**Không nên bê nguyên:** bỏ qua security/audit vì flow nhẹ; coi archive là đủ thay cho release evidence; dùng shared store khi ownership và access policy chưa rõ.

### 2.4 VS Code — AI-assisted TDD

Tài liệu: [Set up a test-driven development flow in VS Code](https://code.visualstudio.com/docs/agents/guides/test-driven-development-guide)

Tài liệu định nghĩa chu kỳ **Red → Green → Refactor** bằng các custom agent riêng. Red chỉ viết test thất bại; Green chỉ viết implementation tối thiểu để pass; Refactor cải thiện cấu trúc nhưng không đổi behavior. Mỗi phase handoff sang phase kế tiếp, có điểm kiểm soát để con người review. Tài liệu cũng khuyên planning trước TDD, path-specific test instructions, test độc lập, test edge/error cases, chạy test thường xuyên và không để agent tự kết luận chất lượng chỉ vì test pass.

**Nên học:** TDD micro-loop cho từng acceptance criterion; producer và reviewer/test arbiter tách nhau; tool access giới hạn theo role; test phải fail đúng lý do trước khi code.

### 2.5 GitHub Copilot cloud-agent best practices

Tài liệu: [Best practices for using Copilot to work on tasks](https://docs.github.com/copilot/how-tos/agents/copilot-coding-agent/best-practices-for-using-copilot-to-work-on-tasks)

GitHub khuyến nghị task có problem statement, acceptance criteria và file scope rõ; agent nên research/plan trước khi mở pull request; làm việc trên branch và iteratively review diff. Tài liệu phân biệt task phù hợp với agent và task nên giữ human-led hoặc supervised chặt như production-critical, security/auth, incident response, domain phức tạp và yêu cầu mơ hồ. Nó cũng khuyến nghị repository-wide instructions, path-specific instructions, `AGENTS.md`, custom agents có tool scope hẹp và môi trường dependency được chuẩn bị trước để validation ổn định.

**Nên học:** task contract rõ; branch/diff review; instruction cấp repo và cấp path; agent specialist; human approval cho vùng nhạy cảm; preflight environment.

### 2.6 GitHub Awesome Copilot và AGENTS.md

Repositories: [github/awesome-copilot](https://github.com/github/awesome-copilot) và [agentsmd/agents.md](https://github.com/agentsmd/agents.md)

`awesome-copilot` là catalog community về custom agents, instructions, skills, hooks, workflows và plugins. Repo cảnh báo phải inspect customization của bên thứ ba trước khi cài. `AGENTS.md` cung cấp format đơn giản để lưu context, development commands, testing instructions, project structure và PR rules gần codebase.

Bài học từ GitHub: [How to write a great AGENTS.md](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/) nhấn mạnh sáu vùng nên có: **commands, testing, project structure, code style, git workflow và boundaries**. Agent tốt cần persona cụ thể, ví dụ code thật, lệnh chạy được, phạm vi file rõ và điều cấm rõ ràng.

**Nên học:** `workflow/AGENTS.md` làm policy chung; adapter mỏng tại project `.github/`/`AGENTS.md`; specialist agent cho QA/security/docs/API; luôn ghi commands thật và boundary không đọc secrets/không sửa vùng ngoài scope.

### 2.7 TrussWorks và Microsoft Engineering Playbook

Repositories/tài liệu: [TrussWorks Engineering Playbook](https://github.com/trussworks/Engineering-Playbook), [Microsoft Code With Engineering Playbook](https://microsoft.github.io/code-with-engineering-playbook/), [Microsoft Code Reviews](https://microsoft.github.io/code-with-engineering-playbook/code-reviews/)

TrussWorks xem engineering guidance là một sản phẩm documentation phải maintain: có Docusaurus, navigation, CI, pre-commit, prose/Markdown lint, contribution guide và version/tooling hygiene. Microsoft nhấn mạnh peer review trên mọi pull request/check-in để ngăn defect, chia sẻ kiến thức và tạo shared understanding.

**Nên học:** workflow docs phải có navigation và ownership; docs cũng chạy lint/CI; mỗi release có review evidence; solo developer có thể dùng adversarial review agent nhưng vẫn cần human sign-off cho high-risk thay đổi.

### 2.8 Paul Duvall — AI Development Patterns

Repository: [PaulDuvall/ai-development-patterns](https://github.com/PaulDuvall/ai-development-patterns)

Catalog này phân loại pattern thành Foundation, Development và Operations. Ý tưởng quan trọng là **Agent = Model + Harness**: harness gồm feedforward controls để hướng dẫn trước hành động và feedback sensors để kiểm tra sau hành động; deterministic checks như lint/type/test nên đi trước đánh giá AI tốn kém hơn. Với autonomous loop, phải có executable done-check, test làm arbiter chứ không phải model, bounded autonomy theo turn/time/spend/stall, một writer cho mỗi shared resource và diagnostic trail.

**Nên học:** giới hạn vòng lặp agent; producer khác grader; command pass/fail làm done-check; task atomic; one-writer ownership; observability và evidence cho agent run.

## 3. Bảng so sánh nhanh

| Nguồn | Mạnh nhất ở | Artifact/process nổi bật | Điểm yếu khi dùng một mình | Mức áp dụng cho workflow hiện tại |
|---|---|---|---|---|
| **Spec Kit** | Spec-driven lifecycle và convergence | Constitution, spec, plan, tasks, implement, converge | Khá nặng với fix nhỏ; cần adapter vào tool | **Rất cao** cho normal/high-risk feature |
| **BMAD** | Progressive context từ product đến architecture/review | Brief, PRD, UX, spec, architecture, stories, readiness, retrospective | Nhiều role/workflow; dễ over-process | **Cao** cho feature lớn và brownfield |
| **OpenSpec** | Change folder nhẹ, iterative, brownfield | Proposal, requirements/scenarios, design, tasks, verify, archive | Không tự cung cấp security/compliance sâu | **Cao** cho feature thường |
| **VS Code TDD** | Handoff theo Red/Green/Refactor | Custom agents theo phase, test-first | Tập trung coding/test, không bao phủ product/data/audit | **Cao** như inner loop |
| **GitHub Copilot guidance** | Task/instruction/tool boundary và human review | Issue contract, repo/path instructions, custom agents | Gắn một phần vào hệ sinh thái GitHub | **Cao** cho AGENTS adapter |
| **Awesome Copilot / AGENTS.md** | Mẫu thực hành agent profile | Persona, commands, boundaries, examples | Community content cần kiểm tra trước khi dùng | **Trung-cao** làm thư viện mẫu |
| **TrussWorks** | Documentation product và CI hygiene | Docs site, lint, CI, contribution | Không phải AI execution workflow | **Trung-cao** cho maintainability |
| **Microsoft playbook** | Review culture | Peer review cho mỗi PR/check-in | Hướng team process hơn là artifact schema | **Cao** cho review gate |
| **AI Development Patterns** | Harness, observability, bounded autonomy | Done-check, sensors, evidence, limits | Catalog rộng, cần chọn pattern theo maturity | **Rất cao** cho agent safety |

## 4. Pattern nên tích hợp vào `workflow/`

### 4.1 Thêm lifecycle per-change, không thay thế A–Z

Giữ phase A–Z hiện tại làm lifecycle cấp dự án. Bổ sung một lifecycle cấp feature:

```text
Intake
  → Explore / clarify
  → Brief + acceptance criteria
  → Canonical data + API + UI contracts
  → Threat-model delta and risk tier
  → Plan + dependency-ordered tasks
  → TDD/implementation loop
  → Contract/unit/integration/E2E/accessibility/security checks
  → Adversarial review
  → Converge against spec and evidence
  → Release / archive / retrospective
```

Mỗi bước phải chỉ ra **input, output, owner, command/check và stop condition**. Nếu thiếu context hoặc contract thì trạng thái là `NEEDS_CLARIFICATION`; nếu bị chặn bởi security, dependency, environment hoặc quyền thì là `BLOCKED`, không được tự điền giả định.

### 4.2 Dùng tiered workflow để tránh quá tải tài liệu

| Tier | Bắt buộc | Không bắt buộc mặc định |
|---|---|---|
| Small fix | Scope, acceptance, targeted test, diff review | PRD, architecture, full compliance matrix |
| Normal feature | Feature spec, data/entity spec, endpoint contract, screen spec, implementation plan, test evidence, review | Full threat model nếu không có risk trigger |
| High-risk | Normal feature artifacts + threat model delta, security matrix, migration/rollback, concurrency/abuse tests, observability, approval, traceability | Không được rút gọn chỉ vì agent đã chạy pass |

### 4.3 Tách outer loop và inner loop

**Outer loop** xử lý product intent, data/API/UI contract, architecture, security, dependency và release evidence. **Inner loop** xử lý từng acceptance criterion bằng Red → Green → Refactor hoặc test → implementation → verify. Việc tách hai loop giúp agent không nhảy thẳng từ một prompt mơ hồ sang sửa toàn bộ repository.

### 4.4 Chuẩn hóa specialist agent

Không nên dùng một “general coding agent” cho mọi việc. Nên có các profile có boundary rõ:

| Agent | Được làm | Không được tự làm |
|---|---|---|
| **Recon/Planner** | Đọc repo, phân tích impact, viết plan | Sửa source |
| **Data/API Contract** | Viết entity/endpoint contract, schema, fixtures | Tự đổi DB production hoặc silently đổi envelope |
| **Backend** | Implement service/controller/repository theo contract | Bỏ qua auth/ownership/idempotency |
| **Frontend/UI** | Implement screen/components/states theo screen spec | Tự tạo field/API/status ngoài contract |
| **TDD/QA** | Viết test, chạy test, phân tích failure | Xóa test để làm xanh suite |
| **Security** | Threat review, negative tests, dependency/config review | Tự chấp thuận risk P0/P1 |
| **Adversarial Reviewer** | Tìm drift, edge case, security/compliance gap | Làm producer và tự certify cùng một change |
| **Release/Evidence** | Gom check results, traceability, release note | Deploy production nếu chưa có approval |

Mỗi profile nên chứa: commands thực tế, project structure, file scope, code examples, testing rules, Git/PR rules, `Always/Ask/Never` boundaries và output schema.

### 4.5 Thiết kế harness theo nguyên tắc bounded autonomy

Một loop agent chỉ được chạy tự động khi có done-check deterministic, rollback/reversal rõ và owner file không bị tranh chấp. Cần giới hạn số lượt, thời gian, chi phí, số file, vùng được sửa và số lần retry. Model không được là grader duy nhất; kết quả phải dựa trên tests/checks/evidence và review độc lập. Với database migration, auth, payment, public upload, AI fetch hoặc production deploy, mặc định chuyển sang supervised mode.

### 4.6 Đưa convergence thành gate bắt buộc

Sau implementation, agent phải đối chiếu từng acceptance criterion với code, tests, contract, UI states, security controls và evidence. Những phần chưa làm phải được ghi thành task còn tồn tại; không được báo “complete” chỉ vì build pass. Đây là pattern quan trọng nhất để ngăn spec drift.

## 5. Cách học theo thứ tự

### Giai đoạn 1 — Nắm tư duy artifact

Đọc [Spec Kit Documentation](https://github.github.com/spec-kit/) để hiểu spec-first và flow Spec → Plan → Tasks → Implement. Sau đó đọc [OpenSpec](https://github.com/Fission-AI/OpenSpec) để thấy cách làm nhẹ theo từng change folder.

### Giai đoạn 2 — Nắm product-to-architecture context

Đọc [BMAD Workflow Map](https://github.com/bmad-code-org/BMAD-METHOD/blob/main/docs/reference/workflow-map.md), tập trung vào product brief, PRD/UX/spec, architecture, stories/readiness và retrospective. Không cần cài toàn bộ BMAD ngay; chỉ lấy artifact relationship.

### Giai đoạn 3 — Nắm execution loop

Đọc [VS Code AI-assisted TDD](https://code.visualstudio.com/docs/agents/guides/test-driven-development-guide), sau đó thử một feature nhỏ bằng ba vai trò Red, Green và Refactor. Đây là bài tập dễ nhất để kiểm chứng agent handoff.

### Giai đoạn 4 — Nắm instruction và boundary

Đọc [GitHub Copilot task best practices](https://docs.github.com/copilot/how-tos/agents/copilot-coding-agent/best-practices-for-using-copilot-to-work-on-tasks), [AGENTS.md](https://github.com/agentsmd/agents.md) và bài [How to write a great AGENTS.md](https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/). Sau đó viết adapter ngắn cho project tournament, không copy toàn bộ workflow vào prompt.

### Giai đoạn 5 — Nắm harness và production discipline

Đọc [AI Development Patterns](https://github.com/PaulDuvall/ai-development-patterns), [TrussWorks Engineering Playbook](https://github.com/trussworks/Engineering-Playbook) và [Microsoft Code Reviews](https://microsoft.github.io/code-with-engineering-playbook/code-reviews/). Tập trung vào deterministic checks, bounded autonomy, docs CI, code review và evidence.

## 6. Khuyến nghị cụ thể cho repository hiện tại

Nên bổ sung một thư mục per-change, chẳng hạn `workflow/changes/`, chỉ khi bắt đầu feature mới; không cần di chuyển toàn bộ tài liệu legacy ngay lập tức. Một change bình thường có thể có:

```text
workflow/changes/<change-id>/
├── 00-brief.md
├── 01-requirements.md
├── 02-data-entity.md
├── 03-api-contract.md
├── 04-screen-spec.md
├── 05-security-delta.md
├── 06-plan.md
├── 07-tasks.md
├── 08-test-plan.md
├── 09-implementation-log.md
├── 10-convergence-review.md
└── 11-release-evidence.md
```

Có thể triển khai dần theo thứ tự: trước hết dùng template và checklist thủ công; sau đó thêm JSON Schema/contract test; tiếp theo thêm CI path validation; cuối cùng mới cân nhắc orchestration tự động. Không nên cài nhiều framework AI cùng lúc hoặc cho agent tự chạy migration/deploy production khi harness và rollback chưa chứng minh được.

## 7. Kết luận học được

Điểm chung của các nguồn chất lượng cao không phải là “prompt dài hơn”. Điểm chung là **context được lưu thành artifact**, **task có scope và acceptance rõ**, **agent có vai trò/boundary**, **test và check là feedback sensor**, **human giữ approval ở vùng rủi ro**, và **workflow có thể quay lại/converge khi implementation lệch spec**.

`workflow/` hiện tại đã có nền tảng mạnh hơn nhiều nguồn riêng lẻ vì đã bao phủ data/API/UI/security/audit. Phần nên nâng cấp tiếp không phải là thêm thật nhiều Markdown, mà là biến các nguyên tắc thành **per-change folder, tiered gates, deterministic validators, specialist adapters và evidence loop** để có thể chạy lặp lại trong dự án mới.

## References

[1]: https://github.com/github/spec-kit "GitHub Spec Kit repository"
[2]: https://github.github.com/spec-kit/ "GitHub Spec Kit Documentation"
[3]: https://docs.bmad-method.org/ "BMAD Method Documentation"
[4]: https://github.com/bmad-code-org/BMAD-METHOD/blob/main/docs/reference/workflow-map.md "BMAD Workflow Map"
[5]: https://github.com/Fission-AI/OpenSpec "Fission-AI OpenSpec repository"
[6]: https://code.visualstudio.com/docs/agents/guides/test-driven-development-guide "VS Code AI-assisted TDD guide"
[7]: https://docs.github.com/copilot/how-tos/agents/copilot-coding-agent/best-practices-for-using-copilot-to-work-on-tasks "GitHub Copilot task best practices"
[8]: https://github.com/github/awesome-copilot "GitHub Awesome Copilot repository"
[9]: https://github.com/agentsmd/agents.md "AGENTS.md open format repository"
[10]: https://github.blog/ai-and-ml/github-copilot/how-to-write-a-great-agents-md-lessons-from-over-2500-repositories/ "How to write a great AGENTS.md"
[11]: https://docs.github.com/en/copilot/tutorials/customization-library/custom-agents/your-first-custom-agent "GitHub custom agent example"
[12]: https://github.com/trussworks/Engineering-Playbook "TrussWorks Engineering Playbook"
[13]: https://microsoft.github.io/code-with-engineering-playbook/ "Microsoft Code With Engineering Playbook"
[14]: https://microsoft.github.io/code-with-engineering-playbook/code-reviews/ "Microsoft Code Reviews"
[15]: https://github.com/PaulDuvall/ai-development-patterns "Paul Duvall AI Development Patterns"
