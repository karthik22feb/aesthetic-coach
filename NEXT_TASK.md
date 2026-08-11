# Next Task

**This file always contains exactly one actionable development task — the next thing to do, right now.** Claude updates this file at the end of every development session per [AI_DEVELOPMENT_GUIDE.md § Definition of Done](docs/AI_DEVELOPMENT_GUIDE.md#definition-of-done-before-moving-to-the-next-task). Read this file first, before [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md), when picking up work — it's the single-task version of that document's broader tracker.

**To actually start the session:** copy [CLAUDE_SESSION_TEMPLATE.md](CLAUDE_SESSION_TEMPLATE.md) and fill in its Session Information, Objective, and other sections using the task below.

---

## Task

**Implement session/device management endpoints: `GET /auth/sessions` and `DELETE /auth/sessions/{deviceId}`.**

## Context

- Module: [Authentication (Module 2)](docs/IMPLEMENTATION_ORDER.md#2-authentication)
- Sprint: [Phase 1 · Sprint 1 — Infrastructure, Authentication & Project Setup](docs/16-development-roadmap.md#phase-1--sprint-1--infrastructure-authentication--project-setup)
- Task reference: [TASK_BREAKDOWN.md § Sprint 1, Task 15](docs/TASK_BREAKDOWN.md#sprint-1--infrastructure-authentication--project-setup) — "Session/device management endpoints (`GET/DELETE /auth/sessions`)"
- Register, login, logout, and refresh-token rotation (with reuse detection and family revocation) are merged to `main`, tagged `v1.0.0-auth-foundation` and `v1.0.0-refresh-rotation`.

## Primary Documents

- [Authentication feature § FR-106](docs/features/authentication.md#functional-requirements) — "Session list shows device name, platform, last active; revoke invalidates that device's refresh token immediately"
- [API Specification § 3](docs/05-api-specification.md#3-authentication-flow) — `GET /auth/sessions` / `DELETE /auth/sessions/{deviceId}`
- [API Examples — Auth](docs/api-examples/auth.md#get-authsessions) — exact response shape (`deviceId`, `deviceName`, `platform`, `lastActiveAt`, `isCurrent`)
- [Database Design § 3.1](docs/04-database-design.md#31-identity--auth) — `devices`, `auth_refresh_tokens` (no new migration expected; existing schema already supports this)

## Definition of Done

- [ ] `GET /auth/sessions` lists the authenticated user's devices with an active (non-revoked, non-expired) refresh token, matching the documented response shape exactly
- [ ] `DELETE /auth/sessions/{deviceId}` revokes that device's active refresh token(s); cross-user access returns `404 not_found` (never `403`, to avoid confirming another user's device ID exists)
- [ ] No sensitive fields (token hashes, plaintext tokens, JWT key material) ever appear in the response
- [ ] Pest Feature tests (real MySQL): listing, revocation, cross-user isolation (IDOR), unauthenticated access, already-revoked idempotency
- [ ] Full auth test suite still passes (no regressions)

## After Completing This Task

1. Confirm the Definition of Done above is fully met — see [AI_DEVELOPMENT_GUIDE.md § Definition of Done](docs/AI_DEVELOPMENT_GUIDE.md#definition-of-done-before-moving-to-the-next-task).
2. Update [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md)'s Sprint Tracker / Module Progress.
3. Replace this file's **Task**, **Context**, **Primary Documents**, and **Definition of Done** with the *next* task — [TASK_BREAKDOWN.md § Sprint 1, Task 12/13](docs/TASK_BREAKDOWN.md) (Google/Apple Sign-In) or Task 14 (email verification + password reset), whichever the next session picks up.
4. Update the **Last updated** line below.

---

**Last updated:** 2026-08-11 · **Session:** Refresh Token Rotation merge + Session Management · **Status:** Session Management in progress
