# ADR-0005: Custom JWT + Rotating Refresh Token Authentication

**Status:** Accepted
**Related documents:** [System Architecture § 3.1 & § 8](../03-system-architecture.md#31-authentication-login--token-refresh) (original condensed rationale) · [Authentication feature](../features/authentication.md) · [SRS § 4.1](../02-srs.md#41-authentication--account-management)

## Context
The product requires JWT access tokens, refresh tokens, Google/Apple Sign-In, multi-device session management, and token revocation — all specified explicitly in the [PRD](../01-prd.md). The backend is stateless-by-design for horizontal scaling ([System Architecture § Scalability Strategy](../03-system-architecture.md#7-scalability-strategy)).

## Problem
How should mobile authentication be implemented to support multiple concurrent device sessions, clean per-device revocation, and detection of stolen/replayed tokens, while keeping the API tier stateless?

## Decision
Implement custom authentication: short-lived (15 min) stateless JWT access tokens (RS256) plus opaque, server-side-hashed, rotating refresh tokens with reuse detection that revokes an entire session family on a replay (BR-3, BR-4).

## Alternatives Considered
| Option | Why not chosen |
|---|---|
| Laravel Sanctum alone | Sanctum's SPA/personal-access-token model doesn't natively provide rotating refresh tokens with reuse detection — the specific multi-device security posture this product needs (BR-3) would require building that logic on top of Sanctum anyway, at which point the abstraction adds more indirection than value |
| Laravel Passport (full OAuth2 server) | Full OAuth2 server capability (multiple client types, authorization code flow for third parties) is more machinery than this product needs — there is exactly one client type (the Aesthetic Coach mobile app), not a third-party developer ecosystem |
| Firebase Authentication | Would offload token management to a third party, but conflicts with the requirement for fine-grained server-side session/device management (BR-5, [Authentication § FR-106](../features/authentication.md#functional-requirements)) and introduces a dependency the rest of this backend-owned architecture doesn't otherwise have |

## Pros
- Access tokens are stateless — any app instance can verify them without a DB round-trip, directly supporting horizontal scaling ([System Architecture § Scalability Strategy](../03-system-architecture.md#7-scalability-strategy)).
- Refresh token rotation + reuse detection provides strong theft-detection: a stolen-and-replayed token immediately revokes the whole session family rather than silently succeeding.
- Full control over session/device semantics (BR-5's 10-device cap, per-device revocation) without fighting a third-party package's assumptions.

## Cons
- More implementation and testing surface than adopting an off-the-shelf package — mitigated by treating this as security-critical and allocating explicit test time ([Development Roadmap § Phase 1 · Sprint 1](../16-development-roadmap.md#phase-1--sprint-1--infrastructure-authentication--project-setup) calls this out directly: "refresh-token rotation/reuse-detection bugs are security-critical and easy to get subtly wrong").
- Requires careful key-rotation planning for the JWT signing key (addressed in [Production Hardening § Secrets Management](../14-production-hardening.md#3-encryption--secrets-management) via a dual-key acceptance window).

## Consequences
The `auth_refresh_tokens` table and its `family_id` rotation-chain design ([Database Design § 3.1](../04-database-design.md#31-identity--auth)) exist specifically to support this decision; the mobile `AuthInterceptor` ([Mobile Architecture § 9](../08-mobile-architecture.md#9-networking-layer)) implements the transparent-refresh-on-401 client-side counterpart.

## Future Review Criteria
Revisit if: a compelling, well-maintained Laravel package emerges that covers rotating-refresh-with-reuse-detection out of the box with equivalent control, reducing the case for custom implementation; or if the product ever needs to support genuine third-party OAuth clients (at which point Passport's full OAuth2 server model would become relevant).
