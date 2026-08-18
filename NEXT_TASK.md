# Next Task

**This file always contains exactly one actionable development task — the next thing to do, right now.** Claude updates this file at the end of every development session per [AI_DEVELOPMENT_GUIDE.md § Definition of Done](docs/AI_DEVELOPMENT_GUIDE.md#definition-of-done-before-moving-to-the-next-task). Read this file first, before [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md), when picking up work — it's the single-task version of that document's broader tracker.

**To actually start the session:** copy [CLAUDE_SESSION_TEMPLATE.md](CLAUDE_SESSION_TEMPLATE.md) and fill in its Session Information, Objective, and other sections using the task below.

---

## Task

**Task 20 — end-to-end staging integration test.**

Tasks 17, 18, and 19 (Flutter Login/Signup screens, Dio `AuthInterceptor` with transparent refresh, secure token storage) are **merged to `main`** as of commit `f7a2580` (squash-merge of PR [#2](https://github.com/karthik22feb/aesthetic-coach/pull/2)). This is implemented and locally verified (unit/widget tests, `flutter analyze`/`dart format`) — **not** yet verified against a live backend or a real device/emulator. **Only Task 20 remains** to close out Module 2 (Authentication).

## Context

- Module: [Authentication (Module 2)](docs/IMPLEMENTATION_ORDER.md#2-authentication) — backend complete, Flutter foundation merged, Flutter auth client (Login/Signup, interceptor, secure storage) merged; only the staging E2E exit criterion remains
- Sprint: [Phase 1 · Sprint 1 — Infrastructure, Authentication & Project Setup](docs/16-development-roadmap.md#phase-1--sprint-1--infrastructure-authentication--project-setup)
- **Environment note (unchanged from prior sessions):** `export HOME=/var/flutter-home` before any `flutter`/`dart` command on this server. The `/home` partition capacity issue that originally forced this is now resolved (~50GB free as of 2026-08-18), but the Flutter SDK's own cache still lives under `/var/flutter-home` from when it was installed there — switching back to the real `$HOME` would mean a ~2.3GB re-download for no functional benefit, so the override stays in place until a dedicated cleanup session decides otherwise.
- Android SDK, Chrome, and the Linux desktop build toolchain (`clang`/`cmake`/`ninja`/`gtk3`) are still not installed — `flutter build`/`flutter run` remain unverified in this environment. This session's login/signup/auth-flow work was verified via `flutter analyze` + `flutter test` (65/65 passing) only, **not** against a real device/emulator, and **not** against the live backend (Docker wasn't started — server had only ~822Mi free / swap already 70% utilized at decision time; starting the full Laravel+MySQL+Redis stack was judged unsafe).

## Primary Documents

- [Authentication feature § Acceptance Criteria](docs/features/authentication.md#acceptance-criteria) — the exact end-to-end scenario Task 20 needs to prove
- [API Examples — Auth](docs/api-examples/auth.md)
- Task 20's own definition: [TASK_BREAKDOWN.md § Sprint 1, Task 20](docs/TASK_BREAKDOWN.md) — "register → verify → login → refresh → logout, on staging"

## Definition of Done (for Task 20, once started)

- [ ] A real staging environment exists and is reachable (this itself may be a blocker — no staging environment has been provisioned yet per Module 1's own Definition of Done; check [IMPLEMENTATION_PROGRESS.md](IMPLEMENTATION_PROGRESS.md) before assuming it's ready)
- [ ] register → verify email → login → refresh → logout exercised end-to-end against that real backend, from the real Flutter client (not mocks)
- [ ] Confirms the mobile client's `AuthInterceptor` genuinely handles a real 401/refresh cycle against the real backend, not just the fake-adapter unit tests from Tasks 17–19

## After Completing This Task

1. Confirm the Definition of Done above is fully met — see [AI_DEVELOPMENT_GUIDE.md § Definition of Done](docs/AI_DEVELOPMENT_GUIDE.md#definition-of-done-before-moving-to-the-next-task).
2. Update [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md)'s Sprint Tracker / Module Progress — Module 2 (Authentication) can finally move to Complete once Task 20 lands.
3. Replace this file's **Task**, **Context**, **Primary Documents**, and **Definition of Done** with the *next* task — Module 3, User Profile ([TASK_BREAKDOWN.md § Sprint 2](docs/TASK_BREAKDOWN.md)).
4. Update the **Last updated** line below.

---

**Last updated:** 2026-08-18 · **Session:** Mobile Authentication (Tasks 17–19 combined) merged · **Status:** Login/Signup screens, Dio `AuthInterceptor` (single-flight transparent refresh), secure refresh-token storage, and the full auth state/routing integration merged to `main` (`f7a2580`, squash-merge of PR #2) and re-verified post-merge (65/65 tests passing, `flutter analyze`/`dart format` clean). Not verified against a live backend or real device — only Task 20 (staging E2E) not started.
