# Infrastructure Readiness Checklist

**Everything required before writing the first line of code.** Every item below has its **Configured** status left unchecked deliberately — this document is a checklist to work through, not a record of what's already done. Update the Configured column as each item is provisioned; see [FIRST_IMPLEMENTATION_SESSION.md § Required Credentials](FIRST_IMPLEMENTATION_SESSION.md#required-credentials) for which of these are needed for session one specifically versus later in Sprint 1.

---

## Table of Contents
- [Development Machine](#development-machine)
- [Local Services](#local-services)
- [Third-Party Credentials](#third-party-credentials)
- [Platform & Distribution Accounts](#platform--distribution-accounts)
- [Infrastructure & Environment](#infrastructure--environment)
- [How to Update This Document](#how-to-update-this-document)

## Development Machine

| Item | Purpose | Required | Optional | Configured | Notes |
|---|---|---|---|---|---|
| PHP | Backend runtime | ✅ | | ☐ | Version per [Backend Architecture](docs/07-backend-architecture.md) — PHP 8.3+ |
| Composer | PHP dependency management | ✅ | | ☐ | |
| Flutter SDK | Mobile runtime/toolchain | ✅ | | ☐ | Latest stable, per [Mobile Architecture](docs/08-mobile-architecture.md) |
| Android Studio | Android build/emulator tooling | ✅ | | ☐ | Needed for Android builds and emulator testing |
| Xcode | iOS build/simulator tooling | ✅ | | ☐ | macOS only — required for iOS builds even if primary dev machine is not a Mac (a Mac build machine/CI runner is still needed) |
| Docker Desktop | Local dev environment ([Deployment Guide § 2](docs/12-deployment-guide.md#2-development-environment)) | ✅ | | ☐ | |
| Git | Version control | ✅ | | ☐ | |
| Node / npm | Frontend tooling (asset pipeline, some CI tooling) | ✅ | | ☐ | |
| Laravel Installer | Convenience CLI for project scaffolding | | ✅ | ☐ | `composer create-project` works without it |
| MySQL client (CLI or GUI) | Direct DB inspection during development | | ✅ | ☐ | Docker-provided MySQL is sufficient without a separate local install |
| Redis client (CLI or GUI) | Direct cache/queue inspection | | ✅ | ☐ | Same — Docker-provided Redis is sufficient |

## Local Services

Provisioned via `docker-compose.yml` per [Deployment Guide § 2](docs/12-deployment-guide.md#2-development-environment) and [GIT_INITIALIZATION.md § Initial Repository Setup](GIT_INITIALIZATION.md#initial-repository-setup) — not separately installed on the host machine:

| Item | Purpose | Required | Optional | Configured | Notes |
|---|---|---|---|---|---|
| MySQL 8 | Primary datastore | ✅ | | ☐ | Via Docker Compose |
| Redis | Cache, queues, rate limiting | ✅ | | ☐ | Via Docker Compose |
| Mailhog | Local email capture (verification, password reset) | ✅ | | ☐ | Via Docker Compose |

## Third-Party Credentials

Needed at different points in [Sprint 1](docs/16-development-roadmap.md#phase-1--sprint-1--infrastructure-authentication--project-setup) and beyond — see the **Notes** column for when each is actually required, not just whether it's required eventually:

| Item | Purpose | Required | Optional | Configured | Notes |
|---|---|---|---|---|---|
| Google OAuth Credentials | Google Sign-In ([Authentication feature](docs/features/authentication.md)) | ✅ | | ☐ | Needed by Sprint 1, Task 12 |
| Apple Sign-In Credentials | Apple Sign-In ([Authentication feature](docs/features/authentication.md)) | ✅ | | ☐ | Needed by Sprint 1, Task 13; requires an active Apple Developer account first |
| Claude API Key (production) | AI Coaching Engine ([AI Coaching Engine](docs/09-ai-coaching-engine.md)) | ✅ | | ☐ | Needed by Sprint 5; **distinct from any developer's personal Claude subscription** — see [Production Hardening § Secrets Management](docs/14-production-hardening.md#3-encryption--secrets-management) |
| Firebase Project | Push notifications (FCM), potentially crash reporting | ✅ | | ☐ | Needed by Sprint 5 (notifications); set up earlier if also using Firebase for crash reporting per [Monitoring & Logging § 6](docs/13-monitoring-logging.md#6-crash-reporting) |
| Apple Push Notification (APNs) key | iOS push notifications | ✅ | | ☐ | Needed by Sprint 5; requires Apple Developer account |
| Android Signing Key | Signed release builds | ✅ | | ☐ | Needed by Sprint 7 (or earlier for internal test track builds) — generate and back up securely, losing it blocks all future updates to a published app |
| SSL Certificates | HTTPS for staging/production | ✅ | | ☐ | Typically automated via Let's Encrypt/ACM per [Deployment Guide § SSL](docs/12-deployment-guide.md#6-ssl) — manual provisioning only if the hosting provider doesn't automate it |

## Platform & Distribution Accounts

| Item | Purpose | Required | Optional | Configured | Notes |
|---|---|---|---|---|---|
| Apple Developer Account | iOS builds, Sign in with Apple, App Store distribution | ✅ | | ☐ | Paid annual membership; needed before Apple Sign-In credentials can be generated |
| Google Play Console | Android app distribution | ✅ | | ☐ | One-time registration fee |
| Apple App Store Connect | iOS app distribution, TestFlight | ✅ | | ☐ | Included with Apple Developer Program membership |
| Git hosting (e.g., GitHub) | Repository, CI/CD, PR review | ✅ | | ☐ | Needed before [GIT_INITIALIZATION.md](GIT_INITIALIZATION.md) can be executed |
| Cloud/hosting provider account | Staging + production infrastructure | ✅ | | ☐ | Per [Deployment Guide § 3](docs/12-deployment-guide.md#3-staging--production-infrastructure) |
| Container registry | Hosting built backend images | ✅ | | ☐ | If deploying via pushed images, per [Deployment Guide § 4](docs/12-deployment-guide.md#4-docker) |
| Analytics vendor account | Product analytics ([Analytics & Events](docs/analytics-events.md)) | | ✅ | ☐ | Vendor not yet selected — see [MASTER_IMPLEMENTATION_PLAN.md § Open Decisions](MASTER_IMPLEMENTATION_PLAN.md#open-decisions); not required for Phase 1 code to function |

## Infrastructure & Environment

| Item | Purpose | Required | Optional | Configured | Notes |
|---|---|---|---|---|---|
| Environment Variables (dev) | Local `.env` per [Deployment Guide § 2](docs/12-deployment-guide.md#2-development-environment) | ✅ | | ☐ | `.env.example` is committed; real `.env` is git-ignored — never commit real values |
| Environment Variables (staging) | Staging secrets | ✅ | | ☐ | Injected via platform secret store, per [Production Hardening § Secrets Management](docs/14-production-hardening.md#3-encryption--secrets-management) — never a checked-in file |
| Environment Variables (production) | Production secrets | ✅ | | ☐ | Same mechanism as staging, fully independent values — see [Production Hardening § 3](docs/14-production-hardening.md#3-encryption--secrets-management) |
| CI/CD secrets (GitHub Actions or equivalent) | Pipeline access to deploy targets | ✅ | | ☐ | Per [CI/CD Pipeline](docs/11-cicd-pipeline.md) |
| Backup storage / object storage (S3-compatible) | Progress photos, exports, database backups | ✅ | | ☐ | Per [Database Design § 7](docs/04-database-design.md#7-backup--restore-strategy) and [Progress Photos feature](docs/features/progress-photos.md) |

## How to Update This Document

- Check the **Configured** box only once an item is genuinely provisioned and verified working — not "created but untested."
- Add a note (date, who configured it) in the **Notes** column when checking a box, so there's a record beyond a bare checkmark.
- This document doesn't need per-session updates like [DEVELOPMENT_LOG.md](DEVELOPMENT_LOG.md) — update it when an infrastructure item's status actually changes, and reference the relevant [TASK_BREAKDOWN.md](docs/TASK_BREAKDOWN.md) task in the commit that configures it.
- If a new dependency is discovered mid-implementation that isn't listed here, add it — this list reflects the frozen v1.0 documentation's known requirements and may not be perfectly exhaustive.
