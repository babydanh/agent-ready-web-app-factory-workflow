# Feature Spec — [Tên feature]

## 1. Metadata

| Trường | Giá trị |
|---|---|
| Feature ID | [FEAT-000] |
| Owner | [Tên] |
| Priority | P0 / P1 / P2 / P3 |
| Status | Draft / Ready / Implementing / Verifying / Done |
| Dependencies | [Feature/module phụ thuộc] |

## 2. Scope

**In scope:** [Những gì sẽ làm]

**Out of scope:** [Những gì chưa làm]

## 3. Domain rule

[Viết quy tắc nghiệp vụ bằng câu rõ ràng, không chỉ mô tả UI.]

## 4. State machine

```text
[STATE_A] → [STATE_B] → [STATE_C]
                  ↓
              [STATE_ERROR]
```

| Current state | Action | Allowed role | Next state | Side effect |
|---|---|---|---|---|
| [A] | [Action] | [Role] | [B] | [Effect] |

## 5. User flow

1. [Người dùng mở màn hình]
2. [Hệ thống tải dữ liệu]
3. [Người dùng nhập/chọn]
4. [Frontend validate]
5. [Backend authorize + validate]
6. [Transaction/update]
7. [UI hiển thị kết quả]

## 6. Edge cases

| Case | Expected behavior |
|---|---|
| Dữ liệu rỗng | [Behavior] |
| Không đủ quyền | [403 + UI message] |
| Resource không tồn tại | [404 + UI state] |
| Request trùng | [Idempotent/conflict] |
| Timeout/reconnect | [Retry/fallback] |
| Concurrent update | [Lock/version/conflict] |

## 7. Impact map

| Layer | File/module dự kiến | Change |
|---|---|---|
| Database | [Schema/migration] | [Change] |
| Backend | [Module/controller/service/repository] | [Change] |
| API | [Method/path/DTO] | [Change] |
| Frontend | [Route/component/hook/store] | [Change] |
| Realtime | [Gateway/event/room] | [Change] |
| Tests | [Unit/API/E2E] | [Change] |
| Docs/Graph | [Files] | [Change] |

## 8. Definition of Done

- [ ] Domain rule được review.
- [ ] API contract được chốt.
- [ ] Permission và ownership được kiểm tra ở backend.
- [ ] Migration được review và chạy.
- [ ] Loading/error/empty/success state có đủ.
- [ ] Edge cases quan trọng có test.
- [ ] Lint, build và test pass.
- [ ] Tài liệu và Graphify được cập nhật nếu cần.
