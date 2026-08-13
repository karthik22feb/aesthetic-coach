# Development Log

**The engineering journal for Aesthetic Coach.** Unlike [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md) (which always shows *current* state) and [NEXT_TASK.md](NEXT_TASK.md) (which always shows the *next* single task), this document is an **append-only history** of what actually happened, session by session — the record you'd read to answer "what did we do on [date]" or "when did we implement X."

---

## Current Status

**Phase 1 · Sprint 1 in progress.** The entire backend Authentication module (register/login/logout, refresh-token rotation, session/device management, Google/Apple Sign-In, email verification, password reset) is merged to `main`, tagged `v1.0.0-auth-complete`. The Flutter mobile foundation (project scaffold, Riverpod/go_router skeleton, 5-tab shell, mobile CI — Tasks 5–7) is implemented and verified on `feature/flutter-foundation`, pending merge. Next: merge that branch, then Login/Signup screens (Task 17).

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

### 2026-08-13 — Sprint 1 · Flutter Mobile Foundation (Tasks 5–7)

**Sprint:** Phase 1 · Sprint 1
**Task ID:** Sprint 1, Tasks 5–7 (Flutter project scaffold, Riverpod/go_router skeleton, mobile CI)
**Objective:** Implement the Flutter mobile foundation that Task 17 (Login/Signup) depends on — `mobile/` did not exist at the start of this session. Explicitly out of scope: any authentication UI, business logic, or Phase 2 work.

**Files Changed:**
- `mobile/` — new Flutter project (`flutter create`, org `com.aestheticcoach`, android+ios platforms only), folder structure per [Mobile Architecture § 2](docs/08-mobile-architecture.md#2-folder-organization): `lib/{app,core,features,shared}`, `test/{unit,widget,integration}`
- `mobile/lib/app/{app.dart,router.dart,app_shell.dart,theme/app_theme.dart}` — `ProviderScope` root, `MaterialApp.router`, `StatefulShellRoute.indexedStack` with 5 branches (Home/Train/Coach/Nutrition/Progress per [UI/UX Design System § 4](docs/06-ui-ux-design-system.md#4-navigation)), `NavigationBar` shell, placeholder Material 3 theme
- `mobile/lib/features/{home,workouts,coach,nutrition,progress}/presentation/*_screen.dart` — 5 placeholder screens, presentation-layer only, each with a keyed content widget for test targeting
- `mobile/lib/core/{network,storage,sync,error,di}/`, `mobile/lib/shared/{widgets,utils}/` — empty (`.gitkeep`) per architecture, intentionally unpopulated this session
- `mobile/test/unit/app_theme_test.dart`, `mobile/test/widget/app_shell_test.dart` — 3 + 3 tests
- `.github/workflows/mobile-ci.yml` — new; analyze/format-check/test job, path-filtered to `mobile/**`, triggers on PR to `main` and push to `main`
- `mobile/pubspec.yaml` — added `flutter_riverpod`, `go_router`

**Database Changes:**
- None.

**API Changes:**
- None.

**Flutter Changes:**
- See Files Changed — this session *is* the first Flutter work in the repo.

**Tests Executed:**
- `flutter analyze`: 0 issues (1 unused-import issue found and fixed mid-session).
- `dart format --output=none --set-exit-if-changed .`: clean (8 files needed reformatting initially, fixed).
- `flutter test`: 6 passed (3 unit, 3 widget).
- Mobile CI negative test: pushed an intentional `dart format` violation, confirmed the GitHub Actions run failed on the format-check step, reverted it, confirmed a subsequent run passed. Verified via the public Actions run list and status badge (no `gh`/API credentials available in this environment).
- Not executed: `flutter run`/`flutter build` (no Android SDK, no Chrome, no Linux desktop build toolchain on the dev server; installing the ~31-package LLVM/clang toolchain was judged unnecessary resource use on a memory-constrained shared server and skipped — `flutter analyze` + `flutter test` don't require it).

**Known Issues:**
- True build/run verification of the Flutter app has never been performed in this environment — flagged in `NEXT_TASK.md` for whoever picks up Task 17+, in case an on-device/emulator check becomes necessary.
- The Flutter SDK's snap installation requires `HOME=/var/flutter-home` on every invocation on this specific dev server, because the real `$HOME` (`/home/administrator`) sits on a partition that is at 100% capacity — unrelated to this project, caused by other tenants' data on the shared box. See `ENGINEERING_DECISION_LOG.md` for the full diagnosis.
- Module 2 (Authentication)'s own Definition of Done still requires Tasks 17–20 (Login/Signup, `AuthInterceptor`, secure token storage, staging E2E) — none of those were started this session, per explicit scope.

**Git Commit:** `0939ad6` (scaffold+CI), `1edf2cf`/`10788ea` (CI negative-test verification + revert), `d6d8b40` (CI trigger narrowed back to documented spec) — all on `feature/flutter-foundation`, not yet merged

**Next Task:** Review and merge `feature/flutter-foundation`, then Flutter Login/Signup screens (Sprint 1, Task 17).

### 2026-08-13 — Sprint 1 · Authentication Milestone Finalization (OAuth + Email Verification/Password Reset merge)

**Sprint:** Phase 1 · Sprint 1
**Task ID:** Sprint 1, Tasks 9–16 (completes the full backend Authentication scope)
**Objective:** Independently review, merge, and finalize the two pending authentication PRs (`feature/auth-oauth`, `feature/email-verification-password-reset`), verify the merged result end to end, and tag the completed backend Authentication milestone.

**Files Changed:**
- No new application code this session — both branches were independently re-reviewed (diff inspection, fresh test runs, secret/logging greps, live re-reads of the security-critical OAuth verifier and account-linking code) and merged as-is; no defects were found requiring a fix.
- Conflict resolution touched `ENGINEERING_DECISION_LOG.md`, `AuthServiceProvider.php`, `AuthController.php`, `AuthService.php`, `routes.php` — in every case the conflicts were import-ordering or doc-comment prose only; every method/route/listener from both branches was already present and non-duplicated after Git's automatic merge, confirmed by manual inspection of each resolved file before staging.

**Database Changes:**
- None new this session. Post-merge, all 8 auth-related migrations verified present and in correct order (`users`, `cache`, `jobs`, `devices`, `auth_refresh_tokens`, `oauth_identities`, `password_reset_tokens` [corrected shape], `email_verification_tokens`). Schema dump confirmed every FK, unique index, and nullable/non-nullable field matches the frozen Database Design spec (except `email_verification_tokens`, which has none — see the 2026-08-13 Task 14 entry). `migrate → rollback --step=3 → migrate` verified clean on the merged `main`.

**API Changes:**
- None new this session — merges `POST /auth/oauth/google`, `POST /auth/oauth/apple` (from `feature/auth-oauth`) and `POST /auth/password/forgot`, `POST /auth/password/reset`, `POST /auth/email/verify`, `POST /auth/email/resend` (from `feature/email-verification-password-reset`) into `main` alongside the already-merged register/login/logout/refresh/sessions endpoints. 12 auth endpoints total, confirmed via `route:list`.

**Flutter Changes:**
- None. Confirmed the `mobile/` directory is still empty — Flutter work has not started.

**Tests Executed:**
- Pest Feature tests (real MySQL): **130 passed, 472 assertions** on the merged `main` (67 shared baseline + 28 OAuth + 35 email/password — reconciled arithmetically against both branches' independently-reported counts, no unexplained loss). Pint: 102 files, clean. `composer validate --strict`: clean.
- Full live smoke test against the running app + real Mailhog + real Redis queue: register → verification email delivered and consumed (`emailVerified` flips true) → login → protected endpoint → refresh → logout → refresh-after-logout rejected (`session_revoked`); forgot-password → reset email delivered and consumed → old password rejected, new password accepted → confirmed a completely untouched session from *before* the reset was also revoked (cross-device revocation, not just the current one); login from two devices → list sessions (both visible, `isCurrent` correct) → revoke one → its refresh token rejected; OAuth endpoints confirmed fail-closed against bogus tokens (no real Google/Apple credentials available, so the 28 already-passing Pest tests — including 9 against real RSA cryptography with a locally generated keypair standing in for the provider — are the primary correctness evidence per this session's own "established test/mocked-provider strategy" instruction); rate limiting live-confirmed (10 requests succeed, 11th returns `429 rate_limited` with the standard envelope).

**Known Issues:**
- Unchanged from prior sessions: BR-5 (max 10 concurrent device sessions) still unenforced by register/login/oauth. FR-104's API contract remains undocumented in the frozen docs (implementation shipped per explicit user approval — see the 2026-08-13 Task 14 `ENGINEERING_DECISION_LOG.md` entry; reconcile if the docs are ever updated).
- Module 2 (Authentication) is **not** fully "Complete" in `IMPLEMENTATION_PROGRESS.md`/`MASTER_IMPLEMENTATION_PLAN.md` module-tracker sense despite the backend being finished — `IMPLEMENTATION_ORDER.md` § 2's own Definition of Done requires the Flutter login/signup screens and a staging E2E test too (Tasks 17–20). Flagged explicitly rather than prematurely marking the module row Complete.

**Git Commit:** `1daa0b1` (OAuth squash-merge), `0bdf52f` (email verification/password reset squash-merge), both on `main`

**Next Task:** Flutter: create the project + Riverpod/go_router scaffold (Sprint 1, Tasks 5–6), then Login/Signup screens (Task 17). No Flutter/Phase 2 work was started this session, per explicit instruction.

### 2026-08-13 — Sprint 1 · Email Verification & Password Reset (Task 14)

**Sprint:** Phase 1 · Sprint 1
**Task ID:** Sprint 1, Task 14 (Email verification + password reset endpoints)
**Objective:** Implement FR-104 (email verification) and FR-105 (password reset) completely and securely, per frozen documentation where it exists.

**Files Changed:**
- `backend/database/migrations/2026_08_13_043803_modify_password_reset_tokens_table.php` — new; corrects `password_reset_tokens` from Laravel's unmodified default shape to the frozen spec (`token_hash` CHAR(64), `expires_at`, `email` VARCHAR(190))
- `backend/database/migrations/2026_08_13_043805_create_email_verification_tokens_table.php` — new; mirrors `password_reset_tokens` exactly
- `backend/app/Modules/Auth/Models/{PasswordResetToken,EmailVerificationToken}.php` — new
- `backend/app/Modules/Auth/Exceptions/{InvalidPasswordResetTokenException,InvalidEmailVerificationTokenException}.php` — new
- `backend/app/Modules/Auth/Http/Requests/{ForgotPasswordRequest,ResetPasswordRequest,VerifyEmailRequest}.php` — new
- `backend/app/Modules/Auth/Mail/{PasswordResetMail,EmailVerificationMail}.php` + Blade views — new
- `backend/app/Modules/Auth/Listeners/SendVerificationEmail.php` — new; wires `UserRegistered` → verification email, closing a gap flagged in that event's own docblock since the Authentication Foundation session
- `backend/app/Modules/Auth/Services/AuthService.php` — `forgotPassword()`, `resetPassword()`, `sendVerificationEmail()`, `verifyEmail()`
- `backend/app/Modules/Auth/Http/Controllers/AuthController.php`, `routes.php`, `AuthServiceProvider.php` — new endpoints + listener registration
- `backend/tests/Feature/Auth/{PasswordResetTest,EmailVerificationTest}.php` — new, 34 tests

**Database Changes:**
- `password_reset_tokens` corrected to match Database Design § 3.1 (was previously Laravel's default shape — a known, previously-flagged inconsistency, never fixed because the feature didn't exist until now)
- New: `email_verification_tokens` (no frozen table spec exists for this — see Known Issues)

**API Changes:**
- `POST /auth/password/forgot`, `POST /auth/password/reset` (FR-105, fully per frozen spec)
- `POST /auth/email/verify`, `POST /auth/email/resend` (FR-104 — endpoint contract invented this session, see Known Issues)

**Flutter Changes:**
- None

**Tests Executed:**
- Pest Feature tests (real MySQL): 102 passed (68 prior baseline on this branch + 34 new) — see this session's own report for the exact command and full breakdown. Pint: 84 files, clean. `composer validate --strict`: clean.
- Live smoke test: real register → verification email delivered via Mailhog → forgot-password → reset email delivered via Mailhog → token consumed → login with new password succeeded.

**Known Issues:**
- **FR-104 (email verification) has no documented API contract anywhere** in the frozen documentation (checked API Specification, Authentication feature, API Examples, Database Design, Mobile Architecture — all consistently silent). Resolved this session, with the user's explicit approval, by mirroring the fully-specified FR-105 (password reset) pattern exactly: same token shape, same 60-minute TTL, same single-use/hashed-storage model. See `ENGINEERING_DECISION_LOG.md` for the full reasoning and the exact endpoints built. If this gap is ever formally closed in the frozen docs, reconcile against what was actually shipped.
- A successful password reset revokes all of the user's active sessions across every device — not explicitly mandated by any frozen document, inferred from BR-3's existing precedent (any suspected-compromise signal revokes the affected session(s)). Documented as an engineering decision, not silently assumed.
- BR-5 (max 10 concurrent device sessions) remains unenforced by register/login/oauth — unchanged, still out of scope, flagged again for whenever it's picked up.

**Git Commit:** `<pending — see this session's own report>` on `feature/email-verification-password-reset`, branched from `main` (does not include the still-unmerged `feature/auth-oauth`)

**Next Task:** Review and merge both `feature/auth-oauth` and `feature/email-verification-password-reset`, then Flutter Login/Signup screens (Sprint 1, Task 17).

### 2026-08-11 — Sprint 1 · Session Management PR Review & Merge

**Sprint:** Phase 1 · Sprint 1
**Task ID:** Sprint 1, Task 15 (Session/Device Management)
**Objective:** Independently re-review the previously-implemented `feature/auth-session-management` branch against frozen documentation, run its security review, merge it to `main`, and tag the milestone.

**Files Changed:**
- `backend/bootstrap/app.php` — added a `NotFoundHttpException` render handler
- `backend/tests/Feature/Auth/SessionTest.php` — 2 regression tests added (malformed `deviceId` envelope, revoke-after-rotation)
- Session management source files (`SessionController`, `SessionResource`, `SessionNotFoundException`, `AuthService::listSessions/revokeSession`, `TokenService`/`AuthServiceProvider` `did` claim) — implemented in the prior session, independently re-verified this session, no further changes needed

**Database Changes:**
- None — the existing `devices`/`auth_refresh_tokens` schema fully supported session management.

**API Changes:**
- `GET /auth/sessions`, `DELETE /auth/sessions/{deviceId}` (merged to `main` this session)

**Flutter Changes:**
- None

**Tests Executed:**
- Pest Feature tests (real MySQL): 67 passing (17 in `SessionTest.php`), Pint clean (70 files), `composer validate --strict` clean, both pre-merge (on the feature branch) and post-merge (on `main`).

**Known Issues:**
- Independent review found a genuine gap: `DELETE /auth/sessions/{deviceId}` with a non-numeric `deviceId` (e.g. `abc`) fell through Laravel's routing layer as an unmatched route (`whereNumber()` constraint), bypassing every existing `AppException`-based handler and returning Laravel's raw exception JSON — including a full stack trace under `APP_DEBUG=true`. Fixed by adding a `NotFoundHttpException` render handler in `bootstrap/app.php`, mapped to the standard `404 not_found` envelope. This is a general fix (covers any unmatched API route), not session-management-specific, but was only surfaced because this PR was the first to add a constrained route parameter.
- BR-5 (max 10 concurrent device sessions, oldest auto-revoked) is still not enforced by register/login — flagged again, unchanged from the prior session, out of scope for both this and the OAuth work that follows.

**Git Commit:** `5401b1f` — `feat(auth): implement session/device listing and revocation` (squash-merge of `feature/auth-session-management`)

**Next Task:** OAuth foundation — Google + Apple Sign-In (`POST /auth/oauth/google`, `POST /auth/oauth/apple`), per [TASK_BREAKDOWN.md § Sprint 1, Tasks 12–13](docs/TASK_BREAKDOWN.md).

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
