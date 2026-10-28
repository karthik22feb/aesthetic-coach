# Next Task

**This file always contains exactly one actionable development task — the next thing to do, right now.** Claude updates this file at the end of every development session per [AI_DEVELOPMENT_GUIDE.md § Definition of Done](docs/AI_DEVELOPMENT_GUIDE.md#definition-of-done-before-moving-to-the-next-task). Read this file first, before [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md), when picking up work — it's the single-task version of that document's broader tracker.

**To actually start the session:** copy [CLAUDE_SESSION_TEMPLATE.md](CLAUDE_SESSION_TEMPLATE.md) and fill in its Session Information, Objective, and other sections using the task below.

---

## Task

**Sprint 2, Task 10 — Widget tests: onboarding flow navigation, skip/resume behavior.**

Modules 2 (Authentication), 3 (User Profile), and 4 (AI Onboarding) are all now **Complete**. Sprint 2 Tasks 1–9 are done: Task 9 (Pest tests: profile update, onboarding goal creation — commit `4f33733`), Task 5 (onboarding flow screens — commit `f7c3f95`), Task 6 ("Meet Your Coach" step, AI call feature-flagged off — commit `e339e3b`), and Tasks 7+8 together (notification-permission step + `POST /devices`, implemented and validated this session, not yet committed). [TASK_BREAKDOWN.md § Sprint 2](docs/TASK_BREAKDOWN.md#sprint-2--user-profile--ai-onboarding) lists Task 10 ("Widget tests: onboarding flow navigation, skip/resume behavior") as depending on Tasks 5–7, all now done — it's the smallest fully-unblocked item remaining in Sprint 2.

Substantial widget-level coverage of the onboarding flow already exists as a side effect of Tasks 5–8's own test suites (`onboarding_flow_screen_test.dart` already drives the full 5-step happy path end-to-end to Home, plus Meet-Your-Coach-specific and notification-permission-specific cases). This task's real remaining work is auditing that existing coverage against [Onboarding § Edge Cases](docs/features/onboarding.md#edge-cases) specifically — skip behavior at each skippable step (goal selection, notification permission), and **resume** behavior (app restarted/killed mid-onboarding — does `AuthState.justRegistered` or step state survive, and what should happen if not) — then filling whatever gaps that audit finds rather than assuming the existing tests already cover it.

**Alternative candidate, not chosen:** Sprint 2 Task 11 (integration test: full onboarding flow reaches Home with AI step correctly deferred) depends on Task 10, so it isn't actually unblocked yet — it becomes the next task immediately after this one.

## Context

- Module: Sprint 2 has no single dedicated module row of its own in [IMPLEMENTATION_ORDER.md](docs/IMPLEMENTATION_ORDER.md)'s 16-module list beyond Module 3 (User Profile) and Module 4 (AI Onboarding), both already Complete — Task 10 adds test-coverage depth on top of work those modules already closed out.
- Sprint: [Phase 1 · Sprint 2 — User Profile & AI Onboarding](docs/16-development-roadmap.md#phase-1--sprint-2--user-profile--ai-onboarding)
- **Environment note:** Flutter/Dart tooling runs fine on this local Windows machine (`flutter analyze`/`flutter test`/`flutter build apk --release` all used directly in the Tasks 5–8 sessions) — no remote server needed for this task, unlike backend Pest work.

## Primary Documents

- [Onboarding § Edge Cases](docs/features/onboarding.md#edge-cases) — the specific skip/resume scenarios this task's tests need to cover
- [Onboarding feature](docs/features/onboarding.md) and [Mobile Architecture § 2](docs/08-mobile-architecture.md#2-folder-organization)
- Existing `mobile/test/widget/onboarding_flow_screen_test.dart` and `mobile/test/widget/notification_permission_step_test.dart` (audit current coverage first — don't duplicate what's already there)

## Definition of Done (for Task 10, once started)

- [ ] Existing onboarding widget-test coverage audited against [Onboarding § Edge Cases](docs/features/onboarding.md#edge-cases); gaps identified explicitly before writing new tests
- [ ] Skip behavior covered for every skippable step (goal selection, notification permission) — already partially covered, confirm and extend if needed
- [ ] Resume behavior covered (app restart/kill mid-onboarding) — not yet covered by any existing test; needs a deliberate design decision on what "resume" means given `AuthState.justRegistered` is in-memory-only (not persisted across restart)
- [ ] `flutter analyze`, `flutter test`, `dart format --set-exit-if-changed` all clean

## After Completing This Task

1. Confirm the Definition of Done above is fully met — see [AI_DEVELOPMENT_GUIDE.md § Definition of Done](docs/AI_DEVELOPMENT_GUIDE.md#definition-of-done-before-moving-to-the-next-task).
2. Update [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md)'s Sprint Tracker / Module Progress and [IMPLEMENTATION_PROGRESS.md](IMPLEMENTATION_PROGRESS.md).
3. Replace this file's **Task**, **Context**, **Primary Documents**, and **Definition of Done** with the next task (Sprint 2 Task 11, integration test: full onboarding flow reaches Home with AI step correctly deferred — now unblocked once Task 10 lands).
4. Update the **Last updated** line below.

---

**Last updated:** 2026-10-27 · **Session:** Sprint 2 Tasks 7+8 (notification permission onboarding step + `POST /devices`), implemented together · **Status:** Tasks 7+8 implemented and fully validated this session (backend: 167/167 Pest passing; mobile: 139/139 tests passing, release APK build SUCCESS) but **not yet committed**. Module 4 (AI Onboarding) moves to Complete. This file's task replaced per this session's own Step 3 above — Sprint 2, Task 10 is next.
