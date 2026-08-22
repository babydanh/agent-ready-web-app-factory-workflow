# Recommendation, Search and Ranking Playbook

> Mục tiêu: thiết kế hệ tìm kiếm/gợi ý có thể giải thích, đo lường, rollback và an toàn hơn thay vì chỉ gọi một model rồi hiển thị danh sách.

Recommendation và search là hệ thống sản phẩm + dữ liệu + ranking + feedback loop. Không nên bắt đầu bằng model. Hãy bắt đầu bằng mục tiêu người dùng, inventory dữ liệu, constraint kinh doanh, privacy boundary và tiêu chí thất bại.

## 1. Phân biệt search, recommendation và ranking

| Bài toán | Input chính | Mục tiêu | Failure đặc trưng |
|---|---|---|---|
| Search | Query + filters + context | Tìm item phù hợp với ý định hiện tại | Zero result, typo, injection, slow query, irrelevant result |
| Recommendation | User/context + corpus | Khám phá item có khả năng hữu ích | Cold start, filter bubble, popularity bias, feedback loop |
| Ranking | Candidate set + features | Sắp xếp candidate theo objective | Leakage, unstable ordering, unfair exposure, latency |
| Personalization | Identity/history/preferences | Điều chỉnh kết quả theo user | PII misuse, stale profile, consent/opt-out |
| Ads/promoted result | Bid/business constraints + relevance | Tối ưu value có disclosure | Hidden promotion, manipulation, policy violation |

Một pipeline production thường tách **candidate generation → scoring → re-ranking**. Google mô tả candidate generation là bước thu hẹp corpus lớn, scoring dùng model chính xác hơn trên tập nhỏ và re-ranking thêm constraint như dislike, freshness, diversity và fairness [1].

## 2. Event taxonomy và data contract

Trước model cần định nghĩa event có schema ổn định:

| Event | Required fields | Ý nghĩa |
|---|---|---|
| `impression` | `eventId`, `requestId`, `userScope`, `itemId`, `position`, `modelVersion`, `timestamp` | Item đã được hiển thị |
| `click/open` | impression correlation, itemId, surface | Tương tác chủ động |
| `save/favorite` | itemId, actor, source | Preference mạnh hơn click |
| `add_to_cart` | itemId, quantity, price snapshot, currency | Commercial intent |
| `purchase/complete` | orderId, itemId, net amount, refund status | Outcome cần attribution |
| `hide/dislike` | itemId, reason, actor | Hard negative/constraint |
| `search` | query class, filters, result count, latency | Search intent và UX |
| `feedback` | rating/reason, target, consent | Explicit feedback |

Event phải phân biệt `shown` với `clicked`, không gắn purchase cho recommendation nếu attribution window không rõ. Không đưa raw PII vào feature store nếu không cần. Cần định nghĩa retention, consent/opt-out, deletion propagation và access control cho event data.

## 3. Candidate generation

Candidate sources có thể gồm lexical search, category/attribute match, collaborative history, content similarity, trending, recent, inventory/availability, seller/business rules và editorial curation. Mỗi source cần owner, freshness, latency budget, failure fallback và diversity role.

Candidate generator phải:

1. Bỏ item không publish, không available, bị block hoặc user đã opt-out.
2. Áp hard safety/business constraint trước khi model ranking.
3. Có fallback deterministic khi vector/search/index/model unavailable.
4. Gắn source provenance để debug và audit exposure.
5. Bounded top-K để tránh memory/latency blow-up.

Không expose raw vector, private feature hay internal score ra API. Client chỉ nhận stable item representation, reason code đã được duyệt và tracking metadata không chứa bí mật.

## 4. Scoring và re-ranking

Scoring objective phải nói rõ đang tối ưu click, useful session, conversion, retention, margin, completion hay multi-objective weighted score. Không dùng CTR một mình nếu nó khuyến khích clickbait. Re-ranking layer phải xử lý:

| Constraint | Ví dụ |
|---|---|
| Availability | Bỏ sản phẩm hết hàng hoặc slot không còn |
| Freshness | Boost item mới trong cửa sổ thời gian |
| Diversity | Không trả 10 item cùng seller/category |
| Safety | Block content/merchant/risk segment |
| Fair exposure | Giới hạn concentration và theo dõi exposure distribution |
| Business | Commission/promotion nhưng phải disclose và không phá relevance |
| User control | Dislike, mute, block, opt-out personalization |
| Legal/privacy | Không suy luận hoặc dùng sensitive attribute ngoài mục đích hợp lệ |

Tất cả ranking response cần chứa `modelVersion`, `policyVersion`, `requestId`, `generatedAt` và optional `explanationCode` ở internal telemetry; public response chỉ expose những trường đã được duyệt.

## 5. Cold start và fallback ladder

Cold start phải là thiết kế chính thức:

```text
personalized model
  → content/category/context model
  → popular/trending trong scope
  → curated/default list
  → empty state có search/onboarding
```

New user cần fallback không yêu cầu thu thập quá mức. New item cần content metadata, editorial seed hoặc controlled exploration. New market/seller cần guardrail để không bị zero exposure nhưng cũng không đẩy item chưa kiểm duyệt.

Fallback phải observable: log `fallbackReason`, `source`, `modelVersion` và latency; dashboard theo dõi tỷ lệ fallback theo route/tenant/device.

## 6. Evaluation

Offline evaluation cần time-based split để tránh future leakage; train/test boundary phải theo thời gian hoặc user/item policy. Metrics cần kết hợp:

| Nhóm | Metrics gợi ý |
|---|---|
| Retrieval | Recall@K, candidate coverage, latency |
| Ranking | NDCG@K, MRR, MAP, calibration |
| Business | conversion, add-to-cart, revenue/margin, completion |
| UX | zero-result, reformulation, hide/dislike, session success |
| Diversity | category/seller coverage, intra-list diversity |
| Fairness | exposure distribution, seller/item long-tail coverage |
| Reliability | timeout, fallback rate, feature freshness, error rate |
| Safety | blocked-content leakage, policy violations, complaint rate |

Online A/B test phải có primary metric, guardrails, minimum sample, exposure randomization, stopping rule, segment analysis và rollback. Không coi improvement nhỏ về click là thắng nếu refund, complaint, latency hoặc safety xấu đi.

## 7. Search-specific controls

Search query phải được normalize và parse thành structured intent; không nối raw query vào SQL, shell, template hoặc filter expression. Cần xử lý typo, synonym, language, pagination, sort stability, zero result và abusive query rate. Search result nên có `total` hoặc cursor semantics rõ ràng, nhưng tránh count đắt nếu không cần.

Autocomplete cần rate limit và privacy review vì query có thể chứa dữ liệu nhạy cảm. Search logs phải có retention và masking. Export/search analytics phải phân quyền theo tenant.

## 8. Recommendation API contract

Một response hợp lệ nên chứa:

```json
{
  "statusCode": 200,
  "message": "Recommendations retrieved",
  "data": {
    "items": [],
    "strategy": "personalized",
    "explanationAvailable": false
  },
  "meta": {
    "requestId": "req_123",
    "modelVersion": "ranker_2026_08",
    "nextCursor": null
  }
}
```

Không đưa score thô, private embedding, hidden policy reason hoặc sensitive feature vào public response. Nếu item bị lọc sau ranking, log internal reason nhưng không leak rule anti-abuse cho attacker.

## 9. Production operations

Cần có feature freshness SLO, model/index versioning, shadow mode, canary, kill switch, fallback, replayable request sample đã mask, drift monitoring và rollback. Model artifact và feature schema phải immutable theo version. Khi event schema thay đổi, phải chạy compatibility check với training/serving consumers.

## 10. Definition of Done

Một recommendation/search feature chỉ đạt DoD khi có event schema, privacy classification, candidate sources, ranking objective, re-ranking constraints, cold-start ladder, public contract, offline eval, online experiment plan, abuse/safety review, latency budget, fallback observability, rollback/kill switch và owner.

## References

[1]: https://developers.google.com/machine-learning/recommendation/overview/types "Google — Recommendation systems overview"
