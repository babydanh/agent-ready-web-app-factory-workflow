# Harness — Lớp điều phối tùy chọn

Harness là lớp hỗ trợ để workflow chạy nhất quán hơn. Nó không thay thế tư duy nghiệp vụ và không tự động cấp credential. Các script ở đây chỉ kiểm tra môi trường, chạy quality gates và ghi kết quả; trước khi chạy cần review command và phạm vi.

## Có sẵn

| Script | Mục đích |
|---|---|
| `validate-env.ps1` | Kiểm tra toolchain, path, file cấu hình và biến môi trường bắt buộc |
| `run-quality-gates.ps1` | Chạy lint, build, test và các check phù hợp cho backend/frontend |
| `run-security-gates.ps1` | Quét secret-like literals, tracked env/key files, query-token path, development bypass và OTP RNG; chỉ báo cáo, không sửa source |
| `init-workflow.ps1` | Tạo bản workflow cho project mới, copy standards/templates/examples/decisions/knowledge/harness và tạo project placeholders |
| `attach-workflow.ps1` | Gắn một workflow hiện có vào project và sinh/cập nhật adapter cho `AGENTS.md`, Copilot, Claude hoặc Cursor |
| `new-change.ps1` | Tạo per-change workspace theo tier `SmallFix`, `Normal` hoặc `HighRisk`, luôn có problem map và thêm profile artifacts khi được chọn |
| `validate-workflow.ps1` | Validate manifest, path, JSON, PowerShell syntax và artifact bắt buộc của change; read-only |

Profile `Theme` tạo `theme-config.json` và `locale-qa-matrix.md`; profile `I18N` tạo `translation-catalog.json` và `locale-qa-matrix.md`. Các profile này yêu cầu Normal hoặc HighRisk, không được dùng SmallFix để bỏ qua design/locale evidence.

## Cách dùng trên Windows PowerShell

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\harness\validate-env.ps1
.\harness\run-security-gates.ps1
.\harness\run-quality-gates.ps1 -Backend -Frontend
```

Mặc định script không sửa code, không reset Git, không xóa file và không đọc giá trị secret. Nếu cần chạy migration hoặc deploy, thực hiện một bước riêng sau khi đã review và xác nhận backup.

## Khởi tạo project mới

Chạy từ thư mục chứa workflow package:

```powershell
Set-ExecutionPolicy -Scope Process Bypass
.\harness\init-workflow.ps1 -TargetRoot ..\MyWebApp -ProjectName "My Web App"
```

Script từ chối target là chính workflow source hoặc một thư mục con của source. Mặc định không ghi đè file đã tồn tại; chỉ dùng `-Force` sau khi đã review conflict list. Dùng `-DryRun` để xem danh sách file sẽ tạo mà không ghi file.

## Gắn workflow vào project và agent

Nếu project đã có thư mục `workflow/`, chạy một lệnh sau từ repository root:

```powershell
.\workflow\harness\attach-workflow.ps1 `
  -ProjectRoot . `
  -Agent All `
  -Profile Commerce,VietnamCompliance
```

Lệnh này tạo hoặc cập nhật một managed block trong `AGENTS.md`, `.github/copilot-instructions.md`, `CLAUDE.md` và `.cursor/rules/workflow.mdc`. Nó không xóa instruction khác trong các file đó; chỉ block có marker `WEB-APP-FACTORY-WORKFLOW` được cập nhật ở những lần chạy sau. Nếu project chưa có `workflow/`, dùng:

```powershell
.\workflow\harness\attach-workflow.ps1 `
  -ProjectRoot . `
  -WorkflowRoot ..\Project_QuanLyGiaiDau\workflow `
  -ProjectName "My Web App" `
  -Bootstrap `
  -Agent All `
  -Profile Dashboard
```

Dùng `-Agent AGENTS`, `-Agent Copilot`, `-Agent Claude` hoặc `-Agent Cursor` nếu chỉ muốn tạo một adapter. Dùng `-DryRun` trước khi ghi file. Profile hỗ trợ `Commerce`, `Recommendation`, `Dashboard`, `VietnamCompliance`, `AppleIOS`, `Theme` và `I18N`; profile chỉ là context routing, còn Việt Nam/Apple/theme/i18n vẫn cần human/design/accessibility review và không tạo certification.

## Tạo workspace cho một change

Chạy tại project root đã có thư mục `workflow/`:

```powershell
.\workflow\harness\new-change.ps1 `
  -ProjectRoot . `
  -ChangeId publish-tournament `
  -Title "Publish tournament" `
  -Tier HighRisk
```

Ví dụ profile:

```powershell
# Commerce + Việt Nam
.\workflow\harness\new-change.ps1 -ProjectRoot . -ChangeId checkout-marketplace -Title "Marketplace checkout" -Tier HighRisk -Profile Commerce,VietnamCompliance

# Recommendation + dashboard
.\workflow\harness\new-change.ps1 -ProjectRoot . -ChangeId ranked-home-feed -Title "Ranked home feed" -Tier HighRisk -Profile Recommendation,Dashboard
```

Nếu change dùng AI, thêm `-IncludeAI`. Generator hỗ trợ `-Profile Commerce|Recommendation|Dashboard|VietnamCompliance|AppleIOS` và có thể nhận nhiều profile bằng mảng PowerShell. Commerce và Recommendation mặc định yêu cầu `-Tier HighRisk`; nếu thật sự cần tier thấp hơn, phải dùng `-AllowRiskWaiver` để sinh `profile-risk-waiver.md`, sau đó được human approve. Generator tạo thư mục `changes/<change-id>/` với `00-problem-map.md`, discovery, architecture/security tùy tier, backend feature design/data/API/UI, profile artifacts, plan, tasks, test plan, implementation log, convergence và release evidence. Problem map phải đánh dấu các card `P-01`–`P-24` áp dụng hoặc `N/A + rationale`.

## Validate workflow và change

```powershell
.\workflow\harness\validate-workflow.ps1 -ProjectRoot . -Strict
.\workflow\harness\validate-workflow.ps1 -ProjectRoot . -ChangeId publish-tournament -Strict
```

Validator chỉ đọc và báo `WORKFLOW_VALIDATION_PASS` hoặc `WORKFLOW_VALIDATION_FAIL`; khi có `-ChangeId`, nó enforce problem map, artifact base, artifact theo tier/AI và các artifact được khai báo bởi `Selected profile(s)` trong README. Nó chỉ kiểm tra existence/metadata; chưa validate semantic OpenAPI/YAML/Markdown links, metric correctness, model fairness, legal compliance, Apple approval hoặc payment-provider certification. Validator không sửa source và không cấp compliance certification.

## Khi nào nên dùng harness

Dùng harness khi project đã có command ổn định và muốn mọi agent chạy cùng một quy trình. `attach-workflow.ps1` là bước onboarding một lần cho project hoặc chạy lại khi muốn cập nhật managed instructions; sau đó mỗi feature dùng `new-change.ps1` và validator như bình thường. Nếu script báo `NOT_AVAILABLE`, không được sửa package để che kết quả; ghi lại vào evidence và xử lý ở phase phù hợp.
