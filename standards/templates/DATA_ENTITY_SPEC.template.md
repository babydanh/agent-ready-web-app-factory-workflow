# Data Entity Spec — [ENTITY_NAME]

## 1. Identity

| Field | Value |
|---|---|
| Entity | `[EntityName]` |
| Business purpose | `[Một câu mô tả]` |
| Owner/bounded context | `[Context]` |
| Privacy class | `PUBLIC / INTERNAL / PERSONAL / SENSITIVE / FINANCIAL` |
| Source of truth | `[table/service/event]` |
| Retention/deletion | `[policy]` |

## 2. Field dictionary

| Field | DB type | API type | Required/null | Default | Validation | Privacy | Read/write actor |
|---|---|---|---|---|---|---|---|
| `id` | uuid | string | required/non-null | generated | UUID | INTERNAL | server |
| `[field]` | `[type]` | `[type]` | `[rule]` | `[default]` | `[rule]` | `[class]` | `[actor]` |

## 3. Relationships and ownership

```text
[Entity] 1 ─── N [RelatedEntity]
```

Ghi rõ FK, composite FK, tenant/tournament scope, cascade behavior, soft delete và query authorization. Không chỉ dựa vào frontend để enforce ownership.

## 4. State machine

| From | Command | Actor | Preconditions | To | Side effects | Idempotent |
|---|---|---|---|---|---|---|
| `[STATE]` | `[command]` | `[role]` | `[condition]` | `[STATE]` | `[event/job]` | yes/no |

## 5. Invariants

- `[Invariant 1: ...]`
- `[Invariant 2: ...]`
- `[Invariant 3: ...]`

Mỗi invariant phải map tới DB constraint, service validation hoặc transaction test.

## 6. Index and query patterns

| Query/use case | Filter/order | Expected cardinality | Index | Explain/evidence |
|---|---|---:|---|---|
| `[use case]` | `[fields]` | `[N]` | `[index]` | `[plan]` |

## 7. Migration and rollback

```text
Expand: [add nullable column/index/table]
Backfill: [bounded job]
Dual-read/write: [if needed]
Contract: [remove/constraint after consumers migrate]
Rollback: [safe path]
```

## 8. API/UI mapping

| Consumer | Projection | Sensitive fields removed | Contract/test |
|---|---|---|---|
| REST `GET ...` | `[projection]` | yes/no | `[fixture]` |
| Realtime event | `[payload]` | yes/no | `[test]` |
| UI screen | `[view model]` | yes/no | `[screen spec]` |
| AI tool | `[compact projection]` | yes/no | `[tool test]` |

## 9. Test matrix

- Valid create/update/read/delete.
- Invalid type, null, boundary and unknown field.
- Cross-owner/cross-tournament access.
- Duplicate/idempotent command.
- Concurrent mutation and retry.
- Migration forward/rollback and old consumer compatibility.
- Serialization/privacy projection.
