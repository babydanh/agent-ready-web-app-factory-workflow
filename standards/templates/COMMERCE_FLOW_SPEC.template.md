# Commerce Flow Spec

## 1. Flow metadata

- Change ID:
- Flow name:
- Business model: storefront / marketplace / booking / subscription / POS / service:
- Owner:
- Risk tier:
- Actors:
- Currency/region:

## 2. Domain boundaries

| Context | Source of truth | Data owned | External dependency | Invariant |
|---|---|---|---|---|
| Catalog |  |  |  |  |
| Pricing |  |  |  |  |
| Order |  |  |  |  |
| Inventory |  |  |  |  |
| Payment/ledger |  |  |  |  |
| Fulfillment |  |  |  |  |

## 3. State machine

```text
[describe states, allowed transitions, actor and terminal states]
```

| From | Command | Preconditions | To | Side effects | Retry/compensation |
|---|---|---|---|---|---|
|  |  |  |  |  |  |

## 4. Money and pricing

- Money representation/minor unit:
- Currency policy:
- Price snapshot fields:
- Discount/tax/shipping precedence:
- Rounding:
- Refund allocation:
- Price tampering controls:

## 5. Inventory/reservation

- Available/reserved/committed representation:
- Reservation TTL:
- Oversell invariant:
- Lock/optimistic strategy:
- Expiry/release job:
- Concurrency tests:

## 6. Payment and ledger

- Provider:
- Intent/idempotency key:
- Amount/currency/order matching:
- Webhook signature/replay/out-of-order:
- Internal payment state:
- Ledger entries/reversals:
- Refund/revoke/dispute:
- Reconciliation cadence and repair approval:

## 7. API and UI

- Endpoint(s):
- Request/response/error contracts:
- Auth/ownership/CSRF/rate limit:
- UI state matrix:
- Receipt/order confirmation:
- Cancel/refund/support path:

## 8. Failure and abuse matrix

| Failure/abuse | Detection | Prevention | Recovery | Test/evidence |
|---|---|---|---|---|
| Duplicate request |  |  |  |  |
| Timeout after provider mutation |  |  |  |  |
| Webhook duplicate/out-of-order |  |  |  |  |
| Inventory race |  |  |  |  |
| Price/coupon abuse |  |  |  |  |
| Refund mismatch |  |  |  |  |

## 9. Observability and release

- Business metrics:
- Technical metrics:
- Audit events:
- SLO/alert/runbook:
- Feature flag/canary:
- Migration/rollback:
- Reconciliation evidence:
- Decision: `PASS / CONDITIONAL / BLOCKED / NOT-READY`:
