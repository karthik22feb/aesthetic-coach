# Master Implementation Plan

**Open this document first in every new session** (after skimming [PROJECT_STATUS.md](PROJECT_STATUS.md) if you need the fuller v1.0-freeze context). This is the **operational dashboard** — a live tracker layered on top of the frozen v1.0 planning documents in [`docs/`](docs/) and the execution framework introduced alongside this freeze, not a replacement for any of them. When in doubt about *what's true right now* (current phase, current sprint, current module, what's done), trust this document; when you need *why* or *how*, follow the links out to the relevant spec.

**Last updated:** 2026-08-18 · **Updated by:** Mobile authentication (Sprint 1, Tasks 17–19 combined) merged to `main` — squash-merge of [PR #2](https://github.com/karthik22feb/aesthetic-coach/pull/2), commit `f7a2580`; Login/Signup screens, Dio `AuthInterceptor`, secure refresh-token storage now live on `main`, re-verified post-merge (65/65 tests)

---

## Table of Contents
- [Executive Summary](#executive-summary)
- [Project Status](#project-status)
- [Current Phase](#current-phase)
- [Current Module](#current-module)
- [Sprint Tracker](#sprint-tracker)
- [Module Progress](#module-progress)
- [Feature Completion Checklist](#feature-completion-checklist)
- [Upcoming Milestones](#upcoming-milestones)
- [Key Documentation Index](#key-documentation-index)
- [Development Order](#development-order)
- [Coding Standards References](#coding-standards-references)
- [Testing Checklist](#testing-checklist)
- [Deployment Checklist](#deployment-checklist)
- [Known Risks](#known-risks)
- [Open Decisions](#open-decisions)
- [Next Recommended Task](#next-recommended-task)
- [Checklist for Starting the Next Development Session](#checklist-for-starting-the-next-development-session)
- [How to Update This Document](#how-to-update-this-document)

---

## Executive Summary

Aesthetic Coach is an AI-powered fitness tracking and personal coaching app, built Flutter + Laravel + MySQL 8, with an AI Coaching Engine on the Claude API. The product ships in two public release phases:

- **Phase 1 — Intelligent Fitness Platform:** core tracking + targeted AI utilities. The production-ready MVP.
- **Phase 2 — AI Personal Coach:** full conversational, multi-persona AI coaching, built on real user history collected during Phase 1.

Full rationale: [Phased Release Strategy](docs/PHASED_RELEASE_STRATEGY.md). The architecture, database schema, and API design already support both phases without redesign — confirmed in [Database Design § 10](docs/04-database-design.md#10-phased-implementation--architecture-validation).

**As of this update: the documentation phase is complete. No application code has been written.** This document's job, going forward, is to track implementation progress against [PHASE1_SCOPE.md](docs/PHASE1_SCOPE.md) and [PHASE2_SCOPE.md](docs/PHASE2_SCOPE.md) as work actually happens.

## Project Status

| Aspect | Status |
|---|---|
| Documentation | ✅ Complete — 100+ documents covering architecture, database, API, mobile, backend, AI, testing, CI/CD, deployment, monitoring, security, and phased release planning |
| Repository / codebase | 🟡 In progress — Laravel backend scaffolded; register/login/logout merged and hardened; Flutter scaffold + Riverpod/go_router + mobile CI merged to `main`; Flutter Login/Signup + `AuthInterceptor` + secure token storage merged to `main`; `GET/PATCH /me` profile endpoint merged to `main` (PR #4) |
| Phase 1 implementation | 🟡 In progress — Sprint 1 (Infrastructure, Authentication) underway |
| Phase 2 implementation | ⬜ Not started (blocked on Phase 1 launch, per [exit criteria](docs/PHASED_RELEASE_STRATEGY.md#exit-criteria-for-each-phase)) |
| Production deployment | ⬜ Not started |

## Current Phase

> **PHASE 1 — Intelligent Fitness Platform** (Sprint 1 in progress)

[Phase 1 · Sprint 1](docs/16-development-roadmap.md#phase-1--sprint-1--infrastructure-authentication--project-setup) is underway: Infrastructure scaffolding is in progress, and the entire backend Authentication module (register/login/logout, refresh-token rotation, session/device management, Google/Apple Sign-In, email verification, password reset) is merged to `main`, tagged `v1.0.0-auth-foundation`, `v1.0.0-refresh-rotation`, `v1.0.0-session-management`, and `v1.0.0-auth-complete`. Flutter mobile foundation (Tasks 5–7: project scaffold, Riverpod/go_router, mobile CI) is merged to `main` (squash-merge of [PR #1](https://github.com/karthik22feb/aesthetic-coach/pull/1), commit `38f1da6`). Flutter Login/Signup, `AuthInterceptor`, and secure token storage (Tasks 17–19) are merged to `main` (squash-merge of [PR #2](https://github.com/karthik22feb/aesthetic-coach/pull/2), commit `f7a2580`); only Task 20 (staging E2E) remains unstarted. [Sprint 2](docs/16-development-roadmap.md#phase-1--sprint-2--user-profile--ai-onboarding)'s Task 1 (`GET/PATCH /me` endpoint) has also landed ahead of strict sequence, merged to `main` (squash-merge of [PR #4](https://github.com/karthik22feb/aesthetic-coach/pull/4), commit `5f7f706`) — this does not change Module 2/Task 20's blocked status. See [Next Recommended Task](#next-recommended-task).

## Current Module

> **Module 2 — Authentication** (per [IMPLEMENTATION_ORDER.md](docs/IMPLEMENTATION_ORDER.md#2-authentication)) — in progress; session/device management underway.

Modules are the finer-grained build unit within a sprint; see [Module Progress](#module-progress) for the full 16-module list and [TASK_BREAKDOWN.md](docs/TASK_BREAKDOWN.md) for the hour-scale tasks within the current module.

## Sprint Tracker

Update the **Status** column as work progresses. Full detail (objectives, deliverables, risks, suggested Claude prompts) for every sprint below is in [Development Roadmap](docs/16-development-roadmap.md).

### Phase 1 — Intelligent Fitness Platform

| Sprint | Focus | Status | Notes |
|---|---|---|---|
| [Sprint 1](docs/16-development-roadmap.md#phase-1--sprint-1--infrastructure-authentication--project-setup) | Infrastructure, Authentication & Project Setup | 🟡 In progress | Backend Authentication complete and merged (`v1.0.0-auth-foundation`, `v1.0.0-refresh-rotation`, `v1.0.0-session-management`, `v1.0.0-auth-complete` — Tasks 9–16). Flutter foundation (Tasks 5–7) merged to `main` (PR #1, `38f1da6`). Flutter auth client (Tasks 17–19) merged to `main` (PR #2, `f7a2580`). Task 8, Task 20 not started. |
| [Sprint 2](docs/16-development-roadmap.md#phase-1--sprint-2--user-profile--ai-onboarding) | User Profile & AI Onboarding | 🟡 In progress | Task 1 (`GET/PATCH /me` + validation) merged to `main` (PR #4, `5f7f706`). Tasks 2–11 not started. |
| [Sprint 3](docs/16-development-roadmap.md#phase-1--sprint-3--workout-engine--exercise-library) | Workout Engine & Exercise Library | ⬜ Not started | Highest offline-sync risk — see [Known Risks](#known-risks) |
| [Sprint 4](docs/16-development-roadmap.md#phase-1--sprint-4--tracking-progress--habits) | Tracking, Progress & Habits | ⬜ Not started | |
| [Sprint 5](docs/16-development-roadmap.md#phase-1--sprint-5--ai-recommendations-analytics--notifications) | AI Recommendations, Analytics & Notifications | ⬜ Not started | Highest AI/product risk — see [Known Risks](#known-risks) |
| [Sprint 6](docs/16-development-roadmap.md#phase-1--sprint-6--testing-performance--security) | Testing, Performance & Security | ⬜ Not started | |
| [Sprint 7](docs/16-development-roadmap.md#phase-1--sprint-7--uat--production-launch) | UAT & Production Launch | ⬜ Not started | Gates Phase 2 kickoff |

### Phase 2 — AI Personal Coach (blocked until Phase 1 Sprint 7 exit criteria met)

| Sprint | Focus | Status |
|---|---|---|
| [Sprint 1](docs/16-development-roadmap.md#phase-2--sprint-1--conversational-coach-foundation) | Conversational Coach Foundation | ⬜ Blocked (Phase 1 not complete) |
| [Sprint 2](docs/16-development-roadmap.md#phase-2--sprint-2--nutrition-coach--recovery-coach) | Nutrition Coach & Recovery Coach | ⬜ Blocked |
| [Sprint 3](docs/16-development-roadmap.md#phase-2--sprint-3--habit-coach-context-memory--adaptive-plans) | Habit Coach, Context Memory & Adaptive Plans | ⬜ Blocked |
| [Sprint 4](docs/16-development-roadmap.md#phase-2--sprint-4--predictive-coaching--advanced-analytics) | Predictive Coaching & Advanced Analytics | ⬜ Blocked |
| [Sprint 5](docs/16-development-roadmap.md#phase-2--sprint-5--wearable-integrations-community-challenges--leaderboards) | Wearable Integrations, Community, Challenges & Leaderboards | ⬜ Blocked |
| [Sprint 6](docs/16-development-roadmap.md#phase-2--sprint-6--testing-hardening--phase-2-launch) | Testing, Hardening & Phase 2 Launch | ⬜ Blocked |

## Module Progress

The 16-module build order from [IMPLEMENTATION_ORDER.md](docs/IMPLEMENTATION_ORDER.md#overall-development-order), tracked at finer grain than the Sprint Tracker above. Update the Status column alongside the Sprint Tracker — a sprint isn't complete until every module scheduled within it is. For Started/Completed **dates**, see [IMPLEMENTATION_PROGRESS.md](IMPLEMENTATION_PROGRESS.md) — that document is the dated source of truth; this table is the quick-glance mirror.

| # | Module | Status | Sprint |
|---|---|---|---|
| 1 | [Infrastructure](docs/IMPLEMENTATION_ORDER.md#1-infrastructure) | 🟡 In progress | 1 |
| 2 | [Authentication](docs/IMPLEMENTATION_ORDER.md#2-authentication) | 🟡 In progress | 1 |
| 3 | [User Profile](docs/IMPLEMENTATION_ORDER.md#3-user-profile) | 🟡 In progress | 2 |
| 4 | [AI Onboarding](docs/IMPLEMENTATION_ORDER.md#4-ai-onboarding) | ⬜ Not started | 2 |
| 5 | [Dashboard (shell)](docs/IMPLEMENTATION_ORDER.md#5-dashboard-shell) | ⬜ Not started | 4 (scaffold) |
| 6 | [Workout Engine](docs/IMPLEMENTATION_ORDER.md#6-workout-engine) | ⬜ Not started | 3 |
| 7 | [Exercise Library](docs/IMPLEMENTATION_ORDER.md#7-exercise-library) | ⬜ Not started | 3 |
| 8 | [Workout History](docs/IMPLEMENTATION_ORDER.md#8-workout-history) | ⬜ Not started | 3 |
| 9 | [Progress Tracking](docs/IMPLEMENTATION_ORDER.md#9-progress-tracking) | ⬜ Not started | 4 |
| 10 | [Habits](docs/IMPLEMENTATION_ORDER.md#10-habits) | ⬜ Not started | 4 |
| 11 | [Analytics](docs/IMPLEMENTATION_ORDER.md#11-analytics) | ⬜ Not started | 5 |
| 12 | [Notifications](docs/IMPLEMENTATION_ORDER.md#12-notifications) | ⬜ Not started | 5 |
| 13 | [AI Recommendations](docs/IMPLEMENTATION_ORDER.md#13-ai-recommendations) | ⬜ Not started | 5 |
| 14 | [Testing](docs/IMPLEMENTATION_ORDER.md#14-testing) | ⬜ Not started | 6 |
| 15 | [Deployment](docs/IMPLEMENTATION_ORDER.md#15-deployment) | ⬜ Not started | 6–7 |
| 16 | [Production Launch](docs/IMPLEMENTATION_ORDER.md#16-production-launch) | ⬜ Not started | 7 |

**Completed:** 0 of 16 (3 in progress: Infrastructure, Authentication, User Profile). **Remaining:** 13 not started — see [MODULE_DEPENDENCIES.md § Critical Path](docs/MODULE_DEPENDENCIES.md#critical-path) for which of these are schedule-critical.

## Feature Completion Checklist

Mirrors [PHASE1_SCOPE.md § Feature Matrix](docs/PHASE1_SCOPE.md#feature-matrix). Check items off as they're implemented **and tested** — per [Development Roadmap § Cross-Phase Notes](docs/16-development-roadmap.md#cross-phase-notes), a feature isn't done without its tests.

### Phase 1
- [ ] Authentication ([spec](docs/features/authentication.md)) — Sprint 1
- [ ] Profile ([spec](docs/features/profile.md)) — Sprint 2
- [ ] AI Onboarding ([spec](docs/features/onboarding.md)) — Sprint 2
- [ ] Workout Tracking ([spec](docs/features/workout-tracking.md)) — Sprint 3
- [ ] Exercise Library ([spec](docs/features/exercise-library.md)) — Sprint 3
- [ ] Workout History ([spec](docs/features/workout-history.md)) — Sprint 3
- [ ] Exercise Details / Guidance ([spec](docs/features/exercise-details.md)) — Sprint 3 (screen) / 5 (AI)
- [ ] Offline Support ([Mobile Architecture § 4](docs/08-mobile-architecture.md#4-offline-first-strategy)) — Sprint 3–4
- [ ] Nutrition ([spec](docs/features/nutrition.md)) — Sprint 4
- [ ] Calorie Tracker ([spec](docs/features/calorie-tracker.md)) — Sprint 4
- [ ] Water Intake ([spec](docs/features/water-intake.md)) — Sprint 4
- [ ] Body Measurements ([spec](docs/features/body-measurements.md)) — Sprint 4
- [ ] Progress Photos ([spec](docs/features/progress-photos.md)) — Sprint 4
- [ ] Habit Tracking ([spec](docs/features/habits.md)) — Sprint 4
- [ ] Progress Tracking / Goals ([spec](docs/features/goals.md)) — Sprint 4
- [ ] Dashboard ([spec](docs/features/dashboard.md)) — Sprint 4 (scaffold) / 5 (finalize)
- [ ] Basic Analytics ([Daily Fitness Score](docs/09-ai-coaching-engine.md#5-recommendation-engine)) — Sprint 5
- [ ] AI Workout Recommendations (FR-206) — Sprint 5
- [ ] Notifications ([spec](docs/features/notifications.md)) — Sprint 5
- [ ] Settings ([spec](docs/features/settings.md)) — Sprint 2 (basic) / 6 (finalized)
- [ ] Subscription Foundation ([spec](docs/features/subscriptions.md)) — Sprint 6
- [ ] Achievements ([spec](docs/features/achievements.md)) — Sprint 6 (stretch)
- [ ] Production Hardening ([checklist](docs/14-production-hardening.md#1-security-checklist)) — Sprint 6
- [ ] Monitoring dashboards/alerts live ([spec](docs/13-monitoring-logging.md#8-alerting)) — Sprint 6
- [ ] CI/CD pipeline green and enforced ([spec](docs/11-cicd-pipeline.md)) — Sprint 1
- [ ] Production deployment + rollback drill ([guide](docs/12-deployment-guide.md)) — Sprint 7
- [ ] App store submission + `v1.0.0` launch — Sprint 7

### Phase 2 (do not start until Phase 1 checklist above is complete)
- [ ] Conversational Coach (full Coach tab) ([spec](docs/features/ai-coach.md))
- [ ] Nutrition Coach persona ([prompt](docs/ai/nutrition-coach.md))
- [ ] Wearable Integrations, first wave ([spec](docs/features/wearable-integrations.md))
- [ ] Recovery Coach persona ([prompt](docs/ai/recovery-coach.md))
- [ ] Habit Coach persona (not yet drafted)
- [ ] Context Memory / long-term memory retrieval ([AI Coaching Engine § 4](docs/09-ai-coaching-engine.md#4-user-memory-strategy))
- [ ] Adaptive Plans (conversational workout adjustment)
- [ ] Predictive Coaching / Advanced Analytics ([prompt](docs/ai/progress-analysis.md))
- [ ] Goal Recommendation AI ([prompt](docs/ai/goal-recommendation.md))
- [ ] Wearable Integrations, remaining providers
- [ ] Community, Challenges, Leaderboards — **requires a dedicated design pass first** ([spec](docs/features/challenges.md))
- [ ] `v2.0.0` launch

## Upcoming Milestones

| Milestone | Target | Status |
|---|---|---|
| Repository scaffolded, CI green, staging reachable | End of Module 1 | ⬜ Not started |
| First authenticated user can log in end-to-end | End of Module 2 | ⬜ Not started |
| A workout can be logged fully offline and syncs correctly | End of Module 6 | ⬜ Not started |
| Daily Fitness Score computes correctly for a test cohort | End of Module 11 | ⬜ Not started |
| First AI-generated workout produced end-to-end | End of Module 13 | ⬜ Not started |
| Zero open critical/high security findings | End of Module 14 | ⬜ Not started |
| Production environment live with a successful rollback drill | End of Module 15 | ⬜ Not started |
| **`v1.0.0` public launch** | End of Module 16 / Sprint 7 | ⬜ Not started |
| Phase 1 exit criteria formally reviewed, Phase 2 kickoff decided | Immediately after launch | ⬜ Not started |
| **`v2.0.0` — full Conversational Coach live** | End of Phase 2 Sprint 6 | ⬜ Blocked on Phase 1 |

## Key Documentation Index

| Need to... | Go to |
|---|---|
| Understand the release strategy | [Phased Release Strategy](docs/PHASED_RELEASE_STRATEGY.md) |
| See what's in Phase 1 | [PHASE1_SCOPE.md](docs/PHASE1_SCOPE.md) |
| See what's in Phase 2 | [PHASE2_SCOPE.md](docs/PHASE2_SCOPE.md) |
| Find the sprint plan | [Development Roadmap](docs/16-development-roadmap.md) |
| Understand product vision/personas | [PRD](docs/01-prd.md) |
| Find a specific requirement | [SRS](docs/02-srs.md) |
| Understand system architecture | [System Architecture](docs/03-system-architecture.md) |
| Look up a database table | [Database Design](docs/04-database-design.md) |
| Look up an API endpoint | [API Specification](docs/05-api-specification.md) + [API Examples](docs/api-examples/) |
| Check design tokens/components | [UI/UX Design System](docs/06-ui-ux-design-system.md) + [Component Library](docs/components/) |
| Implement a Laravel module | [Backend Architecture](docs/07-backend-architecture.md) |
| Implement a Flutter feature | [Mobile Architecture](docs/08-mobile-architecture.md) + [Screen Specs](docs/screens/) |
| Work on AI coaching | [AI Coaching Engine](docs/09-ai-coaching-engine.md) + [AI Prompt Library](docs/ai/) |
| Find a feature's full spec | [Feature Specifications](docs/features/) |
| Write or run tests | [Testing Strategy](docs/10-testing-strategy.md) |
| Set up CI/CD | [CI/CD Pipeline](docs/11-cicd-pipeline.md) |
| Deploy | [Deployment Guide](docs/12-deployment-guide.md) |
| Check monitoring/alerting | [Monitoring & Logging](docs/13-monitoring-logging.md) |
| Run a security review | [Production Hardening](docs/14-production-hardening.md) |
| Write user-facing help content | [User Documentation](docs/15-user-documentation.md) |
| See overall project status / v1.0 freeze context | [PROJECT_STATUS.md](PROJECT_STATUS.md) |
| Find the module-level build order (finer than sprints) | [IMPLEMENTATION_ORDER.md](docs/IMPLEMENTATION_ORDER.md) |
| Find hour-scale tasks within a sprint | [TASK_BREAKDOWN.md](docs/TASK_BREAKDOWN.md) |
| See the dependency graph / critical path / bottlenecks | [MODULE_DEPENDENCIES.md](docs/MODULE_DEPENDENCIES.md) |
| Check backlog priority/effort/value/risk for any item | [DEVELOPMENT_BACKLOG.md](docs/DEVELOPMENT_BACKLOG.md) |
| Run the production-readiness checklist | [RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md) |
| Understand the day-to-day git/PR/release process | [DEVELOPMENT_WORKFLOW.md](docs/DEVELOPMENT_WORKFLOW.md) |
| **Start or run a Claude development session** | [AI_DEVELOPMENT_GUIDE.md](docs/AI_DEVELOPMENT_GUIDE.md), [CLAUDE_SESSION_TEMPLATE.md](CLAUDE_SESSION_TEMPLATE.md) |
| **Run through the pre-session checklist** | [SPRINT1_DAY1_CHECKLIST.md](SPRINT1_DAY1_CHECKLIST.md) |

## Development Order

Strict sequential order within Phase 1 (each sprint depends on the prior — see [Development Roadmap](docs/16-development-roadmap.md) for full dependency detail per sprint):

```
Phase 1: Sprint 1 (Auth/Infra) → Sprint 2 (Profile/Onboarding) → Sprint 3 (Workout Engine)
         → Sprint 4 (Tracking/Progress/Habits) → Sprint 5 (AI/Analytics/Notifications)
         → Sprint 6 (Testing/Hardening) → Sprint 7 (Launch)
                                              ↓
                        [Phase 1 Exit Criteria — see Phased Release Strategy]
                                              ↓
Phase 2: Sprint 1 (Conversational Coach) → Sprint 2 (Nutrition/Recovery Coach)
         → Sprint 3 (Habit Coach/Memory/Adaptive Plans) → Sprint 4 (Predictive/Advanced Analytics)
         → Sprint 5 (Wearables/Community) → Sprint 6 (Testing/Launch)
```

Do not start a sprint's work before its dependencies (listed in that sprint's [Development Roadmap](docs/16-development-roadmap.md) entry) are complete — this is what keeps offline sync (Sprint 3) and AI cost controls (Sprint 5) from being built on shaky foundations.

## Coding Standards References

Before writing any code, confirm you're following:

- **General principles (SOLID, DRY, commenting):** [Coding Standards § General Principles](docs/coding-standards.md#general-principles)
- **Laravel:** [Coding Standards § Laravel Standards](docs/coding-standards.md#laravel-standards) + [Backend Architecture § 2 Layering](docs/07-backend-architecture.md#2-layering--responsibilities)
- **Flutter:** [Coding Standards § Flutter Standards](docs/coding-standards.md#flutter-standards) + [Mobile Architecture § 2 Folder Organization](docs/08-mobile-architecture.md#2-folder-organization)
- **Git workflow / commits / PRs:** [Git Workflow](docs/git-workflow.md)
- **Database naming/migrations:** [Database Design § 1 Naming Conventions](docs/04-database-design.md#1-naming-conventions) + [§ 6 Migration Strategy](docs/04-database-design.md#6-migration-strategy)
- **API conventions:** [API Specification § 2 Conventions](docs/05-api-specification.md#2-conventions)
- **AI prompt changes:** go through the same PR review as code — [AI Prompt Library § Conventions](docs/ai/README.md#conventions)

## Testing Checklist

Per [Testing Strategy](docs/10-testing-strategy.md) — every feature needs, before it's marked done in the [Feature Completion Checklist](#feature-completion-checklist):

- [ ] Unit tests for Services/Notifiers ([§ 3](docs/10-testing-strategy.md#3-unit-testing))
- [ ] Widget/golden tests for new UI components ([§ 4](docs/10-testing-strategy.md#4-widget-testing))
- [ ] API Feature tests: happy path, validation, auth, cross-user isolation, idempotency ([§ 5](docs/10-testing-strategy.md#5-api-testing))
- [ ] Offline sync tests, if the feature touches offline-critical domains ([§ 6](docs/10-testing-strategy.md#6-offline-sync-testing))
- [ ] AI guardrail tests, if the feature touches any AI persona ([AI Coaching Engine § 7](docs/09-ai-coaching-engine.md#7-safety-guardrails))
- [ ] Gherkin acceptance criteria from the feature's own spec pass (every [Feature Specification](docs/features/) ends with these)

Sprint-level gates:
- [ ] Sprint 6 (Phase 1): full load test, E2E device-lab suite, AI smoke suite ([§ 7–8](docs/10-testing-strategy.md#7-performance-testing))
- [ ] Sprint 6 (Phase 1): [Production Hardening § 1 Security Checklist](docs/14-production-hardening.md#1-security-checklist) fully passed
- [ ] Phase 2 Sprint 6: guardrail review for every newly-activated persona ([AI Coaching Engine § 7](docs/09-ai-coaching-engine.md#7-safety-guardrails))

## Deployment Checklist

Per [Deployment Guide](docs/12-deployment-guide.md) and [Release Management](docs/release-management.md):

- [ ] CI green (lint, static analysis, unit/widget/Feature tests, dependency scan) — [CI/CD Pipeline § 4](docs/11-cicd-pipeline.md#4-automated-testing-ci-gates)
- [ ] Staged to staging environment, smoke-tested
- [ ] Migrations reviewed for lock behavior + expand/contract compliance — [Database Design § 6](docs/04-database-design.md#6-migration-strategy)
- [ ] Pre-migration snapshot taken automatically if release includes a destructive migration
- [ ] Release tagged (`vX.Y.Z`, [semantic versioning](docs/release-management.md#semantic-versioning))
- [ ] Manual approval gate cleared — [Release Management § Deployment Approvals](docs/release-management.md#deployment-approvals)
- [ ] Rollback plan confirmed for risky changes — [Deployment Guide § Rollback Procedures](docs/12-deployment-guide.md#10-rollback-procedures)
- [ ] Mobile: Fastlane build submitted to TestFlight/Play internal track
- [ ] Production deploy executed, health checks green ([§ 5](docs/13-monitoring-logging.md#5-health-checks))
- [ ] Post-deploy monitoring watched for the first 24–48h

## Known Risks

Carried forward from [PHASED_RELEASE_STRATEGY.md § Risks](docs/PHASED_RELEASE_STRATEGY.md#risks) and [Development Roadmap](docs/16-development-roadmap.md), kept live here:

| Risk | Status | Mitigation owner |
|---|---|---|
| Offline sync correctness (Phase 1 Sprint 3) — highest technical risk in Phase 1 | Not yet encountered (pre-implementation) | Dedicated sprint time, per [ADR-0007](docs/adr/0007-offline-first-architecture.md#consequences) |
| Refresh-token rotation/reuse-detection bugs (Phase 1 Sprint 1) — security-critical | Not yet encountered | Explicit test time per [Testing Strategy § API Testing](docs/10-testing-strategy.md#5-api-testing) |
| AI cost overrun without budgets from day one (Phase 1 Sprint 5) | Not yet encountered | Build [AI Coaching Engine § 8–9](docs/09-ai-coaching-engine.md#8-cost-optimization) *with* the first AI call, not after |
| Phase 2 delayed/deprioritized after Phase 1 launch | Not yet applicable | Exit criteria make Phase 2 kickoff an explicit gated decision, tracked in this document |
| Community/Challenges is the least-specified Phase 2 item | Acknowledged, deferred | Dedicated design pass required before Phase 2 Sprint 5 implementation begins |
| App store review timelines outside team control | Not yet applicable | Buffer built into Sprint 7 / Phase 2 Sprint 6; feature flags decouple merge from release |

Add new risks here as they're discovered during implementation — this table should stay current, unlike the static risk sections in the underlying docs.

## Open Decisions

Decisions explicitly **not yet made** by Product/Engineering, tracked so they aren't silently assumed:

- **Subscription pricing/tiering model** — [Subscriptions feature](docs/features/subscriptions.md) remains explicitly unscoped; Phase 1 ships foundation scaffolding only. **Owner:** Product. **Blocks:** any real monetization work beyond Phase 1's entitlement scaffolding.
- **Predictive Coaching confidence-language methodology** — [AI Prompt — Progress Analysis](docs/ai/progress-analysis.md) flags this as unresolved. **Owner:** Product + AI Engineering. **Blocks:** Phase 2 Sprint 4.
- **Community/Challenges data model and UX** — no schema or API contract exists yet. **Owner:** Product + Engineering (dedicated design pass). **Blocks:** Phase 2 Sprint 5.
- **Analytics vendor selection** — [Analytics & Events](docs/analytics-events.md) defines the event taxonomy but not a specific tool. **Owner:** Product/Data. **Blocks:** nothing in Phase 1 (events can be defined before a vendor is wired up); needed before dashboards are built.
- **Team size / calendar mapping for sprint estimates** — [Development Roadmap](docs/16-development-roadmap.md) uses relative complexity (S/M/L/XL), not calendar dates. **Owner:** Engineering leadership, at planning time.

## Next Recommended Task

**See [NEXT_TASK.md](NEXT_TASK.md) for the single current task** — it's kept in sync with this section and is the file to read for "what do I do right this moment." This section gives the broader sprint-level entry point: [Phase 1 · Sprint 1 — Infrastructure, Authentication & Project Setup](docs/16-development-roadmap.md#phase-1--sprint-1--infrastructure-authentication--project-setup).

The entire backend Authentication module is merged to `main` as of `v1.0.0-auth-foundation`, `v1.0.0-refresh-rotation`, `v1.0.0-session-management`, and `v1.0.0-auth-complete`: register/login/logout, refresh-token rotation (reuse detection, family revocation), session/device management, Google/Apple Sign-In, email verification, and password reset. The Flutter mobile foundation (project scaffold, Riverpod/go_router, 5-tab shell, mobile CI — Tasks 5–7) is merged to `main` (squash-merge of [PR #1](https://github.com/karthik22feb/aesthetic-coach/pull/1), commit `38f1da6`). The Flutter auth client (Login/Signup screens, `AuthInterceptor`, secure token storage — Tasks 17–19) is merged to `main` (squash-merge of [PR #2](https://github.com/karthik22feb/aesthetic-coach/pull/2), commit `f7a2580`). The next task is Task 20 (staging E2E test) — see [NEXT_TASK.md](NEXT_TASK.md).

Separately, [Sprint 2, Task 1](docs/TASK_BREAKDOWN.md#sprint-2--user-profile--ai-onboarding) (`GET/PATCH /me` endpoint + Form Request validation) is merged to `main` (squash-merge of [PR #4](https://github.com/karthik22feb/aesthetic-coach/pull/4), commit `5f7f706`), approved by two independent reviewers before merge and re-verified post-merge (144/144 Pest tests, Pint clean, `composer validate --strict` clean). This was implemented ahead of strict roadmap order and does not change the fact that Task 20 is still the next task gating Module 2/Sprint 1 completion. Once Task 20 unblocks (a staging environment is provisioned), the next Sprint 2 candidates are Task 2 (Flutter Profile screen, depends on Task 1 + Sprint 1 Task 17, both now satisfied) and Task 9 (Pest tests: profile update + onboarding goal creation — the profile-update half is already substantially covered by the new `ProfileTest.php`).

Concrete first steps (from that sprint's suggested Claude prompts):
1. Scaffold the Laravel backend per [Backend Architecture § 1](docs/07-backend-architecture.md#1-folder-structure) and the Flutter mobile app per [Mobile Architecture § 2](docs/08-mobile-architecture.md#2-folder-organization).
2. Stand up Docker Compose dev environment ([Deployment Guide § 2](docs/12-deployment-guide.md#2-development-environment)) and CI/CD pipeline ([CI/CD Pipeline](docs/11-cicd-pipeline.md)).
3. Implement the Auth module (register/login/OAuth/refresh-token rotation) per [Authentication feature](docs/features/authentication.md) and [Database Design § 3.1](docs/04-database-design.md#31-identity--auth).
4. Update the [Sprint Tracker](#sprint-tracker) and [Feature Completion Checklist](#feature-completion-checklist) above as work lands.

## Checklist for Starting the Next Development Session

Before opening a Claude session (or picking the task back up as a human), per [AI_DEVELOPMENT_GUIDE.md § How to Start a Claude Session](docs/AI_DEVELOPMENT_GUIDE.md#how-to-start-a-claude-session):

- [ ] Read [NEXT_TASK.md](NEXT_TASK.md) — the single task to work on right now — then [Current Phase](#current-phase) and [Current Module](#current-module) above for broader context; don't rely on memory from a prior session
- [ ] Copy [CLAUDE_SESSION_TEMPLATE.md](CLAUDE_SESSION_TEMPLATE.md) and fill it in with that task — this is the required starting point for every implementation session, not an optional aid
- [ ] Find the specific task row in [TASK_BREAKDOWN.md](docs/TASK_BREAKDOWN.md) for the current sprint/module
- [ ] Gather that task's "Primary doc(s)" plus anything [AI_DEVELOPMENT_GUIDE.md § Which Documentation Files to Include](docs/AI_DEVELOPMENT_GUIDE.md#which-documentation-files-to-include) recommends for its task type
- [ ] Confirm the task's dependencies (per [TASK_BREAKDOWN.md](docs/TASK_BREAKDOWN.md) or [MODULE_DEPENDENCIES.md](docs/MODULE_DEPENDENCIES.md)) are actually done — check [Module Progress](#module-progress), don't assume
- [ ] State the task goal in one sentence at the start of the session, per [AI_DEVELOPMENT_GUIDE.md § Prompt Templates](docs/AI_DEVELOPMENT_GUIDE.md#prompt-templates)
- [ ] After the session: confirm [AI_DEVELOPMENT_GUIDE.md § Definition of Done](docs/AI_DEVELOPMENT_GUIDE.md#definition-of-done-before-moving-to-the-next-task) is met, then update [Sprint Tracker](#sprint-tracker), [Module Progress](#module-progress), [Feature Completion Checklist](#feature-completion-checklist), and [Next Recommended Task](#next-recommended-task) before ending the session

## How to Update This Document

This is a **living tracker**, not a static spec — update it as work happens (see [PROJECT_STATUS.md § Documentation Update Policy](PROJECT_STATUS.md#documentation-update-policy) for how this tier relates to the frozen v1.0 docs):
- Flip Sprint Tracker and Module Progress rows from ⬜ Not started → 🟡 In progress → ✅ Complete as work proceeds — keep both in sync with each other.
- Check off Feature Completion Checklist items only when the feature **and its tests** are done, per [Testing Strategy](docs/10-testing-strategy.md).
- Add newly-discovered risks to [Known Risks](#known-risks) rather than letting them live only in a PR comment or someone's memory.
- Resolve items in [Open Decisions](#open-decisions) by linking to where the decision was made (a PR, an ADR, a Product doc update) and removing them from this list.
- Always update [Next Recommended Task](#next-recommended-task) at the end of a work session so the next session (human or Claude) knows where to pick up.
- Bump the **Last updated** line at the top of this document on every edit.
