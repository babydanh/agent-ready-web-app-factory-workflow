# Vietnam Web App Compliance Profile

> **Tôi là AI, không phải luật sư; tài liệu này là working analysis/checklist, không phải tư vấn pháp lý chính thức. Hãy để luật sư hoặc compliance owner đủ năng lực xác nhận trước khi triển khai/kinh doanh.**

**Snapshot:** 2026-08-22. Văn bản pháp luật có thể được sửa đổi, hướng dẫn thêm hoặc áp dụng khác nhau theo ngành, mô hình kinh doanh, loại dữ liệu, người dùng và nơi đặt hạ tầng. Workflow chỉ tạo evidence và câu hỏi review; không tự biến thành chứng nhận tuân thủ.

## 1. Compliance scoping trước khi code

Không hỏi “app này có compliant không?” trước khi xác định: pháp nhân/operator, thị trường, loại hàng hóa/dịch vụ, storefront hay marketplace, B2C/B2B, payment flow, dữ liệu xử lý, vendor/processor, cloud region, children/high-impact data, UGC, advertising, cross-border transfer và record cần giữ.

| Scope question | Nếu trả lời “có” thì mở profile |
|---|---|
| Bán hàng/dịch vụ online | E-commerce + consumer + electronic transaction |
| Có seller/merchant bên thứ ba | Marketplace/intermediary, seller disclosure, moderation, dispute |
| Thu thập định danh/contact/behavior | Personal-data governance, consent/purpose/rights/retention |
| Có data sensitive/high-impact | Elevated privacy/security/legal review |
| Có chuyển dữ liệu/vendor/cloud ngoài Việt Nam | Cross-border/processor/contract and transfer review |
| Có payment/recurring/payout | Payment provider, ledger, refund, tax/accounting review |
| Có UGC/review/chat | Notice/report/block/moderation/evidence/child safety |
| Có quảng cáo/personalization | Ad disclosure, consent/opt-out, attribution and profiling review |
| Có trẻ em/y tế/tài chính/giáo dục | Sector-specific and high-impact review |

## 2. Văn bản cần theo dõi

| Văn bản | Snapshot từ nguồn chính thức | Đưa vào workflow như |
|---|---|---|
| Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15 | Ban hành 2025-06-26, hiệu lực 2026-01-01 [1] | Current top-level data-protection review |
| Nghị định 356/2025/NĐ-CP | Quy định chi tiết/biện pháp thi hành luật dữ liệu, ban hành 2025-12-31, hiệu lực 2026-01-01 [2] | Current implementation/guidance review |
| Nghị định 13/2023/NĐ-CP | Ban hành 2023-04-17, hiệu lực 2023-07-01 [3] | Historical/transition/reference check; không dùng làm nguồn duy nhất |
| Luật Bảo vệ quyền lợi người tiêu dùng 19/2023/QH15 | Ban hành 2023-06-20, hiệu lực 2024-07-01 [4] | B2C, online transaction, seller/platform, complaint/refund transparency |
| Luật Giao dịch điện tử 20/2023/QH15 | Ban hành 2023-06-22, hiệu lực 2024-07-01 [5] | Electronic records/messages/contracts/signatures/evidence |
| Nghị định 85/2021/NĐ-CP sửa NĐ 52/2013 | Ban hành 2021-09-25, hiệu lực 2022-01-01 [6] | E-commerce storefront/marketplace scoping |
| Nghị định 53/2022/NĐ-CP | Ban hành 2022-08-15, hiệu lực 2022-10-01 [7] | Cybersecurity obligations only where scope triggers |

## 3. Personal-data engineering controls

Data inventory phải map field → purpose → data subject → source → role (operator/controller/processor as legally determined) → storage → vendor → retention → deletion/anonymization → access/audit. Classification phải tách public, internal, personal, sensitive/regulated and secret. Không lưu raw identity, token, OTP hoặc payment data ngoài mục đích.

API design cần support privacy-safe defaults: purpose-limited fields, field-level authorization, masked logs, export/delete request workflow, consent/version record where applicable, vendor access expiry và audit. Cache, search index, event stream, backups, analytics and ML features đều phải nằm trong deletion/retention map; xóa primary row nhưng giữ analytics/event copy không phải là full deletion decision.

Security evidence cần có encryption in transit/at rest where appropriate, key ownership/rotation, least privilege, admin access log, incident playbook, backup restore test, vulnerability management, vendor register và privacy impact/legal review khi trigger.

## 4. Commerce and consumer controls

Storefront cần công khai/ghi nhận thông tin business/product/service/price/terms, order acceptance, payment, delivery/provision, cancellation, refund, complaint/support và transaction history theo scope. Marketplace phải phân biệt platform role với seller role; seller identity, listing ownership, moderation, dispute and payout records cần explicit.

Không tuyên bố “đã tuân thủ Nghị định 85” chỉ vì có trang Terms. Cần lưu versioned terms, consent/acceptance evidence, order snapshot, invoice/receipt policy, refund reason, support case và audit trail. Luật consumer và e-commerce có thể tương tác với ngành hàng, promotion, advertising, tax/e-invoice/payment rules; compliance owner phải xác định văn bản bổ sung.

## 5. Electronic records and evidence

Khi hệ thống dựa vào electronic order, terms acceptance, notification, signature hoặc approval, cần record: actor identity, message/document hash, version, timestamp/timezone, delivery/receipt status, consent/acceptance context, device/IP theo policy, signature/verification evidence và retention/lookup path.

Audit log phải append-only hoặc tamper-evident theo risk. Không sửa trực tiếp lịch sử acceptance/payment; correction dùng reversal/amendment record có reason và actor.

## 6. Cybersecurity scope

Áp security baseline cho mọi app: secure SDLC, auth/authorization, rate limit, logging, backup, incident response, dependency/container hygiene, secrets and least privilege. Nghị định 53/2022 và Luật An ninh mạng cần được legal-scope review theo service/system/data/operator; không tự suy diễn mọi web app phải áp cùng localization hoặc nghĩa vụ đặc thù.

## 7. Required compliance artifacts

| Artifact | Owner | Evidence |
|---|---|---|
| Processing/data inventory | Privacy/Data | Reviewed field/vendor/purpose map |
| Legal-source register | Legal/Compliance | Version/effective date/review date |
| Privacy notice/consent record | Product/Legal | Published version + test evidence |
| Data subject request flow | Backend/Product | API/UI/job/audit/E2E evidence |
| Retention/deletion schedule | Data/Legal | TTL, legal hold, backup policy |
| Vendor/DPA register | Security/Legal | Processor, region, access, breach path |
| E-commerce role map | Product/Legal | Storefront/marketplace/seller scope |
| Terms/order/refund evidence | Product/Operations | Versioned records and test fixtures |
| Electronic record policy | Legal/Backend | Integrity, timestamp, retention lookup |
| Incident response | Security/SRE | Runbook, escalation, exercise evidence |
| Compliance traceability | Auditor | Requirement → control → code → test → evidence |

## 8. Release gate

Release status phải là `LEGAL_REVIEW_REQUIRED`, `CONDITIONAL`, hoặc `APPROVED_BY_OWNER`; AI Agent không được xuất “legally compliant” dựa trên file checklist. Mọi exception cần owner, rationale, expiry và compensating control.

## References

[1]: https://vanban.chinhphu.vn/?pageid=27160&docid=214590&classid=1&orggroupid=1 "Luật 91/2025/QH15 — Bảo vệ dữ liệu cá nhân"
[2]: https://vanban.chinhphu.vn/?pageid=27160&docid=216387 "Nghị định 356/2025/NĐ-CP — bảo vệ dữ liệu cá nhân"
[3]: https://vanban.chinhphu.vn/?pageid=27160&docid=207759 "Nghị định 13/2023/NĐ-CP — bảo vệ dữ liệu cá nhân"
[4]: https://vanban.chinhphu.vn/?pageid=27160&docid=208363 "Luật 19/2023/QH15 — bảo vệ quyền lợi người tiêu dùng"
[5]: https://vanban.chinhphu.vn/?pageid=27160&docid=208421 "Luật 20/2023/QH15 — giao dịch điện tử"
[6]: https://vanban.chinhphu.vn/default.aspx?pageid=27160&docid=204191 "Nghị định 85/2021/NĐ-CP — thương mại điện tử"
[7]: https://vanban.chinhphu.vn/?pageid=27160&docid=206381 "Nghị định 53/2022/NĐ-CP — Luật An ninh mạng"
