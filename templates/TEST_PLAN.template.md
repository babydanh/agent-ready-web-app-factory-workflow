# Test Plan — [Tên feature]

## 1. Scope và risk

**Feature:** [Tên]

**Criticality:** Low / Medium / High / Financial / Security-critical

**Main risks:** [Danh sách rủi ro]

## 2. Acceptance test matrix

| ID | Scenario | Given | When | Then | Test type | Status |
|---|---|---|---|---|---|---|
| TC-001 | Happy path | [Context] | [Action] | [Expected] | E2E | Not run |
| TC-002 | Invalid input | [Context] | [Action] | [Expected] | API | Not run |
| TC-003 | Forbidden | [Context] | [Action] | [Expected] | API/E2E | Not run |
| TC-004 | Not found | [Context] | [Action] | [Expected] | API | Not run |
| TC-005 | Duplicate/concurrent | [Context] | [Action] | [Expected] | Integration | Not run |

## 3. Unit tests

- [ ] Domain rules.
- [ ] State transition.
- [ ] Parser/formatter/helper.
- [ ] ELO/bracket/fee calculation nếu có.

## 4. API/integration tests

- [ ] DTO validation.
- [ ] Authentication.
- [ ] Authorization and ownership.
- [ ] Repository query.
- [ ] Transaction rollback.
- [ ] Idempotency.
- [ ] Webhook signature nếu có.

## 5. Frontend/E2E tests

- [ ] Page loads.
- [ ] Loading state.
- [ ] Empty state.
- [ ] Error state.
- [ ] Form validation.
- [ ] Success navigation/toast.
- [ ] Refresh token behavior.
- [ ] Responsive/mobile behavior.
- [ ] Socket reconnect/cleanup nếu có.

## 6. Security tests

- [ ] Không truy cập resource của user khác.
- [ ] Không bypass được role guard.
- [ ] Token hết hạn/replay bị xử lý.
- [ ] Rate limit hoạt động.
- [ ] CORS chỉ cho phép origin hợp lệ.
- [ ] Upload giới hạn type/size.
- [ ] Không lộ secret trong response/log.

## 7. Regression commands

```bash
pnpm lint
pnpm build
pnpm test
pnpm test:e2e
```

**Frontend commands:** `[pnpm lint] [pnpm i18n:check] [pnpm build]`

**Evidence paths:** [Link hoặc đường dẫn report]

## 8. Defects

| ID | Severity | Reproduction | Expected | Actual | Owner | Status |
|---|---|---|---|---|---|---|
| BUG-001 | P0/P1/P2/P3 | [Steps] | [Expected] | [Actual] | [Owner] | Open |

## 9. Release recommendation

**Recommendation:** PASS / PASS WITH KNOWN ISSUES / BLOCK

**Known issues:** [Issue và lý do chấp nhận]

**Sign-off:** [QA, Security, Product, Date]
