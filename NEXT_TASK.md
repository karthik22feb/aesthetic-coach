# Next Task

**This file always contains exactly one actionable development task — the next thing to do, right now.** Claude updates this file at the end of every development session per [AI_DEVELOPMENT_GUIDE.md § Definition of Done](docs/AI_DEVELOPMENT_GUIDE.md#definition-of-done-before-moving-to-the-next-task). Read this file first, before [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md), when picking up work — it's the single-task version of that document's broader tracker.

**To actually start the session:** copy [CLAUDE_SESSION_TEMPLATE.md](CLAUDE_SESSION_TEMPLATE.md) and fill in its Session Information, Objective, and other sections using the task below.

---

## Task

**Implement the OAuth foundation: `POST /auth/oauth/google` and `POST /auth/oauth/apple` (server-side Google/Apple ID token verification, find-or-create user, issue the normal JWT + refresh-token pair).**

## Context

- Module: [Authentication (Module 2)](docs/IMPLEMENTATION_ORDER.md#2-authentication)
- Sprint: [Phase 1 · Sprint 1 — Infrastructure, Authentication & Project Setup](docs/16-development-roadmap.md#phase-1--sprint-1--infrastructure-authentication--project-setup)
- Task reference: [TASK_BREAKDOWN.md § Sprint 1, Task 12](docs/TASK_BREAKDOWN.md#sprint-1--infrastructure-authentication--project-setup) (Google Sign-In) and [Task 13](docs/TASK_BREAKDOWN.md#sprint-1--infrastructure-authentication--project-setup) (Apple Sign-In), both depending on Task 10 (already complete)
- Register, login, logout, refresh-token rotation, and session/device management are merged to `main`, tagged `v1.0.0-auth-foundation`, `v1.0.0-refresh-rotation`, and `v1.0.0-session-management`.

## Primary Documents

- [API Specification § 3](docs/05-api-specification.md#3-authentication-flow) — `POST /auth/oauth/google` / `POST /auth/oauth/apple`: body `{ idToken, platform, deviceName }`, response identical in shape to register
- [System Architecture § 8 Security Architecture](docs/03-system-architecture.md#8-security-architecture) — "Google/Apple sign-in verified server-side via provider public keys/tokeninfo endpoints, never trusting client-asserted identity"
- [Authentication feature § Edge Cases](docs/features/authentication.md#edge-cases) — account linking by verified email; Apple private-relay email is *not* auto-merged with a later real-email account
- [Database Design § 3.1](docs/04-database-design.md#31-identity--auth) — `oauth_identities` (`user_id`, `provider` enum, `provider_user_id`, `UNIQUE(provider, provider_user_id)`)

## Definition of Done

- [ ] `POST /auth/oauth/google` / `POST /auth/oauth/apple` verify the ID token server-side against the provider's published JWKS (signature, issuer, audience, expiration) before trusting any claim
- [ ] Existing `oauth_identities` row → resolves the linked user; no `oauth_identities` row but a verified-email match on an existing `users` row → links (per the documented edge case); otherwise creates a new user
- [ ] New device row created/associated per platform+deviceName, normal JWT access token + rotating refresh token issued
- [ ] No client-asserted identity (email, name) is ever trusted without provider verification
- [ ] Pest Feature tests (real MySQL) covering both providers: valid/invalid signature, expired, wrong issuer, wrong audience, existing user, new user, provider-identity collision, device creation, token issuance
- [ ] Full auth test suite still passes (no regressions)

## After Completing This Task

1. Confirm the Definition of Done above is fully met — see [AI_DEVELOPMENT_GUIDE.md § Definition of Done](docs/AI_DEVELOPMENT_GUIDE.md#definition-of-done-before-moving-to-the-next-task).
2. Update [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md)'s Sprint Tracker / Module Progress.
3. Replace this file's **Task**, **Context**, **Primary Documents**, and **Definition of Done** with the *next* task — [TASK_BREAKDOWN.md § Sprint 1, Task 14](docs/TASK_BREAKDOWN.md) (email verification + password reset), the last authentication task before Flutter integration (Tasks 17–20).
4. Update the **Last updated** line below.

---

**Last updated:** 2026-08-11 · **Session:** Session Management PR Review, Merge & OAuth Foundation · **Status:** Session Management complete; OAuth foundation in progress
