# Database Architecture Specification

## 1. Purpose and authority

Tài liệu này là chuẩn thiết kế dữ liệu cho web app. Nó không thay thế migration hoặc schema thực tế; mỗi entity phải có **data entity spec**, migration, query/service mapping và test invariant. Mọi quyết định trái chuẩn phải được ghi thành ADR có owner, lý do, rủi ro và ngày xem xét lại.

## 2. Modeling sequence

Thiết kế đi theo thứ tự: business capability → bounded context → entity và ownership → lifecycle/state machine → invariants → relationship/cardinality → normalization → physical schema → access patterns → security classification → migration/rollback → evidence. Không bắt đầu bằng việc tạo bảng từ DTO hoặc copy raw API response.

| Artifact | Must answer |
|---|---|
| Context map | Module nào sở hữu dữ liệu và module nào chỉ đọc projection? |
| Entity spec | Khóa, field, nullability, state, invariant, privacy class là gì? |
| ERD | Quan hệ, cardinality, optionality và delete behavior là gì? |
| Access matrix | Query/mutation nào dùng index và ownership scope nào? |
| Migration plan | Backfill, expand/contract, rollback và compatibility window ra sao? |
| Evidence | Schema diff, query plan, test và backup/restore evidence ở đâu? |

## 3. Boundaries, tenancy and ownership

Mỗi record phải có owner hoặc đường dẫn ownership có thể kiểm chứng. Với dữ liệu nhiều tenant, `tenantId` phải nằm trong scope của mọi read/write quan trọng; không dựa riêng vào `WHERE id = ?` nếu ID có thể đoán hoặc không globally isolated. Service layer kiểm tra authorization, database constraint bảo vệ integrity và query helper buộc ownership scope được áp dụng.

Không dùng `userId` để thay thế mọi khái niệm ownership. Phân biệt creator, current owner, participant, operator và auditor; nếu có nhiều vai trò, dùng bảng liên kết có unique constraint thay vì nhiều cột boolean khó nhất quán.

## 4. Normalization policy

Mặc định thiết kế đạt **3NF**: mỗi field chứa một giá trị nguyên tử, non-key field phụ thuộc vào toàn bộ key và không phụ thuộc bắc cầu vào non-key field. Với quan hệ many-to-many, dùng junction table với composite unique key. Tách bảng khi có lifecycle, ownership, access policy, query pattern hoặc retention khác nhau.

Denormalization chỉ được chấp nhận khi có access pattern đo được, consistency strategy, backfill/rebuild plan và ADR. JSONB phù hợp cho metadata mở rộng, snapshot bất biến, provider payload đã redacted hoặc cấu hình không cần relational query; không dùng JSONB để né thiết kế cho field nghiệp vụ cần filter, join, uniqueness, FK, permission hoặc audit.

| Decision | Default |
|---|---|
| Status/domain state | Enum hoặc lookup có state transition rõ ràng |
| Flexible metadata | JSONB với schema/version và size limit |
| Money | Integer minor unit + ISO currency; không dùng float |
| Time | UTC instant; timezone hiển thị ở boundary |
| IDs | UUID/ULID public-safe; không expose sequential internal IDs nếu enumeration risk |
| Audit history | Append-only event/history record; không sửa mất lịch sử |
| Soft delete | Chỉ khi có retention/legal/business reason; phải lọc mặc định |

## 5. Keys and constraints

Mỗi entity có primary key ổn định. Foreign key được khai báo ở database với `ON DELETE`/`ON UPDATE` có chủ đích; không dựa chỉ vào application check. Unique constraint phải phản ánh business invariant, bao gồm composite scope như `(tournament_id, team_id)` hoặc `(tenant_id, slug)`.

CHECK constraints nên bảo vệ các invariant cục bộ: số lượng không âm, ngày kết thúc không trước ngày bắt đầu, tiền tệ hợp lệ, status/visibility hợp lệ. Invariant liên quan nhiều dòng cần transaction/locking, deferred constraint, advisory lock hoặc cơ chế serializable phù hợp; tài liệu phải nói rõ race strategy.

## 6. Index and query-plan policy

Index dựa trên query catalog, không tạo theo cảm tính. Mỗi index mới phải ghi query shape, cardinality ước tính, selectivity, write cost và plan evidence. Composite index đặt cột equality trước range/order khi phù hợp; tránh index trùng hoặc index phủ toàn bộ bảng không có lý do.

Mọi endpoint list/search quan trọng phải có giới hạn page size, deterministic ordering, timeout/budget và query-plan kiểm tra ở dữ liệu đại diện. Không cho client truyền raw column/order/filter SQL. Dùng allowlist mapping từ API field sang column.

## 7. Transactions, isolation and concurrency

Mutation nhiều bước phải xác định transaction boundary và external side effect boundary. Database commit không bao trùm được payment/email/webhook; dùng outbox/inbox hoặc trạng thái pending/retry thay vì giả định distributed transaction.

| Situation | Required behavior |
|---|---|
| Counter/slot/inventory | Atomic update với condition hoặc row lock; test race |
| Payment/receipt | Idempotency key, unique provider reference, reconciliation path |
| Webhook | Verify signature, deduplicate event ID, persist before async processing |
| Job/outbox | At-least-once safe handler, retry/backoff, dead-letter/repair |
| Concurrent status change | State transition guard and conflict response |
| Read-after-write | Document consistency expectation and stale/reload behavior |

## 8. Migration and rollback

Dùng expand → migrate/backfill → contract cho breaking schema changes. Migration phải deterministic, versioned, reviewable, observable và safe khi chạy lại hoặc bị dừng giữa chừng. Không drop/rename field trong cùng release với client chưa upgraded nếu còn consumer cũ.

Mỗi migration record: precondition, forward SQL, lock/timeout impact, batch/backfill strategy, postcondition, rollback/restore plan, data-loss risk, compatibility window and verification query. Production migration không dùng `|| echo`/nuốt lỗi; failure phải làm release fail hoặc chuyển sang documented manual recovery.

## 9. Seed, fixtures, retention and deletion

Seed tách rõ reference data, development data và test fixture. Không seed default credential/secret vào production. Fixture không chứa PII thật hoặc payment payload thật.

Retention policy phải gắn với data classification, business need và legal review. Deletion có thể là hard delete, anonymization hoặc tombstone; phải nêu ảnh hưởng đến audit, foreign key, search index, cache, object storage, webhook và backup. Quyền export/delete chỉ thực hiện sau authorization và audit log.

## 10. Backup, restore and disaster recovery

Mỗi môi trường phải có owner, RPO, RTO, backup frequency, encryption, access control và restore test cadence. Backup thành công không đồng nghĩa restore đã được chứng minh. Restore drill phải ghi thời điểm, version, checksum, missing dependencies, data validation và rollback.

## 11. Database review gate

Database design chỉ PASS khi entity spec, ERD, constraints, index rationale, migration/rollback, transaction strategy, privacy classification và tests đã có. Nếu thiếu ownership path, FK cho invariant quan trọng, race test cho counter/payment hoặc restore evidence cho release-critical data, trạng thái là `NEEDS_REVIEW` hoặc `BLOCKED`, không phải PASS.
