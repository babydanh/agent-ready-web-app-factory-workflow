# Environment Matrix — [Tên project]

## 1. Runtime

| Thành phần | Local | Staging | Production | Canonical version |
|---|---|---|---|---|
| Node.js | [x] | [x] | [x] | [Version] |
| pnpm | [x] | [x] | [x] | [Version] |
| PostgreSQL/PostGIS | [x] | [x] | [x] | [Version] |
| Redis | [x] | [x] | [x] | [Version] |
| Backend | [URL/port] | [URL] | [URL] | [Image/commit] |
| Frontend | [URL/port] | [URL] | [URL] | [Image/commit] |

## 2. Variables

| Variable | Local | Staging | Production | Secret? | Owner |
|---|---|---|---|---:|---|
| `DB_HOST` | [value/placeholder] | [value/secret ref] | [value/secret ref] | No | DevOps |
| `DB_USERNAME` | [placeholder] | [secret ref] | [secret ref] | Yes | DevOps |
| `DB_PASSWORD` | [placeholder] | [secret ref] | [secret ref] | Yes | DevOps |
| `JWT_ACCESS_SECRET` | [placeholder] | [secret ref] | [secret ref] | Yes | Security |
| `JWT_REFRESH_SECRET` | [placeholder] | [secret ref] | [secret ref] | Yes | Security |
| `REDIS_HOST` | [value] | [value] | [value] | No | DevOps |
| `FRONTEND_URL` | [URL] | [URL] | [URL] | No | DevOps |
| `CLOUDINARY_*` | [placeholder] | [secret ref] | [secret ref] | Yes | DevOps |
| `PAYMENT_*` | [sandbox ref] | [sandbox ref] | [production ref] | Yes | Payments |
| `SMTP_*` | [mock/ref] | [secret ref] | [secret ref] | Yes | DevOps |
| `AI_*` | [placeholder] | [secret ref] | [secret ref] | Yes | AI owner |

## 3. Readiness

- [ ] Không có secret trong Git.
- [ ] CORS/allowed origins đúng environment.
- [ ] OAuth callback đúng domain.
- [ ] Payment sandbox/production mode đúng.
- [ ] Storage bucket/cloudinary folder đúng.
- [ ] Database backup/retention đã cấu hình.
- [ ] Health check và alert hoạt động.
- [ ] Migration order đã kiểm tra.
