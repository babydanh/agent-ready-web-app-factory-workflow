# FEATURE IMPACT REVIEW SPEC

## Mục đích

Feature Impact Review (FIR) là artifact bắt buộc trước implementation cho mọi thay đổi có thể chạm vào state, role, button/action, route, API/event, realtime, cache, i18n, cross-platform behavior hoặc terminal business state. FIR biến brief thành một bản đồ tác động có thể review trước khi agent viết code.

FIR bổ sung cho Product Discovery, Architecture Review, API Contract, UI Spec và Test Plan; không thay thế các artifact đó.

## Khi nào bắt buộc

| Điều kiện | FIR |
|---|---|
| SmallFix chỉ đổi text/style thuần túy, không đổi action/state/route | Mini FIR |
| Có button, modal, form, loading/error/permission state hoặc route | Bắt buộc |
| Có API, event, socket, cache, background job hoặc side effect | Bắt buộc + contract/negative cases |
| Có Web và App/Admin/Ops cùng feature | Bắt buộc + cross-platform matrix |
| Có terminal state, payment, ELO, bracket, permission hoặc dữ liệu quan trọng | Normal/HighRisk review tùy risk, không hạ tier theo số dòng code |
| HighRisk/profile-specific | FIR đầy đủ + profile artifacts + human review |

## Quy tắc quyết định

FIR phải kết thúc bằng một quyết định:

- `GO`: scope, source of truth, owner, acceptance criteria và rủi ro đã đủ.
- `GO_WITH_CONDITIONS`: được làm nhưng phải có điều kiện đóng, owner và deadline cụ thể.
- `HOLD`: thiếu evidence, contract, business decision, runtime access hoặc review owner.
- `STOP`: phát hiện conflict, unauthorized behavior, data-integrity threat hoặc scope không được phép.

Không được chuyển sang `IMPLEMENTING` nếu FIR là `HOLD`, `STOP` hoặc còn câu hỏi blocking chưa có owner.

## Nội dung tối thiểu

### Product and decision

Ghi problem, user/context, desired outcome, alternatives, non-goals, assumptions, evidence, priority, tier/profile và decision owner. Không bắt đầu từ tên solution rồi suy ra problem.

### Surface inventory

Liệt kê toàn bộ route/page/tab/modal/card/banner/tooltip/notification/email/deep-link bị ảnh hưởng. Mỗi surface phải ghi role, entry point và expected state.

### Role and permission

Ghi actor, authentication requirement, permission/ownership, visible action, backend enforcement owner và unauthorized behavior. UI hide button không thay thế backend authorization.

### State and domain

Ghi current state, preconditions, action, next state, terminal state, invariant, rollback/undo và conflict behavior. Không suy luận domain state từ message text.

### Button and screen states

Mọi action chính phải có Button-State Matrix. Mọi route/page có thay đổi phải có Screen-State Matrix. Tối thiểu phải xét visible, disabled, loading, confirmation, success, error, empty, permission, offline, retry và duplicate-click.

### Data and integration

Ghi source of truth, field/status/enum/DTO, endpoint/event/socket room, cache invalidation, revision/idempotency, reconnect/resync và consumer. Nếu không đổi layer phải ghi rõ `N/A + rationale`.

### Cross-platform

Nếu có Web/App/Admin/Ops/public/mobile, ghi semantics từng client, điểm giống/khác, lý do khác biệt, test parity và owner. Không coi “đã sửa Web” là bằng chứng App đúng.

### Traceability

Mỗi acceptance criterion phải nối được tới route/screen/button, source file/module, test và evidence. Claim pass không có evidence tương ứng là invalid.

## Gate trước code

Reviewer hoặc agent phải kiểm tra:

1. Đã biết feature chạm những layer/surface nào.
2. Đã biết button nào hiện/ẩn/disabled và click effect cụ thể.
3. Đã biết state transition, invariant và terminal behavior.
4. Đã xác định source of truth và contract owner.
5. Đã liệt kê error, empty, permission, conflict, retry và duplicate action.
6. Đã phân loại Web/App parity.
7. Đã chọn test/evidence bắt buộc.
8. Đã ghi stop conditions và rollback behavior.

Thiếu một mục quan trọng phải chuyển `NEEDS_CLARIFICATION`, `BLOCKED` hoặc `NEEDS_HUMAN_REVIEW`, không tự đoán.

## Điều chỉnh theo tier

SmallFix được phép dùng mini FIR, nhưng nếu phát hiện state/permission/API/realtime/terminal impact thì phải nâng lên Normal. Normal cần FIR đầy đủ trước plan/implementation. HighRisk cần thêm threat/control, concurrency, rollback, observability và human approval.

## Review sau implementation

Convergence Review phải đối chiếu implementation với FIR, không chỉ với task list. Nếu implementation phát sinh surface, button, state, field, endpoint, event hoặc side effect mới, FIR phải được cập nhật trước khi claim complete.
