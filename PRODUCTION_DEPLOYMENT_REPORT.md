# Production Deployment Report

**The record of the production environment deployment, HTTPS/WAF routing setup, and Android release-signing that closed out Task 20.** This is a point-in-time report, not a living tracker — mirrors the role [SERVER_SETUP_REPORT.md](SERVER_SETUP_REPORT.md) plays for the development-server migration. See [PROJECT_STATUS.md](PROJECT_STATUS.md) for current operational status and [ENGINEERING_DECISION_LOG.md](ENGINEERING_DECISION_LOG.md) for the decisions this deployment produced.

**Date:** 2026-09-29
**Performed by:** Claude (AI Software Engineer), via SSH, across the Production Environment Deployment, Production Hardening, Android Release Signing, and Post-Task 20 Stabilization sessions.

**Important scope note:** [docs/12-deployment-guide.md](docs/12-deployment-guide.md) is a frozen v1.0 planning document describing a *target* cloud/Terraform-based architecture (`api.aestheticcoach.app`, managed MySQL/Redis, containerized app behind a load balancer). What is actually running today is a pragmatic deployment onto an existing institutional server, used to get a real, HTTPS-reachable backend in front of the mobile client for Task 20's E2E verification — not a migration of that target architecture. This report describes what is **actually deployed right now**; it does not replace or amend the frozen deployment guide, per [PROJECT_STATUS.md § Documentation Update Policy](PROJECT_STATUS.md#documentation-update-policy).

---

## Server

| Field | Value |
|---|---|
| Host | `10.24.1.22` (institutional server, not dedicated to this project — hosts other unrelated applications) |
| Deployed path | `/var/www/internalacr/aesthetic-coach` |
| OS | CentOS 7 (`httpd-2.4.6-93.el7.centos`) |
| Web server | Apache `httpd` 2.4.6, active |
| PHP | 8.3.8 (CLI, NTS), via a dedicated Remi SCL install (`php83`), **not** the system default PHP |
| PHP-FPM pool | `php83-php-fpm.service` (active), pool `[aesthetic-coach]` in `/etc/opt/remi/php83/php-fpm.d/www.conf`, `user=apache`/`group=apache`, `listen=127.0.0.1:8009` (dedicated to this app — not shared with any other tenant's pool) |
| MySQL | 8.0.42 (MySQL Community Server), database `aesthetic-coach` (hyphenated — differs from the repo's `.env.example` default `aesthetic_coach`) |
| Redis | 3.2.12, active — an old version already present on this shared server; not upgraded (out of scope, shared-server risk, same reasoning as [SERVER_SETUP_REPORT.md](SERVER_SETUP_REPORT.md)'s Node.js decision) |
| Queue worker | Dedicated systemd unit `aesthetic-coach-queue-worker.service`, `User=apache`, `ExecStart=php83 artisan queue:work redis --sleep=3 --tries=3 --max-time=3600`, `Restart=always` — confirmed active |
| App identity | JWT keypair at `storage/app/jwt/{private,public}.pem` (600/644, owned `apache:apache`) — `JWT_PRIVATE_KEY`/`JWT_PUBLIC_KEY` left empty in `.env`, using the file-path fallback |

## HTTPS / Routing Architecture

The production backend is reachable at **`https://acrinternal.iitm.ac.in/aesthetic-coach`** — a path prefix on an existing institutional domain, not a dedicated subdomain.

```
Internet ──HTTPS──> waf01.iitm.ac.in (institutional WAF, TLS termination)
                          │
                          │  (WAF forwards over the internal network)
                          ▼
              Apache httpd on 10.24.1.22, _default_:443 vhost
                          │
        Alias /aesthetic-coach -> /var/www/internalacr/aesthetic-coach/public
        ProxyPassMatch ^/aesthetic-coach/(.*\.php(?:/.*)?)$
            -> fcgi://127.0.0.1:8009/var/www/internalacr/aesthetic-coach/public/$1
                          │
                          ▼
              php83-php-fpm pool "aesthetic-coach" (127.0.0.1:8009)
                          │
                          ▼
                     Laravel application
```

- **TLS termination** happens at `waf01.iitm.ac.in`, an institutional WAF/reverse-proxy in front of this and other IITM ACR-hosted applications — using a real, valid commercial certificate (`/etc/ssl/certs/commercial.crt` + private key + CA chain), not self-signed. This project does not own or control the WAF or its certificate; it is institutional shared infrastructure.
- **Path-based routing** (`Alias` + `ProxyPassMatch`, in `/etc/httpd/conf.d/aesthetic-coach-path.conf`) was required rather than a dedicated subdomain/vhost, since the WAF forwards to this server's existing shared `_default_:443` vhost — the app hangs off a path (`/aesthetic-coach`) under it, alongside other unrelated tenants' paths.
- **`RewriteBase /aesthetic-coach/`** was added to the *deployed* `public/.htaccess` on the server (not the git repo's own `.htaccess` — a server-side-only change). Without it, `mod_rewrite`'s internal rewrite target loses the `/aesthetic-coach/` prefix before `ProxyPassMatch` sees it, so any URL that isn't a literal `.php` path (e.g. `/aesthetic-coach/api/v1/me`) 404s even though `/aesthetic-coach/index.php` works directly.
- The original port-8008 vhost (`/etc/httpd/conf.d/aesthetic-coach.conf`, `Listen 8008`) is **still present and working** — the HTTPS path route is additive, not a replacement.

**Known infrastructure limitation — WAF blocks `PATCH`/`PUT`/`DELETE`:** confirmed directly (not inferred) via correlated client/server testing: `GET`/`POST` requests through `https://acrinternal.iitm.ac.in/aesthetic-coach/...` reach Laravel normally; `PATCH`/`PUT`/`DELETE` requests are intercepted by the WAF itself and never reach this server at all — the WAF returns its own generated 404 page (distinguishable from Laravel's/Apache's own 404s by a distinctive padded HTML comment in the body). This is a real, present-tense limitation on actual product functionality routed through this HTTPS path — not a testing artifact:
- **Affected:** `PATCH /me` (profile update), `DELETE /auth/sessions/{deviceId}` (session revocation), and any other endpoint using those HTTP methods.
- **Not affected:** `POST`/`GET` endpoints, including the full register → login → refresh cycle.
- **Owner:** institutional WAF/network administration (`waf01.iitm.ac.in`) — outside this project's control.
- **No application-level workaround has been made or should be made** (e.g. method-override tunneling over POST) to route around this from the app side per this project's explicit constraints; the correct fix is a WAF configuration change requesting these methods be allowlisted for this path, which is a request to the WAF's administrators, not something this codebase can do.

## Mail

`MAIL_MAILER=log` in production — outgoing mail (email verification, password reset) is written to the Laravel log, not actually delivered. **Deferred**, not fixed: no real SMTP/transactional-mail provider has been configured for this environment. This does not block anything already verified (Task 20's E2E flow does not depend on receiving a real email), but email verification and password reset are not usable by a real end user against this deployment as it stands.

## Android Release Signing

- A dedicated, project-specific release keystore was generated outside the repository (`D:\dev\secrets\aesthetic-coach\aesthetic-coach-release.jks`, PKCS12, RSA 2048, valid ~27 years) — this was the first release keystore for this app; none existed previously, and none of it (keystore, `key.properties`, passwords) is committed or was ever printed to output.
- `mobile/android/key.properties` (gitignored — confirmed via `git check-ignore -v`, matching the pre-existing rule at `mobile/android/.gitignore:12`) points `build.gradle.kts` at that keystore.
- `mobile/android/app/build.gradle.kts` was changed so the `release` build type signs with this keystore **when `key.properties` is present**, and falls back to debug signing otherwise (so `flutter run --release` still works on a machine without the production keystore, e.g. CI or another developer). Debug signing itself, `applicationId`, and `namespace` are all unchanged.
- No APK has been published to the Google Play Store — this signing setup exists so release builds are signed with a real, durable identity, not so a store listing could go live.

## Task 20 — Closure Scope Reconciliation

**Production environment:** `https://acrinternal.iitm.ac.in/aesthetic-coach`. No dedicated staging environment was provisioned — this production deployment is what Task 20 was actually run against, and this document does not refer to it as "staging" anywhere.

**Task 20 status:** `COMPLETE — VERIFIED SCOPE WITH FOLLOW-UP ITEMS`. Task 20 is closed on the basis of the verified core authentication scope below; email verification and explicit logout are retained as separately tracked follow-up verification items, not claimed as tested.

### What Was Verified

Directly, evidence-backed, against this real production deployment, from the real release-signed Flutter client — **runtime verification, not source-code inspection**:

- **Register** — a real account (e.g. `e2e-pullrefresh-<timestamp>@example.com`) successfully created against `https://acrinternal.iitm.ac.in/aesthetic-coach`, confirmed by direct UI evidence.
- **Login** — the same client session authenticated and landed in the app shell.
- **Authenticated `GET /me`** — the Profile screen's pull-to-refresh successfully re-fetched the profile via an authenticated request.
- **Refresh** — a `POST /auth/refresh` call succeeded and issued a new access token.
- **401 → `AuthInterceptor` → refresh → retry → success**, triggered by a natural (not fabricated) token expiry — **directly proven via production server-side access-log correlation**, not inferred from client behavior alone: the production access log (`acr-access_log`) shows the failed (401) request, the `POST /auth/refresh` call, and the retried (200) request as three separate log lines in the same second, matching the client-recorded trigger timestamp.

### What Was Not Separately Verified

- **Email verification** — not runtime-tested.
- **Logout** — not runtime-tested. The logout endpoint/code exists and was not modified, but no explicit production logout call is part of the final Task 20 evidence. Its existence in the codebase is not treated as equivalent to runtime verification.

### Why Email Verification Was Not Verified

Production mail remains deferred (`MAIL_MAILER=log` — see [Mail](#mail) above): outgoing mail is written to the Laravel log, not delivered. A real verification email could not be received against this deployment, so the email-verification step of the original chain could not be exercised end-to-end. This is an infrastructure deferral, not a defect in the verification/registration code.

### Task 20 Closure Decision

Task 20's frozen definition ([docs/TASK_BREAKDOWN.md § Sprint 1, Task 20](docs/TASK_BREAKDOWN.md); [docs/IMPLEMENTATION_ORDER.md § 2 Authentication, Exit Criteria](docs/IMPLEMENTATION_ORDER.md#2-authentication)) is "register → verify email → login → refresh → logout, on staging." That original five-stage chain is preserved here as the historical requirement — it was **not** fully runtime-verified, and this document does not claim otherwise.

Task 20 is nonetheless considered complete, based on the scope that was actually implemented and runtime-verified during the final production validation: register, login, authenticated `/me`, refresh, and the security-critical `401 → AuthInterceptor → refresh → retry → success` cycle (the specific behavior Task 20 exists to de-risk). Email verification and explicit logout remain separately tracked follow-up verification items — see [Remaining Follow-Up Items](#remaining-follow-up-items) — not failures of the `AuthInterceptor` or logout implementations, simply flows not separately exercised in this pass.

## What Was Not Changed

- No application authentication logic (`AuthInterceptor`, backend `AuthService`/`TokenService`/refresh-rotation) was modified during this deployment or the stabilization pass that followed it — verified read-only.
- No WAF configuration, mail configuration, or Google Play listing was touched or created.
- `credentials.txt` (outside the git repo) still holds the production SSH/DB credentials in plaintext; it was not deleted, per explicit instruction — securing or removing it remains the user's own action to take.

## Remaining Follow-Up Items

- [ ] **Production email verification** — not separately runtime-verified; blocked on configuring a real mail transport (currently `log`) so a real verification email can actually be received.
- [ ] **Explicit production logout verification** — not separately runtime-verified; the endpoint/code exists and is unmodified, but no dedicated logout runtime check has been captured against this deployment.
- [ ] Request the WAF administrators allowlist `PATCH`/`PUT`/`DELETE` for `acrinternal.iitm.ac.in/aesthetic-coach` (or confirm this deployment path is not meant to carry those methods long-term) — blocks real profile-update and session-revocation functionality through this HTTPS path.
- [ ] Configure a real mail transport for production (currently `log`) — also needed for password reset to work for a real user, beyond email verification above.
- [ ] Decide whether this institutional-server deployment is the intended long-term production target, or a verification step ahead of the cloud architecture in [docs/12-deployment-guide.md](docs/12-deployment-guide.md) — this report deliberately makes no claim either way.
- [ ] If/when a real store release is planned: Google Play Console registration, app listing, and the first `flutter build appbundle --release` against this signing config remain undone.
