# Next Task

**This file always contains exactly one actionable development task — the next thing to do, right now.** Claude updates this file at the end of every development session per [AI_DEVELOPMENT_GUIDE.md § Definition of Done](docs/AI_DEVELOPMENT_GUIDE.md#definition-of-done-before-moving-to-the-next-task). Read this file first, before [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md), when picking up work — it's the single-task version of that document's broader tracker.

**To actually start the session:** copy [CLAUDE_SESSION_TEMPLATE.md](CLAUDE_SESSION_TEMPLATE.md) and fill in its Session Information, Objective, and other sections using the task below.

---

## Task

**Review and merge `feature/flutter-foundation`, then start Task 17 (Login + Signup screens).**

Tasks 5, 6, and 7 (Flutter project scaffold, Riverpod/go_router foundation, mobile CI) are **implemented, verified, and pushed**, but **not yet merged** to `main`:

- Branch: `feature/flutter-foundation`
- PR: https://github.com/karthik22feb/aesthetic-coach/pull/new/feature/flutter-foundation

Once reviewed and merged, Task 17's dependency (Task 6) is satisfied and Login/Signup screens can begin for real.

## Context

- Module: [Authentication (Module 2)](docs/IMPLEMENTATION_ORDER.md#2-authentication) — backend complete; this branch is the Flutter foundation portion
- Sprint: [Phase 1 · Sprint 1 — Infrastructure, Authentication & Project Setup](docs/16-development-roadmap.md#phase-1--sprint-1--infrastructure-authentication--project-setup)
- **Environment note for whoever picks this up:** the Flutter SDK was not installed on this Linux dev server at all before this session. It's now installed via `snap install flutter --classic`, but two non-obvious fixes were required and matter for future sessions:
  1. `snap` apps need an active systemd user session — run `loginctl enable-linger administrator` once if a fresh shell reports "cannot run snap applications on this system" (already done; only relevant if the server is rebuilt).
  2. **`$HOME` (`/home/administrator`) is on a separate partition that is at 100% capacity (0 bytes free)** — unrelated to this project, caused by other tenants' data on this shared box. Flutter's snap wrapper downloads its SDK/tooling under `$HOME/snap/flutter/...` by default, which fails immediately on that full partition. Every `flutter`/`dart` invocation in this session used `export HOME=/var/flutter-home` first (a dedicated directory created on the healthy `/var` partition) — **keep doing this** for any `flutter`/`dart` command on this server until the `/home` partition issue is separately resolved (out of scope for this session; do not delete other tenants' files without explicit authorization).
  - Android SDK and Chrome are not installed (not needed for Tasks 5–7: `flutter analyze`/`flutter test` don't require them). Installing the Linux desktop build toolchain (`clang`/`cmake`/`ninja`/`pkg-config`, ~31 packages including full LLVM) was deliberately skipped as unnecessary resource use given this server's tight memory (server has ~3.8GB RAM, was already near its limit before this session even started, from unrelated tenants' workloads) — a true `flutter build`/`flutter run` has never been exercised in this environment. If Task 17+ needs an actual on-device/emulator run to verify, that likely needs to happen somewhere other than this shared server.

## Primary Documents

- [Screens — Login](docs/screens/login.md), [Screens — Signup](docs/screens/signup.md)
- [Mobile Architecture § 9 Networking Layer](docs/08-mobile-architecture.md#9-networking-layer) (Dio, not yet wired — that's Task 18, after this)
- [API Specification § 3](docs/05-api-specification.md#3-authentication-flow) — exact request/response shapes to build the UI against; all these endpoints are live on `main` (130/130 Pest tests passing)
- [Authentication feature § Validation Rules](docs/features/authentication.md#validation-rules) — password policy (BR-1), required fields

## Definition of Done (for Task 17, once started)

- [ ] Login screen: email/password form, calls `POST /auth/login`, client-side validation matching BR-1
- [ ] Signup screen: name/email/password form, calls `POST /auth/register`, same validation
- [ ] Form validation errors surfaced from the API's `422 validation_failed` envelope, not just client-side checks
- [ ] Widget tests for both screens
- [ ] Screens live under `lib/features/auth/presentation/` per the folder org already scaffolded (Task 5) — `lib/features/auth/data/` and `application/` are still empty; this task starts populating them (`AuthRepository`, `AuthNotifier`) but does not implement `AuthInterceptor` or secure token storage (Tasks 18–19)

## After Completing This Task

1. Confirm the Definition of Done above is fully met — see [AI_DEVELOPMENT_GUIDE.md § Definition of Done](docs/AI_DEVELOPMENT_GUIDE.md#definition-of-done-before-moving-to-the-next-task).
2. Update [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md)'s Sprint Tracker / Module Progress.
3. Replace this file's **Task**, **Context**, **Primary Documents**, and **Definition of Done** with the *next* task — [TASK_BREAKDOWN.md § Sprint 1, Task 18](docs/TASK_BREAKDOWN.md) (Dio `AuthInterceptor`).
4. Update the **Last updated** line below.

---

**Last updated:** 2026-08-13 · **Session:** Flutter Mobile Foundation (Tasks 5–7) · **Status:** Flutter project scaffold, Riverpod/go_router skeleton, and mobile CI implemented and verified on `feature/flutter-foundation` — awaiting review/merge. Task 17 (Login/Signup) not started.
