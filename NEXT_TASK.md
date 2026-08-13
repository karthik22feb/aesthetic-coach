# Next Task

**This file always contains exactly one actionable development task — the next thing to do, right now.** Claude updates this file at the end of every development session per [AI_DEVELOPMENT_GUIDE.md § Definition of Done](docs/AI_DEVELOPMENT_GUIDE.md#definition-of-done-before-moving-to-the-next-task). Read this file first, before [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md), when picking up work — it's the single-task version of that document's broader tracker.

**To actually start the session:** copy [CLAUDE_SESSION_TEMPLATE.md](CLAUDE_SESSION_TEMPLATE.md) and fill in its Session Information, Objective, and other sections using the task below.

---

## Task

**Review and merge the two pending authentication PRs, then start Flutter integration.**

Two backend authentication PRs are implemented, tested, and pushed, but **neither is merged yet**:

1. `feature/auth-oauth` — Google/Apple Sign-In (Sprint 1, Tasks 12–13)
2. `feature/email-verification-password-reset` — Email verification + password reset (Sprint 1, Task 14)

Once both are reviewed and merged, Sprint 1's entire backend authentication scope (Tasks 9–16) is complete, and the next task becomes [TASK_BREAKDOWN.md § Sprint 1, Task 17](docs/TASK_BREAKDOWN.md) (Flutter: Login + Signup screens).

## Context

- Module: [Authentication (Module 2)](docs/IMPLEMENTATION_ORDER.md#2-authentication)
- Sprint: [Phase 1 · Sprint 1 — Infrastructure, Authentication & Project Setup](docs/16-development-roadmap.md#phase-1--sprint-1--infrastructure-authentication--project-setup)
- Register, login, logout, refresh-token rotation, and session/device management are merged to `main`, tagged `v1.0.0-auth-foundation`, `v1.0.0-refresh-rotation`, and `v1.0.0-session-management`.
- `feature/auth-oauth`: implements `POST /auth/oauth/google` / `POST /auth/oauth/apple`. 95 tests passing on that branch (includes the session-management baseline as of when it was cut).
- `feature/email-verification-password-reset`: implements `POST /auth/password/forgot`, `POST /auth/password/reset`, `POST /auth/email/verify`, `POST /auth/email/resend`. Branched from `main` (does **not** include the unmerged OAuth work) — 102 tests passing on that branch.
- **Note for whoever merges both:** `feature/auth-oauth` was cut before `feature/email-verification-password-reset`, and neither includes the other's work. Whichever merges to `main` second will very likely need a straightforward rebase (both touch `AuthController.php`/`AuthService.php`/`routes.php`, but in non-overlapping ways — new methods/routes, not shared lines).

## Primary Documents (for Task 14, already applied)

- [API Specification § 3](docs/05-api-specification.md#3-authentication-flow) — `POST /auth/password/forgot` / `POST /auth/password/reset` ("Standard reset-link flow", FR-105)
- [Database Design § 3.1](docs/04-database-design.md#31-identity--auth) — `password_reset_tokens` (`email` PK, `token_hash` CHAR(64), `expires_at`)
- **FR-104 (email verification) has no documented API contract anywhere** (checked API Specification, Authentication feature, API Examples, Database Design, Mobile Architecture) — resolved this session by mirroring the password-reset pattern exactly, with the user's explicit approval. See `ENGINEERING_DECISION_LOG.md` for the full reasoning. If this doc gap is ever formally closed (endpoints added to `docs/05-api-specification.md` § 3), reconcile against what was actually built: `POST /auth/email/verify` (body `{token}`, public), `POST /auth/email/resend` (authenticated, no body).

## Definition of Done

- [x] Both PRs implemented, migrated, tested (102/102 and 95/95 respectively on their own branches), Pint-clean, `composer validate --strict`-clean
- [ ] Both PRs reviewed
- [ ] Both PRs merged to `main` (rebase/reconcile per the note above)
- [ ] Full suite re-verified on `main` post-merge (expect roughly 95 + 34 new − 67 shared baseline ≈ 129 tests once both are in, exact count depends on rebase)
- [ ] Milestone tag(s) created per the established `v1.0.0-<milestone>` convention
- [ ] Operational docs updated to reflect both merges

## After Completing This Task

1. Confirm the Definition of Done above is fully met — see [AI_DEVELOPMENT_GUIDE.md § Definition of Done](docs/AI_DEVELOPMENT_GUIDE.md#definition-of-done-before-moving-to-the-next-task).
2. Update [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md)'s Sprint Tracker / Module Progress.
3. Replace this file's **Task**, **Context**, **Primary Documents**, and **Definition of Done** with the *next* task — [TASK_BREAKDOWN.md § Sprint 1, Task 17](docs/TASK_BREAKDOWN.md) (Flutter: Login + Signup screens, form validation).
4. Update the **Last updated** line below.

---

**Last updated:** 2026-08-13 · **Session:** Email Verification & Password Reset (Task 14) · **Status:** Task 14 implemented, tested, pushed — awaiting review/merge alongside the still-pending OAuth PR
