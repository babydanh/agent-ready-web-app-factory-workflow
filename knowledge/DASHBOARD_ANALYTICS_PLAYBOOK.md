# Dashboard and Analytics Playbook

> Mục tiêu: biến dashboard từ tập biểu đồ đẹp thành một sản phẩm dữ liệu có định nghĩa metric, quyền truy cập, freshness, performance, lineage và hành động rõ ràng.

## 1. Dashboard là một data product

Mỗi dashboard cần có audience, decision/use case, owner, refresh/freshness target, data source, access scope, metric glossary, filter semantics, empty/partial/stale state, export policy và runbook. Không chấp nhận dashboard chỉ có screenshot hoặc query không có definition.

| Thành phần | Câu hỏi bắt buộc |
|---|---|
| Audience | Ai xem và quyết định gì? |
| Grain | Một row là order, user, session, event hay day? |
| Metric | Tử số/mẫu số, filter, timezone, currency, null và rounding là gì? |
| Freshness | Dữ liệu trễ tối đa bao lâu? |
| Source | OLTP, replica, warehouse, event stream hay read model? |
| Access | Tenant/role nào được xem row nào? |
| Performance | Query budget, cache TTL và concurrency target là gì? |
| Action | Nếu metric xấu thì ai làm gì và trong bao lâu? |

Apache Superset mô tả dataset-centric visualization, semantic layer cho dimensions/metrics, caching, role/auth và API customization [1]. Đây là pattern tốt để workflow tách dataset/semantic definition khỏi layout dashboard.

## 2. OLTP, read model và warehouse

Không dùng dashboard nặng query trực tiếp vào transactional primary database nếu có thể ảnh hưởng user flow. Chọn mô hình theo freshness và workload:

| Mô hình | Khi dùng | Rủi ro |
|---|---|---|
| OLTP query/read replica | Dashboard nhỏ, near-real-time | Lock/load, metric drift |
| Materialized/read model | Metric ổn định, cần nhanh | Refresh lag, backfill |
| Event projection | Cần timeline/funnel/realtime | Event loss/dup/order |
| Warehouse/OLAP | Phân tích lớn, nhiều chiều | Cost, latency, governance |
| Cache | Query lặp, target rõ | Stale data, invalidation |

Mọi read model phải có rebuild/backfill path. Không chỉ có cron “chạy được” mà không biết khôi phục khi job fail.

## 3. Metric contract

Metric contract mẫu:

```yaml
metric: gross_merchandise_value
owner: commerce
source: order_fact
grain: order_line
formula: sum(captured_amount - refunded_amount)
currency: order.currency
timezone: Asia/Ho_Chi_Minh
filters:
  - order_status in [paid, fulfilled, partially_refunded]
  - test_order = false
freshness_slo: 15m
privacy: internal
```

Metric phải phân biệt gross/net, created/paid/fulfilled, UTC/local timezone, order count/line count, unique user/session, cancelled/refunded và partial data. Nếu có multi-currency, cần exchange-rate source/version và policy snapshot. Không cộng trực tiếp amount khác currency.

## 4. Dashboard state matrix

Dashboard UX cần có initial, loading, success, empty, partial, stale, error, unauthorized, forbidden, rate-limited và offline/reconnect state. Một chart bị lỗi không nhất thiết làm toàn trang trắng; hiển thị panel-level error và thời điểm dữ liệu.

`lastUpdatedAt`, `dataAsOf`, freshness status và source nên hiển thị khi có thể. Stale không đồng nghĩa empty. Zero có nghĩa không có sự kiện; null/error có nghĩa không biết.

## 5. Query and performance controls

Mỗi query production cần query budget, index/partition expectation, maximum time range, maximum series/rows, pagination or aggregation strategy, cache policy và cancellation. Export phải có row/size limit, async job cho file lớn, authorization re-check và audit.

Grafana repository minh họa việc instrument repository operations với operation, size, duration và outcome để nhận biết payload lớn, slow path và error chứ không chỉ đếm request [2]. Áp dụng cùng principle cho dashboard query: `dashboardId`, `panelId`, `queryId`, `tenant`, `bytes/rows`, `duration`, `cacheHit`, `outcome`.

## 6. Access control và data leakage

Dashboard phải áp dụng row-level/tenant-level security ở backend hoặc data layer, không chỉ hide filter trên frontend. Cần test cross-tenant, export, share link, embed token, cached response và drilldown. Cache key phải bao gồm security scope hoặc chỉ cache dữ liệu public.

Sensitive metrics cần access justification, audit trail và masking/aggregation. Không hiển thị PII khi aggregate đủ để trả lời câu hỏi. Phải quyết định có cho phép download raw rows hay chỉ aggregate.

## 7. Alerting và actionability

Alert không phải là chart đỏ. Mỗi alert cần owner, signal, threshold/baseline, evaluation window, missing-data behavior, dedupe/grouping, severity, runbook, escalation và suppress/maintenance rule. Alert theo error budget nên liên kết SLO; alert theo metric business cần chống seasonality và double notification.

## 8. Versioning and dashboard-as-code

Dashboard definition, dataset, metric, query, alert và access policy nên được lưu dưới dạng versioned artifacts hoặc provisioning-as-code. Một thay đổi metric phải tạo contract change, review owner và migration note. Không sửa production dashboard thủ công mà không có export/diff/audit.

Cần tách `dashboardId` ổn định khỏi title; title có thể đổi. Panel query cần `queryId` và version. Broken reference, deleted dataset hoặc renamed field phải fail CI hoặc được báo rõ.

## 9. Dashboard test matrix

| Test | Nội dung |
|---|---|
| Metric unit | Công thức với known fixtures, null, timezone, refund/partial |
| Data contract | Dataset schema và required dimension/measure |
| Access | Tenant/role/export/embed/expired token |
| Freshness | Lag, missing partition, late event |
| Performance | Cold/warm cache, time range, high cardinality |
| Visual | Label, tooltip, no-data, error, mobile/tablet |
| Alert | Threshold, no data, recovery, dedupe, notification owner |
| Rebuild | Re-run projection/materialized view không duplicate |
| Change | Rename/deprecate metric có compatibility note |

## 10. Definition of Done

Dashboard feature chỉ đạt DoD khi có decision/use case, owner, metric contracts, source/grain, access policy, freshness target, query budget, cache policy, empty/stale/error UI, export controls, tests, alert/runbook nếu có và versioned dashboard artifact.

## References

[1]: https://github.com/apache/superset "Apache Superset repository"
[2]: https://github.com/grafana/grafana "Grafana repository"
