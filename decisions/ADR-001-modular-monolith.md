# ADR-001 — Chọn Modular Monolith trước Microservices

## Status

Accepted for current project; review when scale/ownership evidence changes.

## Context

Đồ án có nhiều domain: auth, tournaments, matches, rankings, payments, communities, chat và admin. Một số use case cần transaction liên kết giữa các domain, trong khi team và deployment complexity cần được kiểm soát.

## Decision

Dùng NestJS modular monolith. Mỗi domain có module boundary, public service interface, repository và test riêng. Không chia process/service chỉ vì số lượng module lớn.

## Rationale

Modular monolith giữ transaction và consistency đơn giản hơn, debug local dễ hơn, ít network failure hơn và phù hợp tốc độ phát triển của team nhỏ. Boundary module vẫn được thiết kế nghiêm để có thể tách service khi có bằng chứng.

## Consequences

**Tốt:** Dễ chạy local, dễ migration, ít operational overhead, transaction liên domain rõ.

**Đổi lại:** Một deploy unit có thể scale không độc lập; phải kiểm soát dependency/circular coupling bằng architecture review.

## Trigger review

- Một module có tải khác hẳn và cần scale độc lập.
- Team ownership/deploy cadence đã tách.
- Security/compliance yêu cầu isolation.
- Workload media/AI cần worker fleet riêng.
- Metrics chứng minh monolith là bottleneck.
