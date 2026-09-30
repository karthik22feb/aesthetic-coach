# Next Task

**This file always contains exactly one actionable development task — the next thing to do, right now.** Claude updates this file at the end of every development session per [AI_DEVELOPMENT_GUIDE.md § Definition of Done](docs/AI_DEVELOPMENT_GUIDE.md#definition-of-done-before-moving-to-the-next-task). Read this file first, before [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md), when picking up work — it's the single-task version of that document's broader tracker.

**To actually start the session:** copy [CLAUDE_SESSION_TEMPLATE.md](CLAUDE_SESSION_TEMPLATE.md) and fill in its Session Information, Objective, and other sections using the task below.

---

## Task

**Sprint 2, Task 9 — Pest tests: profile update, onboarding goal creation.**

Module 2 (Authentication) is now **Complete** — Task 20 (end-to-end verification) landed against a real production deployment; see [PRODUCTION_DEPLOYMENT_REPORT.md](PRODUCTION_DEPLOYMENT_REPORT.md) and [IMPLEMENTATION_PROGRESS.md](IMPLEMENTATION_PROGRESS.md) for the full scope of what was verified. Sprint 2 Tasks 1–4 are already merged to `main` ahead of strict roadmap order (Module 3, User Profile, is Complete). [TASK_BREAKDOWN.md § Sprint 2](docs/TASK_BREAKDOWN.md#sprint-2--user-profile--ai-onboarding) lists Task 9 ("Pest tests: profile update, onboarding goal creation") as depending only on Tasks 1 and 4, both already done — it's the smallest fully-unblocked item remaining in Sprint 2.

Task 1's profile-update endpoint already has substantial existing Pest coverage (`ProfileTest.php`, referenced in earlier sessions) — this task's real remaining work is auditing that coverage against [Testing Strategy § 5](docs/10-testing-strategy.md#5-api-testing)'s checklist (happy path, validation, auth, cross-user isolation, idempotency) and adding tests for the `goals` table/model from Task 4, which has no dedicated test coverage yet (Task 4 was verified only via a manual Tinker round-trip, not an automated test).

**Alternative candidate, not chosen:** Sprint 2 Task 5 (onboarding flow screens: profile basics, goal selection, experience level) is also unblocked (depends only on Task 2, done) and is a larger, feature-shaped piece of work — a reasonable next choice if test-coverage work is deprioritized in favor of feature velocity, but Task 9 was picked here as the smaller, lower-risk item that closes an existing gap rather than opening new surface area.

**Not this task — tracked separately:** Task 20's two follow-up verification items (production email verification, explicit production logout verification — see [PRODUCTION_DEPLOYMENT_REPORT.md § Remaining Follow-Up Items](PRODUCTION_DEPLOYMENT_REPORT.md#remaining-follow-up-items)) are not folded into Task 9's scope above; they remain distinct, separately trackable items governed by their own prerequisites (a real mail transport, for email verification) rather than the existing Sprint 2 task sequence.

## Context

- Module: Sprint 2 has no single dedicated module row of its own in [IMPLEMENTATION_ORDER.md](docs/IMPLEMENTATION_ORDER.md)'s 16-module list beyond Module 3 (User Profile, already Complete) and Module 4 (AI Onboarding, In Progress) — Task 9 contributes test coverage to both.
- Sprint: [Phase 1 · Sprint 2 — User Profile & AI Onboarding](docs/16-development-roadmap.md#phase-1--sprint-2--user-profile--ai-onboarding)
- **Environment note:** this session ran on a bare Windows machine with no local PHP/Composer/Docker at all — Pest tests could not be executed locally here. Prior sessions ran backend work on a separate Linux dev server (`10.24.8.219`, `/var/www/html/aesthetic-coach`, `HOME=/var/flutter-home` override for Flutter/Dart only — irrelevant to PHP) where PHP/Composer/MySQL/Redis/Docker are already installed and validated (see [SERVER_SETUP_REPORT.md](SERVER_SETUP_REPORT.md)). That dev server (not the separate `10.24.1.22` production server from Task 20) is almost certainly still the right place to run this task's Pest suite.

## Primary Documents

- [Testing Strategy § 5 API Testing](docs/10-testing-strategy.md#5-api-testing) — the checklist every Feature test suite needs to satisfy
- [Profile feature](docs/features/profile.md) and [Database Design § 3.5](docs/04-database-design.md#35-habits--goals) (`goals` table)
- Existing `backend/tests/Feature/Profile/ProfileTest.php` (audit its current coverage first — don't duplicate what's already there)

## Definition of Done (for Task 9, once started)

- [ ] Existing profile-update Pest coverage audited against [Testing Strategy § 5](docs/10-testing-strategy.md#5-api-testing)'s checklist (happy path, validation, auth, cross-user isolation, idempotency); gaps filled
- [ ] New Pest Feature tests added for the `goals` table/model (Task 4) — at minimum, model creation, the documented enum casts, and the `user()`/`goals()` relations
- [ ] Full Pest suite run and passing on the Linux dev server (or another environment with a working `mysql` Docker hostname / real MySQL connection)
- [ ] `composer validate --strict` and Pint clean

## After Completing This Task

1. Confirm the Definition of Done above is fully met — see [AI_DEVELOPMENT_GUIDE.md § Definition of Done](docs/AI_DEVELOPMENT_GUIDE.md#definition-of-done-before-moving-to-the-next-task).
2. Update [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md)'s Sprint Tracker / Module Progress and [IMPLEMENTATION_PROGRESS.md](IMPLEMENTATION_PROGRESS.md).
3. Replace this file's **Task**, **Context**, **Primary Documents**, and **Definition of Done** with the next task (Sprint 2 Task 5, onboarding flow screens, or the next smallest unblocked item — check [MODULE_DEPENDENCIES.md](docs/MODULE_DEPENDENCIES.md)).
4. Update the **Last updated** line below.

---

**Last updated:** 2026-09-29 · **Session:** Task 20 production E2E verification, then Post-Task 20 Stabilization, Documentation & Production Readiness Audit · **Status:** Task 20 complete against a real production deployment (see [PRODUCTION_DEPLOYMENT_REPORT.md](PRODUCTION_DEPLOYMENT_REPORT.md)); Module 2 (Authentication) moves to Complete. This file's task replaced per this session's own Step 3 above — Sprint 2, Task 9 is next.
