# PRD — [Tên sản phẩm/feature]

## 1. Tóm tắt

**Vấn đề:** [Người dùng đang gặp vấn đề gì?]

**Mục tiêu:** [Kết quả đo được cần đạt]

**Không làm trong phiên bản này:** [Out-of-scope]

## 2. Người dùng và vai trò

| Persona | Mục tiêu | Quyền cần có |
|---|---|---|
| [Player] | [Mục tiêu] | [Quyền] |
| [Organizer] | [Mục tiêu] | [Quyền] |
| [Admin] | [Mục tiêu] | [Quyền] |

## 3. Use cases

### UC-001 — [Tên use case]

**Actor:** [Vai trò]

**Precondition:** [Điều kiện trước khi bắt đầu]

**Main flow:**

1. [Bước 1]
2. [Bước 2]
3. [Bước 3]

**Alternative/error flow:**

1. [Lỗi hoặc nhánh thay thế]
2. [Cách hệ thống phản hồi]

## 4. Acceptance criteria

- **AC-001:** Given [điều kiện], When [hành động], Then [kết quả].
- **AC-002:** Given [điều kiện], When [hành động], Then [kết quả].
- **AC-003:** Người dùng không đủ quyền nhận lỗi phù hợp và không làm thay đổi dữ liệu.

## 5. Dữ liệu và tích hợp

| Đối tượng | Trường quan trọng | Quan hệ | Quy tắc xoá |
|---|---|---|---|
| [Entity] | [Fields] | [Relations] | [Soft/hard delete] |

**Tích hợp:** [Email, payment, storage, map, AI, realtime...]

## 6. Phi chức năng

| Nhóm | Yêu cầu |
|---|---|
| Security | [Auth, RBAC, validation, audit] |
| Performance | [Latency, pagination, cache] |
| Reliability | [Retry, idempotency, recovery] |
| Accessibility | [Keyboard, labels, contrast] |
| Localization | [Ngôn ngữ, date/currency format] |

## 7. Success metrics

| Chỉ số | Baseline | Target | Cách đo |
|---|---:|---:|---|
| [Metric] | [x] | [y] | [Method] |

## 8. Open questions

| Câu hỏi | Người trả lời | Deadline | Trạng thái |
|---|---|---|---|
| [Question] | [Owner] | [Date] | Open |
