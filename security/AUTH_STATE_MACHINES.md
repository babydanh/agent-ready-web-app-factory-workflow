# Auth State Machines

> Auth bug thường nằm ở transition, không nằm ở màn hình login. Mỗi transition phải có actor, precondition, side effect, audit event, expiry/revocation và test negative.

## 1. Account state

```text
CREATED
  ├── email verified ──> ACTIVE
  ├── admin/user action ──> SUSPENDED
  ├── policy ban ──> BANNED
  └── deletion request ──> DELETED

ACTIVE ── password reset / suspicious event ──> REAUTH_REQUIRED
REAUTH_REQUIRED ── successful step-up ──> ACTIVE
SUSPENDED/BANNED/DELETED ── never bypass by stale JWT ──> policy review
```

| Transition | Actor | Preconditions | Side effects |
|---|---|---|---|
| Register → Created | Anonymous | Valid input, unique email | Hash password, profile/role transaction, audit |
| Created → Active | User via verification | Valid unexpired unused token | Atomic consume, mark verified, notify/audit |
| Active → Suspended/Banned | Admin/policy | Authorized reason | Revoke sessions, audit, close sockets |
| Active → Reauth required | Risk engine/policy | Sensitive action/risk event | Short step-up session, audit |
| Any → Deleted | User/admin policy | Retention/legal checks | Revoke sessions, soft-delete, purge schedule |

## 2. Session state

```text
ISSUED → ACTIVE → ROTATED → REVOKED
                 └──────> REUSE_DETECTED → FAMILY_REVOKED
ACTIVE → EXPIRED
ACTIVE → LOGGED_OUT
ACTIVE → ACCOUNT_BANNED
```

A refresh request may transition `ACTIVE(R1)` to `ROTATED(R2)` exactly once. A second `R1` request must not create an unlimited new session. Concurrent behavior needs a bounded policy, not a broad grace period that hides replay.

Session table recommended fields: `id`, `userId`, `clientType`, `tokenHash`, `familyId`, `issuedAt`, `lastUsedAt`, `rotatedAt`, `revokedAt`, `expiresAt`, `reuseDetectedAt`, optional device metadata under privacy policy.

## 3. Password reset state

```text
NONE → REQUESTED → SENT → CONSUMED
                    └──> EXPIRED
REQUESTED/SENT ──> REVOKED
```

`REQUESTED` does not prove the account exists. External response remains generic. `CONSUMED` must be an atomic one-time transition coupled with password update and session revocation. Concurrent consume allows one success only.

## 4. Email/phone verification state

```text
UNVERIFIED → CHALLENGE_SENT → VERIFIED
               ├──> EXPIRED
               ├──> ATTEMPT_LIMITED
               └──> REVOKED
```

A verification challenge has type, subject, hashed code, expiry, used timestamp, attempt counter, request cooldown and audit. A new challenge can revoke older challenges for the same purpose according to product policy.

## 5. OAuth transaction state

```text
STARTED → CALLBACK_VALIDATED → IDENTITY_VERIFIED → LINKED/CREATED → SESSION_ISSUED
   ├──> EXPIRED
   ├──> STATE_MISMATCH
   ├──> NONCE_MISMATCH
   ├──> PKCE_FAILED
   └──> PROVIDER_REJECTED
```

OAuth transaction state is short-lived and bound to browser/client context. Do not use provider email as the sole identity key. Clear transaction state after success or terminal failure.

## 6. Sensitive action step-up

```text
NORMAL_SESSION
  → ACTION_REQUESTED
  → REAUTH_CHALLENGE
  → STEP_UP_VERIFIED
  → ACTION_COMMITTED
  → STEP_UP_EXPIRED
```

Payment detail change, payout, password/email change, role/admin action, adding trusted device and account recovery may require step-up. The step-up result is scoped, short-lived and not a general long-lived access token.

## 7. Payment state boundary

```text
PENDING
  ├── webhook verified + amount/order match ──> PAID
  ├── provider failure ──> FAILED
  ├── expiry ──> EXPIRED
  └── refund flow ──> REFUND_PENDING → REFUNDED/REFUND_FAILED
```

Browser return does not transition `PENDING` to `PAID`. Only verified provider event/reconciliation can do so. Each transition stores provider reference, idempotency key, actor/source and audit event.

## 8. Transition test format

```text
Transition ID: SESSION-ROTATE-001
Actor: authenticated web user
Given: session R1 is active and unexpired
When: refresh is called twice concurrently
Then: at most one rotation is canonical; R1 cannot be reused indefinitely
And: R2/session state is consistent
Evidence: DB rows, response status, audit event, no raw token in log
```

## 9. Invariant list

- A revoked/expired/banned/deleted account cannot gain access using a stale access token beyond the chosen revocation window.
- A reset/verification challenge cannot be consumed twice.
- A role/owner in request body cannot override authenticated actor or server policy.
- A payment cannot become paid from a client redirect alone.
- A socket cannot outlive account session policy indefinitely.
- A failed external call cannot create a duplicate payment, email, payout or notification side effect.
