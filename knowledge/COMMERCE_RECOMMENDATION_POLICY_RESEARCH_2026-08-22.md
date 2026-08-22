# Research Snapshot — Commerce, Recommendation, Dashboard, Apple and Vietnam Policy

**Author:** Manus AI  
**Research date:** 2026-08-22  
**Purpose:** Làm cơ sở cho reusable Web App Factory; không phải legal advice, platform certification, provider certification hoặc guarantee of App Review approval.

## 1. Scope and method

Research này tổng hợp tài liệu chính thức của Google, Apple và Cổng Thông tin điện tử Chính phủ Việt Nam cùng việc quan sát các repository công khai Medusa, Apache Superset và Grafana. Kết luận được chuyển thành playbook/checklist có tính engineering governance; chúng không chứng minh một codebase cụ thể đã đạt mục tiêu. Luật, policy, SDK, provider behavior và upstream repositories có thể thay đổi; owner phải xác nhận lại effective version trước launch/release.

## 2. Google recommendation architecture

Google mô tả một kiến trúc recommendation phổ biến gồm **candidate generation → scoring → re-ranking**. Candidate generation thu hẹp corpus lớn thành tập nhỏ hơn; scoring áp dụng mô hình chi tiết hơn; re-ranking áp các constraint như disliked items, freshness, diversity và fairness [1].

### Reusable implications

Recommendation/search feature phải khai báo event taxonomy, candidate sources, eligibility/authorization filters, ranking objective, re-ranking constraints, latency budget, cold-start fallback, feedback/explanation policy, offline metrics, online guardrails, kill switch và rollback version. Output ranking là một decision artifact có provenance, không phải business truth không cần review.

## 3. Apple App Store, StoreKit and privacy

Apple App Review Guidelines nhóm yêu cầu theo Safety, Performance, Business, Design và Legal. Guideline nhấn mạnh việc test crash/bug, metadata chính xác, review access/demo account khi cần, backend hoạt động và giải thích feature hoặc in-app purchase không hiển nhiên; developer vẫn chịu trách nhiệm với third-party SDK, analytics và ad network [2].

Apple cung cấp StoreKit documentation cho in-app purchase. Với iOS commerce, cần phân biệt digital goods/subscriptions với physical goods hoặc offline services; thiết kế product catalog, transaction verification, entitlement projection, restore, renewal/expiration, refund/revoke, server notifications và backend reconciliation [3].

Apple yêu cầu app hỗ trợ account creation phải cho user khởi tạo account deletion trong app. Hướng dẫn yêu cầu xử lý toàn bộ account và associated data theo chính sách, thông báo nếu xử lý mất thời gian và revoke Sign in with Apple tokens khi applicable [4].

Apple privacy manifests (`PrivacyInfo.xcprivacy`) ghi data types và required-reason APIs, cùng các thông tin liên quan tracking/tracking domains và accessed API types [5]. Vì vậy iOS release evidence cần SDK inventory, runtime data-flow review, privacy-manifest/App Store privacy mapping, ATT/tracking decision và build-artifact verification.

### Reusable implications

Apple profile phải có review account hoặc demo mode, review notes, live backend, account-deletion map, identity/token revocation path, UGC report/block/moderation, permission-denied behavior, accessibility checks, StoreKit sandbox evidence, SDK inventory và policy re-check at submission. Checklist không thể cam kết Apple approval vì quyết định cuối thuộc App Review và policy hiện hành.

## 4. Vietnam personal data and cybersecurity scope

Cổng Thông tin điện tử Chính phủ xác định Luật Bảo vệ dữ liệu cá nhân 91/2025/QH15 được ban hành ngày 2025-06-26 và có hiệu lực 2026-01-01 [6]. Nghị định 356/2025/NĐ-CP được ban hành ngày 2025-12-31 và có hiệu lực 2026-01-01 để quy định chi tiết/biện pháp thi hành theo nguồn chính thức [7]. Do đó, Decree 13/2023/NĐ-CP không được dùng như nguồn top-level duy nhất cho một profile hiện hành; Decree 13 vẫn là nguồn lịch sử/tham chiếu cần legal owner xác định quan hệ chuyển tiếp [8].

Engineering implication là lập data inventory và processing map: field/category, purpose, role, source, vendor/region, retention, deletion/anonymization, data-subject request, access/audit, security control, cross-border/third-party flow và incident route. Quyết định legal basis, role classification, transfer mechanism và nghĩa vụ cụ thể phải do qualified legal/compliance reviewer xác nhận.

Nghị định 85/2021/NĐ-CP được nguồn Chính phủ xác định là văn bản sửa đổi quy định về thương mại điện tử, ban hành 2021-09-25 và hiệu lực 2022-01-01 [9]. Commerce workflow vì vậy phải phân biệt merchant storefront với marketplace/intermediary; xác định seller/platform role, listing/order/refund/complaint records, disclosure, moderation và evidence. Không suy ra rằng có trang Terms là đã đáp ứng toàn bộ nghĩa vụ.

Nghị định 53/2022/NĐ-CP quy định chi tiết một số điều của Luật An ninh mạng, ban hành 2022-08-15 và hiệu lực 2022-10-01 [10]. Workflow cần security baseline và scope review theo service/system/data/operator; không áp một kết luận localization hoặc cybersecurity giống nhau cho mọi web app.

Luật Bảo vệ quyền lợi người tiêu dùng 19/2023/QH15 có hiệu lực 2024-07-01 theo nguồn Chính phủ [11]. Luật Giao dịch điện tử 20/2023/QH15 cũng có hiệu lực 2024-07-01 [12]. Commerce/electronic transaction evidence nên giữ versioned terms, order/acceptance context, electronic message/document provenance, timestamp, actor, delivery/receipt status, refund/support evidence và retention/lookup path theo scope.

### Reusable implications

Vietnam profile phải ghi legal-source register với effective date/review date, compliance scope record, data/vendor map, e-commerce role map, terms/notice versions, retention/deletion, electronic record evidence, incident runbook và owner. Status chưa quyết định phải là `LEGAL_REVIEW_REQUIRED`; workflow không được xuất “legally compliant”. Ngoài các nguồn trên, tax/e-invoice, advertising, payment/intermediary, sector licensing, children, health, finance, gambling, consumer product và cross-border rules có thể cần profile riêng.

## 5. Repository patterns observed in public projects

Medusa mô tả commerce platform/framework với các hướng DTC/B2B, marketplace, distributor, POS và service business. Repository có `.changeset`, `.github`, `integration-tests`, `packages`, `scripts`, `thoughts/shared` và docs; một change description quan sát được nhấn mạnh dashboard projection change cần HTTP integration test, changeset, lý do/cách test và phân biệt test không khởi động được với test pass [13].

Apache Superset mô tả nền tảng data visualization/exploration có chart, SQL Editor, semantic layer cho dimensions/metrics, caching, role/auth, API và cloud-native deployment. Repository có `.github`, `.claude`, `.cursor/rules`, docs, docker/helm, scripts và tests [14].

Grafana mô tả observability/data visualization platform kết hợp metrics, logs và traces từ nhiều nguồn. Repository quan sát được có `.github`, skills, apps, docs, provisioning và E2E areas; các pattern hiển thị ownership/CI, frontend testing và operation metrics với outcome/size/duration dimensions [15].

### Reusable implications

Repository/CI profile nên có package/module boundaries, CODEOWNERS, focused integration tests, changeset/release note, dependency/version policy, cache-key correctness, artifact provenance, CI tiers, dashboard-as-code/provisioning, metric-label discipline và explicit `BLOCKED`/`NOT_RUN` reporting. Screenshot không phải source of truth cho dashboard; metric/panel/query definitions phải versioned hoặc có import/export mechanism.

## 6. Limitations and review protocol

Research này không phải legal opinion và không bao quát mọi sector, tax/e-invoice, payment network, PCI, consumer product, health, financial, gambling, advertising, children hoặc cross-border obligation. Một URL Chính phủ trước đó được xác định là unrelated và không được sử dụng; profile chỉ giữ các official URLs đã được kiểm tra. Repository observations là snapshot, không phải đánh giá security hay quality của upstream.

Trước launch/release, owner phải xác định market/entity/data/vendor/product channel; cập nhật source/effective date; yêu cầu legal/compliance review cho Việt Nam; kiểm tra policy hiện tại và submission evidence cho Apple; kiểm tra provider-specific payment/recommendation contracts; sau đó lưu decision, reviewer, expiry và open questions trong change workspace.

## References

[1]: https://developers.google.com/machine-learning/recommendation/overview/types "Google for Developers — Recommendation systems"
[2]: https://developer.apple.com/app-store/review/guidelines/ "Apple — App Review Guidelines"
[3]: https://developer.apple.com/documentation/storekit/in-app-purchase "Apple Developer — In-App Purchase / StoreKit"
[4]: https://developer.apple.com/support/offering-account-deletion-in-your-app/ "Apple — Offering account deletion in your app"
[5]: https://developer.apple.com/documentation/bundleresources/privacy-manifest-files "Apple — Privacy manifest files"
[6]: https://vanban.chinhphu.vn/?pageid=27160&docid=214590&classid=1&orggroupid=1 "Luật 91/2025/QH15 — Bảo vệ dữ liệu cá nhân"
[7]: https://vanban.chinhphu.vn/?pageid=27160&docid=216387 "Nghị định 356/2025/NĐ-CP — bảo vệ dữ liệu cá nhân"
[8]: https://vanban.chinhphu.vn/?pageid=27160&docid=207759 "Nghị định 13/2023/NĐ-CP — bảo vệ dữ liệu cá nhân"
[9]: https://vanban.chinhphu.vn/default.aspx?pageid=27160&docid=204191 "Nghị định 85/2021/NĐ-CP — thương mại điện tử"
[10]: https://vanban.chinhphu.vn/?pageid=27160&docid=206381 "Nghị định 53/2022/NĐ-CP — Luật An ninh mạng"
[11]: https://vanban.chinhphu.vn/?pageid=27160&docid=208363 "Luật 19/2023/QH15 — Bảo vệ quyền lợi người tiêu dùng"
[12]: https://vanban.chinhphu.vn/?pageid=27160&docid=208421 "Luật 20/2023/QH15 — Giao dịch điện tử"
[13]: https://github.com/medusajs/medusa "Medusa GitHub repository"
[14]: https://github.com/apache/superset "Apache Superset GitHub repository"
[15]: https://github.com/grafana/grafana "Grafana GitHub repository"
