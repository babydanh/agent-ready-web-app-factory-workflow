# Contract Change Checklist

Dùng checklist này cho mọi thay đổi có thể ảnh hưởng data/API/UI/realtime/AI.

## Before coding

- [ ] Có PRD/Feature Spec và acceptance criteria.
- [ ] Có data dictionary và state transition nếu thêm/sửa entity hoặc status.
- [ ] Có endpoint contract với operationId, auth, ownership, CSRF, rate limit và idempotency.
- [ ] Có screen spec với loading/empty/error/conflict/offline/realtime states.
- [ ] Có security/privacy impact và profile áp dụng.
- [ ] Có impact map backend/frontend/mobile/worker/AI/event/test/docs.
- [ ] Đã xác định breaking vs non-breaking và migration/rollback.

## During coding

- [ ] DTO/schema validate input ở server.
- [ ] Serializer/projection không trả raw row hoặc sensitive field.
- [ ] Response success dùng canonical envelope.
- [ ] Error dùng problem type/code ổn định, detail không lộ internals.
- [ ] Database constraint/index/transaction phù hợp invariant.
- [ ] Mutation có idempotency/concurrency behavior.
- [ ] UI không dùng message text để suy luận domain state.
- [ ] Realtime event có version, revision/sequence và resync path.
- [ ] AI tool/output đi qua cùng schema và authorization.

## Before merge

- [ ] OpenAPI/JSON Schema validate.
- [ ] Contract fixtures pass ở success và error.
- [ ] Backend unit/API tests pass.
- [ ] Frontend typecheck/build/lint pass.
- [ ] E2E và accessibility checks pass hoặc có waiver.
- [ ] Security negative tests pass: auth, IDOR, CSRF/CORS, rate limit, abuse.
- [ ] Concurrency/retry/idempotency tests pass nếu có mutation.
- [ ] Migration dry-run/rollback note đã review.
- [ ] Dependency/config scan pass hoặc risk acceptance có expiry.

## Before release

- [ ] Consumer inventory và deprecation plan cập nhật.
- [ ] Observability: operationId/requestId/metrics/logs/traces có mặt.
- [ ] Backup/restore và rollback đã chứng minh.
- [ ] Release evidence lưu commit, artifact, test report và reviewer.
- [ ] Không có secret, token, PII hoặc production payload trong diff/fixture/log.
- [ ] Quyết định release là `PASS`, `PASS_WITH_RISK`, `NEEDS_REVIEW` hoặc `BLOCKED`; không dùng trạng thái mơ hồ.
