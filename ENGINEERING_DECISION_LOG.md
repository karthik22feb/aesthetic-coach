# Engineering Decision Log

**A chronological record of important engineering decisions made during implementation.**

## Purpose

This document is **not** a replacement for [Architecture Decision Records](docs/adr/). ADRs remain reserved for major architectural decisions — technology choices, system-level structure, and anything that would require a new ADR-numbered file to change (see [docs/adr/README.md](docs/adr/README.md)). This log is for everything one level down: the implementation-level decisions that come up in day-to-day development and are worth recording, but don't rise to architectural significance.

**When to add an entry here vs. an ADR:** if the decision changes *how the system is built or structured* in a way future engineers would need to know before touching related code — a package choice, a trade-off made under a real constraint, a workaround for an unexpected limitation — it belongs here. If it changes *what the architecture is* — a technology swap, a new module boundary, a reversal of something an existing ADR already decided — it needs a real ADR instead. See [DEVELOPMENT_WORKFLOW.md § When to Record an Engineering Decision](docs/DEVELOPMENT_WORKFLOW.md#when-to-record-an-engineering-decision) for the fuller trigger list.

This log is append-only, most-recent-entry-first, exactly like [DEVELOPMENT_LOG.md](DEVELOPMENT_LOG.md) — past entries are never edited to reflect later changes, only new entries are added (a later entry can supersede an earlier one, but should say so explicitly rather than silently rewriting history).

## Entry Template

Copy this template for every new entry:

```markdown
### YYYY-MM-DD — [Short Decision Title]

**Sprint:** Phase 1 · Sprint N (or Phase 2 · Sprint N)
**Task ID:** [reference into TASK_BREAKDOWN.md, e.g. "Sprint 1, Task 3"]
**Decision Summary:** [one sentence — what was decided]

**Background:**
[What situation prompted this decision — the constraint, question, or problem encountered during implementation.]

**Alternatives Considered:**
- [Option A — why it was or wasn't chosen]
- [Option B — why it was or wasn't chosen]

**Final Decision:**
[What was actually decided/implemented.]

**Reasoning:**
[Why this option over the alternatives — the actual justification, not just a restatement of the decision.]

**Impact:**
[What this affects — other modules, future work, performance, security posture, etc. Note explicitly if this decision constrains or informs later tasks.]

**Related Files:**
- `path/to/file`

**Related Documentation:**
- [Link to any spec, ADR, or other doc this decision touches or depends on]

**Git Commit:** `<short-sha>`

**Author:** [who made the call]
```

## Entries

### 2026-08-13 — Flutter/Dart tooling on the shared dev server requires a scoped `$HOME` override

**Sprint:** Phase 1 · Sprint 1
**Task ID:** Sprint 1, Task 5 (Flutter project scaffold)
**Decision Summary:** Every `flutter`/`dart` invocation on this specific dev server (`10.24.8.219`) must run with `HOME=/var/flutter-home` set, because the real `$HOME` (`/home/administrator`) sits on a partition that is at 100% capacity for reasons unrelated to this project.

**Background:**
No Flutter SDK existed on the server at session start — this was a genuine hard-stop condition, resolved only after the user explicitly authorized installing it (`snap install flutter --classic`). Two independent infrastructure blockers surfaced during that install, neither caused by this project:
1. `snap` requires an active systemd user session; the `administrator` account had none (`loginctl` reported "not logged in or lingering"). Fixed with `sudo loginctl enable-linger administrator` — a one-time, safe, non-destructive fix.
2. The Flutter SDK download then failed partway through (`curl` error 23, "Failure writing output to destination") after ~1.35MB. Diagnosis: `df -h` showed `/` and `/var` both had 195GB+ free, but `/home` — a separate mount point — was at 100% capacity (0 bytes available, 69G/69G used). Flutter's snap wrapper downloads its SDK/tooling under `$HOME/snap/flutter/...` by default, which fails immediately when `$HOME` has no space. The largest consumers of `/home` are other tenants' directories on this shared server (a 50GB `backups/` folder and several unrelated tenant home directories) — not anything this project created or has authorization to delete.

**Alternatives Considered:**
- Delete files under `/home` to free space — rejected: the largest consumers are either unattributable as safe-to-delete or belong to other tenants (`chennai36`, `eservicesadmin`, `frappe`), and this session's own constraints explicitly forbid interfering with other tenants' data or taking destructive action without clear authorization.
- Request the server owner resize/expand the `/home` partition — out of scope for an implementation session; flagged as a separate, standalone infrastructure issue rather than something to silently work around forever.
- Scope `$HOME` to a new directory on a partition with room (chosen) — `/var` had 195GB free and is not shared with `/home`'s tenants in the same way; created `/var/flutter-home`, owned by `administrator`, and exported `HOME=/var/flutter-home` before every `flutter`/`dart` command for the rest of the session.

**Final Decision:**
Created `/var/flutter-home` (`sudo mkdir` + `sudo chown administrator:administrator`) and used `HOME=/var/flutter-home` as a per-invocation environment override for all Flutter/Dart tooling. The Flutter SDK (1.46GB) then downloaded successfully. No change was made to the `administrator` account's actual login `$HOME`, systemd config, or any other user/tenant's files.

**Reasoning:**
This isolates the fix to exactly the tool that needed it (Flutter/Dart), on exactly the partition that had room, without touching shared/unrelated state — consistent with the session's explicit resource-conservation and no-interference-with-other-tenants constraints. A global `$HOME` change would have been both unnecessary (nothing else on this server needs it) and riskier (touches the account's default environment for every other process).

**Impact:**
Any future session running `flutter`/`dart` commands directly on this dev server must set `HOME=/var/flutter-home` first, or those commands will fail the same way. This is now documented in `NEXT_TASK.md` so it isn't rediscovered from scratch. The underlying `/home` partition being full is a separate, still-unresolved infrastructure issue outside this project's scope — it may eventually need the server owner's attention if other tenants' tooling hits the same wall.

**Related Files:**
- None (server-level configuration, not repository code)

**Related Documentation:**
- [NEXT_TASK.md](NEXT_TASK.md) — environment note for future sessions

**Git Commit:** N/A (infrastructure-only change, not a repository commit)

**Author:** Claude (implementation session), authorized by the user via explicit "install Flutter anyway, proceed carefully" approval after a reported hard-stop condition

### 2026-08-13 — Email verification (FR-104) API contract: invented, not discovered, with explicit user approval

**Sprint:** Phase 1 · Sprint 1
**Task ID:** Sprint 1, Task 14 (Email verification + password reset endpoints)
**Decision Summary:** No frozen document defines an email-verification endpoint, request/response shape, token table, or delivery mechanism anywhere. With the user's explicit sign-off, this session mirrors FR-105's (password reset's) fully-specified pattern exactly: `POST /auth/email/verify` (body `{token}`, public) and `POST /auth/email/resend` (authenticated, no body), backed by a new `email_verification_tokens` table shaped identically to `password_reset_tokens`.

**Background:**
FR-104 ("User can verify email") is a real, required entry in `docs/02-srs.md`'s functional requirements table and `docs/features/authentication.md`'s FR table. But checking every place an endpoint would be documented turned up nothing:
- `docs/05-api-specification.md` § 3 lists ten endpoints, including both password-reset ones (`POST /auth/password/forgot`, `POST /auth/password/reset`) — no email-verification endpoint.
- `docs/features/authentication.md` § APIs enumerates the same ten, verbatim.
- `docs/api-examples/auth.md` has no example for it (though, notably, it also has none for password reset, so this alone wasn't conclusive).
- `docs/04-database-design.md` § 3.1 specifies `password_reset_tokens` column-by-column (`email` PK, `token_hash` CHAR(64), `expires_at`) but no equivalent table for verification tokens.
- `docs/08-mobile-architecture.md` has no deep-link or verification-link scheme documented anywhere.

This is a genuine, consistent gap across every document that would define it — not a contradiction between two docs that disagree, and not a minor unspecified detail like an exact token byte-length. It's the complete absence of an API contract for a required feature, which the session's own instructions treat as a stop-and-report condition rather than something to quietly infer. Stopped and asked the user before writing any endpoint code.

**Alternatives Considered:**
- Silently invent a contract and proceed — rejected outright per this session's explicit instruction not to invent the API; the user needed to be the one to decide, not have a decision made for them.
- Implement password reset only, defer email verification entirely — offered as an option; not chosen.
- Ask the user to specify the exact contract themselves — offered as an option; not chosen (they instead approved the recommended default below).
- Mirror the password-reset pattern exactly (chosen, user-approved) — password reset is the closest fully-specified sibling feature in the same document set, sharing the same shape (single-use, expiring, server-generated token delivered by email, consumed via a token in the request body). Reusing it introduces zero new architectural patterns.

**Final Decision:**
Built exactly as approved: `POST /auth/email/verify` (public — a user may not hold a fresh access token when clicking/entering the code, since the 60-minute token TTL exceeds the 15-minute access-token TTL) and `POST /auth/email/resend` (authenticated — only a logged-in user would need to re-request their own verification email; no email parameter, so no enumeration surface exists on this endpoint the way it would if it were public and email-keyed like `password/forgot`). Token: `Str::random(64)`, SHA-256-hashed at rest, 60-minute expiry (matching FR-105's documented value for the sibling feature, not independently specified), single-use (deleted on consumption), one live token per email (a new request overwrites any prior unused one).

**Reasoning:**
Given the user's approval, the goal was to introduce the smallest possible new surface area: no new token-security model, no new table shape, no new response envelope pattern — everything is a direct application of conventions this codebase already uses and has already security-reviewed for the sibling feature.

**Impact:**
If FR-104's contract is ever formally added to the frozen documentation, this implementation needs to be reconciled against it — flagged explicitly in `NEXT_TASK.md` and `DEVELOPMENT_LOG.md` so it isn't forgotten. `docs/api-examples/auth.md` has no worked example for either password reset or email verification; adding both would be a natural follow-up (documentation-only, not this session's scope).

**Related Files:**
- `backend/app/Modules/Auth/Models/EmailVerificationToken.php`
- `backend/app/Modules/Auth/Http/Controllers/AuthController.php` (`verifyEmail`, `resendVerification`)
- `backend/app/Modules/Auth/routes.php`
- `backend/database/migrations/2026_08_13_043805_create_email_verification_tokens_table.php`

**Related Documentation:**
- [SRS § 4.1](docs/02-srs.md#41-authentication--account-management) (FR-104)
- [API Specification § 3](docs/05-api-specification.md#3-authentication-flow) (documents FR-105's endpoints, silent on FR-104's)

**Git Commit:** `<pending — see this session's own report>`

**Author:** Claude (AI Software Engineer), Sprint 1 Session 6 — Email Verification & Password Reset

### 2026-08-13 — Password reset revokes every session, not just the current one

**Sprint:** Phase 1 · Sprint 1
**Task ID:** Sprint 1, Task 14 (Email verification + password reset endpoints)
**Decision Summary:** A successful `POST /auth/password/reset` revokes every one of the user's active refresh tokens across all devices/families, not just the session on the device that requested the reset.

**Background:**
No frozen document states what a password reset should do to existing sessions. The session's own instructions explicitly called this out as a "do not invent behavior" point requiring a documented decision either way.

**Alternatives Considered:**
- Preserve all existing sessions — rejected: a password reset is frequently triggered *because* the user suspects their account is compromised (or, conversely, an attacker who obtained the old password is the one being locked out by the legitimate user's reset); leaving old sessions alive defeats the point in both cases.
- Revoke only the family associated with whichever refresh token (if any) accompanies the reset request — not applicable: `POST /auth/password/reset` is unauthenticated by design (a reset token, not a session token, is the credential), so there is no "current session" to distinguish from the others in the first place.
- Revoke every active session across all devices (chosen) — matches this module's existing security posture: BR-3 already revokes an entire token family the instant reuse (a suspected-compromise signal) is detected. A password reset is at least as strong a signal, and the user can simply log back in on every device afterward — a minor inconvenience against a real security property.

**Final Decision:**
`AuthService::resetPassword()` row-locks and revokes every unrevoked `auth_refresh_tokens` row for the user (not just one family) inside the same transaction as the password change and token deletion, dispatching `SessionRevoked` for each only after commit — the same transaction-then-dispatch structure already established for `refresh()`/`revokeSession()`.

**Reasoning:**
Consistency with BR-3's existing "any compromise signal revokes sessions" precedent was preferred over inventing a *weaker* default no document asked for.

**Impact:**
A user resetting their password from one device is logged out of every device, including the one they used to request the reset — they must log back in afterward. This is standard behavior for this kind of flow industry-wide and is regression-tested (`PasswordResetTest.php`: "resetting the password revokes every active session across all devices").

**Related Files:**
- `backend/app/Modules/Auth/Services/AuthService.php` (`resetPassword`)
- `backend/tests/Feature/Auth/PasswordResetTest.php`

**Related Documentation:**
- [SRS § 6 Business Rules](docs/02-srs.md#6-business-rules) (BR-3)

**Git Commit:** `<pending — see this session's own report>`

**Author:** Claude (AI Software Engineer), Sprint 1 Session 6 — Email Verification & Password Reset

### 2026-08-12 — OAuth email-collision handling: link only on a provider-verified email, else refuse

**Sprint:** Phase 1 · Sprint 1
**Task ID:** Sprint 1, Task 12/13 (Google/Apple Sign-In)
**Decision Summary:** When a Google/Apple ID token's email matches an existing user's email, the accounts are linked (a new `oauth_identities` row is created for the existing user) only if the provider's token asserts `email_verified: true`. If the provider does not assert verification, the sign-in is refused with `409 conflict` rather than linked or silently duplicated.

**Background:**
`docs/features/authentication.md` Edge Cases documents: "User signs up with email, later attempts Google Sign-In using the same email → account is linked (matched by verified email) rather than creating a duplicate." The qualifier "verified" is doing real work here: `users.email` is `UNIQUE` (Database Design section 3.1), so a colliding email can never produce a genuine duplicate row regardless — the only question is whether to silently attach the new provider identity to the existing account. The frozen docs don't say what to do when the provider's own claim doesn't assert verification, so this required a judgment call rather than a literal restatement of the doc.

**Alternatives Considered:**
- Link on any email match, verified or not — rejected: would let anyone who can get *any* OAuth provider to issue them a token claiming a victim's email address (some providers allow unverified email claims, or an attacker-controlled provider account with a self-asserted, never-confirmed address) attach their provider identity to the victim's existing password-protected account, then sign in as that user going forward. This is a real account-takeover path, not a hypothetical.
- Refuse the sign-in entirely with no path forward — considered, but a flat refusal without explanation is worse UX than a specific, actionable `409 conflict` and doesn't change the security posture either way.
- Link only when the provider's token asserts `email_verified: true` (chosen) — the literal reading of the documented qualifier; the provider itself vouching for the email is exactly the kind of independent verification the rest of this module already leans on (Security Architecture: "never trusting client-asserted identity").

**Final Decision:**
`AuthService::resolveOAuthUser()` checks `$claims->emailVerified` before linking; if false and an existing user's email matches, throws `OAuthEmailConflictException` (409, `conflict`) instead of proceeding.

**Reasoning:**
This is the narrowest reading of "matched by verified email" that's still consistent with the schema's `UNIQUE` constraint (duplication was never on the table) and with the module's existing trust model (provider verification, not client assertion, is what's trusted). It fails closed on the ambiguous case rather than guessing toward the more permissive, more exploitable behavior.

**Impact:**
Affects both `POST /auth/oauth/google` and `POST /auth/oauth/apple` identically (shared logic in `AbstractOAuthIdTokenVerifier`/`AuthService::resolveOAuthUser`). A user who registered with email/password and wants to add Google/Apple sign-in on an account where the provider can't/won't assert email verification has no linking path yet — not a blocker for this session's scope (no such flow is documented), but worth knowing if a future "link a provider to my existing account" self-service feature is ever specified.

**Related Files:**
- `backend/app/Modules/Auth/Services/AuthService.php`
- `backend/app/Modules/Auth/Exceptions/OAuthEmailConflictException.php`
- `backend/tests/Feature/Auth/OAuthGoogleTest.php`, `OAuthAppleTest.php`

**Related Documentation:**
- [Authentication feature § Edge Cases](docs/features/authentication.md#edge-cases)
- [Database Design § 3.1](docs/04-database-design.md#31-identity--auth)

**Git Commit:** `<pending — see this session's Suggested Git Commit>`

**Author:** Claude (AI Software Engineer), Sprint 1 Session 5 — Session Management PR Review, Merge & OAuth Foundation

### 2026-08-12 — Reuse firebase/php-jwt for Google/Apple ID token verification (no new dependency)

**Sprint:** Phase 1 · Sprint 1
**Task ID:** Sprint 1, Task 12/13 (Google/Apple Sign-In)
**Decision Summary:** Server-side verification of Google/Apple ID tokens (signature against the provider's JWKS, issuer, audience, expiration) is implemented using `firebase/php-jwt` — already a project dependency for this app's own JWT access tokens — via its `JWK::parseKeySet()` support, rather than adding a dedicated OAuth/provider SDK.

**Background:**
System Architecture section 8 requires Google/Apple sign-in to be "verified server-side via provider public keys/tokeninfo endpoints, never trusting client-asserted identity," but doesn't name a library. Both providers' ID tokens are standard signed JWTs (RS256) verifiable against a published JWKS endpoint — this is a generic JWT+JWKS verification problem, not something inherently requiring a provider-specific SDK.

**Alternatives Considered:**
- `google/apiclient` (official Google API PHP client) — rejected: a large, general-purpose SDK for calling the entire Google API surface; using it only for ID token verification pulls in far more than needed for a single JWT-verification concern, mirroring the same "don't reinvent, but don't over-adopt" reasoning already applied to the JWT library choice in the Authentication Foundation session.
- A dedicated Apple Sign-In package — rejected: no comparably standard, widely-adopted one exists for Laravel/PHP the way `firebase/php-jwt` is already the de facto choice for JWT itself; Apple's ID token is a standard JWT, no Apple-specific parsing logic is actually required.
- Google/Apple's tokeninfo HTTP endpoints (send the raw token, provider verifies and echoes back claims) — rejected: an extra network round-trip on every single sign-in (vs. a locally cached JWKS), and functionally equivalent to what local JWKS verification already provides once the key set is cached.
- `firebase/php-jwt`'s existing `JWK::parseKeySet()` (chosen) — the library is already a dependency, already trusted (it verifies this app's own access tokens), and its JWK support handles exactly this case: decode against a `kid`-keyed set of provider-published public keys.

**Final Decision:**
`App\Modules\Auth\Services\HttpJwksProvider` fetches and caches each provider's JWKS (Redis, configurable TTL) and hands `JWK::parseKeySet()`'s output to `Firebase\JWT\JWT::decode()`. `AbstractOAuthIdTokenVerifier` (with `GoogleIdTokenVerifier`/`AppleIdTokenVerifier` subclasses) layers issuer/audience checks and claim extraction on top.

**Reasoning:**
Isolating this behind an `OAuthTokenVerifier` interface (mirroring how `TokenService` already isolates `firebase/php-jwt` for this app's own tokens) means swapping the underlying library later touches only these few classes, not the rest of the auth module — consistent with the precedent set by the original JWT-library decision.

**Impact:**
No new Composer dependency. Provider signing-key rotation is handled transparently (cached JWKS is re-fetched after TTL expiry, not hardcoded). `config/oauth.php` holds the provider client IDs (public, non-secret) and JWKS URLs; no client secret is required by this flow at all, since ID-token verification is asymmetric-key-based.

**Related Files:**
- `backend/app/Modules/Auth/Contracts/{JwksProvider,OAuthTokenVerifier}.php`
- `backend/app/Modules/Auth/Services/{HttpJwksProvider,AbstractOAuthIdTokenVerifier,GoogleIdTokenVerifier,AppleIdTokenVerifier}.php`
- `backend/config/oauth.php`

**Related Documentation:**
- [System Architecture § 8 Security Architecture](docs/03-system-architecture.md#8-security-architecture)
- [ADR-0005](docs/adr/0005-jwt-refresh-token-auth.md) (precedent for the `firebase/php-jwt` choice)

**Git Commit:** `<pending — see this session's Suggested Git Commit>`

**Author:** Claude (AI Software Engineer), Sprint 1 Session 5 — Session Management PR Review, Merge & OAuth Foundation

### 2026-08-11 — Map unmatched-route 404s to the standard error envelope

**Sprint:** Phase 1 · Sprint 1
**Task ID:** Sprint 1, Task 15 (Session/Device Management)
**Decision Summary:** Added a `NotFoundHttpException` render handler in `bootstrap/app.php`, alongside the existing `AppException`/`ValidationException`/`AuthenticationException`/`ThrottleRequestsException` handlers, so a request whose route parameter fails its constraint (e.g. `DELETE /auth/sessions/{deviceId}` with a non-numeric `deviceId`) returns the app's standard `{"error": {...}}` envelope instead of Laravel's default exception JSON.

**Background:**
Independently re-reviewing `feature/auth-session-management` before merge (per this session's explicit "verify all errors use the standard envelope" checklist item), live-tested `DELETE /api/v1/auth/sessions/abc` and `DELETE /api/v1/auth/sessions/-1` against the running dev app. `{deviceId}` is constrained with `->whereNumber()`, so a non-numeric or negative value never reaches `SessionController` at all — Laravel treats it as "no route matched" and throws `NotFoundHttpException` straight from the router, which is a different exception class than anything the existing exception-render closures handled. The response was Laravel's default JSON error shape (`{"message": ..., "exception": ..., "file": ..., "line": ..., "trace": [...]}`) — with `APP_DEBUG=true` in dev, this included full file paths and a stack trace in the HTTP response body.

**Alternatives Considered:**
- Leave as-is — rejected: this is a pre-existing gap in `bootstrap/app.php` (present since Authentication Foundation), but `feature/auth-session-management` is the first PR to add a route parameter a client could plausibly send malformed (every prior route was a fixed literal path), making it directly reachable and directly relevant to this endpoint's error-handling review.
- Validate `deviceId` inside `SessionController`/a Form Request instead of at the route level — rejected: the route-level `->whereNumber()` constraint already existed and is the correct place for this check (matches Laravel convention); the actual gap was the missing exception mapping, not the validation location.
- Add a `render()` closure for `NotFoundHttpException`, scoped to `api/*` requests, returning the standard `not_found` envelope (chosen) — the same pattern already established for every other exception type in this file; zero new abstractions.

**Final Decision:**
Added the closure exactly as described above, imported `Symfony\Component\HttpKernel\Exception\NotFoundHttpException`. Covers every unmatched API route app-wide (constrained route parameters and genuinely unknown paths alike), not just this one endpoint.

**Reasoning:**
The documented error taxonomy ([API Specification § 4](docs/05-api-specification.md#4-error-response-format)) already defines `404 not_found` as "Resource doesn't exist or isn't owned by the caller" — a client hitting this exception is functionally requesting a resource that doesn't exist (a malformed or negative ID can never resolve to a real device row), so mapping it to the same code is consistent with the existing taxonomy, not a new one. Fixing it in the shared exception handler (rather than working around it in `SessionController`) means every future route with a constrained parameter gets this for free.

**Impact:**
No API contract change for any currently-passing request. Regression-tested in `SessionTest.php` (malformed `deviceId` → `404 not_found`, standard envelope, no `exception`/`trace` keys). Establishes that `bootstrap/app.php`'s exception-render block is the definitive place to add handling for any future exception type that can surface at the API boundary.

**Related Files:**
- `backend/bootstrap/app.php`
- `backend/tests/Feature/Auth/SessionTest.php`

**Related Documentation:**
- [API Specification § 4](docs/05-api-specification.md#4-error-response-format)

**Git Commit:** `<pending — see this session's Suggested Git Commit>`

**Author:** Claude (AI Software Engineer), Sprint 1 Session 5 — Session Management PR Review, Merge & OAuth Foundation

### 2026-08-11 — Row-lock session revocation to close a rotate-vs-revoke race

**Sprint:** Phase 1 · Sprint 1
**Task ID:** Sprint 1, Task 15 (Session/Device Management)
**Decision Summary:** `AuthService::revokeSession()` now reads and revokes a device's active refresh token(s) inside a `DB::transaction()` with `lockForUpdate()`, matching the pattern already used by `refresh()`/`revokeFamily()`, instead of an unlocked read-then-update.

**Background:**
While writing the security review for `DELETE /auth/sessions/{deviceId}`, re-reading `revokeSession()` next to `refresh()` surfaced an inconsistency: `refresh()` row-locks the token it's about to rotate specifically because two requests can race on the same row (this is the documented reason the refresh-rotation session's transaction-bug fix mattered). `revokeSession()` had no equivalent protection — it read the device's currently-active tokens, then updated each one individually with no lock. A revoke racing a concurrent `refresh()` on the same device could read the token list just before `refresh()` rotates it: `refresh()`'s own locked transaction would win, replacing the row `revokeSession()` was about to revoke with a new, still-active one that `revokeSession()`'s already-fetched list never sees. The device session that DELETE was supposed to kill could survive the call.

**Alternatives Considered:**
- Leave as-is — rejected: this is a real, if narrow, timing window on a security-relevant operation (a revoke that doesn't reliably revoke), not a hypothetical.
- Optimistic locking (version column) — rejected: no `version`/`lock_version` column exists on `auth_refresh_tokens`, and adding one is a schema change outside this session's stated scope (no migration required for session management, per the frozen requirements).
- Row-lock with `lockForUpdate()` inside `DB::transaction()`, retried on deadlock (chosen) — the exact mechanism already established and tested for this same table in `refresh()`/`revokeFamily()`; no schema change, no new dependency, consistent with existing code.

**Final Decision:**
Wrapped the fetch-and-revoke loop in `DB::transaction($closure, 3)` with `lockForUpdate()` on the token query; `SessionRevoked` events are still dispatched only after the transaction commits (same reasoning as the refresh-rotation bug fix: throwing/dispatching inside the closure risks being undone by a rollback, so side effects happen after).

**Reasoning:**
This is the same concurrency-safety idiom already proven correct and tested for this table elsewhere in the module — reusing it here is consistency, not a new pattern. The alternative of leaving it unlocked would mean the newer, more security-sensitive endpoint (explicit user-initiated revocation) is *less* race-safe than the older rotation path, which is backwards.

**Impact:**
No API contract change, no schema change, no behavior change in the non-racing case (verified by the full existing + new Pest suite, 66/66 passing). Establishes that any future code touching `auth_refresh_tokens` writes should default to this lock-inside-transaction pattern rather than treating `refresh()`'s locking as a one-off.

**Related Files:**
- `backend/app/Modules/Auth/Services/AuthService.php`
- `backend/tests/Feature/Auth/SessionTest.php`

**Related Documentation:**
- [ADR-0005](docs/adr/0005-jwt-refresh-token-auth.md)
- [Database Design § 3.1](docs/04-database-design.md)

**Git Commit:** `<pending — see this session's Suggested Git Commit>`

**Author:** Claude (AI Software Engineer), Sprint 1 Session 4 — Refresh Token Rotation Merge & Session Management

### 2026-08-11 — JWT `did` (device id) claim for isCurrent

**Sprint:** Phase 1 · Sprint 1
**Task ID:** Sprint 1, Task 15 (Session/Device Management)
**Decision Summary:** Added an optional `did` (device id) custom claim to the access-token JWT payload, carried through to a transient (non-persisted) `User::$currentDeviceId` property on the resolved user, so `GET /auth/sessions` can compute the documented `isCurrent` field.

**Background:**
`docs/api-examples/auth.md`'s documented response shape for `GET /auth/sessions` includes `isCurrent: true/false` per session. Nothing about the existing JWT payload (`iss`, `sub`, `iat`, `exp` — see ADR-0005 and the original Authentication Foundation session) let a request be traced back to the device that issued it; `sub` identifies the *user*, not the device, and a user can have several concurrent devices. Without some way to identify the issuing device, `isCurrent` could not be computed at all.

**Alternatives Considered:**
- Look up the current device via the access token's `sub` (user id) plus request metadata (IP/User-Agent) — rejected: fragile and non-deterministic (multiple devices can share an IP; User-Agent strings aren't guaranteed unique or stable), and would require heuristics never specified anywhere in the frozen docs.
- Encode the device id in the *refresh* token instead and require the client to also send it to `/auth/sessions` — rejected: `GET /auth/sessions` is documented as taking only an `Authorization: Bearer` header (see `docs/api-examples/auth.md`), so requiring an additional client-supplied parameter would change the documented request contract, which this session's rules explicitly forbid inventing.
- Add a `did` claim to the access token JWT (chosen) — purely additive to the token's internal payload, invisible to the client (JWTs are opaque strings to consumers), doesn't touch the documented request or response contract of any endpoint, and is already available on every authenticated request without an extra lookup.

**Final Decision:**
`TokenService::issueAccessToken()` now accepts an optional `?int $deviceId` and includes it as `did` in the signed payload (via `array_filter`, so it's omitted entirely when null, keeping the claim backward-compatible with any already-issued tokens that predate this change). `AuthServiceProvider`'s `Auth::viaRequest('jwt', ...)` closure reads `$payload->did` and assigns it to a transient `$user->currentDeviceId` property — never persisted, scoped to the single request.

**Reasoning:**
This is internal token plumbing, not a documented API surface: no frozen document specifies what claims the JWT must or must not contain, only what the *decoded, authenticated identity* must support (ADR-0005). Adding a claim to satisfy an already-documented response field is filling an implementation gap, not inventing new functionality or contradicting frozen documentation — judged not to meet the session's "stop and report" bar for ambiguity, since it has no external API or security-model impact.

**Impact:**
Every call site that issues an access token (`register`, `login`, `refresh`) now passes the relevant `Device` id. Any future session touching token issuance should be aware `issueAccessToken()` takes a second parameter. No impact on token validation, expiry, or signature logic.

**Related Files:**
- `backend/app/Modules/Auth/Services/TokenService.php`
- `backend/app/Modules/Auth/AuthServiceProvider.php`
- `backend/app/Modules/Auth/Services/AuthService.php`
- `backend/app/Modules/Auth/Http/Resources/SessionResource.php`

**Related Documentation:**
- [ADR-0005](docs/adr/0005-jwt-refresh-token-auth.md)
- [API Examples § GET /auth/sessions](docs/api-examples/auth.md)

**Git Commit:** `<pending — see this session's Suggested Git Commit>`

**Author:** Claude (AI Software Engineer), Sprint 1 Session 4 — Refresh Token Rotation Merge & Session Management

### 2026-08-07 — JWT encode/decode library: firebase/php-jwt

**Sprint:** Phase 1 · Sprint 1
**Task ID:** Sprint 1, Task 9 (Authentication Foundation)
**Decision Summary:** Use `firebase/php-jwt` for RS256 JWT access token encode/decode, since ADR-0005 mandates custom JWT auth but doesn't name a library.

**Background:**
ADR-0005 explicitly rejects Laravel Sanctum and Passport in favor of custom JWT access tokens (RS256, 15-minute TTL) plus opaque rotating refresh tokens. The ADR specifies the token *design* but leaves the actual JWT encode/decode mechanism unspecified — implementing RS256 signing/verification by hand (base64url encoding, OpenSSL signature calls, timing-safe comparison) is exactly the kind of security-sensitive low-level code that should not be hand-rolled.

**Alternatives Considered:**
- Hand-rolled JWT encode/decode via raw `openssl_sign`/`openssl_verify` calls — rejected: reinventing a well-standardized, security-sensitive primitive for no benefit; higher risk of a subtle signature-verification bug.
- `lcobucci/jwt` — a capable alternative with a more object-oriented builder API, but heavier surface area than this project needs (just encode a claims array, decode and verify it).
- `firebase/php-jwt` (chosen) — minimal, widely-used (the de facto standard for exactly this use case in PHP), actively maintained, does one thing: `JWT::encode()`/`JWT::decode()` against a signing key and algorithm.

**Final Decision:**
Added `firebase/php-jwt` (^7.1) as a `require` dependency. `App\Modules\Auth\Services\TokenService` wraps it entirely — no other class touches the library directly.

**Reasoning:**
`firebase/php-jwt` is a pure encode/decode utility, not an auth framework — it doesn't reintroduce the session/route assumptions ADR-0005 explicitly moved away from when rejecting Sanctum/Passport. Isolating it behind `TokenService` means swapping it later (per ADR-0005's own "Future Review Criteria") only touches one class.

**Impact:**
Every future session issuing or validating access tokens (refresh-token rotation, OAuth login, any authenticated endpoint) depends on `TokenService`, not on `firebase/php-jwt` directly. The RS256 keypair is generated per-environment (see Security Review in this session's report) and never committed.

**Related Files:**
- `backend/composer.json`
- `backend/app/Modules/Auth/Services/TokenService.php`
- `backend/config/jwt.php`

**Related Documentation:**
- [ADR-0005](docs/adr/0005-jwt-refresh-token-auth.md)
- [Backend Architecture § 1](docs/07-backend-architecture.md#1-folder-structure)

**Git Commit:** `<pending — see this session's Suggested Git Commit>`

**Author:** Claude (AI Software Engineer), Sprint 1 Session 3 — Authentication Foundation
