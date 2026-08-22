# Commerce, Recommendation and Compliance Pack Release Evidence — v1.7.0

**Ngày:** 2026-08-22  
**Phạm vi:** Mở rộng reusable Web App Factory cho commerce/marketplace, recommendation/search/ranking, dashboard/analytics, transaction/concurrency, repository/CI, compliance Việt Nam và Apple iOS/App Store.  
**Chế độ:** Documentation, templates, harness and governance only; không sửa source backend/frontend, không đọc secret production và không đóng gói ZIP theo yêu cầu hiện tại.

## 1. Artifact inventory

| Nhóm | Artifact |
|---|---|
| Commerce | `knowledge/COMMERCE_SYSTEMS_PLAYBOOK.md` |
| Recommendation/search/ranking | `knowledge/RECOMMENDATION_SEARCH_RANKING_PLAYBOOK.md` |
| Dashboard/analytics | `knowledge/DASHBOARD_ANALYTICS_PLAYBOOK.md` |
| Transaction/concurrency | `knowledge/TRANSACTION_CONCURRENCY_PLAYBOOK.md` |
| Repository/CI | `knowledge/REPOSITORY_CI_PATTERNS_PLAYBOOK.md` |
| Policy research | `knowledge/COMMERCE_RECOMMENDATION_POLICY_RESEARCH_2026-08-22.md` |
| Vietnam profile | `standards/VIETNAM_WEB_APP_COMPLIANCE_PROFILE.md` |
| Apple profile | `standards/APPLE_IOS_APP_STORE_POLICY_PROFILE.md` |
| Executable gates | `standards/COMMERCE_RECOMMENDATION_DASHBOARD_GATES.md` |
| Feature templates | `COMMERCE_FLOW_SPEC`, `RECOMMENDATION_FEATURE_SPEC`, `DASHBOARD_ANALYTICS_SPEC`, `TRANSACTION_CONCURRENCY_TEST`, `COMPLIANCE_SCOPE_RECORD`, `APPLE_IOS_RELEASE_REVIEW` |
| Integration | Profile-aware `harness/init-workflow.ps1`, `harness/new-change.ps1`, `harness/validate-workflow.ps1` |
| Index/manifest | Updated `README.md`, `WORKFLOW.md`, `SKILL.md`, `AGENTS.md`, `knowledge/README.md`, `standards/README.md`, `MANIFEST.json` |

## 2. Coverage delivered

Commerce coverage now makes catalog/pricing/cart/order/inventory/payment/ledger/refund/marketplace/payout/reconciliation and fraud/business metrics explicit. Recommendation coverage follows event taxonomy, candidate generation, scoring, re-ranking, cold start, privacy/fairness, evaluation, search safety and rollback. Dashboard coverage defines metric contract, grain, semantic/read models, access, freshness, query budget, alerts, export and dashboard-as-code. Transaction coverage defines invariants, transaction boundaries, isolation/locking, constraints, idempotency, outbox/inbox/saga, retries, recovery, reconciliation and concurrency tests. Repository/CI coverage defines package boundaries, CODEOWNERS, change/release evidence, CI tiers, cache correctness and supply-chain controls.

The Vietnam profile treats Law 91/2025/QH15 and Decree 356/2025/NĐ-CP as current 2026 data-protection sources, while keeping Decree 13/2023/NĐ-CP as a historical/transition reference that must not be the sole basis. It also scopes consumer, electronic transaction, e-commerce and cybersecurity review. The Apple profile covers App Review access, StoreKit/IAP, entitlement/reconciliation, account deletion, Sign in with Apple, privacy manifests/SDKs, permissions, UGC, accessibility and submission evidence.

## 3. Harness integration

`init-workflow.ps1` now copies the new knowledge playbooks and policy research while retaining recursive standards/templates copying. `new-change.ps1` supports `Commerce`, `Recommendation`, `Dashboard`, `VietnamCompliance` and `AppleIOS` profiles. Commerce and Recommendation default to `HighRisk`; a lower tier is rejected unless `-AllowRiskWaiver` generates `profile-risk-waiver.md`. Selected profiles generate exact per-change artifacts, and `validate-workflow.ps1` checks those artifacts from the README metadata. The validator remains intentionally read-only and does not claim semantic OpenAPI/YAML/Markdown validation, legal compliance, metric correctness, model fairness, Apple approval or provider certification.

## 4. Validation evidence

| Check | Result |
|---|---|
| `MANIFEST.json` parse | PASS; version `1.7.0` |
| Strict workflow validator | PASS; `registered_paths=114`, `json_files=5`, no change selected |
| Manifest path existence/empty-file/JSON/PowerShell checks | PASS through strict validator |
| Physical workflow ↔ manifest cross-check | PASS; 114 physical files, 114 registered, 0 unregistered, 0 missing |
| Bootstrap/profile integration | PASS; bootstrap 104 files; HighRisk Commerce + VietnamCompliance + AppleIOS change 19 files; Normal Recommendation with waiver change 15 files |
| Required waiver behavior | PASS; Normal Commerce without `-AllowRiskWaiver` rejected as expected |
| Profile change validation | PASS for HighRisk multi-profile and Normal Recommendation waiver workspaces |
| Temporary test cleanup | PASS; integration helper and temporary workspaces removed |
| Source application build/test rerun | NOT RUN; no source code was changed in this pack |

## 5. Research basis

The research artifact records Google’s candidate-generation/scoring/re-ranking pattern; Apple App Review, StoreKit, account deletion and privacy-manifest guidance; official Vietnamese sources for personal data, e-commerce, consumer, electronic transactions and cybersecurity; and public repository observations from Medusa, Apache Superset and Grafana. These sources support design questions and evidence requirements, not approval or certification.

## 6. Limitations and open review

This pack is not a legal opinion and does not cover every tax/e-invoice, payment-network, PCI, advertising, financial, healthcare, gambling, children, consumer-product, sector licensing or cross-border obligation. A qualified Vietnam legal/compliance reviewer must confirm scope, current effective text, roles, data transfers and required filings. Apple policy is living; the submission owner must re-check current guidelines, product category, storefront/region exceptions and App Review evidence. Payment, payout and recommendation providers require separate contract/certification review.

The validator checks artifact presence and syntax only. It does not prove that placeholders are completed, invariants are true, metrics are correct, queries are safe, ranking is fair, policies are satisfied or runtime behavior matches documentation. Existing application P0/P1 findings remain untouched: this release improves the workflow package and does not remediate the app audit backlog.

## Decision

**Decision:** `PASS_WITH_CONDITIONS`

**Conditions:** Apply the relevant profile to a real feature, complete every generated artifact, obtain qualified legal/platform review where indicated, run domain-specific executable tests and keep unresolved engineering/legal/platform status explicit. Do not describe the workflow as a legal certificate, App Store approval, PCI/payment certification or proof that the current app is production-ready.
