# Endpoint Contract — [OPERATION_ID]

## 1. Metadata

| Field | Value |
|---|---|
| Operation ID | `[stable.operationId]` |
| Method/path | `[GET|POST|PUT|PATCH|DELETE] /api/v1/[path]` |
| Purpose | `[Một câu]` |
| Bounded context | `[context]` |
| Profile | `PUBLIC_WEB / MONEY_MOVING / AI_ENABLED / ...` |
| Owner | `[team]` |
| Version/deprecation | `[version]` |

## 2. Policy

| Policy | Value |
|---|---|
| Authentication | `required / optional / public` |
| Roles | `[roles]` |
| Ownership/tenant scope | `[rule/query scope]` |
| CSRF | `required / not applicable / reason` |
| Rate limit | `[policy name + limit]` |
| Idempotency | `required / optional / not applicable` |
| Audit event | `[event name]` |
| Sensitive input/output | `[classification]` |

## 3. Request

### Headers

| Header | Required | Schema | Purpose |
|---|---:|---|---|
| `Authorization` | `[yes/no]` | `Bearer ...` | `[policy]` |
| `X-CSRF-Token` | `[yes/no]` | string | `[cookie client]` |
| `Idempotency-Key` | `[yes/no]` | opaque 16–255 chars | `[mutation]` |
| `If-Match`/revision | `[yes/no]` | string/integer | `[concurrency]` |

### Path/query/body schema

```yaml
pathParams: {}
query:
  type: object
  additionalProperties: false
body:
  type: object
  additionalProperties: false
```

Normalize and validate trim, Unicode, timezone, enum, numeric boundaries, unknown properties and content size.

## 4. Responses

| HTTP | Code/type | Body schema | Retry? | Privacy note |
|---:|---|---|---|---|
| 200/201 | success | `[Schema]` | no | `[projection]` |
| 400 | `VALIDATION_ERROR` | Problem | no | no internals |
| 401 | `UNAUTHENTICATED` | Problem | after login | no user existence leak |
| 403 | `FORBIDDEN` | Problem | no | no permission details beyond need |
| 404 | `NOT_FOUND` | Problem | no | privacy-preserving if needed |
| 409 | `STATE_CONFLICT` | Problem | refresh/resolve | revision only |
| 422 | `SEMANTIC_ERROR` | Problem | no | actionable detail |
| 429 | `RATE_LIMITED` | Problem | Retry-After | no token |
| 500/503 | `SERVICE_UNAVAILABLE` | Problem | bounded | generic detail |

### Success example

```json
{
  "statusCode": 200,
  "message": "[message]",
  "data": {},
  "meta": {
    "requestId": "req_01J..."
  }
}
```

### Error example

```json
{
  "type": "https://api.example.com/problems/[problem-type]",
  "title": "[stable title]",
  "status": 409,
  "detail": "[client-actionable detail]",
  "instance": "/api/v1/[path]",
  "code": "[STABLE_CODE]",
  "requestId": "req_01J..."
}
```

## 5. Side effects and state

```text
Preconditions: [state/permission]
Transaction: [tables/locks/isolation]
Outbox/events: [event names]
External calls: [provider + timeout + retry]
Idempotency: [key scope/TTL/result replay]
Rollback/compensation: [procedure]
```

## 6. Tests and evidence

- Schema request/response validation.
- Auth, role, ownership and cross-tenant negative tests.
- Unknown field, boundary, nullability and malformed input.
- 401/403/404/409/429/5xx mapping.
- Duplicate/retry/concurrent mutation.
- Privacy projection and error redaction.
- OpenAPI breaking-change diff.
- UI state mapping and E2E trace.
