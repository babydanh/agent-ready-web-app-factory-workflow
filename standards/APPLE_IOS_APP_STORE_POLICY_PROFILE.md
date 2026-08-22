# Apple iOS and App Store Policy Profile

> Mục tiêu: chuẩn hóa product, backend, mobile, privacy, payment và release khi web app có iOS/iPadOS client. **Đây là engineering/release checklist, không bảo đảm App Review approval. Apple policy là tài liệu sống và phải được kiểm tra lại trước mỗi submission.**

## 1. App Store scoping

Trước khi code, xác định app có: account creation, login providers, digital goods/subscriptions, physical goods/services, UGC, ads/tracking, health/financial/children content, location, background capability, push, Sign in with Apple, external purchase/link, web companion và third-party SDK.

Apple tổ chức App Review Guidelines theo Safety, Performance, Business, Design và Legal; trước submission yêu cầu test crash/bug, metadata chính xác, backend live, review access/demo account và ghi chú cho feature hoặc in-app purchase không hiển nhiên [1].

## 2. Payment decision tree

```text
User pays for digital content/functionality consumed in app?
  ├─ Yes → StoreKit/IAP policy review + entitlement backend
  └─ No → physical goods/offline service/web business flow review

Subscription?
  ├─ Yes → product/offer/renewal/cancel/refund/server notification/reconcile
  └─ No → one-time/non-consumable policy and restore review
```

Không nhúng web payment vào iOS chỉ để né review. Phân loại digital vs physical/service và storefront/region phải được product/legal owner xác nhận. StoreKit là nguồn kỹ thuật cho in-app purchase; backend vẫn cần receipt/transaction verification, entitlement projection, restore, revoke/refund và reconciliation [2].

## 3. IAP backend state machine

```text
PRODUCT_CONFIGURED
  → PURCHASE_PENDING
  → VERIFIED
  → ENTITLED
  → REVOKED / REFUNDED / EXPIRED
```

Lưu transaction ID/original transaction ID, product ID, app/bundle/environment, purchase/expiration/revocation time, verification result, user mapping và entitlement history. Dùng unique constraint/idempotency để transaction notification lặp không cấp entitlement hai lần. Không coi client receipt hoặc UI “success” là authority duy nhất.

Subscription system phải xử lý renewal, grace/billing retry nếu có, cancellation, upgrade/downgrade/proration, refund/revoke, family sharing/restore nếu product hỗ trợ và App Store Server Notifications. Mỗi state cần owner, retry, support path và test fixture.

## 4. Account creation/deletion

Apple yêu cầu app có account creation cho phép user khởi tạo account deletion trong app. Hướng dẫn Apple yêu cầu xóa toàn bộ account record và associated data theo policy, không chỉ disable tạm; nếu xử lý mất thời gian phải thông báo thời lượng và xác nhận hoàn tất [3].

Nếu dùng Sign in with Apple, khi xóa account cần revoke user tokens qua Sign in with Apple REST API [3]. Workflow phải map deletion tới primary DB, sessions/refresh tokens, OAuth identity, uploads, search index, events/analytics, recommendation features, backups/legal hold và third-party processors.

## 5. Privacy and SDK inventory

Apple privacy manifest `PrivacyInfo.xcprivacy` ghi data types mà app/third-party SDK thu thập và required-reason APIs; tài liệu Apple nêu các key liên quan tracking, tracking domains, collected data types và accessed API types [4].

Release phải có SDK inventory:

| Item | Evidence |
|---|---|
| SDK name/version/vendor | Lockfile/binary inventory |
| Data collected | Privacy manifest + App Store privacy details mapping |
| Required-reason API | API scan + declared reason |
| Tracking domains/ATT | Decision and permission UX |
| Network endpoints | Data-flow map and region |
| Retention/deletion | Processor contract and deletion job |
| Crash/analytics | Fields, masking, opt-out and access |
| License/security | Version pin, CVE review, update owner |

Không tuyên bố “privacy-safe” chỉ vì có `PrivacyInfo.xcprivacy`; phải đối chiếu runtime behavior, SDK configuration và App Store disclosure.

## 6. Authentication and review access

Login phải có clear error/loading/offline states, keychain/secure storage, session expiry, logout, account deletion và recovery. Nếu app dùng third-party/social login, review Sign in with Apple requirements and identity mapping. Không log token, password, OTP hoặc raw authorization code.

App Review cần active demo account hoặc fully-featured demo mode nếu account-based feature; backend, seed data, payment sandbox and feature flags phải hoạt động trong review environment [1]. Tài liệu review notes phải giải thích non-obvious permissions, purchase, roles, test account và test steps.

## 7. User-generated content and moderation

Nếu app có post, review, comment, chat, profile/media hoặc seller content, cần report, block/mute, moderation path, abuse response, prohibited-content policy, evidence retention và account enforcement. UGC feature cần privacy/children/safety review; backend không được chỉ hide content bằng frontend.

## 8. Permissions and platform behavior

Mỗi permission cần purpose string, just-in-time request, denial/degraded experience và data minimization. Location, camera, microphone, photos, contacts, tracking, notifications, Bluetooth, health and background modes phải có feature rationale và test trên denied/restricted state.

UI phải tuân Apple Human Interface Guidelines và accessibility expectations; test Dynamic Type, VoiceOver, reduced motion, dark mode, localization, safe area, permission denial, poor network, interrupted purchase và background/foreground.

## 9. Release gates

| Gate | PASS evidence |
|---|---|
| Build | Reproducible archive, signing/profile, supported OS matrix |
| Crash/performance | Device/simulator smoke, crash-free critical flows |
| Payment | Sandbox purchase, restore, refund/revoke, duplicate/out-of-order notification |
| Account | Signup/login/logout/recovery/deletion completion |
| Privacy | Manifest, SDK inventory, App Store privacy answers, ATT decision |
| Security | Token storage, transport, deep link/universal link, jailbreak/threat review as applicable |
| UGC | Report/block/moderation and abuse test |
| Review | Demo account, review notes, live backend, test data |
| Accessibility | VoiceOver, Dynamic Type, contrast, keyboard/external input where applicable |
| Legal | Terms/privacy/consumer/payment/region review owner approval |

## 10. Web + iOS consistency

Web backend phải expose platform-neutral domain contracts while iOS adds StoreKit-specific adapter and entitlement mapping. Không để iOS purchase state bypass the same authorization/ledger/audit path. API should include platform/app version where policy/feature behavior depends on it, but server remains authoritative for entitlement.

## References

[1]: https://developer.apple.com/app-store/review/guidelines/ "Apple App Review Guidelines"
[2]: https://developer.apple.com/documentation/storekit/in-app-purchase "Apple StoreKit — In-App Purchase"
[3]: https://developer.apple.com/support/offering-account-deletion-in-your-app/ "Apple — Offering account deletion in your app"
[4]: https://developer.apple.com/documentation/bundleresources/privacy-manifest-files "Apple — Privacy manifest files"
