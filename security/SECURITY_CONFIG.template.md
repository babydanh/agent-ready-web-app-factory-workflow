# Security Configuration Template

> Chỉ lưu tên biến và placeholder. Secret thật phải được cấp qua secret manager/runtime environment.

## 1. Environment profile

| Variable | Local | Staging | Production | Rule |
|---|---|---|---|---|
| `NODE_ENV` | `development` | `staging` | `production` | Không dùng alone để tắt security |
| `SECURITY_PROFILE` | `local-strict` | `staging-strict` | `production-strict` | Explicit policy |
| `FRONTEND_URL` | `https://local.example` | Exact staging origin | Exact production origin | Allowlist, không tự do redirect |
| `API_URL` | Placeholder | Staging API | Production API | HTTPS ngoài local |
| `TRUSTED_ORIGINS` | Exact list | Exact list | Exact list | Không `*` với credentials |
| `APP_API_KEY` | Placeholder/fixture | Secret manager | Secret manager | Admission-only, rotate |

## 2. JWT/session

| Variable | Rule |
|---|---|
| `JWT_ACCESS_SECRET` | Strong random secret; separate from refresh; rotate plan |
| `JWT_REFRESH_SECRET` | Strong random secret; separate from access |
| `JWT_ISSUER` | Exact service identifier; verify on every path |
| `JWT_AUDIENCE_WEB` | Exact audience for web |
| `JWT_AUDIENCE_MOBILE` | Exact audience for mobile |
| `JWT_ACCESS_EXPIRES_IN` | Short TTL chosen by risk/UX |
| `JWT_REFRESH_EXPIRES_IN` | Longer TTL chosen by risk/device policy |
| `COOKIE_DOMAIN` | Narrowest valid domain; avoid broad parent domain |
| `COOKIE_SECURE` | `true` in staging/prod HTTPS |
| `COOKIE_SAMESITE` | Explicit `Lax`/`Strict`/`None` decision |
| `ALLOW_QUERY_TOKEN` | `false` in production |
| `SESSION_REUSE_POLICY` | family revoke/step-up/notify decision |

## 3. Password/recovery

| Variable | Rule |
|---|---|
| `PASSWORD_HASH_ALGORITHM` | `bcrypt`/`argon2id`/`pbkdf2` policy |
| `PASSWORD_HASH_COST` | Benchmark-based, documented |
| `RESET_TOKEN_TTL` | Canonical value shared by code/email/UI |
| `VERIFY_TOKEN_TTL` | Canonical value shared by code/email/UI |
| `OTP_MAX_ATTEMPTS` | Bounded; lock/expire on excess |
| `RECOVERY_RATE_LIMIT` | Shared-store policy |
| `TOKEN_PEPPER_REF` | Reference only; no pepper value in repo |

## 4. Rate limit/abuse

| Variable | Rule |
|---|---|
| `RATE_LIMIT_STORE` | Redis/shared store for multi-instance |
| `LOGIN_RATE_LIMIT` | IP + account/device policy |
| `RESET_RATE_LIMIT` | IP + normalized identifier |
| `OTP_RATE_LIMIT` | User + device/IP + purpose |
| `WEBSOCKET_RATE_LIMIT` | Connection/message/room policy |
| `BODY_SIZE_LIMIT` | Smallest acceptable per endpoint |
| `QUEUE_ATTEMPTS` | Per job type; do not retry permanent errors |

## 5. OAuth/OIDC

| Variable | Rule |
|---|---|
| `GOOGLE_CLIENT_ID` | Exact audience allowlist |
| `GOOGLE_CLIENT_SECRET` | Server secret; never client bundle |
| `APPLE_CLIENT_ID` | Exact audience |
| `OAUTH_REDIRECT_ALLOWLIST` | Exact URI list, no wildcard |
| `OAUTH_STATE_TTL` | Short-lived transaction |
| `OAUTH_NONCE_REQUIRED` | `true` where OIDC flow uses nonce |
| `OAUTH_PKCE_REQUIRED` | `true` for public clients |
| `SYSTEM_ADMINS` | Controlled bootstrap list; audit and expiry/review |

## 6. Payment/provider

| Variable | Rule |
|---|---|
| `PAYOS_CLIENT_ID` | Server-side secret/config |
| `PAYOS_API_KEY` | Secret manager |
| `PAYOS_CHECKSUM_KEY` | Secret manager; never log/client |
| `PAYMENT_WEBHOOK_URL` | HTTPS public backend endpoint |
| `PAYMENT_ENV` | Sandbox and production separated |
| `PAYMENT_IDEMPOTENCY_POLICY` | Unique provider/order reference |

## 7. Logging/observability

| Variable | Rule |
|---|---|
| `LOG_REDACTION_ENABLED` | Required outside local fixture |
| `OTEL_EXPORTER_ENDPOINT` | Server-side only; no secret in URL |
| `CORRELATION_ID_HEADER` | One canonical name |
| `LOG_RETENTION_DAYS` | Privacy/incident policy |
| `AUDIT_RETENTION_DAYS` | Business/legal policy |

## 8. Startup assertions

Production startup phải fail-closed nếu thiếu secret hoặc policy quan trọng: JWT secrets, issuer/audience, exact origin, payment secret khi payment enabled, database/Redis URL và security profile. Startup không được in secret value; chỉ báo tên biến thiếu và hướng dẫn cấu hình an toàn.

## 9. Config review checklist

- [ ] Không có secret value trong `.env.example`, Git, Docker image hoặc frontend bundle.
- [ ] Local/staging/prod có profile rõ; staging không dùng mock bypass.
- [ ] Cookie domain/path/SameSite/Secure nhất quán với clear-cookie.
- [ ] JWT access/refresh/WS verify cùng issuer/audience/algorithm policy.
- [ ] OAuth redirect exact allowlist, state/nonce/PKCE policy.
- [ ] Payment sandbox/prod credentials tách biệt.
- [ ] Redis shared rate-limit/queue policy rõ.
- [ ] Logs redacted và observability endpoint không lộ credential.
