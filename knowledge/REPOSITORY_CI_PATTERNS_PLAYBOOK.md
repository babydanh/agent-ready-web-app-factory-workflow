# Repository and CI Patterns Playbook

> Mục tiêu: chuẩn hóa cách tổ chức repository, ownership, changeset, test, CI, release và automation cho web app/backend từ project nhỏ đến monorepo.

## 1. Chọn repository shape

| Shape | Phù hợp | Trade-off |
|---|---|---|
| Single app repo | MVP, team nhỏ, deploy cùng nhau | Dễ bắt đầu nhưng dễ phình và coupling |
| Monorepo | Web + API + shared types + packages | Cần boundary, affected CI, cache và ownership |
| Polyrepo | Team/service độc lập, release độc lập | Contract/version/integration phức tạp hơn |
| Platform + product repos | Nhiều app dùng chung platform | Cần API/SDK governance và compatibility |

Đừng chọn microservices chỉ vì workflow có playbook. Boundary nên xuất hiện từ ownership, scaling, data authority, release cadence hoặc security isolation.

## 2. Baseline layout cho web app

```text
repo/
├── apps/
│   ├── web/
│   ├── api/
│   └── worker/
├── packages/
│   ├── contracts/
│   ├── config/
│   ├── ui/
│   └── test-fixtures/
├── docs/
├── changes/
├── infra/
├── scripts/
├── .github/
│   ├── workflows/
│   ├── CODEOWNERS
│   └── pull_request_template.md
├── AGENTS.md
├── CONTRIBUTING.md
└── README.md
```

Không đặt domain truth trong generated client hoặc frontend types. Contract package/source of truth phải có owner, version và generation policy.

## 3. Module boundary và dependency direction

Mỗi package/module cần public API rõ, không import xuyên private internals. Một hướng đơn giản:

```text
UI → application/use-case → domain → ports
                         ↘ adapters/infrastructure
```

Controller không chứa pricing/authorization/inventory invariant. Repository không tự quyết định policy. Worker không bypass service contract mà không có lý do được ghi trong ADR. Shared package không biến thành “miscellaneous” chứa mọi thứ.

Architecture fitness check nên kiểm tra forbidden imports, dependency direction, duplicate DTO, route-to-contract drift và database access bypass.

## 4. Ownership và review

CODEOWNERS hoặc ownership matrix phải map path/domain tới owner. High-risk paths gồm auth, payment, migrations, permissions, infrastructure, data export, AI tools và CI. PR cần reviewer phù hợp; approval không thay cho test/evidence.

GitHub repository patterns trong Medusa, Superset và Grafana cho thấy `.github`, docs, tests, scripts, changesets/release material và domain packages là các thành phần cần được quản lý cùng code [1] [2] [3].

## 5. Change folder và pull request

Mỗi change nên có change ID, problem map, discovery, design, contract, tests, risk, implementation log, convergence và release evidence. PR body phải link change ID, issue/decision, test results, migration/rollback, security impact và screenshots/contract diff nếu liên quan.

Một PR tốt trả lời được:

```text
What changed?
Why now?
What contract/data/permission changed?
What can fail and how is it recovered?
What tests actually ran?
How can it be rolled back?
What evidence proves readiness?
```

## 6. CI pipeline tiers

| Tier | Trigger | Checks |
|---|---|---|
| Fast PR | Every PR | formatting, typecheck, unit focused, manifest, secret scan, contract/schema |
| Affected | Changed paths | package tests, API integration, frontend build, migration checks |
| Full | Main/nightly | full unit/integration/E2E, security, dependency, accessibility, performance smoke |
| Release | Tag/approval | artifact provenance, migration rehearsal, smoke, rollback, SLO/runbook, evidence |

CI phải fail closed cho security/contract/migration checks. Không dùng `|| echo` để biến production migration failure thành success. Nếu check intentionally skipped, output phải có `SKIPPED` với reason và policy, không giả làm pass.

## 7. Cache correctness

Cache key phải bao gồm lockfile, runtime version, OS/architecture khi cần và relevant build inputs. Cache không được làm CI bỏ qua install/test cần thiết. Với monorepo, affected graph phải được tính từ source/config/lockfile và shared package changes; đừng chỉ dựa vào path của app.

Cache hit phải observable. Cần một scheduled clean install job để phát hiện lỗi mà cache che mất. Recent repository change material in Medusa mô tả việc test thật và kiểm tra generated output/runtime compatibility để tránh “build pass nhưng runtime fail” [1].

## 8. Contract and integration tests

Unit test không đủ để chứng minh controller, database, queue, provider và generated client khớp nhau. Tối thiểu cần:

| Layer | Evidence |
|---|---|
| Schema | JSON Schema/OpenAPI validation |
| API | HTTP integration + auth/error/status |
| DB | migration up/down or forward-only rehearsal + constraints |
| Worker | retry/idempotency/DLQ |
| Realtime | event schema/ack/reconnect |
| Frontend | consumer contract + critical E2E |
| External | sandbox/fixture/verification + timeout/failure |

Không ghi `PASS` nếu test chưa chạy. Dùng `PASS`, `FAIL`, `BLOCKED`, `SKIPPED` với reason và command.

## 9. Build and release

Artifact phải reproducible, versioned và traceable tới commit, dependency lock, build command và environment. Release checklist cần include migration, feature flag, config/secrets, health/readiness, smoke, rollback, support contact và changelog.

Nếu dùng changesets, mỗi user-visible/package/API change phải có release intent. Nếu không dùng changesets, cần một cơ chế equivalent. Generated files phải có policy: commit hay build-time generate, ai review, làm sao detect drift.

## 10. Security supply chain

CI nên có dependency audit/SBOM, secret scan, lockfile review, container/image scan, artifact signing/provenance khi phù hợp và least-privilege tokens. Pin action versions hoặc digest theo policy. Không expose secrets trong logs hoặc fixtures.

## 11. Repository hygiene

Các file tạm, build output, coverage và local env phải được ignore nhưng không ignore evidence cần commit. Giữ root README ngắn, link tới docs index; mọi command phải chạy được hoặc ghi rõ prerequisite. Không chạy script nguy hiểm mà không có dry-run, scope guard và confirmation.

## 12. Definition of Done

Repository change chỉ đạt DoD khi boundary/owner rõ, change artifact tồn tại, affected CI đúng, contract/integration tests chạy, cache không che test, migration/release path rõ, security checks fail-closed và evidence có trạng thái trung thực.

## References

[1]: https://github.com/medusajs/medusa "Medusa repository"
[2]: https://github.com/apache/superset "Apache Superset repository"
[3]: https://github.com/grafana/grafana "Grafana repository"
