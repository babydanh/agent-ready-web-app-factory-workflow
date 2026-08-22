# Phase 01 — Recon và Architecture

## Mục tiêu

Hiểu hệ thống hiện tại trước khi sửa và biến các quyết định công nghệ thành architecture decision có lý do. Không chọn stack vì đang phổ biến; chọn vì phù hợp workload, team, rủi ro và khả năng vận hành.

## Recon protocol

- Đọc README, current status, skill docs, Graphify report và domain docs.
- Kiểm tra Git baseline, working tree và file đang thay đổi.
- Lập dependency map: route → API → service → repository → schema.
- Đánh dấu boundary: public/private, role/ownership, sync/async, source of truth/cache.
- Ghi architecture drift: version, path, environment, dependency hoặc contract không khớp.

## Technology evaluation

Mỗi lựa chọn ghi theo mẫu: context, options, decision, consequences, security impact, operational impact, migration và trigger để đánh giá lại. So sánh ít nhất hai phương án khi quyết định ảnh hưởng lớn.

## Baseline khuyến nghị

Modular monolith cho domain nhiều transaction liên kết; PostgreSQL làm source of truth; Redis không thay database; queue dùng cho external/slow work; Socket.IO chỉ vận chuyển event sau khi persist; Next.js server-first; REST/OpenAPI cho contract; OpenTelemetry cho correlation; Docker Compose local và CI/CD có staging gate.

## Đầu ra

`feature-impact-map.md`, `architecture.md`, `ADR-*.md`, dependency map, threat-model sơ bộ và danh sách canonical versions/paths.

## Gate

Architecture phải giải thích được data flow, failure mode, scaling boundary, auth boundary, migration strategy và rollback. Nếu chưa giải thích được, chưa được code.
