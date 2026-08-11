# Development Log

**The engineering journal for Aesthetic Coach.** Unlike [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md) (which always shows *current* state) and [NEXT_TASK.md](NEXT_TASK.md) (which always shows the *next* single task), this document is an **append-only history** of what actually happened, session by session — the record you'd read to answer "what did we do on [date]" or "when did we implement X."

---

## Current Status

**Phase 1 · Sprint 1 in progress.** Infrastructure, Authentication Foundation (register/login/logout, hardened), and refresh-token rotation are merged to `main`. Next: session/device management.

---

## Entry Format

Every future entry follows this template exactly — copy it, fill it in, prepend the new entry above older ones (most recent first) below the [Entries](#entries) heading:

```markdown
### YYYY-MM-DD — [Sprint X · Task/Module Name]

**Sprint:** Phase 1 · Sprint N (or Phase 2 · Sprint N)
**Task ID:** [reference into TASK_BREAKDOWN.md, e.g. "Sprint 1, Task 3"]
**Objective:** [one sentence — what this session set out to do]

**Files Changed:**
- `path/to/file` — [what changed]

**Database Changes:**
- [migration name, table(s) affected, or "None"]

**API Changes:**
- [endpoint(s) added/changed, or "None"]

**Flutter Changes:**
- [screen(s)/widget(s) added/changed, or "None"]

**Tests Executed:**
- [test suite(s) run and result — e.g. "Pest Feature tests: 12 passed", "Widget tests: 4 passed"]

**Known Issues:**
- [anything left incomplete, deferred, or a new risk discovered — or "None"]

**Git Commit:** `<short-sha>` — `<conventional-commit message>`

**Next Task:** [what NEXT_TASK.md was updated to point at]
```

**Rules:**
- One entry per development session, not per commit — if a session produces multiple commits, list them all under **Git Commit**.
- **Known Issues** is not optional to fill in honestly — an entry that says "None" when something was actually deferred defeats the purpose of the log. Cross-reference [MASTER_IMPLEMENTATION_PLAN.md § Known Risks](MASTER_IMPLEMENTATION_PLAN.md#known-risks) if the issue is significant enough to track there too.
- This log records what happened; it does not replace updating [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md)'s Sprint Tracker/Module Progress or [NEXT_TASK.md](NEXT_TASK.md) — do both.

---

## Entries

### 2026-08-11 — Sprint 1 · Refresh Token Rotation Merge & Session Management

**Sprint:** Phase 1 · Sprint 1
**Task ID:** Sprint 1, Task 11 (Refresh Token Rotation), Task 15 (Session/Device Management)
**Objective:** Review, security-audit, and merge the refresh-token rotation implementation to `main`; then implement session/device management (`GET/DELETE /auth/sessions`).

**Files Changed:**
- `backend/app/Modules/Auth/Services/{AuthService,TokenService}.php` — `refresh()`, `revokeFamily()`
- `backend/app/Modules/Auth/Exceptions/{InvalidRefreshTokenException,SessionRevokedException}.php` — new
- `backend/app/Modules/Auth/Http/Requests/RefreshRequest.php` — new
- `backend/tests/Feature/Auth/RefreshTest.php` — new, 14 tests
- Session management files listed in this session's own deliverables report (see PR)

**Database Changes:**
- None — the existing `auth_refresh_tokens`/`devices` schema (Database Design section 3.1) already supported both refresh rotation and session management without modification.

**API Changes:**
- `POST /auth/refresh` (merged this session)
- `GET /auth/sessions`, `DELETE /auth/sessions/{deviceId}` (implemented this session — see PR for exact behavior)

**Flutter Changes:**
- None

**Tests Executed:**
- Pest Feature tests (real MySQL): 50 passing before session management; see this session's own report for the post-session-management count.

**Known Issues:**
- A **critical transaction bug** was found via manual smoke testing before the formal test suite existed: throwing an exception inside `DB::transaction()` rolls back every write made in that transaction, including the family-revocation `UPDATE` — reuse detection was silently a no-op until the closure was restructured to return a status and throw only after commit. Fixed and verified via both automated tests and live smoke tests pre- and post-merge.
- `JWT_ISSUER=` (empty-but-set in `.env`) doesn't trigger the `APP_NAME` fallback, since `env()` only falls back on truly-unset keys. Harmless (issuance/validation stay consistent) but still unfixed, flagged again.

**Git Commit:** `d18eadc` — `feat(auth): implement refresh token rotation and session management` (squash-merge of `feature/refresh-token-rotation`)

**Next Task:** OAuth (Google/Apple Sign-In) or email verification + password reset, per [TASK_BREAKDOWN.md § Sprint 1](docs/TASK_BREAKDOWN.md).

### 2026-08-10 — Sprint 1 · Authentication Foundation & Security Hardening

**Sprint:** Phase 1 · Sprint 1
**Task ID:** Sprint 1, Task 9 (Authentication Foundation)
**Objective:** Implement register/login/logout per ADR-0005, then resolve the blocking findings from an independent security review, then merge both to `main`.

**Files Changed:**
- `backend/app/Modules/Auth/**` — AuthService, TokenService, Form Requests, DTOs, Platform enum, UserResource, AuthController, AuthServiceProvider, routes
- `backend/app/Shared/**` — RequestIdMiddleware, ForceJsonResponse, ApiResponse, AppException (standardized error envelope, needed for consistent auth error responses)
- `backend/config/{jwt,cors,api}.php` — new config for JWT signing/leeway/issuer, environment-driven CORS allow-list, API contract version
- `backend/database/migrations/*` — `users` scoped to auth-relevant columns, new `devices` and `auth_refresh_tokens` tables
- `backend/app/Providers/ModuleServiceProvider.php` — fixed a latent string-interpolation bug (present since the Infrastructure session) that silently broke module auto-discovery; never exercised until Auth's own `AuthServiceProvider` needed it
- `docs/05-api-specification.md`, `docs/api-examples/auth.md`, `docs/features/authentication.md` — added the `platform`/`deviceName` fields the `devices` table requires but the original register/login/oauth examples never showed (a genuine spec gap found during pre-implementation validation, fixed with user approval)

**Database Changes:**
- Modified: `users` (renamed `password` to `password_hash`, dropped `remember_token`, added `deleted_at`)
- New: `devices` (`platform`, `device_name`, `push_token`, `app_version`, `last_active_at`)
- New: `auth_refresh_tokens` (`token_hash` unique, `family_id`, `revoked_at`, `expires_at`)

**API Changes:**
- `POST /auth/register`, `POST /auth/login`, `POST /auth/logout` — all rate-limited (10 req/min per IP), fail-closed by default (register/login explicitly exempted from the `auth:api` requirement)

**Flutter Changes:**
- None

**Tests Executed:**
- Pest Feature tests (real MySQL, per Testing Strategy section 5): 36 passed — registration, login, logout, CORS, rate limiting, JWT validation (signature, issuer, expiration)

**Known Issues:**
- `phpunit.xml`'s `<env>` overrides don't reliably win over Docker's `env_file`-injected `$_SERVER` values inside this project's containers; documented the required `-e` flag invocation directly in `phpunit.xml`.
- `password_reset_tokens` table still has Laravel's unmodified default shape (mismatched with Database Design's documented schema) — harmless since Password Reset isn't implemented yet, but needs correcting when that feature lands.
- BR-5 (max 10 concurrent device sessions, oldest revoked) is not yet enforced by register/login — flagged, not fixed, since it's a login/register behavior change outside this session's scope.
- Unhandled exceptions still leak full stack traces when `APP_DEBUG=true` (local dev default) — mitigated in production via a documented deploy-time `APP_DEBUG=false` check that doesn't exist yet (no CI/CD module built).

**Git Commit:** `3dd9d9b` — `docs(auth): document required platform/deviceName fields on register, login, oauth`; `2a079df` — `feat(auth): implement authentication foundation`

**Next Task:** Refresh-token rotation & session management (`POST /auth/refresh`)

### 2026-08-06 — Sprint 1 · Infrastructure Scaffolding

**Sprint:** Phase 1 · Sprint 1
**Task ID:** Sprint 1, Task 1 (Infrastructure)
**Objective:** Migrate the development environment to a Linux server, scaffold the Laravel backend per the documented `app/Modules/*` architecture, and validate the full Docker/MySQL/Redis stack.

**Files Changed:**
- `backend/**` — Laravel 13 application, `app/Modules/Auth/{Http,Models,Services}` structure-only scaffold, `app/Shared/`, `app/Providers/ModuleServiceProvider.php`
- `docker-compose.yml`, `backend/Dockerfile` — local dev stack (app/mysql/redis/mailhog), host ports remapped to avoid colliding with the shared server's own native MySQL/Redis
- `SERVER_SETUP_REPORT.md` — server specs, installed software, validation results

**Database Changes:**
- None (default Laravel `users`/`cache`/`jobs` migrations only, no application schema yet)

**API Changes:**
- None

**Flutter Changes:**
- None

**Tests Executed:**
- Pest example tests: 2 passed. Full Docker stack validated end-to-end (migrations, rollback, Redis cache/queue, HTTP health checks).

**Known Issues:**
- Shared server has tight memory headroom (as little as ~140Mi free observed under load) — Docker stack must be brought up deliberately (not left running continuously) and torn down after each session's verification pass.
- Node.js 18 on the host is past standard LTS support; left untouched since upgrading risks breaking other tenants' services.

**Git Commit:** `5c0a6de` — `feat(infra): scaffold Laravel backend foundation and validate development environment`

**Next Task:** Authentication Foundation (register/login/logout)
