# Development Log

**The engineering journal for Aesthetic Coach.** Unlike [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md) (which always shows *current* state) and [NEXT_TASK.md](NEXT_TASK.md) (which always shows the *next* single task), this document is an **append-only history** of what actually happened, session by session — the record you'd read to answer "what did we do on [date]" or "when did we implement X."

---

## Current Status

**Phase 1 · Sprint 1 in progress.** The entire backend Authentication module (register/login/logout, refresh-token rotation, session/device management, Google/Apple Sign-In, email verification, password reset) is merged to `main`, tagged `v1.0.0-auth-complete`. The Flutter mobile foundation (project scaffold, Riverpod/go_router skeleton, 5-tab shell, mobile CI — Tasks 5–7) is merged to `main` (squash-merge of [PR #1](https://github.com/karthik22feb/aesthetic-coach/pull/1), commit `38f1da6`). The Flutter auth client (Login/Signup screens, Dio `AuthInterceptor`, secure token storage — Tasks 17–19) is now also merged to `main` (squash-merge of [PR #2](https://github.com/karthik22feb/aesthetic-coach/pull/2), commit `f7a2580`), locally re-verified (65/65 tests) but not yet checked against a live backend or real device. Next: Task 20 (staging E2E test). Separately, **Sprint 2 · Task 1** (`GET/PATCH /me` profile endpoint) is merged to `main` (squash-merge of [PR #4](https://github.com/karthik22feb/aesthetic-coach/pull/4), commit `5f7f706`), re-verified post-merge (144/144 Pest tests, Pint clean) — backend/local verification only, not staging or real-device verified. **Sprint 2 · Task 2** (Flutter Profile screen + Edit Profile sheet) is also merged to `main` (squash-merge of [PR #5](https://github.com/karthik22feb/aesthetic-coach/pull/5), commit `cc2385f`), re-verified post-merge (90/90 tests, `flutter analyze`/`dart format` clean, release APK build SUCCESS) — Flutter-test verification only, not staging or real-device verified. **Module 3 (User Profile) is now Complete.** **Sprint 2 · Task 3** (basic Settings screen: theme, unit preference) is also merged to `main` (squash-merge of [PR #6](https://github.com/karthik22feb/aesthetic-coach/pull/6), commit `450442b`), re-verified post-merge (102/102 tests, `flutter analyze`/`dart format` clean, release APK build SUCCESS) — Flutter-test verification only, not staging or real-device verified. None of these three tasks changes Task 20's blocked status. Separately, this project's **first real Android device/emulator testing** (on a local Windows dev machine, not the Linux server, which has no KVM) found and fixed a genuine client-side URL-construction bug: `ApiConfig.baseUrl` lacking a trailing slash caused Dio to silently concatenate relative paths into malformed URLs (e.g. `/api/v1auth/register` instead of `/api/v1/auth/register`), surfacing as a misleading "Unable to reach the server" error on every API call. Fixed and merged to `main` (squash-merge of [PR #7](https://github.com/karthik22feb/aesthetic-coach/pull/7), commit `11da8ea`), re-verified post-merge (104/104 tests, `flutter analyze`/`dart format` clean, release APK build SUCCESS) and confirmed against the real emulator + local Laravel backend (register/login/`GET /me` all now hit the correct paths). This does not touch Task 20 or staging/real-device *E2E* verification, which remain separately BLOCKED/not started. Separately, **Sprint 2 · Task 4** (`goals` table migration + Eloquent model) is merged to `main` (squash-merge of [PR #8](https://github.com/karthik22feb/aesthetic-coach/pull/8), commit `7c5d12e`), approved by two independent reviewers distinct from the author (the migration-touching review requirement) and re-verified post-merge (`composer validate --strict` clean, Pint clean, a direct Tinker database round-trip against the real local MySQL instance confirmed) — the full Pest suite remains **not verified locally**, blocked by a pre-existing Docker-Compose `mysql`-hostname requirement in `phpunit.xml` that this bare-Windows environment doesn't satisfy (confirmed unrelated to this change: it reproduces identically on unrelated pre-existing tests). Task 4 provides only the migration/model layer; the `POST /goals` endpoint remains Sprint 4 scope, so **Module 4 (AI Onboarding) moves to In Progress**, not Complete. Does not touch or unblock Task 20.

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

### 2026-08-28 — Sprint 2 Task 4: `goals` table migration and model

**Sprint:** Phase 1 · Sprint 2 — User Profile & AI Onboarding
**Task ID:** Sprint 2, Task 4
**Objective:** Add the `goals` table migration and Eloquent model per [Database Design § 3.5](docs/04-database-design.md#35-habits--goals), providing the persistence layer Module 4 (AI Onboarding) needs to seed a goal row during onboarding. Scoped narrowly to migration + model (the full `GET/POST/PATCH/DELETE /goals` CRUD API is Sprint 4 scope per [Goals feature](docs/features/goals.md#release-phase)).

**Files Changed:**
- `backend/database/migrations/2026_08_28_090000_create_goals_table.php` — new `goals` table
- `backend/app/Modules/Goals/Models/Goal.php` — new Eloquent model, `user()` relation
- `backend/app/Modules/Goals/Enums/{GoalType,GoalStatus}.php` — new backed enums
- `backend/database/factories/GoalFactory.php` — new factory
- `backend/app/Modules/Auth/Models/User.php` — added `goals()` inverse relation and a `newFactory()` override
- `backend/database/factories/UserFactory.php` — added an explicit `$model` property

**Database Changes:**
- New migration `2026_08_28_090000_create_goals_table.php`: `goals` table (`id`, `user_id` FK cascade-on-delete, `type` enum, `title`, `target_metric`, `target_value`, `target_date`, `status` enum default `active`, `created_at`)

**API Changes:**
- None — the `POST /goals` endpoint is explicitly deferred to Sprint 4

**Flutter Changes:**
- None

**Tests Executed:**
- `composer validate --strict`: PASS
- Laravel Pint (`--test`): PASS
- Direct database round-trip via Tinker (create `User`+`Goal` against the real local MySQL 9 instance, verify enum casts, `user()`/`goals()` relations, `created_at` cast, delete): PASS — run both pre-merge and again post-merge on `main`
- Full Pest suite: **NOT VERIFIED**. This bare-Windows local environment has no Docker-Compose `mysql` hostname, which `phpunit.xml` forces via `force="true"` on `DB_HOST=mysql`/`DB_PORT=3306`. Confirmed as a pre-existing, unrelated environment limitation, not a Task 4 regression: reproduces identically on `CorsTest` (0/4 passing, identical `getaddrinfo for mysql failed` error) before and after this change. This repository also has no backend CI workflow yet (`.github/workflows/` only contains `mobile-ci.yml`), so this suite has not been exercised in any other environment either.

**Known Issues:**
- Full Pest verification remains blocked pending either a Docker-capable environment or a deliberate, separately-authorized change to how the test DB connection is resolved locally (a hosts-file alias or an `.env.testing` override) — not attempted here since both require system-level changes beyond this task's scope.
- Module 4 (AI Onboarding) is now In Progress, not Complete — Tasks 5–7, 10, 11 (onboarding screens, "Meet Your Coach" step, notification permission prompt, widget/integration tests) remain unstarted.
- Does not touch or unblock Task 20, which remains BLOCKED.

**Git Commit:** `7c5d12e` — `feat(backend): add goals table migration and model (#8)` (squash-merge of PR #8). Approved by two independent reviewers (`shashwanth22dec`, `karthikatacr`) distinct from the author before merge, per the migration-touching review requirement in [git-workflow.md](docs/git-workflow.md).

**Next Task:** Not updated — [NEXT_TASK.md](NEXT_TASK.md) still points at Task 20 per its own documented update rule (only replaced once Task 20 itself lands).

### 2026-08-28 — First real Android device/emulator testing; Dio base-URL bug found and fixed

**Sprint:** N/A — environment setup and bug-fix session, not a `TASK_BREAKDOWN.md` item
**Task ID:** N/A
**Objective:** Establish real interactive Android testing on a local Windows development machine (the Linux server has no KVM and cannot run an Android emulator), run the existing app's Login → Home → Profile → Settings flow for real for the first time, and fix whatever genuine bugs that surfaced.

**Environment setup (Windows, not the Linux server):**
- Local project checkout, Flutter SDK, Android SDK/cmdline-tools/platform-36/build-tools, a JDK 17, and an Android 33 emulator AVD (`aesthetic_test`) all installed to `D:\dev\` after discovering the system drive (`C:`) had 0 bytes free — an additional Windows page file was also added on `D:` (with explicit user approval, via UAC) after the first Gradle build hit a native OOM crash caused by the page file being stuck on the full `C:` drive.
- Local backend: XAMPP's bundled MariaDB was found incompatible with a migration that assumes real MySQL 8 timestamp-default behavior (`SQLSTATE[42000]: Invalid default value for 'expires_at'`) — resolved by installing a standalone MySQL 9.4.0 instance on a separate port (3307) rather than touching the shared XAMPP MariaDB instance (which serves several unrelated projects on that machine) or the migration itself. PHP 8.3 was also installed standalone (XAMPP's bundled PHP was 8.2, below Laravel 13's `^8.3` requirement).
- `php artisan serve` bound to `0.0.0.0:8080` (port 8000 was already occupied by an unrelated Splunk instance on that machine). The emulator reaches it via Android's standard `10.0.2.2` host alias — the Wi-Fi network here is Windows-classified `Public` (an institutional network), so no firewall port was opened and the backend was never exposed to the LAN.

**Bug found:** `ApiConfig.baseUrl` (`mobile/lib/core/network/api_config.dart`) had no trailing slash, and every relative Dio request path (`auth/register`, `auth/login`, `me`, etc.) had no leading slash. Dio 5.11.0 concatenates these with no separator (confirmed by reading `package:dio/src/options.dart` directly), silently producing malformed URLs like `/api/v1auth/register`. No existing test caught it because every unit/widget test injects a fake API client that bypasses Dio's real URL construction — this was the first time the real Flutter client ever made a real network call to the real backend.

**Files Changed:**
- `mobile/lib/core/network/api_config.dart` — `baseUrl` changed from a `static const` to a computed getter guaranteeing exactly one trailing slash (no double slash if the supplied value already has one)
- `mobile/test/unit/api_config_test.dart` — new regression test covering the normalization

**Tests Executed:**
- `flutter analyze`: 0 issues; `dart format`: clean; `flutter test`: 104/104 passing (102 existing + 2 new)
- Real Android emulator (`emulator-5554`, Android 13/API 33) via `adb` UI automation: signup, login, and `GET /me` (Profile screen) all verified against the real local Laravel backend, confirmed via the server's own request log showing the correct `/api/v1/auth/register`, `/api/v1/auth/login`, and `/api/v1/me` paths with no timeouts (previously ~15s hangs ending in a misleading "Unable to reach the server" error)
- Release APK build: SUCCESS both before and after merge (51.6–54.1MB), no OOM (confirmed via `dmesg`-equivalent checks and the absence of any JVM crash log, unlike the pre-page-file-fix attempt)

**Known Issues:**
- This is local Windows-emulator verification only — not staging, not a physical device, not iOS. Task 20 (staging E2E) was not touched and remains BLOCKED.
- The local Windows git identity (`Mahalakshmi <mahalakshmi@acr.iitm.ac.in>`) differs from the `karthik22feb`/"ACR Developer" identity used on the Linux server for the rest of this project; PR #7's commit carries that author. Local repo config on the Windows checkout was updated afterward (see this session's git-identity change) so future commits from this machine use the intended identity.

**Git Commit:** `11da8ea` — `fix(mobile): normalize API base URL (#7)` (squash-merge of PR #7). Approved by an independent reviewer (`shashwanth22dec`) distinct from the author before merge.

**Next Task:** Task 20 (staging E2E test, Module 2) remains the primary blocked item — see [NEXT_TASK.md](NEXT_TASK.md). No Sprint/module status changed by this session.

### 2026-08-28 — Sprint 2 · Settings screen merge (Task 3)

**Sprint:** Phase 1 · Sprint 2
**Task ID:** Sprint 2, Task 3 — basic Settings screen (theme, unit preference)
**Objective:** Implement the next genuinely unblocked Sprint 2 task after Task 1/2, following the same discover-roadmap → implement → test → PR → review-gate → merge cycle.

**Files Changed:**
- `mobile/lib/core/storage/theme_storage.dart` — thin `SharedPreferences` wrapper for the theme choice; genuinely local-only, unlike unit preference (no server column for theme exists)
- `mobile/lib/core/di/settings_providers.dart` — `themeStorageProvider`, matching the `network_providers.dart`/`profile_providers.dart` DI pattern
- `mobile/lib/features/settings/application/theme_mode_notifier.dart` — `Notifier<ThemeMode>`, restores the persisted choice on `build()` (same fire-and-forget pattern as `AuthNotifier`/`ProfileNotifier`)
- `mobile/lib/features/settings/presentation/settings_screen.dart` — theme `SegmentedButton` (local, instant) and a unit-preference `SegmentedButton` that reads/writes `profileNotifierProvider` directly via a partial `PATCH /me` (`{"unitPreference": ...}`), rather than a second, divergent local copy of that value
- `mobile/lib/app/app.dart` — `MaterialApp.router`'s `themeMode` now reads `themeModeProvider` instead of the previous hardcoded `ThemeMode.system`
- `mobile/lib/app/router.dart` — new top-level `/settings` route, covered by the existing auth redirect guard
- `mobile/lib/features/profile/presentation/profile_screen.dart` — added the gear-icon AppBar action documented in `docs/screens/profile.md`'s navigation diagram ("Profile -->|gear icon| Settings"), previously deferred pending this task
- `mobile/pubspec.yaml`/`pubspec.lock` — added `shared_preferences` (via `flutter pub add`), the one new dependency this task strictly required for genuine theme persistence
- `mobile/test/unit/theme_mode_notifier_test.dart`, `mobile/test/widget/settings_screen_test.dart` — 12 new tests
- `docs/features/settings.md`, `docs/screens/settings.md` — corrected a stale Business Rules/Offline Behavior sentence describing unit preference as device-local; that was accurate before Sprint 2 Task 1/2 shipped it server-backed. Fixed in this PR per the project's own Change Management Process for gaps found during implementation. Theme remains correctly described as local-only.

**Database Changes:**
- None (mobile only; unit preference already had a working `users.unit_preference` column and endpoint from Task 1)

**API Changes:**
- None (consumes the existing `PATCH /me`, sending only `{"unitPreference": ...}`)

**Flutter Changes:**
- New Settings screen, reachable via a gear icon on the Profile screen's AppBar

**Tests Executed:**
- `flutter analyze`: 0 issues
- `dart format --set-exit-if-changed .`: clean
- `flutter test`: 102/102 passing (90 existing + 12 new), re-run on the feature branch and again on merged `main`
- `flutter build apk --release`: SUCCESS both pre- and post-merge, 54.1MB; the pre-merge build (first time compiling the new `shared_preferences_android` native plugin) peaked at ~3.8GB of 3.9GB total RAM with heavy swap use — tighter than any prior build on this server, though still 0 OOM-killer events (verified via `dmesg`); the post-merge rebuild reused Gradle's build cache and peaked at a comfortable ~2.7GB

**Known Issues:**
- No staging or real-device/emulator verification — this dev server has no KVM/usable Android emulator.
- Deliberately deferred, not bugs: notification preferences, Devices & Sessions UI, data export, account deletion, and a logout button are all out of this task's scope, per `docs/features/settings.md`'s own Release Phase split (basic: Sprint 2; finalized: Sprint 6). Devices & Sessions and logout already have working backends (Sprint 1) but no UI yet.
- Worth watching: the first build after adding `shared_preferences` pushed memory usage right to the edge of this server's capacity. Future dependency additions should be watched closely for the same effect.

**Git Commit:** `450442b` — `feat(settings): add basic Settings screen (theme, unit preference) (#6)` (squash-merge of PR #6). Approved by an independent reviewer (`shashwanth22dec`) distinct from the author before merge.

**Next Task:** Task 20 (staging E2E test, Module 2) remains the primary blocked item — see [NEXT_TASK.md](NEXT_TASK.md). Sprint 2 candidates once picking further ahead-of-sequence work: Task 4 (`goals` table migration, no dependencies) and Task 9 (Pest tests: profile update + onboarding goal creation).

### 2026-08-27 — Sprint 2 · Flutter Profile screen merge (Task 2) — Module 3 Complete

**Sprint:** Phase 1 · Sprint 2
**Task ID:** Sprint 2, Task 2 — Flutter Profile screen (view + Edit Profile bottom sheet)
**Objective:** Implement the Profile screen against the merged `GET/PATCH /me` backend endpoint, review it, and take it through the repository's normal review-and-merge process into `main`.

**Files Changed:**
- `mobile/lib/features/profile/data/models/{profile_enums,user_profile}.dart` — client-side model mirroring `ProfileResource` exactly, with `UnitPreference`/`BiologicalSex` enums whose `.name` matches the backend's wire values
- `mobile/lib/features/profile/data/{profile_api,profile_repository}.dart` — `GET/PATCH /me` calls on the shared `dioProvider` (so `AuthInterceptor` applies automatically) and `Failure` mapping, mirroring `AuthApi`/`AuthRepository`'s established pattern
- `mobile/lib/features/profile/application/{profile_state,profile_notifier}.dart` — load/update state management; `updateProfile()` rethrows `Failure` rather than absorbing it into screen state, so edit failures surface inline in the Edit Profile sheet without disturbing the screen behind it
- `mobile/lib/features/profile/presentation/profile_screen.dart` — view screen (avatar/initials, name, read-only email, six editable fields); edit trigger is an AppBar icon rather than a button at the end of the scrollable list, after widget tests caught the list's lazy sliver not building an end-of-list button within the default test viewport
- `mobile/lib/features/profile/presentation/edit_profile_sheet.dart` — bottom sheet covering all seven PATCH-able fields (`SegmentedButton` for unit preference, dropdown for sex, a date picker capped at 18+ years to match the backend rule, a chip editor for dietary restrictions); always submits the full field set rather than a diff, since the sheet is always initialized from the current profile
- `mobile/lib/core/di/profile_providers.dart` — DI wiring, built on the existing `dioProvider`
- `mobile/lib/app/router.dart` — new top-level `/profile` route, already covered by the existing auth redirect guard
- `mobile/lib/features/home/presentation/home_screen.dart` — AppBar profile icon as the navigation entry point (Profile isn't one of the 5 fixed bottom-nav tabs)
- `mobile/test/unit/{profile_repository,profile_notifier}_test.dart`, `mobile/test/widget/profile_screen_test.dart` — 25 new tests

**Database Changes:**
- None (mobile only)

**API Changes:**
- None (consumes the existing `GET/PATCH /me` from PR #4; no backend changes)

**Flutter Changes:**
- New Profile screen + Edit Profile bottom sheet, reachable via a profile icon on the Home tab's AppBar

**Tests Executed:**
- `flutter analyze`: 0 issues
- `dart format --set-exit-if-changed .`: clean
- `flutter test`: 90/90 passing (65 existing + 25 new), re-run on the feature branch and again on merged `main`
- `flutter build apk --release`: SUCCESS, 53.7MB, using PR #3's OOM-safe Gradle config (`-Xmx1536m`, daemon/parallel disabled); memory sampled every 3s throughout, peak ~2.9GB used, 0 OOM-killer events in `dmesg`; APK independently verified as a genuine Android package (`file`, `unzip -l` showing `AndroidManifest.xml`, `classes.dex`, native libs for 3 ABIs)

**Known Issues:**
- No staging or real-device/emulator verification — local Docker (backend) and this dev server's Flutter toolchain (mobile) only.
- Deliberately deferred, not bugs: the feature doc's summary-stats row (workouts/streaks) and Body Measurements/Progress Photos entry points (F-PROF-02/F-PROF-03) depend on modules that don't exist yet (Workout Engine, Habits, Body Measurements, Progress Photos). The Settings gear icon is deferred to Sprint 2 Task 3.
- The commit (`fbb51f6`) was originally made directly on local `main` before PR #3 was merged; to submit it through a normal PR without amending it, it was cherry-picked (unchanged content, new hash `21d65b7`) onto `feature/flutter-profile-screen` branched from `origin/main`. `fbb51f6` itself was never rewritten.

**Git Commit:** `cc2385f` — `feat(profile): add Flutter Profile screen (view + Edit Profile sheet) (#5)` (squash-merge of PR #5, cherry-picked from `fbb51f6`). Approved by an independent reviewer (`shashwanth22dec`) distinct from the author before merge.

**Next Task:** Task 20 (staging E2E test, Module 2) remains the primary blocked item — see [NEXT_TASK.md](NEXT_TASK.md). Module 3 (User Profile) is now Complete; the next Sprint 2 candidates are Task 3 (basic Settings screen) and Task 9 (Pest tests: profile update + onboarding goal creation).

### 2026-08-27 — Sprint 2 · User Profile endpoint merge (Task 1)

**Sprint:** Phase 1 · Sprint 2
**Task ID:** Sprint 2, Task 1 — `GET/PATCH /me` endpoint + Form Request validation
**Objective:** Implement the profile view/update endpoint, review it, fix the findings, and take it through the repository's normal review-and-merge process into `main`.

**Files Changed:**
- `backend/app/Modules/Auth/Enums/{UnitPreference,Sex}.php` — new backed enums for the two profile fields that aren't free text
- `backend/app/Modules/Auth/Dtos/UpdateProfileDto.php` — partial-update DTO (column-mapped, sparse array, to distinguish "field omitted" from "field explicitly set to null")
- `backend/app/Modules/Auth/Http/Requests/UpdateProfileRequest.php` — `sometimes`-rule PATCH validation; a post-review fix added `'filled'` to `name` so an explicit empty string is rejected
- `backend/app/Modules/Auth/Http/Resources/ProfileResource.php` — flat response shape matching `docs/api-examples/users-profile.md` exactly
- `backend/app/Modules/Auth/Services/ProfileService.php`, `Http/Controllers/ProfileController.php` — update/fetch logic; `$request->user()` only ever resolves the caller's own account, so no user-ID input surface exists (IDOR structurally impossible)
- `backend/app/Modules/Auth/Models/User.php` — extended `#[Fillable]`/casts for the six new columns; also fixed a latent bug where `AuthServiceProvider`'s JWT guard callback set `currentDeviceId` as an undeclared dynamic property, which Eloquent's `__set()` silently tracked as an attribute — the first `save()` call from `ProfileService` then tried to persist a nonexistent column. Fixed by declaring it as a real typed property.
- `backend/app/Modules/Auth/routes.php` — new `GET/PATCH /me` route group on the general `throttle:api` limiter (120/min), not the 10/min `throttle:auth` limiter
- `backend/app/Providers/AppServiceProvider.php` — registered the general `api` rate limiter (previously empty `boot()`)
- `backend/tests/Feature/Auth/ProfileTest.php` — 14 tests; two added post-review (explicit null-clearing, empty-name rejection)

**Database Changes:**
- New migration `2026_08_19_120000_add_profile_fields_to_users_table.php` — additive only, adds `timezone`, `unit_preference`, `date_of_birth`, `sex`, `height_cm`, `dietary_restrictions` to `users`; `down()` drops all six

**API Changes:**
- `GET /me`, `PATCH /me` — both new, both behind `auth:api` + `throttle:api`. `DELETE /me` and `POST /me/export` (also in the API examples doc) are explicitly out of scope for this task.

**Flutter Changes:**
- None (backend only)

**Tests Executed:**
- Pest Feature tests: 144/144 passing (543 assertions), re-run post-merge on `main` and matching the pre-merge baseline exactly
- Pint: clean (111 files)
- `composer validate --strict`: clean
- `git diff --check`: clean

**Known Issues:**
- No backend CI workflow exists yet (`mobile-ci.yml` is path-filtered to `mobile/**`), so this PR triggered zero automated status checks — approvals and validation were performed manually/independently instead.
- Not verified against a live/staging backend or a real device — local Docker verification only.
- The Flutter Profile screen (Sprint 2, Task 2) is not implemented, so Module 3's own exit criterion isn't met yet even though Task 1 is done.

**Git Commit:** `5f7f706` — `feat(profile): GET/PATCH /me endpoint (#4)` (squash-merge of PR #4; squashes `dd03696` implementation + `96bc4c2` review-fix commit). Approved by two independent reviewers (`karthikatacr`, `shashwanth22dec`) distinct from the author before merge, per `docs/git-workflow.md`'s two-approval requirement for migration-touching changes.

**Next Task:** Task 20 (staging E2E test, Module 2) remains the primary blocked item — see [NEXT_TASK.md](NEXT_TASK.md). Once unblocked, Sprint 2 Task 2 (Flutter Profile screen) is the next candidate for this module.

### 2026-08-18 — Sprint 1 · Mobile Authentication merge (Tasks 17–19)

**Sprint:** Phase 1 · Sprint 1
**Task ID:** Sprint 1, Tasks 17–19 — merge/finalization
**Objective:** Independently verify PR #2's approval and CI state, squash-merge it into `main`, re-verify the merged result, and update the operational trackers accordingly.

**Files Changed:**
- No new application code — the implementation from the prior session's commit (`bdb6b0d` on `feature/mobile-auth`) was merged as-is. Independent re-verification (fresh `flutter analyze`/`format`/`test` run on `main`, backend-diff check, secret/keystore scan, presence check for all 15 new auth-module files, confirmation that access token stays memory-only and only the refresh token is ever passed to secure storage) found no defects.

**Database Changes:**
- None.

**API Changes:**
- None.

**Flutter Changes:**
- `mobile/lib/features/auth/**`, `mobile/lib/core/{network,storage,di,error}/**`, `mobile/lib/app/{splash_screen,router_refresh_notifier}.dart`, and the routing changes to `mobile/lib/app/router.dart` are now live on `main` for the first time.

**Tests Executed:**
- PR #2 approval independently verified via both `gh pr view --json reviews,reviewDecision` and the raw REST endpoint `gh api repos/karthik22feb/aesthetic-coach/pulls/2/reviews`: one `APPROVED` review from `karthikatacr` (account ID 318109433, distinct from the PR author `karthik22feb`), submitted against the exact head commit (`bdb6b0d`) — not a stale approval on an older commit.
- PR #2 CI independently re-checked via `gh pr view`'s `statusCheckRollup`: `SUCCESS`.
- `gh pr merge 2 --squash` executed; merge independently confirmed via a fresh `gh pr view 2 --json state,mergedAt,mergeCommit` call (not assumed from the command's exit status alone): `state: MERGED`, merge commit `f7a2580`.
- Post-merge on `main` (fresh `flutter pub get`, `flutter analyze`, `dart format --set-exit-if-changed`, `flutter test`): analyze clean, format clean, **65/65 tests passing**. `git diff --check`: clean. Tree hash of `main`'s new HEAD confirmed identical to `feature/mobile-auth`'s tip, verifying the squash preserved content exactly.

**Known Issues:**
- Unchanged from the implementation session: not verified against a live backend (Docker not started — server memory too tight) or a real device/emulator. `NOT VERIFIED AGAINST LIVE BACKEND` remains accurate for this merged code, not just the pre-merge branch.
- Same review-policy gap as PR #1: this repository has no GitHub branch-protection rule enforcing the "1 approving review" requirement from `docs/git-workflow.md` — the approval this time was genuine and independently verified, but the gate itself is still only a documented convention, not a platform-enforced one. Worth a future session configuring actual branch protection if that's desired.

**Git Commit:** `f7a2580` — squash-merge of PR [#2](https://github.com/karthik22feb/aesthetic-coach/pull/2) (`feature/mobile-auth` → `main`)

**Next Task:** Task 20 (end-to-end staging integration test) — blocked on a staging environment that doesn't exist yet. Not started this session.

### 2026-08-18 — Sprint 1 · Mobile Authentication (Tasks 17–19 combined)

**Sprint:** Phase 1 · Sprint 1
**Task ID:** Sprint 1, Tasks 17–19 (Flutter Login/Signup screens, Dio `AuthInterceptor` with transparent refresh, secure token storage) — user explicitly requested the full combined scope in one session rather than three separate ones; TASK_BREAKDOWN.md's own split is preserved in the tracking docs for traceability, but the implementation genuinely spans all three.
**Objective:** Build the complete mobile authentication client against the already-merged backend contract: register/login/logout/refresh, session state, auth-aware routing, and the token lifecycle (in-memory access token, securely-persisted rotating refresh token).

**Files Changed:**
- `mobile/lib/core/error/failure.dart` — new; typed `Failure` sealed class (`NetworkFailure`, `ValidationFailure`, `AuthFailure`, `RateLimitedFailure`, `ServerFailure`) per Mobile Architecture § 7
- `mobile/lib/core/storage/secure_token_storage.dart` — new; wraps `flutter_secure_storage` behind a small `TokenKeyValueStore` interface (for testability without a platform channel), persists the refresh token only
- `mobile/lib/core/network/{api_config,api_client,auth_token_store,auth_interceptor}.dart` — new; API base URL via `--dart-define`, shared `Dio` instance, in-memory access-token holder, and `AuthInterceptor` (header injection, single-flight 401-triggered refresh, exactly-once retry, exempt-path list for login/register/refresh)
- `mobile/lib/core/di/network_providers.dart` — new; DI wiring, written as standalone functions (not inline closures) to avoid a Dart top-level-inference cycle from the Dio↔AuthRepository circular runtime dependency
- `mobile/lib/features/auth/data/{auth_api,auth_repository}.dart`, `models/{auth_tokens,auth_user,auth_session}.dart` — new; hand-written (no codegen — see `ENGINEERING_DECISION_LOG.md`) API client and repository coordinating the server + token storage + in-memory token state, mapping `DioException`s to `Failure`s
- `mobile/lib/features/auth/application/{auth_state,auth_notifier}.dart` — new; `AuthNotifier` (hand-written `Notifier`) owning login/register/logout/session-restore, with a staleness guard so a slow background session-restore can never clobber a more-recent explicit login/logout
- `mobile/lib/features/auth/presentation/{login_screen,signup_screen}.dart` — new; email/password only (OAuth buttons from the design spec deliberately not implemented, out of scope), client-side validation mirroring backend rules (BR-1 password policy), inline server-error display
- `mobile/lib/app/splash_screen.dart`, `router_refresh_notifier.dart` — new; Splash screen + a `ChangeNotifier` bridge so go_router's `redirect` re-evaluates on auth-state changes without rebuilding the router
- `mobile/lib/app/router.dart` — modified; added `/splash`, `/login`, `/signup` routes and the authentication redirect guard around the existing 5-tab shell
- `mobile/test/widget/app_shell_test.dart` — modified; now overrides `authNotifierProvider` with a fake authenticated notifier (the shell is gated by auth now, and `AuthNotifier.build()` would otherwise fire a real network call in every widget test)
- `mobile/test/unit/{secure_token_storage,auth_repository,auth_notifier,auth_interceptor,auth_security}_test.dart`, `mobile/test/widget/{login_screen,signup_screen,routing_auth}_test.dart` — new, 46 additional tests
- `mobile/pubspec.yaml` — added `dio`, `flutter_secure_storage` (via `flutter pub add`)

**Database Changes:**
- None.

**API Changes:**
- None — integrates against the already-live `POST /api/v1/auth/{register,login,refresh,logout}` contract, verified against the actual backend source (routes.php, AuthController.php, the Form Requests, UserResource, ApiResponse) rather than assumed from docs alone.

**Flutter Changes:**
- See Files Changed. This is the first real business-logic/state layer in `mobile/` — everything before this (Tasks 5–7) was scaffold/placeholder.

**Tests Executed:**
- `flutter analyze`: 0 issues (several rounds of fixes: a Dart top-level-inference cycle in the DI wiring, wrong relative import paths, `curly_braces_in_flow_control_structures` after `dart format` reflowed single-line validators, a `prefer_initializing_formals` lint deliberately suppressed with an explanation since following it would require private-named constructor parameters and break cross-file construction).
- `dart format --set-exit-if-changed .`: clean, 0 changes.
- `flutter test`: **65/65 passed** (19 pre-existing + 46 new: 5 token-storage, 9 repository, 8 notifier, 11 interceptor including single-flight/no-infinite-loop, 7 security-labeled, 6 login-screen, 8 signup-screen, 5 routing).
- **Not verified:** a real device/emulator run (no Android SDK/Chrome/Linux desktop toolchain on this server, unchanged from Tasks 5–7), and the live backend (Docker was not started — server had ~822Mi free / swap already 70% utilized at decision time, judged unsafe to add the full Laravel+MySQL+Redis stack on top of that). Explicitly `NOT VERIFIED AGAINST LIVE BACKEND`, per this task's own instruction not to claim otherwise.

**Known Issues:**
- Session restoration after a pure token refresh has no `user` object (the real `POST /auth/refresh` response never includes one) — `AuthState.authenticated` can have `user: null` in that case. A `GET /me` call to populate identity after a cold-start restore is a natural follow-up once Module 3 (User Profile) exists.
- Signup's documented destination is Onboarding (Module 4, not built yet) — successful signup currently routes to the same app shell as login. Flagged in `NEXT_TASK.md`, not silently faked.
- The 2-second splash-restore timeout (`AuthNotifier.restoreTimeout`) uses `Future.timeout`, not a Dio `CancelToken` — if the underlying refresh call is unusually slow, it can still complete in the background after the timeout and write a valid session even though the UI already moved to Login. Low-impact (no security issue, just a rare UX inconsistency) and not fixed this session to avoid further scope growth.
- The documented workflow's "1 approving review" requirement for the eventual PR/merge is unresolved by this session — same situation as PR #1's merge (see the 2026-08-14 entry).

**Git Commit:** `<pending — see this session's own report>` on `feature/mobile-auth`, branched from `main` at `a190ae6`

**Next Task:** Review and merge `feature/mobile-auth`, then Task 20 (end-to-end staging integration test) — blocked on a staging environment that doesn't exist yet.

### 2026-08-14 — Sprint 1 · Flutter Mobile Foundation merge (Tasks 5–7)

**Sprint:** Phase 1 · Sprint 1
**Task ID:** Sprint 1, Tasks 5–7 (Flutter project scaffold, Riverpod/go_router skeleton, mobile CI) — merge/finalization
**Objective:** Independently re-verify the `feature/flutter-foundation` branch against the repository's actual current state (not a prior session's report), then take it through the documented PR → CI → review → squash-merge workflow into `main`.

**Files Changed:**
- No new application code — `mobile/`, `.github/workflows/mobile-ci.yml`, and the six operational docs already implemented/updated on the feature branch were merged as-is; independent re-verification (fresh `flutter analyze`/`format`/`test` run, backend-diff check, dependency check, folder-structure comparison against `08-mobile-architecture.md` § 2 and `06-ui-ux-design-system.md` § 4, CI run history re-checked via GitHub's API) found no defects.

**Database Changes:**
- None.

**API Changes:**
- None.

**Flutter Changes:**
- `mobile/` (project scaffold, Riverpod + go_router foundation, 5-tab shell, mobile CI) merged to `main` for the first time — previously only existed on the feature branch.

**Tests Executed:**
- Pre-merge (on `feature/flutter-foundation`, freshly re-run this session): `flutter analyze` clean, `dart format --set-exit-if-changed` clean, `flutter test` 6/6 passing. CI history independently re-verified via `gh`/GitHub REST API (not just the badge): run `0939ad6` success, run `1edf2cf` (intentional violation) **failure** (`Process completed with exit code 1`), run `10788ea` (revert) success.
- PR #1 CI (`gh pr checks`, watched to completion): `Analyze, format check, test` — **pass**, 1m43s.
- Post-merge (on `main`, HEAD `38f1da6`): `flutter pub get`, `flutter analyze` clean, `dart format --set-exit-if-changed` clean (0 changes), `flutter test` 6/6 passing. `git diff HEAD~1..HEAD -- backend/` confirmed empty. Tree hash of `main`'s HEAD confirmed identical to the feature branch's HEAD (`b9b103b...`), verifying the squash-merge preserved content exactly.

**Known Issues:**
- Same as before: `flutter build`/`flutter run` still not exercised in this environment (no Android SDK, Chrome, or Linux desktop build toolchain on the dev server). `/home` partition on the dev server remains at 100% capacity (unrelated infrastructure issue); `HOME=/var/flutter-home` override still required for all `flutter`/`dart` commands here.
- The documented workflow's "1 approving review" requirement was explicitly waived by the user for this specific PR, after GitHub authentication was set up via a `gh auth login --web` device-flow (there was no pre-existing GitHub API credential in this environment) and it was confirmed that the only available GitHub identity (`karthik22feb`) was also the PR's author, making self-approval structurally impossible on GitHub. Recorded here for traceability, not as an engineering decision (process exception, not a technical trade-off).

**Git Commit:** `38f1da6` — squash-merge of PR [#1](https://github.com/karthik22feb/aesthetic-coach/pull/1) (`feature/flutter-foundation` → `main`). Feature branch deleted locally and on `origin` after merge was independently confirmed via both the GitHub API (`state: MERGED`) and local git (tree-hash match, files present on `main`).

**Next Task:** Flutter Login/Signup screens (Sprint 1, Task 17) — a separate implementation session, not started here.

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
