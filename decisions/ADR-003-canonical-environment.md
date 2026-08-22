# ADR-003 — Chốt Canonical Environment trước Automation

## Status

Proposed; human review required.

## Observed drift

- Một số tài liệu ghi Node 18, trong khi backend/frontend skills yêu cầu Node 20 LTS trở lên.
- `current-status.md` mô tả PostgreSQL 16 nhưng Docker Compose đang dùng image PostGIS PostgreSQL 15.
- README/Compose có tên thư mục cũ trong khi filesystem hiện tại có `HethongBackendApi_QuanlyGiaiDau` và `HethongFrontEndWeb_QLgiaidau`.

## Decision required

Chọn một Node version, một PostgreSQL/PostGIS image và một canonical path. Cập nhật README, Compose, CI, Dockerfile, local setup và harness cùng một lượt.

## Why this matters

Automation chỉ đáng tin khi command/path/version ổn định. Nếu không chốt baseline, agent có thể chạy nhầm package, migration khác database version hoặc deploy image không tương thích.

## Acceptance criteria

- [ ] Node version canonical có `.nvmrc`/Volta/toolchain policy hoặc CI pin.
- [ ] PostgreSQL/PostGIS image được xác nhận bằng test migration và extension.
- [ ] Compose mount/path khớp filesystem.
- [ ] README/local setup/CI/harness cùng dùng canonical values.
- [ ] Migration test trên database sạch pass.
- [ ] Quyết định được ghi vào release/runbook.
