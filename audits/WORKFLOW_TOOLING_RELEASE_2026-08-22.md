# Workflow Tooling Release Evidence — 2026-08-22

## Release identity

- **Package:** `web-app-factory-workflow`
- **Version:** `1.3.0`
- **Scope:** Bootstrap generator, per-change workspace generator và read-only workflow validator
- **Source-code remediation:** None; chỉ thay đổi trong `workflow/`.

## Tooling delivered

| Tool | Purpose | Write behavior |
|---|---|---|
| `harness/init-workflow.ps1` | Tạo workflow copy cho project mới, copy standards/templates/phases/security/harness và tạo knowledge placeholders | Ghi vào target mới; từ chối source hoặc child path; không overwrite mặc định |
| `harness/new-change.ps1` | Tạo `changes/<change-id>/` theo `SmallFix`, `Normal`, `HighRisk`, có optional AI artifact | Ghi change workspace; không overwrite mặc định |
| `harness/validate-workflow.ps1` | Kiểm tra manifest paths, JSON, empty files, PowerShell syntax và required change artifacts | Read-only; chỉ báo PASS/FAIL |

## Supported workflow behavior

- `init-workflow.ps1` hỗ trợ `-DryRun` và `-Force`.
- `new-change.ps1` hỗ trợ `-DryRun`, `-Force`, `-Tier` và `-IncludeAI`.
- `validate-workflow.ps1` hỗ trợ validate toàn workflow hoặc một `-ChangeId` cụ thể.
- Change workspace có README artifact map, plan, tasks, test plan, implementation log, convergence review và release evidence; Normal/HighRisk thêm contract artifacts, HighRisk thêm architecture/security, AI tùy `-IncludeAI`.
- Generator mặc định không sửa source app, không đọc secret và không xóa file.

## Validation evidence

| Check | Result | Evidence |
|---|---|---|
| PowerShell parser trên toàn bộ harness | PASS | 6 scripts hiện tại, 0 parser failure |
| Bootstrap dry-run | PASS | Dự kiến tạo 73 workflow files |
| Change dry-run | PASS | Không ghi file vào project nguồn |
| Bootstrap integration test | PASS | Tạo project tạm và validate thành công |
| HighRisk + AI change integration | PASS | Tạo `publish-tournament` với 14 files và validate thành công |
| Temporary test cleanup | PASS | Thư mục test đã được xóa |
| Current workflow validation | PASS | Manifest v1.3.0, path/JSON/Powershell checks pass |

## Known limitations

- Generator chưa cài dependency hoặc sinh CI pipeline theo framework cụ thể; nó chỉ copy workflow artifacts và tạo skeleton.
- Validator chưa semantic-validate OpenAPI/YAML/Markdown links nếu project chưa cài dependency validator tương ứng.
- Generated manifest của project mới là flat file inventory tối giản; team cần bổ sung domain-specific sections khi project ổn định.
- Tooling chưa tạo dashboard, AI eval runner hoặc architecture fitness runner; các phần đó vẫn là bước nâng cấp tiếp theo.

## Release decision

`PASS_WITH_CONDITIONS`

Điều kiện: chạy `-DryRun` trước lần bootstrap đầu tiên; thay placeholders trong `knowledge/PROJECT_CONTEXT.md`; chạy `validate-workflow.ps1` sau khi tạo change; review mọi `-Force`; và không coi generator/validator là compliance certification hay thay thế human review.
