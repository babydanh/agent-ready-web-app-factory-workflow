# Domain Adaptation Guide — Chuyển workflow sang đề tài web app khác

**Mục đích:** Giúp bắt đầu nhanh một dự án mới mà không bê nhầm domain model của đồ án Quản lý Giải đấu. Workflow gồm phần khung dùng chung và phần domain phải thiết kế lại.

## 1. Ba lớp cần phân biệt

| Lớp | Giữ lại giữa các dự án? | Ví dụ |
|---|---:|---|
| Engineering framework | Gần như giữ nguyên | Phases, roles, handoff, evidence, release gates |
| Technical standards | Giữ nguyên rồi cấu hình | API envelope, data naming, auth, testing, observability, SLO |
| Domain model/policy | Không bê nguyên | Product/order, booking/room, course/enrollment, tournament/match |

Một workflow tái sử dụng tốt không cố đoán domain. Nó yêu cầu owner xác nhận glossary, actors, invariants, state machine, ownership và compliance trước khi tạo schema/API.

## 2. Quy trình adapt cho project mới

```text
1. Bootstrap workflow
2. Điền PROJECT_CONTEXT và DOMAIN_RULES
3. Chọn domain archetype/profile
4. Lập glossary và actor/permission map
5. Tạo Product Discovery Brief
6. Chọn problem cards P-01…P-24
7. Thiết kế entity/state/invariant
8. Thiết kế API/UI/event/job contracts
9. Chọn security/compliance/SRE profile
10. Tạo change workspace và chạy gates
```

## 3. Archetype và problem cards mặc định

| Archetype | Invariant trung tâm | Cards mặc định | Review đặc biệt |
|---|---|---|---|
| E-commerce | Order total, inventory, payment state | P-02, P-06, P-08, P-09, P-10, P-11, P-12, P-13, P-14, P-17, P-20 | Money, stock, refund, webhook, tax/shipping |
| Booking/reservation | Availability, hold expiry, double booking | P-02, P-06, P-08, P-09, P-10, P-12, P-14, P-15, P-20 | Time zone, calendar conflict, cancellation/refund |
| SaaS multi-tenant | Tenant isolation, plan quota, billing | P-05, P-06, P-07, P-08, P-09, P-10, P-17, P-19, P-20, P-21, P-22 | Tenant boundary, admin/support access, data export/delete |
| CRM/ERP | Ownership, workflow state, reporting consistency | P-02, P-03, P-06, P-07, P-10, P-14, P-17, P-19, P-21 | Field-level auth, import/export, audit |
| LMS | Enrollment, progress, content access | P-02, P-03, P-06, P-07, P-10, P-11, P-14, P-17, P-24 | Entitlement, copyright/content privacy, progress integrity |
| CMS/blog | Draft/publish/version, content safety | P-02, P-03, P-06, P-10, P-11, P-14, P-17, P-21, P-24 | XSS/sanitization, revision, moderation, SEO |
| Social/community | Visibility, moderation, abuse budget | P-03, P-05, P-06, P-11, P-14, P-15, P-16, P-18, P-21, P-24 | Spam, report/moderation, privacy, fan-out |
| Marketplace | Listing/order/escrow ownership | P-02, P-06, P-07, P-08, P-09, P-12, P-13, P-14, P-17, P-21 | Buyer/seller isolation, disputes, payouts |
| Media/live | Asset ownership, processing state, delivery | P-06, P-07, P-11, P-12, P-15, P-16, P-17, P-19, P-22 | Upload/codec/storage/CDN, signed delivery, bandwidth |
| AI product | Safe bounded output/action and spend | P-06, P-11, P-12, P-16, P-18, P-19, P-21, P-22, P-23 | Prompt injection, tool scope, eval, cost, human approval |
| Finance/high-impact | Ledger/account balance and authorization | P-05, P-06, P-07, P-08, P-09, P-12, P-13, P-14, P-19, P-20, P-21, P-23 | Segregation of duties, immutable audit, reconciliation, legal owner |

Các card là điểm khởi đầu, không phải bằng chứng rằng feature đã bao phủ risk. Product/Architect Agent phải ghi `yes` hoặc `N/A + rationale` trong Problem Map.

## 4. Domain discovery questions

### Actors và quyền

Ai là anonymous user, registered user, owner, staff, manager, admin, support, provider và worker? Actor nào được đọc/sửa/xóa/publish/export/approve? Quyền ở object và property level có gì khác nhau? Tenant có được support/admin truy cập không và access đó có audit/step-up không?

### Resource và lifecycle

Resource được tạo bởi ai? Draft/published/active/paused/archived/deleted/restore ra sao? Có state terminal không? State có thể sửa bởi nhiều actor không? Có cần optimistic version, approval hoặc two-person review không?

### Invariants

Điều gì không bao giờ được phép xảy ra: âm tiền, overbooking, trùng membership, đọc chéo tenant, order không có line item, publish thiếu data, notification sai người nhận, event mất hoặc job side effect lặp? Invariant thuộc DB, service, provider hay eventual consistency?

### Time và localization

Timezone source là gì? Lưu UTC hay local? DST, ngày hết hạn, business day, locale, currency, decimal rounding và language fallback xử lý thế nào? Không dùng JavaScript floating point cho money invariant.

### Data/privacy

Field nào là public, internal, confidential, sensitive hoặc regulated? Có cần minimization, masking, retention, export, deletion, legal hold, audit access hay regional residency không? Dataset/test fixture có dùng raw production data không?

### Integration và failure

Provider nào có thể timeout, 429, 5xx, schema drift hoặc trả success nhưng local process chết? Có cần webhook/inbox, outbox, reconciliation, retry/DLQ, circuit breaker hay manual repair không?

## 5. Profile gợi ý

| Profile | Khi chọn | Bắt buộc |
|---|---|---|
| `CRUD_STANDARD` | Resource nội bộ, không side effect lớn | P-03, P-04, P-06, P-19, P-24 |
| `AUTHENTICATED_APP` | Có account/session | P-05, P-06, P-07, P-21 |
| `SHARED_RESOURCE` | Booking/inventory/quota/slot | P-08, P-09, P-17, concurrency tests |
| `PAYMENT_LEDGER` | Tiền/refund/payout | P-08, P-09, P-12, P-13, reconciliation, audit |
| `FILE_CONTENT` | Upload/import/export/editor | P-06, P-11, P-21, abuse tests |
| `ASYNC_INTEGRATION` | Provider/queue/notification | P-12, P-14, P-16, P-19, retry/DLQ |
| `REALTIME` | Live score/chat/presence | P-06, P-15, P-16, resync/dedup tests |
| `AI_FEATURE` | Model/tool/external content | P-11, P-12, P-18, P-19, P-22, eval/human gate |
| `HIGH_IMPACT` | Finance, health, legal, identity, admin destructive | Tất cả control liên quan, human/legal/security review |

## 6. Domain glossary template

| Term | Definition đã xác nhận | Synonyms không dùng | Owner/source |
|---|---|---|---|
| `<term>` | `<domain definition>` | `<ambiguous variants>` | `<owner/source>` |

Quy tắc: một domain concept chỉ có một canonical name trong data/API/UI. Label thân thiện có thể khác canonical field nhưng phải có mapping rõ.

## 7. Common wrong adaptations

| Sai lầm | Vì sao sai | Cách làm đúng |
|---|---|---|
| Copy entity tournament sang app khác | Domain invariant khác | Dùng template, tạo entity từ glossary/outcome |
| Dùng `status: string` cho mọi domain | Typos và transition không kiểm soát | Registry/union/check/state machine |
| Dùng JSONB thay mọi quan hệ | Né invariant và queryability | Normalize core identity/relationship; JSONB chỉ cho bounded flexible data |
| Chỉ làm UI vì “backend CRUD đơn giản” | Auth/ownership/concurrency vẫn tồn tại | Chọn problem cards và test direct API |
| Dùng một SLO cho mọi app | Criticality và dependency khác nhau | Service catalog theo feature/endpoint/risk |
| Dùng một retry policy cho mọi provider | Retry permanent error gây storm/duplicate | Retry matrix theo error class/idempotency |
| Gắn `public` cho upload/AI để demo | Demo path thường thành production path | Auth/quota/egress policy hoặc feature flag rõ |

## 8. Exit criteria khi adapt xong

Project được coi là đã adapt đủ khi có context, domain rules, glossary, actor/permission map, archetype/profile, applied problem map, first feature discovery, source-of-truth decision, compliance/SRE profile và danh sách open questions. Không được bắt đầu database/API implementation nếu các invariant quan trọng còn được đánh dấu là “suy đoán”.

## References

[1]: [OWASP Top 10 API Security Risks — 2023](https://owasp.org/API-Security/editions/2023/en/0x11-t10/)  
[2]: [PostgreSQL — Transaction Isolation](https://www.postgresql.org/docs/current/transaction-iso.html)  
[3]: [RFC 9457 — Problem Details for HTTP APIs](https://www.rfc-editor.org/info/rfc9457/)  
