# Phase 00 — Intake và Product Specification

## Mục tiêu

Đóng phạm vi trước khi chọn công nghệ hoặc viết code. Một brief tốt phải trả lời ai dùng, vấn đề gì, vì sao cần giải quyết, hành động nào được hỗ trợ và thế nào là thành công.

## Quy trình

1. Ghi problem statement trong một đoạn ngắn.
2. Xác định persona, role, quyền và mức độ tin cậy.
3. Viết user journey chính và failure journey.
4. Chia MVP, post-MVP và out-of-scope.
5. Viết acceptance criteria có thể kiểm thử.
6. Liệt kê dữ liệu, tích hợp, SLA, privacy và compliance.
7. Ghi open questions; câu hỏi blocker phải có owner.

## Công nghệ cần quyết định

| Chủ đề | Câu hỏi |
|---|---|
| Rendering | Dữ liệu nào cần server render, client interaction, streaming hoặc cache? |
| API | REST/OpenAPI hay GraphQL? Cần versioning, pagination, idempotency nào? |
| Data | Entity nào là source of truth? Có transaction/concurrency/spatial query không? |
| Auth | Public, session, JWT, OAuth/OIDC, MFA hay role/resource policy? |
| Realtime | Polling, SSE, WebSocket hay event stream? Mất event xử lý ra sao? |
| Jobs | Công việc nào chạy async, retry, schedule hoặc cần manual review? |
| Files | File size/type, retention, virus scan, CDN và access control? |
| AI | Model/tool nào, output schema, budget, privacy, human approval? |
| Release | Local, staging, production, backup, rollback và owner? |

## Đầu ra

`PRD.md`, `acceptance-criteria.md`, `persona-map.md`, `permission-matrix.md`, `risk-register.md` và `open-questions.md`.

## Gate

Không được sang Phase 01 nếu còn câu hỏi ảnh hưởng trực tiếp đến schema, quyền, tiền, dữ liệu cá nhân, external side effect hoặc tiêu chí pass/fail.
