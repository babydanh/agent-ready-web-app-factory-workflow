# Contract Governance

## 1. Source-of-truth hierarchy

Mỗi thay đổi phải chỉ rõ artifact authoritative. Business meaning đến từ approved feature/PRD; entity, invariant và privacy đến từ canonical data spec; wire format đến từ OpenAPI/JSON Schema/event schema; UI behavior đến từ screen spec/design tokens; implementation chỉ là hiện thực hóa contract. DTO, ORM row, database column hoặc UI copy không tự động trở thành public contract.

Nếu hai artifact mâu thuẫn, agent không tự chọn theo file dễ sửa hơn. Trạng thái phải là `NEEDS_CLARIFICATION`, nêu conflict, consumer bị ảnh hưởng và đề xuất owner quyết định.

## 2. Contract lifecycle

Contract đi qua các trạng thái `DRAFT → REVIEW → APPROVED → IMPLEMENTED → VERIFIED → DEPRECATED → RETIRED`. Chỉ `APPROVED` mới được code against; `IMPLEMENTED` chưa có evidence không được coi là verified. Mỗi contract có owner, version, changelog, compatibility window, consumer inventory và ngày review.

| Stage | Gate |
|---|---|
| Draft | Request/response, errors, auth, ownership, state and examples are present |
| Review | Product, backend, frontend and security impacts are reviewed |
| Approved | Breaking classification, migration and deprecation plan are accepted |
| Implemented | Server, client, schema and docs use the same version |
| Verified | Contract, negative, security and UI tests have evidence |
| Deprecated | Replacement, sunset date and migration notice are published |
| Retired | Consumer inventory is zero or explicit owner-approved exception exists |

## 3. Schema and OpenAPI rules

OpenAPI 3.1 và JSON Schema 2020-12 là baseline cho HTTP contract. Mỗi operation có unique `operationId`, explicit auth, content type, success status, all relevant error status, pagination/filter rules, idempotency and examples. Schema phải đặt `additionalProperties` có chủ đích; không để accidental fields leak từ ORM/entity.

Success response dùng envelope hiện hành `{statusCode,message,data,meta}` trong compatibility window. Error response dần chuyển sang `application/problem+json` theo RFC 9457-compatible model với stable `type`, `code`, `status`, `detail`, `instance`, `requestId` và optional field errors. Migration phải dual-read/dual-write hoặc versioned, không silently break clients.

## 4. Breaking-change classification

| Change | Classification | Default action |
|---|---|---|
| Add optional response field | Non-breaking, verify tolerant clients | Contract test and changelog |
| Add required request field | Breaking | New version or staged optional-then-required migration |
| Remove/rename field | Breaking | Deprecation window and replacement |
| Narrow enum/status | Breaking | New status strategy; never silently repurpose old value |
| Change meaning/unit/timezone | Breaking semantic change | New field/version and data migration |
| Change error code/type | Potentially breaking | Preserve old code during window |
| Change pagination ordering | Breaking for cursor/client assumptions | Version or explicit contract update |
| Change auth/ownership | Security-impacting | Security review, negative tests and release gate |

## 5. Validation and test layers

Validate artifact syntax first, then schema examples, then generated/manual types, then live endpoint responses. A green TypeScript build alone is insufficient. Contract fixtures cover at least success, validation, unauthenticated, forbidden, not found, conflict, rate limited and server error. Sensitive fields and extra fields must have explicit tests.

Consumer-driven contract tests are required when independently deployed clients depend on the API. Provider verification runs against the same contract version. Golden fixtures are versioned and sanitized; they must not contain tokens, PII, production identifiers or real payment data.

## 6. Code generation and mapping

Code generation may produce API types/client from approved schema, but generated code is not a substitute for domain validation, authorization or response projection. Manual mapping is acceptable when documented; it must map only allowlisted fields and preserve nullability, enum and date/money semantics. Never expose ORM rows directly.

## 7. Deprecation and versioning

Prefer additive changes and tolerant readers. Use URL/header/media-type versioning consistently; do not mix strategies per endpoint without ADR. A deprecation notice records replacement, first deprecated release, sunset date, telemetry metric and owner. Removal requires consumer inventory evidence, migration guide and rollback/compatibility decision.

## 8. Realtime and asynchronous contracts

Socket events and job payloads are contracts too. Each event/job includes name, version, event ID, aggregate ID, occurredAt, producer, payload schema and deduplication/replay behavior. Unknown events must be ignored safely or trigger resync; clients must not infer domain truth from display text.

## 9. Governance decision record

Every approved change appends a record containing contract version, affected consumers, breaking classification, security/privacy impact, test evidence, rollout/rollback and approvers. Missing consumer inventory, missing rollback for breaking behavior or unexplained schema drift means `BLOCKED`.
