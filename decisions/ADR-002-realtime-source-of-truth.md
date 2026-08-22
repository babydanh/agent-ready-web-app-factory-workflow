# ADR-002 — Database là Source of Truth cho Realtime

## Status

Accepted.

## Context

Socket.IO bảo đảm thứ tự message nhưng mặc định không bảo đảm mọi event đến được client khi disconnect. Live score, standings và payment cần correctness cao hơn tốc độ broadcast.

## Decision

Mutation đi qua authenticated API/socket handler, được validate và persist ở PostgreSQL trước. Sau commit, backend emit event có `eventId`, `matchId` và `version/sequence`. Client reconnect phải resync snapshot hoặc replay từ offset; nếu version lệch thì bỏ state stale và tải lại.

## Consequences

**Tốt:** Refresh/reconnect không làm mất source data; audit và replay có căn cứ.

**Đổi lại:** Cần thêm event metadata, snapshot endpoint, persistence/offset strategy và test eventual update.

## Rejected option

Không coi broadcast socket chưa persist là sự thật cuối cùng; không cập nhật score chỉ ở client rồi hy vọng server đồng bộ.

## Validation

- [ ] Disconnect giữa lúc update.
- [ ] Reconnect và snapshot resync.
- [ ] Duplicate event không làm tăng score hai lần.
- [ ] Out-of-order/stale version bị bỏ.
- [ ] Unauthorized socket không đọc room.
