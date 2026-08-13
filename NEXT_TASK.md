# Next Task

**This file always contains exactly one actionable development task — the next thing to do, right now.** Claude updates this file at the end of every development session per [AI_DEVELOPMENT_GUIDE.md § Definition of Done](docs/AI_DEVELOPMENT_GUIDE.md#definition-of-done-before-moving-to-the-next-task). Read this file first, before [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md), when picking up work — it's the single-task version of that document's broader tracker.

**To actually start the session:** copy [CLAUDE_SESSION_TEMPLATE.md](CLAUDE_SESSION_TEMPLATE.md) and fill in its Session Information, Objective, and other sections using the task below.

---

## Task

**Flutter: create the project and scaffold, then Login + Signup screens.**

The entire backend Authentication module (Sprint 1, Tasks 9–16) is now merged to `main` and tagged `v1.0.0-auth-complete`. This is the first Flutter/mobile work in the project — **no Flutter code exists yet** (the `mobile/` directory is empty).

The eventual target is [TASK_BREAKDOWN.md § Sprint 1, Task 17](docs/TASK_BREAKDOWN.md#sprint-1--infrastructure-authentication--project-setup) (Login + Signup screens), but Task 17 depends on Task 6, which depends on Task 5 — **neither is done**. Verify the actual starting point against `TASK_BREAKDOWN.md`'s dependency column before assuming Task 17 can start directly:

1. **Task 5** — Create Flutter project, scaffold `lib/{app,core,features,shared}` structure (no dependency, start here)
2. **Task 6** — Wire Riverpod + go_router skeleton with 5 placeholder tab routes (depends on 5)
3. **Task 17** — Login + Signup screens, form validation (depends on 6)

Do not skip 5/6 to jump straight to login/signup UI.

## Context

- Module: [Authentication (Module 2)](docs/IMPLEMENTATION_ORDER.md#2-authentication) (backend, complete) — this task begins Flutter mobile work, still under the Sprint 1 umbrella
- Sprint: [Phase 1 · Sprint 1 — Infrastructure, Authentication & Project Setup](docs/16-development-roadmap.md#phase-1--sprint-1--infrastructure-authentication--project-setup)
- All backend auth endpoints are live on `main`: `POST /auth/register`, `POST /auth/login`, `POST /auth/logout`, `POST /auth/oauth/google`, `POST /auth/oauth/apple`, `POST /auth/refresh`, `GET/DELETE /auth/sessions`, `POST /auth/password/forgot`, `POST /auth/password/reset`, `POST /auth/email/verify`, `POST /auth/email/resend`. 130/130 Pest tests passing. Build the Flutter UI against these documented contracts — do not redesign them.
- Subsequent Sprint 1 Flutter tasks, in order after Task 17: Task 18 (Dio `AuthInterceptor`), Task 19 (secure token storage via `flutter_secure_storage`), Task 20 (end-to-end staging integration test).

## Primary Documents

- [Mobile Architecture § 2 Folder Organization](docs/08-mobile-architecture.md#2-folder-organization) (Task 5)
- [Mobile Architecture § 1 State Management](docs/08-mobile-architecture.md#1-state-management) and § 3 (Riverpod + go_router, per ADR-0004) (Task 6)
- [Screens — Login](docs/screens/login.md), [Screens — Signup](docs/screens/signup.md) (Task 17)
- [API Specification § 3](docs/05-api-specification.md#3-authentication-flow) — exact request/response shapes to build the UI against
- [Authentication feature § Validation Rules](docs/features/authentication.md#validation-rules) — password policy (BR-1), required fields

## Definition of Done

- [ ] Flutter project created, `lib/{app,core,features,shared}` structure matches Mobile Architecture § 2
- [ ] Riverpod + go_router wired, 5 placeholder tab routes reachable
- [ ] Login screen: email/password form, calls `POST /auth/login`, client-side validation matching BR-1
- [ ] Signup screen: name/email/password form, calls `POST /auth/register`, same validation
- [ ] Form validation errors surfaced from the API's `422 validation_failed` envelope, not just client-side checks
- [ ] Widget tests for both screens

## After Completing This Task

1. Confirm the Definition of Done above is fully met — see [AI_DEVELOPMENT_GUIDE.md § Definition of Done](docs/AI_DEVELOPMENT_GUIDE.md#definition-of-done-before-moving-to-the-next-task).
2. Update [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md)'s Sprint Tracker / Module Progress.
3. Replace this file's **Task**, **Context**, **Primary Documents**, and **Definition of Done** with the *next* task — [TASK_BREAKDOWN.md § Sprint 1, Task 18](docs/TASK_BREAKDOWN.md) (Dio `AuthInterceptor`).
4. Update the **Last updated** line below.

---

**Last updated:** 2026-08-13 · **Session:** Authentication Milestone Finalization (OAuth + Email Verification/Password Reset merge) · **Status:** Backend Authentication module (Sprint 1, Tasks 9–16) complete and merged; Flutter work (Tasks 5, 6, 17+) not yet started
