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

### 2026-10-07 — Onboarding goal creation backed by a mock `GoalsApiClient`, not the real `POST /goals`

**Sprint:** Phase 1 · Sprint 2
**Task ID:** Sprint 2, Task 5 (Onboarding flow screens)
**Decision Summary:** The Goal Selection step's goal-creation call is implemented against a `GoalsApiClient` interface with two implementations: `GoalsApi` (real, written against the documented `POST /goals` contract, not currently wired up) and `MockGoalsApi` (a client-side stand-in, currently bound in `core/di/goals_providers.dart`). `MockGoalsApi` is deliberately deployed now because the real endpoint does not exist yet.

**Background:** docs/features/onboarding.md's APIs section documents the Goal Selection step as calling `POST /goals`, but that endpoint has never been built -- Sprint 2 Task 4 shipped only the `goals` migration and Eloquent model (backend/app/Modules/Goals/{Models,Enums}/*), with the full CRUD endpoint explicitly deferred to Sprint 4 per docs/TASK_BREAKDOWN.md's own note on that task. Nothing in the roadmap authorizes pulling that endpoint forward into Sprint 2 -- Task 4's scope note is explicit that it doesn't, and no later document revises that. This task's own instructions were to resolve the gap via "the project's approved mocked-response approach unless the existing roadmap clearly authorizes pulling the endpoint forward" -- the roadmap does not, so the mock path was the one actually available.

**Alternatives Considered:**
- Build a real `POST /goals` endpoint now, ahead of Sprint 4 -- rejected: the roadmap explicitly scopes that work to Sprint 4, and this task's own instructions require not doing this unless the roadmap "clearly authorizes" it, which it does not. Pulling backend work forward silently would also reopen the exact kind of unauthorized scope expansion this project's conventions already warn against.
- Have the Goal Selection step silently succeed in the UI without calling anything -- rejected: F-ONB-02 requires every user to end onboarding with a real seeded `goals` row (and the skip-default edge case specifically describes seeding one), so a true no-op would misrepresent what happened and leave nothing for a later session to find or correct.
- A mock implementation behind the same interface the real endpoint will eventually satisfy (chosen) -- directly mirrors this project's own established pattern for exactly this situation, docs/10-testing-strategy.md section 5's `FakeClaudeProvider implementing AiProviderInterface` (a fake behind the real interface, not a parallel code path) for AI endpoints that also aren't live yet.

**Final Decision:** `GoalsApiClient` (features/onboarding/data/goals_api.dart) is implemented twice: `GoalsApi` (real `POST /goals` call, written to the documented contract, ready to use) and `MockGoalsApi` (no network call, generates a client-side-only id, otherwise behaves identically). `core/di/goals_providers.dart` binds `MockGoalsApi` today; switching to the real backend once it ships is a one-line change in that file (swap the bound implementation), with no change needed in `GoalsRepository`, `OnboardingNotifier`, or any screen -- all of them depend on the interface, never on which implementation is wired up.

**Reasoning:** This keeps the onboarding flow fully functional and fully tested today without inventing unauthorized backend scope, and makes the eventual real-endpoint cutover a deliberately small, low-risk change rather than a rewrite.

**Impact:** Every goal a user "creates" during onboarding today is **not actually persisted to the real backend** -- it exists only as a `MockGoalsApi`-generated in-memory id for the duration of that app session. This is a real, user-facing limitation (not just an internal implementation detail) until Sprint 4's real endpoint is wired up, and should be called out explicitly if onboarding is ever demoed or tested against a real account expecting the goal to actually appear server-side later. Any future session wiring up the real `POST /goals` endpoint should start from `GoalsApi` (already written) and `core/di/goals_providers.dart` (the one line to change), not re-derive this from scratch.

**Related Files:**
- `mobile/lib/features/onboarding/data/goals_api.dart`
- `mobile/lib/core/di/goals_providers.dart`
- `mobile/lib/features/onboarding/data/goals_repository.dart`

**Related Documentation:**
- [docs/features/onboarding.md § APIs](docs/features/onboarding.md#apis)
- [docs/TASK_BREAKDOWN.md § Sprint 2](docs/TASK_BREAKDOWN.md#sprint-2--user-profile--ai-onboarding) (Task 4's scope note)
- [docs/10-testing-strategy.md § 5](docs/10-testing-strategy.md#5-api-testing) (the `FakeClaudeProvider` precedent this mirrors)

**Git Commit:** `<pending -- working tree changes not yet committed, see this session's report>`

**Author:** Claude (AI Software Engineer), Sprint 2 Task 5 implementation session

### 2026-10-07 — Onboarding entry trigger is session-only; full cross-restart resume deferred

**Sprint:** Phase 1 · Sprint 2
**Task ID:** Sprint 2, Task 5 (Onboarding flow screens)
**Decision Summary:** A user enters Onboarding only immediately after a fresh `register()` call in the current app session (`AuthState.justRegistered`, read by router.dart's redirect guard). This flag is in-memory only and is never persisted -- an app restart mid-onboarding lands the user on Home, not back in Onboarding, even if they hadn't finished.

**Background:** docs/features/onboarding.md's Edge Cases say a user who backgrounds the app mid-onboarding should resume "at the last completed step on relaunch," with progress persisted "server-side via the same `PATCH /me`/`POST /goals` calls, not a separate onboarding-state table." That description implicitly assumes some way to tell, on a later app launch, whether a given user still needs onboarding -- but no such signal exists anywhere in the documented API: there is no `GET /goals` (so goal existence can't be checked), and no onboarding-completion field on `/me` or anywhere else.

**Alternatives Considered:**
- Add a new field (e.g. an `onboardingCompleted` flag on `/me`, or a local `shared_preferences` marker) to make this resumable -- rejected without raising it first: this project's own established convention (see the 2026-08-13 Email Verification Contract entry in this log) is to stop and report a genuine, consistent documentation gap rather than silently inventing a new backend contract or a parallel client-side state mechanism the backend doesn't know about.
- Infer onboarding status from existing data (e.g., "has the user ever set a non-default timezone") -- rejected: unreliable (a user legitimately choosing the default value is indistinguishable from never having onboarded) and would be guessing at a contract, not implementing one.
- Trigger Onboarding only on a fresh, same-session registration, and explicitly flag full cross-restart resume as not yet implemented (chosen) -- the only option that adds no invented contract, reuses existing session-lifetime state (`AuthState`, already rebuilt fresh on every cold start), and is trivially extensible later once a real signal exists.

**Final Decision:** `AuthState.justRegistered` is set `true` only by `AuthNotifier.register()`'s success path, defaults `false` everywhere else (login, session restore, initial state), and is cleared by `AuthNotifier.clearJustRegistered()` once the Experience Level step's Finish action runs. Fully session-scoped; survives in-app navigation but not a process restart.

**Reasoning:** Shipping a flow that works correctly for the common case (a user completes onboarding in one sitting, which the NFR in docs/features/onboarding.md itself targets at "< 90 seconds median") without inventing scope is preferable to either blocking this task on a documentation gap or quietly building a parallel, undocumented persistence mechanism.

**Impact:** A user who closes the app before finishing onboarding currently lands on Home on their next launch, with onboarding never revisited -- a real, user-facing gap, not just an internal one. This should be resolved once there is a documented way to determine onboarding completion server-side (most naturally, once Sprint 4's real `POST /goals` ships alongside some way to read it back, or a dedicated decision is made to add an explicit completion flag). Flagged here and in this session's report rather than left to be rediscovered.

**Related Files:**
- `mobile/lib/features/auth/application/auth_state.dart`
- `mobile/lib/features/auth/application/auth_notifier.dart`
- `mobile/lib/app/router.dart`

**Related Documentation:**
- [docs/features/onboarding.md § Edge Cases](docs/features/onboarding.md#edge-cases)

**Git Commit:** `<pending -- working tree changes not yet committed, see this session's report>`

**Author:** Claude (AI Software Engineer), Sprint 2 Task 5 implementation session

### 2026-09-29 — Task 20 Closure Scope — Verified Core Authentication With Explicit Follow-Up Items

**Sprint:** Phase 1 · Sprint 1
**Task ID:** Sprint 1, Task 20 (closure scope reconciliation)
**Decision Summary:** Task 20 is closed (`COMPLETE — VERIFIED SCOPE WITH FOLLOW-UP ITEMS`) on the basis of its runtime-verified core authentication scope — register, login, authenticated `/me`, refresh, and the `401 → AuthInterceptor → refresh → retry → success` cycle — rather than its full original five-stage definition. Email verification and explicit logout are recorded as separately tracked follow-up verification items, not claimed as tested.

**Background:** Task 20's original frozen scope ([docs/IMPLEMENTATION_ORDER.md § 2, Exit Criteria](docs/IMPLEMENTATION_ORDER.md#2-authentication); [docs/TASK_BREAKDOWN.md § Sprint 1, Task 20](docs/TASK_BREAKDOWN.md)) is "register → verify email → login → refresh → logout, on staging." The final production validation session directly, runtime-verified register, login, authenticated `/me`, and refresh, with the security-critical `401 → AuthInterceptor → refresh → retry → success` cycle specifically proven via production server-log correlation. It did not separately exercise email verification (production mail is deferred, `MAIL_MAILER=log`, so no real verification email could be received) or an explicit logout call (the endpoint/code exists and is unmodified, but no dedicated runtime check was captured). Earlier documentation of this closure risked being read either too weakly (implying the `AuthInterceptor` work was unverified) or too strongly (implying the full five-stage chain was runtime-tested) depending on which paragraph a reader landed on — this entry and the accompanying documentation pass exist to remove that ambiguity.

**Alternatives Considered:**
- Reopen Task 20 and attempt to runtime-verify email verification and logout before closing it — rejected: explicitly out of scope for this reconciliation pass (a documentation-only task), and re-running production authentication tests was not requested; email verification specifically cannot be genuinely verified until a real mail transport is configured, which is its own separate, larger piece of work.
- Mark Task 20 as still open/blocked until all five original stages are verified — rejected: the two unverified stages are not blocked on anything this project can resolve quickly (email verification needs a real mail provider; logout needs only a short dedicated verification pass, not new development), and the stage that Task 20 exists to de-risk — the `AuthInterceptor`'s refresh behavior — is the one that has been most rigorously proven, via direct server correlation rather than inference.
- Describe Task 20 as fully complete without qualification (the wording risk this entry corrects) — rejected: would misrepresent the evidence and violate this project's explicit rule against manufacturing or overstating verification.
- Mark Task 20 complete with an explicit, itemized closure-scope statement and separately tracked follow-up items (chosen) — the most honest available option: closes a task whose core risk is genuinely retired, while keeping the two unverified stages visible and actionable rather than silently dropped.

**Final Decision:** Task 20 status is recorded as `COMPLETE — VERIFIED SCOPE WITH FOLLOW-UP ITEMS` everywhere it appears (`PROJECT_STATUS.md`, `MASTER_IMPLEMENTATION_PLAN.md`, `IMPLEMENTATION_PROGRESS.md`, `PRODUCTION_DEPLOYMENT_REPORT.md`), each with the same explicit verified/not-separately-verified breakdown. `PRODUCTION_DEPLOYMENT_REPORT.md § Task 20 — Closure Scope Reconciliation` is the canonical source for this breakdown; every other document cross-references it rather than restating it with different wording.

**Reasoning:** A task-closure status is only useful if it's precise enough to be acted on later — "complete" alone would have let a future reader assume logout and email verification are safe to build on top of without further checking, which isn't true yet. Naming the gap explicitly, without reopening the investigation to close it immediately, matches this project's standing principle (see [Change Management Process](PROJECT_STATUS.md#change-management-process)) that documentation should reflect what's actually known, not what's convenient to claim.

**Impact:** Any future session touching email verification or logout should treat them as unverified-in-production, not as "already covered by Task 20" — they remain real follow-up items ([PRODUCTION_DEPLOYMENT_REPORT.md § Remaining Follow-Up Items](PRODUCTION_DEPLOYMENT_REPORT.md#remaining-follow-up-items)). No code, test, or infrastructure changed as a result of this decision — it is a documentation/classification decision only.

**Related Files:**
- None (documentation-only; no application code affected)

**Related Documentation:**
- [PRODUCTION_DEPLOYMENT_REPORT.md § Task 20 — Closure Scope Reconciliation](PRODUCTION_DEPLOYMENT_REPORT.md#task-20--closure-scope-reconciliation)
- [docs/IMPLEMENTATION_ORDER.md § 2 Authentication](docs/IMPLEMENTATION_ORDER.md#2-authentication) (the original frozen exit criteria, preserved and cross-referenced, not rewritten)

**Git Commit:** `<pending — working tree changes not yet committed, see this session's report>`

**Author:** Claude (AI Software Engineer), Task 20 Final Scope Reconciliation session

### 2026-09-29 — WAF `PATCH`/`PUT`/`DELETE` block: no application-level workaround

**Sprint:** Phase 1 · Sprint 1
**Task ID:** Sprint 1, Task 20 (staging/production E2E verification)
**Decision Summary:** The institutional WAF fronting `https://acrinternal.iitm.ac.in/aesthetic-coach` blocks `PATCH`/`PUT`/`DELETE` HTTP methods entirely (confirmed via correlated client/server testing — these requests never reach Laravel). No application-side workaround (e.g. method-override tunneling over `POST`, or changing any endpoint's documented HTTP method) was made or is planned to route around this.

**Background:** `PATCH /me` and `DELETE /auth/sessions/{deviceId}` both stopped working through the new HTTPS path, initially appearing to be an application bug. Direct `curl` testing against the WAF, cross-referenced with the production access log, showed `GET`/`POST` pass through normally while `PATCH`/`PUT`/`DELETE` are intercepted by the WAF itself (a distinct WAF-generated 404 page, never reaching this server). This blocked the originally-planned Task 20 trigger (Edit Profile → Save, a `PATCH`), requiring a pivot to a `GET`-based trigger (Profile pull-to-refresh) to complete the `AuthInterceptor` verification at all.

**Alternatives Considered:**
- Tunnel `PATCH`/`PUT`/`DELETE` over `POST` with a method-override header/param (common workaround pattern) — rejected: this project's explicit constraints forbid bypassing the WAF in application code, and a method-override shim is exactly that kind of bypass; it would also mean every client and every future endpoint has to remember to use it for this one institutional deployment, silently diverging from the documented API contract.
- Change the documented HTTP methods for affected endpoints to `POST` — rejected: contradicts [API Specification § 2 Conventions](docs/05-api-specification.md#2-conventions) and would be an architecture-affecting API contract change made to accommodate one specific institutional deployment's network policy, not a real product requirement.
- Leave it blocked and request a WAF administrator change (chosen) — the correct owner for a network-layer policy is the network/WAF administrators, not this codebase; flagged as an explicit open infrastructure follow-up in [PRODUCTION_DEPLOYMENT_REPORT.md](PRODUCTION_DEPLOYMENT_REPORT.md) rather than worked around.

**Final Decision:** No code change. The limitation is documented as a real, present-tense gap in actual product functionality (not just a testing inconvenience) in [PRODUCTION_DEPLOYMENT_REPORT.md](PRODUCTION_DEPLOYMENT_REPORT.md), with the WAF administrators named as the sole owner of a fix.

**Reasoning:** Working around a network-security control from inside the application would both violate this task's explicit constraints and create a worse long-term outcome (a permanent, undocumented divergence between the real API contract and what actually works through this one deployment path) than accepting a documented, owned-elsewhere limitation.

**Impact:** Through this specific HTTPS path, profile updates and session revocation are currently non-functional for a real end user; every other flow (register, login, refresh, logout if implemented as `POST`, `GET`-based reads) is unaffected. Any future session touching this deployment should not attempt to "fix" this in application code — the fix is a WAF allowlist change, tracked as an open follow-up item.

**Related Files:**
- None (infrastructure/network policy, not repository code)

**Related Documentation:**
- [PRODUCTION_DEPLOYMENT_REPORT.md](PRODUCTION_DEPLOYMENT_REPORT.md)

**Git Commit:** N/A (infrastructure-only; no application code changed)

**Author:** Claude (AI Software Engineer), Production Flutter AuthInterceptor E2E Verification session

### 2026-09-29 — Profile pull-to-refresh added to make Task 20's `AuthInterceptor` trigger reachable

**Sprint:** Phase 1 · Sprint 1
**Task ID:** Sprint 1, Task 20 (staging/production E2E verification)
**Decision Summary:** Added a `RefreshIndicator`-based pull-to-refresh to the Profile screen (`mobile/lib/features/profile/presentation/profile_screen.dart`), calling `ProfileNotifier.loadProfile()` on pull, so `GET /me` could be re-triggered in-session to observe a natural 401→refresh cycle — without this, the WAF's `PATCH` block ruled out the originally-planned Edit Profile → Save trigger, and Riverpod's non-`.autoDispose` `NotifierProvider` caching meant simply revisiting the Profile screen made no new network call at all.

**Background:** Task 20 needed a way to force a real, in-session `GET /me` call once the access token had naturally expired, without restarting the app (which would just re-run session restoration rather than exercising the interceptor's live-401 path) and without fabricating a 401. Two options were presented to the user: request a WAF allowlist change for `PATCH`, or add a small pull-to-refresh affordance. The user explicitly chose pull-to-refresh.

**Alternatives Considered:**
- Request the WAF administrators allowlist `PATCH` so the original Edit Profile → Save trigger could be used — offered, not chosen (would have introduced an external dependency/wait on this task's critical path).
- Add pull-to-refresh to the Profile screen (chosen, user-directed) — a small, self-contained client-side addition with a legitimate product justification on its own merits (profile data can go stale without any refresh affordance at all today), not solely a test scaffold.

**Final Decision:** Implemented as permanent product code: `RefreshIndicator` wraps the loaded-state view, `AlwaysScrollableScrollPhysics` on the inner `ListView` so the pull gesture is always reachable, and a new widget test (`mobile/test/widget/profile_screen_test.dart`) asserting a fling-to-refresh triggers a second `getProfile()` call and the refreshed data renders.

**Reasoning:** Although this change originated from a testing need, it is not test-only scaffolding — no Profile screen anywhere in this codebase previously had any way to refresh server-side profile data without restarting the app, which is a real, independently-justifiable product gap. It stays in the codebase after Task 20 for that reason, not because it happens to have been useful for verification.

**Impact:** Every future session touching the Profile screen should treat pull-to-refresh as permanent product behavior, not diagnostic instrumentation — it is not scheduled for removal. `flutter analyze` clean; full `flutter test` suite (105/105) passing with the new test included.

**Related Files:**
- `mobile/lib/features/profile/presentation/profile_screen.dart`
- `mobile/test/widget/profile_screen_test.dart`

**Related Documentation:**
- [PRODUCTION_DEPLOYMENT_REPORT.md](PRODUCTION_DEPLOYMENT_REPORT.md)

**Git Commit:** `<pending — working tree changes not yet committed, see this session's report>`

**Author:** Claude (AI Software Engineer), Production Flutter AuthInterceptor E2E Verification session, per explicit user direction

### 2026-09-29 — Production mail transport deferred (`MAIL_MAILER=log`)

**Sprint:** Phase 1 · Sprint 1
**Task ID:** Sprint 1, Task 20 (production deployment)
**Decision Summary:** The production deployment at `10.24.1.22` runs with `MAIL_MAILER=log` — outgoing mail is written to the Laravel log, not delivered — rather than configuring a real SMTP/transactional-mail provider.

**Background:** No real mail-provider credentials (SMTP host, API key for a transactional provider, etc.) were supplied for this deployment, and this task's own instructions explicitly forbade inventing or configuring mail delivery without real details.

**Alternatives Considered:**
- Configure a real provider using placeholder/invented credentials so the deployment "looks" production-ready — rejected outright: would silently fail in a way that's hard to distinguish from a real outage, and violates the explicit "no falsely production-ready" constraint from the Production Hardening task.
- Leave `MAIL_MAILER=log` (chosen) — honest about the actual capability of this deployment: email verification and password reset requests succeed at the API level but no email is actually sent.

**Final Decision:** `MAIL_MAILER=log` in production `.env`. Documented as an open follow-up in [PRODUCTION_DEPLOYMENT_REPORT.md](PRODUCTION_DEPLOYMENT_REPORT.md), not silently left undocumented.

**Reasoning:** An explicitly deferred, documented limitation is safer than a falsely-configured one that could plausibly be mistaken for working mail delivery.

**Impact:** A real end user cannot complete email verification or receive a password-reset email against this deployment today. Does not affect Task 20's own verified scope (register/login/refresh), which does not depend on mail delivery.

**Related Files:**
- None (environment configuration, not repository code)

**Related Documentation:**
- [PRODUCTION_DEPLOYMENT_REPORT.md](PRODUCTION_DEPLOYMENT_REPORT.md)

**Git Commit:** N/A (environment-only, not a repository change)

**Author:** Claude (AI Software Engineer), Production Hardening session

### 2026-09-29 — Dedicated production queue worker via a native systemd unit, not Supervisor

**Sprint:** Phase 1 · Sprint 1
**Task ID:** Sprint 1, Task 20 (production deployment)
**Decision Summary:** The production queue worker (`php83 artisan queue:work redis`) runs under a dedicated systemd unit (`aesthetic-coach-queue-worker.service`, `User=apache`, `Restart=always`) created directly on `10.24.1.22`, rather than Supervisor (used on the separate dev server, per [SERVER_SETUP_REPORT.md](SERVER_SETUP_REPORT.md)) or Docker.

**Background:** This production server is a bare-metal institutional host with systemd already managing every other service on it (Apache, the dedicated `php83-php-fpm` pool, MySQL, Redis) — there was no existing Supervisor installation on this specific server, and introducing a second process-management tool for just this one worker would add an unnecessary dependency.

**Alternatives Considered:**
- Install Supervisor (matching the dev-server pattern) — rejected: this server already has systemd doing the same job for every other service; adding a second tool for one process is inconsistent with how the rest of this host is run.
- Run the worker manually/via `nohup` — rejected: no automatic restart on crash or reboot, unacceptable for a queue worker in any environment meant to be reachable, even a verification deployment.
- A dedicated native systemd unit (chosen) — matches this server's existing convention for every other long-running process, gets `Restart=always` and boot-time start for free, no new tooling.

**Final Decision:** `/etc/systemd/system/aesthetic-coach-queue-worker.service` created, enabled, and confirmed active.

**Reasoning:** Consistency with how this specific host already manages services outweighs matching the dev server's Supervisor convention — the two servers were never claimed to be identically configured, and each should use the process manager already idiomatic to it.

**Impact:** Any future production deployment session on this server should manage the queue worker via `systemctl`, not Supervisor. This is server-specific; it does not set a precedent for how a future dedicated/cloud production environment (per [docs/12-deployment-guide.md](docs/12-deployment-guide.md)) should run its workers.

**Related Files:**
- None (server-level configuration, not repository code)

**Related Documentation:**
- [PRODUCTION_DEPLOYMENT_REPORT.md](PRODUCTION_DEPLOYMENT_REPORT.md)

**Git Commit:** N/A (infrastructure-only)

**Author:** Claude (AI Software Engineer), Production Environment Deployment session

### 2026-09-29 — HTTPS via institutional WAF path-based routing, not a dedicated subdomain

**Sprint:** Phase 1 · Sprint 1
**Task ID:** Sprint 1, Task 20 (production deployment / HTTPS)
**Decision Summary:** Production HTTPS access is served at `https://acrinternal.iitm.ac.in/aesthetic-coach` — a path under an existing institutional domain, TLS-terminated by an institutional WAF (`waf01.iitm.ac.in`) using a real commercial certificate — rather than provisioning a dedicated subdomain/certificate for this project.

**Background:** The user directly asked whether using `https://acrinternal.iitm.ac.in/aesthetic-coach` instead of the plain server IP would resolve the app's HTTPS/cleartext-traffic problem. Investigation confirmed the institutional WAF already terminates TLS with a valid, trusted commercial certificate for that domain and could be configured to forward a path to this server — a materially faster path to real, trusted HTTPS than requesting a new dedicated domain and certificate.

**Alternatives Considered:**
- Self-signed certificate directly on `10.24.1.22` — rejected: would still require the mobile client to trust an untrusted CA (either bundling it or disabling certificate validation), which is a real security regression, not a genuine HTTPS solution.
- Request a dedicated subdomain + Let's Encrypt/ACM certificate, per [docs/12-deployment-guide.md § 6](docs/12-deployment-guide.md#6-ssl)'s frozen design — the eventual correct approach for a real production launch, but a separate provisioning request outside this task's scope and timeline.
- Path-based routing under the existing institutional domain/WAF (chosen, user-approved) — reuses already-trusted, already-terminated TLS with no new certificate request, at the cost of a URL path prefix (`/aesthetic-coach`) instead of a clean subdomain, and inheriting whatever policies the WAF enforces (see the separate `PATCH`/`PUT`/`DELETE` decision above).

**Final Decision:** `/etc/httpd/conf.d/aesthetic-coach-path.conf` (`Alias` + `ProxyPassMatch`) added on `10.24.1.22`, plus a server-side-only `RewriteBase /aesthetic-coach/` fix in the deployed `.htaccess`. Confirmed working end-to-end from the real release-signed Flutter client.

**Reasoning:** Given the user's explicit approval and the goal of getting Task 20 (real E2E verification) unblocked, reusing existing trusted infrastructure was the pragmatic choice — it does not preclude a proper dedicated-domain setup later for an eventual real public launch.

**Impact:** The app's production `API_BASE_URL` for this deployment is `https://acrinternal.iitm.ac.in/aesthetic-coach/api/v1/`, passed via `--dart-define` at build time (see [mobile/lib/core/network/api_config.dart](mobile/lib/core/network/api_config.dart) — mechanism unchanged). Inherits the institutional WAF's method-filtering policy as a real, documented constraint (see the WAF decision entry above). This is explicitly not claimed to be this project's final public production domain.

**Related Files:**
- None in the git repository (server-level Apache config)

**Related Documentation:**
- [PRODUCTION_DEPLOYMENT_REPORT.md](PRODUCTION_DEPLOYMENT_REPORT.md)
- [docs/12-deployment-guide.md § 6 SSL](docs/12-deployment-guide.md#6-ssl) (the frozen target design this deviates from, pragmatically, for now)

**Git Commit:** N/A (infrastructure-only)

**Author:** Claude (AI Software Engineer), per explicit user approval ("yes, proceed")

### 2026-09-29 — Production Android signing identity generated outside git, PKCS12 shared store/key password

**Sprint:** Phase 1 · Sprint 1
**Task ID:** Sprint 1, Task 20 (Android production release signing)
**Decision Summary:** A dedicated release keystore for this app (`aesthetic-coach-release.jks`) was generated on the local dev machine, stored entirely outside the git repository (`D:\dev\secrets\aesthetic-coach\`), and referenced from `mobile/android/app/build.gradle.kts` via a gitignored `key.properties`. Store and key passwords are the same value, because the modern PKCS12 keystore format `keytool` produces does not support them differing.

**Background:** No release keystore existed anywhere for this app before this session — every prior release build used debug signing (`TODO: Add your own signing config for the release build` in the original `build.gradle.kts`). The user explicitly authorized generating a brand-new dedicated keystore.

**Alternatives Considered:**
- Continue debug signing for release builds — rejected: explicitly disallowed by this task's own constraints, and debug-signed release builds cannot be the basis for any real distributed release.
- Commit the keystore or its passwords to the repository (even encrypted) — rejected outright per explicit constraint; secrets of this kind belong outside version control entirely, not in an encrypted-in-repo form.
- Request separate store/key passwords — not possible: `keytool -genkeypair` against a PKCS12-format keystore (the modern default, JKS being legacy/deprecated) silently ignores a distinct `-keypass` and uses the store password for both; this is a `keytool` constraint, not a choice made here.

**Final Decision:** Keystore generated once, stored outside the repo; `mobile/android/key.properties` (gitignored, confirmed via `git check-ignore -v`) holds `storePassword`/`keyPassword` (identical value)/`keyAlias`/`storeFile`; `build.gradle.kts` conditionally defines a `release` signing config only when that file is present, falling back to debug signing otherwise so the project still builds on any machine without the production keystore.

**Reasoning:** Keeping the keystore and its credentials entirely outside git, with a conditional fallback in the Gradle config, means no machine other than the one holding the keystore can produce a signature-matching release build — the correct security posture for a signing identity that (per Android's own model) can never be rotated once an app is published, while not breaking `flutter run --release` for anyone else on the team.

**Impact:** Every future release build must run on a machine with `mobile/android/key.properties` present and pointing at the real keystore file, or it will silently fall back to (unusable-for-release) debug signing — this fallback is intentional, not a bug, but worth knowing. `applicationId` (`com.aestheticcoach.aesthetic_coach`) and `namespace` are unchanged; no Play Store listing exists yet.

**Related Files:**
- `mobile/android/app/build.gradle.kts`
- `mobile/android/key.properties` (gitignored, not tracked)

**Related Documentation:**
- [PRODUCTION_DEPLOYMENT_REPORT.md](PRODUCTION_DEPLOYMENT_REPORT.md)

**Git Commit:** `<pending — working tree changes not yet committed, see this session's report>`

**Author:** Claude (AI Software Engineer), Android Production Release Signing session, per explicit user authorization

### 2026-09-29 — Root cause of "Unable to reach the server" (release builds): missing `INTERNET` permission, not the `--dart-define` mechanism

**Sprint:** Phase 1 · Sprint 1
**Task ID:** Sprint 1, Task 20 (staging/production E2E verification)
**Decision Summary:** `mobile/lib/core/network/api_config.dart`'s `--dart-define=API_BASE_URL=...` mechanism (added in an earlier session) was working correctly all along; the release-build-specific "Unable to reach the server" failures investigated across Tasks 20A/20B/20 had a second, independent root cause — `android.permission.INTERNET` was declared only in the debug-only manifest (for an unrelated reason: the Flutter tool's own hot-reload channel), never in the main manifest that release builds inherit. Fixed by adding the permission to `mobile/android/app/src/main/AndroidManifest.xml`; the `--dart-define` mechanism itself was left unchanged.

**Background:** Every prior debug-build test of this app worked, masking the missing permission, because the debug manifest happened to declare `INTERNET` for a completely unrelated reason. The first release build (once release signing existed) exposed the real gap. Diagnosis initially suspected Android's cleartext-traffic-blocked-by-default behavior for non-debuggable release builds targeting API 28+ — a plausible, investigated, but ultimately incorrect theory; the actual cause was confirmed by direct comparison of `aapt dump permissions` output between debug and release builds, which showed `INTERNET` present in one and absent in the other.

**Alternatives Considered:**
- Add a Network Security Config permitting cleartext traffic — would have been the fix for the cleartext theory, not this actual bug; not applied, since it wouldn't have fixed anything and would have added an unnecessary, unused config file.
- Move the `INTERNET` permission's declaration or duplicate it differently — rejected in favor of simply adding it to the main manifest (the correct, minimal fix): every build variant merges the main manifest, so this covers debug and release identically going forward; the debug manifest's own (harmless, narrower-reasoned) declaration was left in place rather than removed, since removing it isn't necessary and touches an unrelated concern (hot-reload).

**Final Decision:** `<uses-permission android:name="android.permission.INTERNET"/>` added to `mobile/android/app/src/main/AndroidManifest.xml`. No change to `api_config.dart`'s dart-define mechanism, dev default, or the fact that no host is ever hardcoded.

**Reasoning:** The two-root-cause structure (an earlier missing-`--dart-define` issue investigated in Tasks 20A/20B, and this independent missing-permission issue found only once a real release build existed) needs to be on record so a future session doesn't re-investigate a supposedly-still-broken `--dart-define` mechanism that was never actually the remaining problem.

**Impact:** Every release build produced before this fix (across this project's entire history) was silently unable to make any network call at all, regardless of how correctly `API_BASE_URL` was set. Any future permission-related "Unable to reach the server" symptom on a *release* build should check `aapt dump permissions` against both build variants before assuming it's a URL/dart-define problem.

**Related Files:**
- `mobile/android/app/src/main/AndroidManifest.xml`

**Related Documentation:**
- [mobile/lib/core/network/api_config.dart](mobile/lib/core/network/api_config.dart) (unchanged, confirmed correct)
- [PRODUCTION_DEPLOYMENT_REPORT.md](PRODUCTION_DEPLOYMENT_REPORT.md)

**Git Commit:** `<pending — working tree changes not yet committed, see this session's report>`

**Author:** Claude (AI Software Engineer), Task 20A/20B and Production Flutter AuthInterceptor E2E Verification sessions

### 2026-08-18 — Task 17-19 (mobile auth): continuing to defer riverpod_generator/freezed codegen

**Sprint:** Phase 1 · Sprint 1
**Task ID:** Sprint 1, Tasks 17-19 (Flutter Login/Signup screens, AuthInterceptor, secure token storage)
**Decision Summary:** The mobile auth module (AuthState, AuthNotifier, AuthRepository, AuthTokens/AuthUser/AuthSession models) is implemented with hand-written `Notifier` classes and plain immutable Dart classes (manual `==`/`hashCode`/`fromJson`), not `riverpod_generator`'s `@riverpod` codegen or `freezed`, despite [ADR-0004](docs/adr/0004-riverpod-for-state-management.md) explicitly naming `flutter_riverpod` + `riverpod_generator` as the accepted decision.

**Background:**
The Flutter foundation session (Tasks 5-7) already deferred `riverpod_generator` once, but that was defensible at the time because no real business-logic providers existed yet — the deferral was never actually exercised against a provider that mattered. This session is the first to add real state (`AuthNotifier`, cross-cutting DI wiring in `core/di/network_providers.dart`) where ADR-0004's codegen recommendation is directly relevant, so the deferral needed to be an explicit, reconsidered choice rather than silent inertia.

**Alternatives Considered:**
- Adopt `riverpod_generator` + `build_runner` now, matching ADR-0004 exactly — the architecturally "correct" choice, and genuinely low system-resource risk (pure Dart/pub tooling, no new `apt` packages, unlike the Linux-desktop-build-toolchain question from the previous session). Not chosen this session primarily for iteration-speed reasons: this task already involves writing ~20 new files with many rounds of `flutter analyze`/`flutter test` verification over SSH, and adding a code-generation step (requiring a `dart run build_runner build` re-run after every model/provider edit, checked over the same SSH round-trip) would have materially slowed an already-large session.
- Continue hand-written `Notifier`s and plain classes (chosen) — fully valid Riverpod usage (same `Notifier`/`AsyncNotifier` base classes ADR-0004 specifies, same no-`get_it`-service-locator DI principle), just without the `@riverpod` annotation macro's boilerplate reduction. No parallel architecture was introduced; this is a strict subset of the documented approach.

**Final Decision:**
Hand-written `Notifier` classes and plain immutable Dart classes continue through Task 17-19. `riverpod_generator`/`freezed`/`build_runner` were not added to `mobile/pubspec.yaml`.

**Reasoning:**
The resource/session-scope trade-off outweighs strict ADR conformance for now, and the deviation is a strict subset (less boilerplate reduction, not a different pattern) rather than a competing architecture — low risk to reconcile later.

**Impact:**
Every future Flutter session adding Riverpod providers or JSON models inherits this same hand-written convention until reconsidered. If a future session finds the boilerplate genuinely painful (e.g., once `workouts`/`nutrition`/`habits` features multiply the number of providers and DTOs), revisit adopting `riverpod_generator`/`freezed` in one dedicated pass rather than mixing conventions mid-module.

**Related Files:**
- `mobile/lib/features/auth/application/auth_notifier.dart`, `auth_state.dart`
- `mobile/lib/features/auth/data/models/*.dart`
- `mobile/lib/core/di/network_providers.dart`

**Related Documentation:**
- [ADR-0004](docs/adr/0004-riverpod-for-state-management.md)
- [Mobile Architecture § 1](docs/08-mobile-architecture.md#1-state-management)

**Git Commit:** `<pending — see this session's own report>` on `feature/mobile-auth`

**Author:** Claude (mobile auth implementation session)


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
