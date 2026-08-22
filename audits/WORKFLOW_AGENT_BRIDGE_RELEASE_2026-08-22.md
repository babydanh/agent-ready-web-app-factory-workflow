# Workflow Agent Bridge Release Evidence — v1.8.0

**Ngày:** 2026-08-22  
**Phạm vi:** One-command onboarding để liên kết `workflow/` với coding agents thông qua repository instruction adapters.  
**Chế độ:** Workflow/tooling only; không sửa backend/frontend business source, không đọc secret và không tạo ZIP.

## Design decision

Workflow được nối với agent bằng mô hình **repository-local instructions + progressive disclosure + per-change workspace**. `AGENTS.md` là adapter dùng chung; `.github/copilot-instructions.md`, `CLAUDE.md` và `.cursor/rules/workflow.mdc` là adapter tương ứng cho hệ sinh thái agent khác. Các adapter chỉ chứa routing và safety rules ngắn; knowledge/playbook chi tiết vẫn nằm trong `workflow/` và chỉ được load khi profile áp dụng.

Pattern này phù hợp với AGENTS.md open format, GitHub repository custom instructions, VS Code custom instructions và Claude project configuration [1] [2] [3] [4]. Agent host cụ thể có thể có khác biệt về discovery/priority; adapter không thay thế việc kiểm tra agent thực tế.

## New command

`workflow/harness/attach-workflow.ps1` hỗ trợ:

| Option | Behavior |
|---|---|
| `-ProjectRoot .` | Project cần nhận workflow |
| `-Agent All` | Sinh/cập nhật AGENTS, Copilot, Claude và Cursor adapters |
| `-Agent AGENTS|Copilot|Claude|Cursor` | Chỉ sinh một adapter |
| `-Profile Commerce,...` | Ghi profile routing vào managed block |
| `-Bootstrap` | Bootstrap workflow trước nếu target chưa có `workflow/` |
| `-DryRun` | Chỉ in kế hoạch, không ghi file |

Managed block có marker `WEB-APP-FACTORY-WORKFLOW:BEGIN/END`. Khi chạy lại, command chỉ thay block do nó sở hữu và giữ nguyên instruction khác trong file đích.

## Validation evidence

| Check | Result |
|---|---|
| Attach DryRun | PASS; liệt kê 4 adapter destinations, không ghi file |
| Attach real run trên project hiện tại | PASS; `WORKFLOW_ATTACHED`, 4 adapters updated |
| Adapter existence/managed marker | PASS; root `AGENTS.md`, `.github/copilot-instructions.md`, `CLAUDE.md`, `.cursor/rules/workflow.mdc` |
| Workflow strict validator after bridge | PASS; manifest v1.8.0, `registered_paths=116`, `json_files=5` |
| Bridge integration | PASS; bootstrap, merge-preservation, marker deduplication và Bootstrap DryRun |
| Original app source changes | NONE; bridge chỉ tạo/update instruction adapters và workflow harness/docs |
| Secret access | NONE; không đọc hoặc in `.env`, credentials, token hoặc production data |

## Operating model

Attach là bước onboarding một lần cho repository. Sau đó agent vẫn phải tạo `changes/<change-id>/` bằng `new-change.ps1`, chọn profile, hoàn thiện artifacts, chạy test và validator, rồi ghi evidence. Attach không tự triển khai code, không tự approve release và không làm cho legal/platform review biến mất.

## Limitations

Adapter discovery phụ thuộc agent host và cấu hình workspace. Repository instructions có thể bị personal/organization instructions hoặc managed settings override; khi có conflict phải review priority của agent cụ thể. `attach-workflow.ps1` không thể chứng minh agent đã đọc mọi tài liệu, không cấp MCP/tool permission và không tự biến workflow thành background orchestrator.

## Decision

**Decision:** `PASS_WITH_CONDITIONS`.

**Conditions:** Mở một agent session mới, xác nhận agent thấy adapter và thực sự đọc `workflow/README.md`; sau đó chạy một pilot feature thật. Nếu dùng Copilot/VS Code/Claude/Cursor, kiểm tra discovery theo phiên bản công cụ đang sử dụng. Giữ legal/platform status và source-app P0/P1 findings độc lập với workflow bridge.

## References

[1]: https://agents.md/ "AGENTS.md — open format for guiding coding agents"
[2]: https://docs.github.com/en/copilot/customizing-copilot/adding-repository-custom-instructions-for-github-copilot "GitHub Copilot — Repository custom instructions"
[3]: https://code.visualstudio.com/docs/copilot/customization/custom-instructions "VS Code — Use custom instructions"
[4]: https://code.claude.com/docs/en/claude-directory "Claude Code — Project configuration directory"
