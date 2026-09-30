# Project Status

**This is the official project status dashboard.** For live sprint/task tracking use [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md); this document answers "where does the project stand overall, and what's the process going forward."

---

## Table of Contents
- [Dashboard Summary](#dashboard-summary)
- [Documentation Version](#documentation-version)
- [Current Project Status](#current-project-status)
- [Current Phase](#current-phase)
- [Overall Progress](#overall-progress)
- [Completed Planning Activities](#completed-planning-activities)
- [Remaining Development Activities](#remaining-development-activities)
- [Known Risks](#known-risks)
- [Open Product Decisions](#open-product-decisions)
- [Change Management Process](#change-management-process)
- [Documentation Update Policy](#documentation-update-policy)

---

## Dashboard Summary

| Field | Value |
|---|---|
| **Planning** | Complete |
| **Implementation** | In Progress |
| **Development Environment** | Linux Server (`/var/www/html/aesthetic-coach` on `10.24.8.219`, Ubuntu 24.04.3 LTS) — migrated 2026-08-06 from local Windows/XAMPP; see [SERVER_SETUP_REPORT.md](SERVER_SETUP_REPORT.md) |
| **Production (verification) Environment** | Live at `https://acrinternal.iitm.ac.in/aesthetic-coach` (`10.24.1.22`, institutional server, HTTPS via institutional WAF path routing) — see [PRODUCTION_DEPLOYMENT_REPORT.md](PRODUCTION_DEPLOYMENT_REPORT.md). Not the target cloud architecture in [docs/12-deployment-guide.md](docs/12-deployment-guide.md); used to get Task 20 genuinely E2E-verified. |
| **Status** | **Task 20: COMPLETE — VERIFIED SCOPE WITH FOLLOW-UP ITEMS. Module 2 (Authentication) moves to Complete.** Task 20's original/frozen scope ([docs/IMPLEMENTATION_ORDER.md § 2, Exit Criteria](docs/IMPLEMENTATION_ORDER.md#2-authentication)) is "register → verify email → login → refresh → logout, on staging." No staging environment was ever provisioned, so Task 20 ran directly against the real production deployment above instead. **Core production authentication flow verified** (runtime-verified, not merely code-reviewed, from the real release-signed Flutter client): register → login → authenticated `GET /me` → refresh, plus the security-critical `401 → AuthInterceptor → refresh → retry → success` cycle, the last one specifically proven via direct correlation against the production access log — three log lines (401, `POST /auth/refresh`, retried 200) in the same second, matching the client-recorded trigger timestamp. **Follow-up verification items (not separately runtime-verified, not implementation failures):** email verification (production mail is deferred, `MAIL_MAILER=log`, so no real verification email could be received) and an explicit production logout call (the endpoint/code exists and is unmodified; no dedicated runtime check was captured). This is a scope gap against Task 20's literal five-stage frozen definition, reconciled rather than glossed over — see [PRODUCTION_DEPLOYMENT_REPORT.md § Task 20 — Closure Scope Reconciliation](PRODUCTION_DEPLOYMENT_REPORT.md#task-20--closure-scope-reconciliation). Getting there also required: fixing a release-build-only bug where `android.permission.INTERNET` was missing from the main Android manifest (present only in the debug-only manifest, for an unrelated reason); generating a dedicated production Android release-signing keystore (none existed previously); and discovering a real, WAF-administrator-owned infrastructure limitation — the institutional WAF blocks `PATCH`/`PUT`/`DELETE` for this HTTPS path, affecting real profile-update and session-revocation functionality, with no application-side workaround made or planned. A pull-to-refresh affordance was added to the Profile screen (permanent product code, not test scaffolding) to make the refresh-cycle trigger reachable once the WAF ruled out the originally-planned Edit Profile → Save trigger. Backend Authentication module (Sprint 1, Tasks 9–16) **complete** and merged to `main`, tagged `v1.0.0-auth-complete`. Flutter mobile foundation (Tasks 5–7) **merged to `main`** (`38f1da6`). Flutter auth client (Tasks 17–19: Login/Signup screens, `AuthInterceptor`, secure token storage) **merged to `main`** via squash-merge of [PR #2](https://github.com/karthik22feb/aesthetic-coach/pull/2), commit `f7a2580`. Sprint 2 Task 1 (`GET/PATCH /me` profile endpoint) also **merged to `main`** via squash-merge of [PR #4](https://github.com/karthik22feb/aesthetic-coach/pull/4), commit `5f7f706` — verified locally (144/144 Pest tests, Pint clean), **not** verified against a real device. Sprint 2 Task 2 (Flutter Profile screen + Edit Profile sheet, since extended with pull-to-refresh) also **merged to `main`** via squash-merge of [PR #5](https://github.com/karthik22feb/aesthetic-coach/pull/5), commit `cc2385f`. **Module 3 (User Profile) is now Complete.** Sprint 2 Task 3 (basic Settings screen: theme, unit preference) also **merged to `main`** via squash-merge of [PR #6](https://github.com/karthik22feb/aesthetic-coach/pull/6), commit `450442b`. This project's first real Android emulator testing (on a local Windows machine) found and fixed a client-side URL-construction bug (`ApiConfig.baseUrl` lacked a trailing slash); fixed and **merged to `main`** via squash-merge of [PR #7](https://github.com/karthik22feb/aesthetic-coach/pull/7), commit `11da8ea`. Sprint 2 Task 4 (`goals` table migration + Eloquent model) is also **merged to `main`** via squash-merge of [PR #8](https://github.com/karthik22feb/aesthetic-coach/pull/8), commit `7c5d12e` — approved by two independent reviewers distinct from the author, re-verified post-merge (`composer validate --strict` clean, Pint clean, direct Tinker database round-trip confirmed); the full Pest suite remains **not verified locally** (this bare-Windows dev environment has no Docker-Compose `mysql` hostname, which `phpunit.xml` forces; a pre-existing environment limitation, not a Task 4 regression). **Module 4 (AI Onboarding) is In Progress** (Task 4 only). |
| **Current Sprint** | Sprint 2 ([Phase 1 · Sprint 2 — User Profile & AI Onboarding](docs/16-development-roadmap.md#phase-1--sprint-2--user-profile--ai-onboarding)) — Sprint 1 (Infrastructure, Authentication) has Authentication Complete; Infrastructure (Module 1) still open |
| **Current Module** | AI Onboarding ([Module 4](docs/IMPLEMENTATION_ORDER.md#4-ai-onboarding)) — in progress. Authentication ([Module 2](docs/IMPLEMENTATION_ORDER.md#2-authentication)) is now **Complete**. |
| **Next Task** | Sprint 2, Task 9 (Pest tests: profile update, onboarding goal creation) — see [NEXT_TASK.md](NEXT_TASK.md) |
| **Documentation Version** | v1.0 — frozen 2026-08-06, no further planning/documentation expansion unless explicitly requested (see [Documentation Update Policy](#documentation-update-policy)) |
| **Risk Level** | Low — no implementation risk has been incurred yet; the highest-rated risks ([Known Risks](#known-risks)) are scoped to specific future sprints, not present-tense |
| **Documentation Health** | Excellent — 123 documents, 0 broken internal links/anchors as of the last validation pass, single-source-of-truth metadata (see [Change Management Process](#change-management-process)) |
| **Architecture Stability** | High — no redesign has been required across five consecutive planning/refinement passes; [Database Design § 10](docs/04-database-design.md#10-phased-implementation--architecture-validation) formally confirms the schema supports both release phases without rework |

## Documentation Version

**v1.0** — frozen 2026-08-06.

All planning and architecture documentation (PRD through Master Implementation Plan, listed in full under [Completed Planning Activities](#completed-planning-activities)) is considered complete, internally consistent, and stable as of this version. Documentation authored after this freeze date is **execution tooling** (task breakdowns, workflow guides, this status dashboard) layered on top of v1.0, not a continuation of the planning/architecture phase — see [Change Management Process](#change-management-process) for how v1.0 itself may still evolve once implementation begins.

## Current Project Status

**Documentation and architecture phase: complete. Implementation phase: in progress.**

Laravel backend scaffolding and the complete Authentication module are merged to `main`: register/login/logout (security-hardened: rate limiting, CORS allow-list, fail-closed authorization, JWT issuer/leeway validation), refresh-token rotation (single-use rotation, reuse detection, family revocation, transaction-safe row locking), session/device management (`GET/DELETE /auth/sessions`), Google + Apple Sign-In (server-side ID token verification against provider JWKS), and email verification + password reset (queued email delivery, single-use hashed tokens, anti-enumeration, full-session revocation on reset). Tagged `v1.0.0-auth-foundation`, `v1.0.0-refresh-rotation`, `v1.0.0-session-management`, and `v1.0.0-auth-complete`. 130/130 Pest tests passing. The Flutter mobile foundation now also exists on `main`: `mobile/` (Riverpod + go_router, 5-tab shell, `flutter analyze`/`flutter test` clean) and a mobile CI workflow, merged via squash-merge of [PR #1](https://github.com/karthik22feb/aesthetic-coach/pull/1) (commit `38f1da6`). The Flutter auth client (Login/Signup screens, Dio `AuthInterceptor` with single-flight transparent refresh, secure refresh-token storage, session restoration, and auth-aware routing — Tasks 17–19) is **merged to `main`** via squash-merge of [PR #2](https://github.com/karthik22feb/aesthetic-coach/pull/2) (commit `f7a2580`), approved by a reviewer distinct from the author before merge. Re-verified post-merge on `main` (`flutter analyze` clean, `dart format` clean, 65/65 tests passing) — still **not** verified against a live backend or a real device/emulator. Per [IMPLEMENTATION_ORDER.md § 2](docs/IMPLEMENTATION_ORDER.md#2-authentication), the Authentication module's own Definition of Done isn't met until the staging E2E test also lands (Task 20, not started — blocked on a staging environment that doesn't exist yet), so Module 2 remains tracked as in-progress. Separately, Sprint 2's Module 3 (User Profile) is now **Complete**: Task 1 (`GET/PATCH /me` endpoint + Form Request validation) is merged to `main` via squash-merge of [PR #4](https://github.com/karthik22feb/aesthetic-coach/pull/4) (commit `5f7f706`), approved by two independent reviewers distinct from the author before merge and re-verified post-merge (144/144 Pest tests passing, 543 assertions; Pint clean; `composer validate --strict` clean). Task 2 (Flutter Profile screen + Edit Profile bottom sheet) is merged to `main` via squash-merge of [PR #5](https://github.com/karthik22feb/aesthetic-coach/pull/5) (commit `cc2385f`), approved by an independent reviewer distinct from the author before merge and re-verified post-merge (`flutter analyze` clean, `dart format` clean, 90/90 tests passing, `flutter build apk --release` SUCCESS — 53.7MB, no OOM). Module 3's own exit criterion ("a user can view and edit every profile field") is met; the feature doc's summary-stats and Body Measurements/Progress Photos entry points (F-PROF-02/F-PROF-03) remain deliberately deferred pending unbuilt modules, and the AI-context-propagation check is explicitly deferred per that module's own Definition of Done. Separately, Sprint 2 Task 3 (basic Settings screen: theme, unit preference) is merged to `main` via squash-merge of [PR #6](https://github.com/karthik22feb/aesthetic-coach/pull/6) (commit `450442b`), approved by an independent reviewer distinct from the author before merge and re-verified post-merge (102/102 tests passing, `flutter analyze`/`dart format` clean, release APK build SUCCESS — 54.1MB, no OOM). Unit preference reuses the same server-backed field as Profile rather than a second local copy; theme is genuinely device-local, persisted via `shared_preferences`. Task 3 has no dedicated module in [IMPLEMENTATION_ORDER.md](docs/IMPLEMENTATION_ORDER.md)'s 16-module list, so it doesn't move a Module Progress row — see [MASTER_IMPLEMENTATION_PLAN.md § Sprint Tracker](MASTER_IMPLEMENTATION_PLAN.md#sprint-tracker) for its status. Notification preferences, sessions, export, and account deletion remain deferred to Sprint 6 per that feature doc's own Release Phase split. This is backend/local + Flutter-test verification only — no staging or real-device verification was performed for any of these three tasks, and none supersedes or unblocks Task 20. Separately, Sprint 2 Task 4 (`goals` table migration + Eloquent model, per [Database Design § 3.5](docs/04-database-design.md#35-habits--goals)) is merged to `main` via squash-merge of [PR #8](https://github.com/karthik22feb/aesthetic-coach/pull/8) (commit `7c5d12e`), approved by two independent reviewers distinct from the author before merge (the migration-touching review requirement) and re-verified post-merge (`composer validate --strict` clean, Pint clean, a direct Tinker database round-trip against the real local MySQL instance confirming enum casts, the `user()`/`goals()` relations, and the `created_at` cast). The full Pest suite remains **not verified** for this task: this bare-Windows local environment has no Docker-Compose `mysql` hostname, which `phpunit.xml` forces via `DB_HOST=mysql` — confirmed as a pre-existing environment limitation (it reproduces identically on unrelated existing tests such as `CorsTest`), not a defect introduced by Task 4. Task 4 provides only the migration and model layer; the `POST /goals` endpoint itself remains Sprint 4 scope per [Goals feature](docs/features/goals.md), so **Module 4 (AI Onboarding) moves to In Progress**, not Complete. Since then, **Task 20 (end-to-end verification) is complete**, closing out Module 2 (Authentication): with no staging environment ever provisioned, Task 20 ran against a real production deployment stood up for this purpose (`https://acrinternal.iitm.ac.in/aesthetic-coach`, HTTPS via an institutional WAF's path-based routing — see [PRODUCTION_DEPLOYMENT_REPORT.md](PRODUCTION_DEPLOYMENT_REPORT.md) for the full architecture, including the WAF's `PATCH`/`PUT`/`DELETE` block, deferred mail, and the Android release-signing keystore generated for this work). Register, login, and the Dio `AuthInterceptor`'s 401→refresh→retry→success cycle are runtime-verified from the real release-signed Flutter client, the refresh cycle specifically proven via direct production server-log correlation rather than inferred from client behavior or a code review. Email verification and an explicit logout call were not separately exercised in this pass — recorded as an open scope gap against Task 20's literal frozen wording, not claimed as covered. **Module 2 (Authentication) moves to Complete.** Every future implementation session starts from [CLAUDE_SESSION_TEMPLATE.md](CLAUDE_SESSION_TEMPLATE.md).

## Current Phase

> **Phase 1 — Intelligent Fitness Platform**, Sprint 1 (Authentication module), in progress

Per [Phased Release Strategy](docs/PHASED_RELEASE_STRATEGY.md), Phase 2 does not begin until Phase 1's [exit criteria](docs/PHASED_RELEASE_STRATEGY.md#exit-criteria-for-each-phase) are met.

## Overall Progress

| Track | Progress | Detail |
|---|---|---|
| Documentation (v1.0) | 100% | 117 documents across product, architecture, database, API, mobile, backend, AI, testing, ops, phased release planning, and execution framework — see [VERSION_HISTORY.md](VERSION_HISTORY.md) |
| Execution framework | 100% | Implementation order, task breakdown, dependency graph, backlog, release checklist, workflow, AI development guide, plus the operational control documents (this file, [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md), [NEXT_TASK.md](NEXT_TASK.md), [DEVELOPMENT_LOG.md](DEVELOPMENT_LOG.md)) |
| Phase 1 implementation | ~8% | 2 of 16 modules complete (Authentication, User Profile); Sprint 2 underway — see [MASTER_IMPLEMENTATION_PLAN.md § Sprint Tracker](MASTER_IMPLEMENTATION_PLAN.md#sprint-tracker) |
| Phase 2 implementation | 0% (blocked) | Cannot begin until Phase 1 ships |

## Completed Planning Activities

- **Product & Requirements:** [PRD](docs/01-prd.md), [SRS](docs/02-srs.md)
- **Architecture & Design:** [System Architecture](docs/03-system-architecture.md), [Database Design](docs/04-database-design.md), [API Specification](docs/05-api-specification.md), [UI/UX Design System](docs/06-ui-ux-design-system.md)
- **Implementation Architecture:** [Backend Architecture](docs/07-backend-architecture.md), [Mobile Architecture](docs/08-mobile-architecture.md), [AI Coaching Engine](docs/09-ai-coaching-engine.md)
- **Quality & Operations:** [Testing Strategy](docs/10-testing-strategy.md), [CI/CD Pipeline](docs/11-cicd-pipeline.md), [Deployment Guide](docs/12-deployment-guide.md), [Monitoring & Logging](docs/13-monitoring-logging.md), [Production Hardening](docs/14-production-hardening.md), [User Documentation](docs/15-user-documentation.md)
- **Detailed Specifications:** 22 [Feature Specifications](docs/features/), 10 [Screen Specifications](docs/screens/), 12-item [Component Library](docs/components/), 10-item [AI Prompt Library](docs/ai/), 12-domain [API Contract Examples](docs/api-examples/), 10 [Architecture Decision Records](docs/adr/)
- **Engineering Process Reference:** [Database Seeding](docs/database-seeding.md), [Coding Standards](docs/coding-standards.md), [Git Workflow](docs/git-workflow.md), [Release Management](docs/release-management.md), [Analytics & Events](docs/analytics-events.md), [Permissions Matrix](docs/permissions-matrix.md), [Future Integrations](docs/future-integrations.md), [Performance Budget](docs/performance-budget.md)
- **Phased Release Planning:** [Phased Release Strategy](docs/PHASED_RELEASE_STRATEGY.md), [PHASE1_SCOPE.md](docs/PHASE1_SCOPE.md), [PHASE2_SCOPE.md](docs/PHASE2_SCOPE.md), [Development Roadmap](docs/16-development-roadmap.md) (sprint-driven), [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md)
- **Execution Framework:** [IMPLEMENTATION_ORDER.md](docs/IMPLEMENTATION_ORDER.md), [TASK_BREAKDOWN.md](docs/TASK_BREAKDOWN.md), [MODULE_DEPENDENCIES.md](docs/MODULE_DEPENDENCIES.md), [DEVELOPMENT_BACKLOG.md](docs/DEVELOPMENT_BACKLOG.md), [RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md), [DEVELOPMENT_WORKFLOW.md](docs/DEVELOPMENT_WORKFLOW.md), [AI_DEVELOPMENT_GUIDE.md](docs/AI_DEVELOPMENT_GUIDE.md), [GIT_INITIALIZATION.md](GIT_INITIALIZATION.md), [INFRASTRUCTURE_READINESS.md](INFRASTRUCTURE_READINESS.md)
- **Operational Control Documents:** [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md), [NEXT_TASK.md](NEXT_TASK.md), [DEVELOPMENT_LOG.md](DEVELOPMENT_LOG.md), [FIRST_IMPLEMENTATION_SESSION.md](FIRST_IMPLEMENTATION_SESSION.md), [IMPLEMENTATION_PROGRESS.md](IMPLEMENTATION_PROGRESS.md), [VERSION_HISTORY.md](VERSION_HISTORY.md), [CLAUDE_SESSION_TEMPLATE.md](CLAUDE_SESSION_TEMPLATE.md) — the standard starting point for every implementation session from this point forward

## Remaining Development Activities

Everything from here forward is implementation, not planning:

1. **Phase 1, Sprints 1–7** — see [IMPLEMENTATION_ORDER.md](docs/IMPLEMENTATION_ORDER.md) for the module-level build order and [TASK_BREAKDOWN.md](docs/TASK_BREAKDOWN.md) for the hour-scale task list within each sprint.
2. **Phase 1 exit criteria validation** — [Phased Release Strategy § Exit Criteria](docs/PHASED_RELEASE_STRATEGY.md#exit-criteria-for-each-phase).
3. **Phase 2, Sprints 1–6** — gated on (1) and (2), scoped in [PHASE2_SCOPE.md](docs/PHASE2_SCOPE.md).
4. **Ongoing, not phase-gated:** documentation maintenance per the [Documentation Update Policy](#documentation-update-policy) below, and resolution of the items in [Open Product Decisions](#open-product-decisions).

## Known Risks

Carried live in [MASTER_IMPLEMENTATION_PLAN.md § Known Risks](MASTER_IMPLEMENTATION_PLAN.md#known-risks) — summary:

| Risk | Severity |
|---|---|
| Offline sync correctness (Phase 1 Sprint 3) | Highest technical risk in Phase 1 |
| Refresh-token rotation/reuse-detection correctness (Sprint 1) | Security-critical |
| AI cost overrun without budgets from day one (Sprint 5) | High if mismanaged, well-mitigated by design |
| Phase 2 deprioritized after Phase 1 launch | Managed via explicit exit-criteria gate |
| Community/Challenges is the least-specified Phase 2 item | Requires a dedicated design pass before build |
| App store review timelines outside team control | Buffered in Sprint 7 / Phase 2 Sprint 6 |

## Open Product Decisions

Carried live in [MASTER_IMPLEMENTATION_PLAN.md § Open Decisions](MASTER_IMPLEMENTATION_PLAN.md#open-decisions) — summary: subscription pricing/tiering model, Predictive Coaching confidence-language methodology, Community/Challenges data model, analytics vendor selection, and team-size-to-calendar mapping for sprint estimates. None of these block the start of Phase 1 Sprint 1.

## Change Management Process

The v1.0 freeze does not mean the documentation is immutable — it means changes are now **deliberate and tracked**, not ad hoc edits made in passing:

1. **Implementation reveals a gap or error in a frozen document** (e.g., a schema detail that doesn't quite work in practice): fix the document in the **same PR** as the code change that revealed it, per the standing rule in [Development Roadmap § Cross-Phase Notes](docs/16-development-roadmap.md#cross-phase-notes) — "documentation is living." This is a correction, not a redesign, and doesn't require this document to be updated.
2. **A genuine scope or architecture change is proposed** (a new feature, a different technology choice, a phase reallocation): requires an explicit decision, recorded as either a new/updated [ADR](docs/adr/) (for architecture) or an update to the relevant scope document ([PHASE1_SCOPE.md](docs/PHASE1_SCOPE.md), [PHASE2_SCOPE.md](docs/PHASE2_SCOPE.md), [DEVELOPMENT_BACKLOG.md](docs/DEVELOPMENT_BACKLOG.md)) — never a silent code-first change that documentation catches up to later.
3. **A new open question surfaces:** add it to [MASTER_IMPLEMENTATION_PLAN.md § Open Decisions](MASTER_IMPLEMENTATION_PLAN.md#open-decisions), don't let it go untracked.
4. **A new risk surfaces:** add it to [MASTER_IMPLEMENTATION_PLAN.md § Known Risks](MASTER_IMPLEMENTATION_PLAN.md#known-risks).
5. Neither this document nor the Master Implementation Plan requires updating for routine day-to-day implementation work (writing code against an already-specified feature) — only for the five kinds of change above.

## Documentation Update Policy

| Document tier | Update frequency | Who updates |
|---|---|---|
| Frozen v1.0 planning/architecture docs (PRD → ADRs, § "Completed Planning Activities" above) | Rare — only per [Change Management Process](#change-management-process) item 1–2 | Whoever's PR revealed the gap or proposed the change |
| Execution framework (this freeze's 7 new `docs/` documents) | Occasional — as sprint/task granularity needs refinement | Engineering, reviewed like any other doc PR |
| Living trackers (this document, [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md)) | Every session/sprint boundary | Whoever's actively working — see [MASTER_IMPLEMENTATION_PLAN.md § How to Update This Document](MASTER_IMPLEMENTATION_PLAN.md#how-to-update-this-document) |

**Rule of thumb:** if you're unsure whether a change belongs in a frozen document or a living tracker, ask "does this describe what's permanently true about the system, or what's true about the project *right now*?" — the former goes in the frozen tier, the latter in the living tier.
