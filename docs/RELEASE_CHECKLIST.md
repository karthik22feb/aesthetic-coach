# Release Checklist

**Product:** Aesthetic Coach — Phase 1 (`v1.0.0`) Production Readiness
**Purpose:** the complete, single-page checklist gating a production release. Every item cross-references the document that defines *how* to satisfy it — this checklist is the aggregation and sign-off surface, not a duplicate specification.
**Related documents:** [TASK_BREAKDOWN.md § Sprint 6–7](TASK_BREAKDOWN.md#sprint-6--testing-performance--security) (when these items get built) · [Testing Strategy](10-testing-strategy.md) · [Production Hardening](14-production-hardening.md) · [Deployment Guide](12-deployment-guide.md)

## Table of Contents
- [Backend](#backend)
- [Flutter](#flutter)
- [Security](#security)
- [QA](#qa)
- [Production](#production)
- [App Store](#app-store)
- [Sign-off](#sign-off)

## Backend

- [ ] All Phase 1 API endpoints implemented and matching [API Specification § 6](05-api-specification.md#6-endpoint-reference) exactly, including the [§ 9 Phase Allocation](05-api-specification.md#9-phase-allocation) tags (Phase 2 endpoints feature-flagged dark, not publicly reachable)
- [ ] Queues: all three named queues (`default`, `ai-heavy`, `notifications`) configured and workers running — [Backend Architecture § 4](07-backend-architecture.md#4-queues)
- [ ] Scheduler: every scheduled task in [Backend Architecture § 6](07-backend-architecture.md#6-scheduled-tasks-routesconsolephp--scheduler) is registered and confirmed running in staging (DFS computation, Weekly Review, token/account cleanup jobs)
- [ ] Migrations: full migration set applies cleanly to an empty database; expand/contract discipline followed for every altering migration — [Database Design § 6](04-database-design.md#6-migration-strategy)
- [ ] Reference data seeded in production (exercises, foods, achievement catalog) via the idempotent seeders — never demo/user data — [Database Seeding](database-seeding.md)
- [ ] Cache (Redis) configured for exercise library, user profile summary, DFS-of-the-day per [System Architecture § Scalability Strategy](03-system-architecture.md#7-scalability-strategy)
- [ ] Structured JSON logging live with `requestId` propagation end-to-end — [Monitoring & Logging § 1 & § 7](13-monitoring-logging.md#1-observability-principles)
- [ ] Monitoring dashboards and alert rules provisioned as code and live — [Monitoring & Logging § 8–9](13-monitoring-logging.md#8-alerting)
- [ ] `/health` and `/health/deep` endpoints live and wired to the load balancer/orchestrator — [Monitoring & Logging § 5](13-monitoring-logging.md#5-health-checks)

## Flutter

- [ ] Android build: signed release AAB builds successfully via Fastlane — [CI/CD Pipeline § 5](11-cicd-pipeline.md#5-release-management--versioning)
- [ ] iOS build: signed release archive builds successfully via Fastlane
- [ ] Offline Support: full offline logging verified for Workout Tracking, Nutrition, and Habits per the [SRS § 7 canonical offline scenario](02-srs.md#7-acceptance-criteria-format) and [Testing Strategy § 6](10-testing-strategy.md#6-offline-sync-testing)
- [ ] Push notifications: registration, delivery, and deep-linking verified on both platforms — [Notifications feature](features/notifications.md)
- [ ] Accessibility: WCAG 2.1 AA-equivalent contrast verified per [UI/UX Design System § 8](06-ui-ux-design-system.md#8-accessibility); dynamic type tested up to 200%; screen reader pass on every primary screen
- [ ] Localization readiness: all user-facing strings externalized (even though Phase 1 ships English-only) per [SRS NFR-10](02-srs.md#5-non-functional-requirements)
- [ ] Cold start < 2.5s on a mid-tier Android device — [Performance Budget § App Startup](performance-budget.md#app-startup)
- [ ] Crash reporting SDK wired and verified (a test crash appears in the dashboard) — [Monitoring & Logging § 6](13-monitoring-logging.md#6-crash-reporting)

## Security

- [ ] JWT: access tokens ≤ 15 min TTL, signed RS256 — [System Architecture § 8](03-system-architecture.md#8-security-architecture)
- [ ] Refresh tokens: rotation + reuse detection verified with a dedicated test (BR-3) — [ADR-0005](adr/0005-jwt-refresh-token-auth.md)
- [ ] HTTPS/TLS 1.2+ enforced everywhere, HSTS enabled — [Deployment Guide § SSL](12-deployment-guide.md#6-ssl)
- [ ] Rate limiting active on auth and AI endpoints, verified by test — [API Specification § 7](05-api-specification.md#7-rate-limiting)
- [ ] Secrets: no secrets in source control; production secrets injected via the platform secret store, distinct from any developer's personal credentials — [Production Hardening § 3](14-production-hardening.md#3-encryption--secrets-management)
- [ ] Backups: automated, verified nightly (checksum/row-count restore drill) — [Production Hardening § 7](14-production-hardening.md#7-backup-verification)
- [ ] Full [Production Hardening § 1 Security Checklist](14-production-hardening.md#1-security-checklist) completed with zero open critical/high findings
- [ ] Cross-user IDOR test exists for every resource-scoped endpoint — [Testing Strategy § 5](10-testing-strategy.md#5-api-testing)

## QA

- [ ] Unit tests: all Services/Notifiers covered, DFS formula table-driven-tested across boundary values — [Testing Strategy § 3](10-testing-strategy.md#3-unit-testing)
- [ ] Integration tests: full offline-sync suite passes, including partial-batch-failure scenarios — [Testing Strategy § 6](10-testing-strategy.md#6-offline-sync-testing)
- [ ] Widget tests: every shared design-system component has a golden test in light + dark theme — [Testing Strategy § 4](10-testing-strategy.md#4-widget-testing)
- [ ] API tests: every endpoint has happy-path, validation, auth, cross-user-isolation, and idempotency coverage — [Testing Strategy § 5](10-testing-strategy.md#5-api-testing)
- [ ] Performance tests: k6 load test meets NFR-1 (API p95 < 300ms) and NFR-2 (AI first-token < 2s p95) — [Testing Strategy § 7](10-testing-strategy.md#7-performance-testing)
- [ ] AI smoke suite run against the real Claude API on a fixed prompt set, results reviewed manually — [Testing Strategy § 5](10-testing-strategy.md#5-api-testing)
- [ ] Adversarial/guardrail tests pass for every active AI capability — [AI Coaching Engine § 7](09-ai-coaching-engine.md#7-safety-guardrails)
- [ ] E2E device-lab suite passes on real devices (not just simulators) — [Testing Strategy § 8](10-testing-strategy.md#8-load-testing)

## Production

- [ ] Production infrastructure provisioned via infrastructure-as-code, matching staging topology — [Deployment Guide § 3](12-deployment-guide.md#3-staging--production-infrastructure)
- [ ] Deployment pipeline executes migrations as a pre-traffic step — [Deployment Guide § 8](12-deployment-guide.md#8-database-migrations-on-deploy)
- [ ] Rollback drill rehearsed successfully at least once before launch — [Deployment Guide § 10](12-deployment-guide.md#10-rollback-procedures)
- [ ] Monitoring dashboards live in production, not just staging — [Monitoring & Logging § 9](13-monitoring-logging.md#9-dashboards)
- [ ] Alert routing confirmed (a test alert actually pages/notifies the right channel) — [Monitoring & Logging § 8](13-monitoring-logging.md#8-alerting)
- [ ] Crash reporting confirmed live in the production build specifically (not just debug builds)
- [ ] `v1.0.0` tag created and annotated — [Release Management § Release Tags](git-workflow.md#release-tags)
- [ ] Post-launch monitoring watch scheduled for the first 24–48h — [MASTER_IMPLEMENTATION_PLAN.md § Deployment Checklist](../MASTER_IMPLEMENTATION_PLAN.md#deployment-checklist)

## App Store

### Google Play
- [ ] App listing created, correct category and content rating
- [ ] Data Safety form completed, matching actual data flows in [Database Design](04-database-design.md) and [Production Hardening § 9](14-production-hardening.md#9-compliance-considerations)
- [ ] Internal testing track validated before production track submission

### Apple App Store
- [ ] App Store Connect listing created
- [ ] App Privacy (nutrition label) disclosures completed, matching actual data flows
- [ ] TestFlight beta validated before App Store submission
- [ ] Sign in with Apple correctly implemented per Apple's guidelines (required if any other third-party login is offered) — [Authentication feature](features/authentication.md)

### Shared
- [ ] **Privacy Policy** published and linked from both store listings and in-app Settings
- [ ] **Terms of Service** published and linked from both store listings and in-app Settings
- [ ] **Screenshots** — current build, all required device sizes, both platforms
- [ ] **Icons** — all required resolutions, both platforms, matching [UI/UX Design System](06-ui-ux-design-system.md) branding
- [ ] **Descriptions** — store listing copy written, reviewed against [UI/UX Design System § 9 Content & Tone Guidelines](06-ui-ux-design-system.md#9-content--tone-guidelines)
- [ ] **Version numbers** — `1.0.0` set consistently across `pubspec.yaml`, Android `versionCode`/`versionName`, iOS build number, matching the tagged release
- [ ] **Release notes** — first-release notes written (what the app does, not a changelog, since this is `v1.0.0`)
- [ ] In-app help center content published — [User Documentation § 2–4](15-user-documentation.md#2-user-guide-help-center-article-outline)

## Sign-off

This checklist is complete when every box above is checked **and** the [Phase 1 Exit Criteria](PHASED_RELEASE_STRATEGY.md#exit-criteria-for-each-phase) that depend on it are independently confirmed. Record the sign-off (who, when, any accepted exceptions) in [MASTER_IMPLEMENTATION_PLAN.md](../MASTER_IMPLEMENTATION_PLAN.md) at the time of release — this document itself stays a reusable template for `v1.0.0` and every release after it, not a one-time record.
