# Task Breakdown

**Product:** Aesthetic Coach — Phase 1 (Intelligent Fitness Platform)
**Purpose:** every Phase 1 sprint broken into tasks small enough to complete in a few hours each — the level of granularity an individual work session (human or AI-assisted) should target.
**Related documents:** [Development Roadmap](16-development-roadmap.md) (sprint objectives/deliverables this breaks down) · [IMPLEMENTATION_ORDER.md](IMPLEMENTATION_ORDER.md) (module dependencies) · [AI_DEVELOPMENT_GUIDE.md](AI_DEVELOPMENT_GUIDE.md) (how to turn one task below into a Claude prompt)

## Table of Contents
- [How to Use This Document](#how-to-use-this-document)
- [Sprint 1 — Infrastructure, Authentication & Project Setup](#sprint-1--infrastructure-authentication--project-setup)
- [Sprint 2 — User Profile & AI Onboarding](#sprint-2--user-profile--ai-onboarding)
- [Sprint 3 — Workout Engine & Exercise Library](#sprint-3--workout-engine--exercise-library)
- [Sprint 4 — Tracking, Progress & Habits](#sprint-4--tracking-progress--habits)
- [Sprint 5 — AI Recommendations, Analytics & Notifications](#sprint-5--ai-recommendations-analytics--notifications)
- [Sprint 6 — Testing, Performance & Security](#sprint-6--testing-performance--security)
- [Sprint 7 — UAT & Production Launch](#sprint-7--uat--production-launch)

## How to Use This Document

Each task is scoped to a few hours — small enough to be one Claude session (see [AI_DEVELOPMENT_GUIDE.md](AI_DEVELOPMENT_GUIDE.md)) or one human focused work block, and small enough to land as one reviewable pull request per [Git Workflow](git-workflow.md). "Depends on" references other task numbers *within the same sprint* unless another sprint is named explicitly. Tasks within a sprint are numbered for reference, not strictly forced-sequential — see each sprint's dependency notes and [IMPLEMENTATION_ORDER.md § Parallel Development Opportunities](IMPLEMENTATION_ORDER.md#parallel-development-opportunities) for what can run concurrently.

---

## Sprint 1 — Infrastructure, Authentication & Project Setup

Full sprint context: [Development Roadmap § Phase 1 · Sprint 1](16-development-roadmap.md#phase-1--sprint-1--infrastructure-authentication--project-setup).

| # | Task | Depends on | Primary doc(s) |
|---|---|---|---|
| 1 | Create Laravel project, scaffold `app/Modules/*` structure | — | [Backend Architecture § 1](07-backend-architecture.md#1-folder-structure) |
| 2 | Configure Docker (docker-compose: app, MySQL 8, Redis, Mailhog) | 1 | [Deployment Guide § 2](12-deployment-guide.md#2-development-environment) |
| 3 | Configure MySQL connection, base `.env`, run first migration (`users` table) | 2 | [Database Design § 3.1](04-database-design.md#31-identity--auth) |
| 4 | Configure GitHub Actions CI (lint, static analysis, test job skeleton) | 1 | [CI/CD Pipeline § 3.1](11-cicd-pipeline.md#31-backend-laravel) |
| 5 | Create Flutter project, scaffold `lib/{app,core,features,shared}` structure | — | [Mobile Architecture § 2](08-mobile-architecture.md#2-folder-organization) |
| 6 | Wire Riverpod + go_router skeleton with 5 placeholder tab routes | 5 | [Mobile Architecture § 1 & § 3](08-mobile-architecture.md#1-state-management) |
| 7 | Configure Flutter CI (analyze, format check, test job skeleton) | 5 | [CI/CD Pipeline § 3.2](11-cicd-pipeline.md#32-mobile-flutter) |
| 8 | Provision staging environment, deploy Sprint 1's health-check endpoint end-to-end | 4, 7 | [Deployment Guide § 3](12-deployment-guide.md#3-staging--production-infrastructure) |
| 9 | Migrations: `oauth_identities`, `devices`, `auth_refresh_tokens`, `password_reset_tokens` | 3 | [Database Design § 3.1](04-database-design.md#31-identity--auth) |
| 10 | `AuthService`: register + email/password login, JWT issuance (RS256) | 9 | [Authentication feature](features/authentication.md), [ADR-0005](adr/0005-jwt-refresh-token-auth.md) |
| 11 | Refresh token rotation + reuse-detection (family revocation, BR-3) | 10 | [Authentication § Business Rules](features/authentication.md#business-rules) |
| 12 | Google Sign-In (server-side token verification) | 10 | [Authentication § APIs](features/authentication.md#apis) |
| 13 | Apple Sign-In (server-side token verification) | 10 | [Authentication § APIs](features/authentication.md#apis) |
| 14 | Email verification + password reset endpoints | 10 | [API Examples — Auth](api-examples/auth.md) |
| 15 | Session/device management endpoints (`GET/DELETE /auth/sessions`) | 10 | [Authentication § FR-106](features/authentication.md#functional-requirements) |
| 16 | Pest Feature tests: refresh rotation/reuse, cross-user isolation, rate limiting | 11–15 | [Testing Strategy § 5](10-testing-strategy.md#5-api-testing) |
| 17 | Flutter: Login + Signup screens, form validation | 6 | [Screens — Login](screens/login.md), [Screens — Signup](screens/signup.md) |
| 18 | Flutter: Dio `AuthInterceptor` (attach token, transparent refresh on 401) | 17 | [Mobile Architecture § 9](08-mobile-architecture.md#9-networking-layer) |
| 19 | Flutter: secure token storage (`flutter_secure_storage`) | 18 | [Mobile Architecture § 5](08-mobile-architecture.md#5-local-storage) |
| 20 | End-to-end integration test: register → verify → login → refresh → logout, on staging | 16, 19 | [Authentication § Acceptance Criteria](features/authentication.md#acceptance-criteria) |

---

## Sprint 2 — User Profile & AI Onboarding

Full sprint context: [Development Roadmap § Phase 1 · Sprint 2](16-development-roadmap.md#phase-1--sprint-2--user-profile--ai-onboarding).

| # | Task | Depends on | Primary doc(s) |
|---|---|---|---|
| 1 | `GET/PATCH /me` endpoint + Form Request validation | Sprint 1 #10 | [Profile § APIs](features/profile.md#apis) |
| 2 | Flutter Profile screen (view + Edit Profile bottom sheet) | 1, Sprint 1 #17 | [Screens — Profile](screens/profile.md) |
| 3 | Basic Settings screen: theme (light/dark/system), unit preference | Sprint 1 #17 | [Settings feature](features/settings.md) |
| 4 | Migrations/model: `goals` table seed support for onboarding | — | [Database Design § 3.5](04-database-design.md#35-habits--goals) |
| 5 | Onboarding flow screens: profile basics, goal selection, experience level | 2 | [Onboarding feature](features/onboarding.md) |
| 6 | Onboarding: "Meet Your Coach" step UI, feature-flagged off (no live AI call yet) | 5 | [Onboarding § Release Phase](features/onboarding.md) |
| 7 | Notification permission prompt screen with contextual copy | 5 | [Onboarding § UI Flow](features/onboarding.md#ui-flow) |
| 8 | `POST /devices` endpoint (push token registration, backend only — full Notifications module is Sprint 5) | — | [API Specification § 6.11](05-api-specification.md#611-notifications) |
| 9 | Pest tests: profile update, onboarding goal creation | 1, 4 | [Testing Strategy § 5](10-testing-strategy.md#5-api-testing) |
| 10 | Widget tests: onboarding flow navigation, skip/resume behavior | 5–7 | [Onboarding § Edge Cases](features/onboarding.md#edge-cases) |
| 11 | Integration test: full onboarding flow reaches Home with AI step correctly deferred | 6, 10 | [Onboarding § Acceptance Criteria](features/onboarding.md#acceptance-criteria) |

---

## Sprint 3 — Workout Engine & Exercise Library

Full sprint context: [Development Roadmap § Phase 1 · Sprint 3](16-development-roadmap.md#phase-1--sprint-3--workout-engine--exercise-library).

| # | Task | Depends on | Primary doc(s) |
|---|---|---|---|
| 1 | Migrations: `exercises`, `workout_templates`, `template_exercises` | Sprint 1 | [Database Design § 3.2](04-database-design.md#32-exercise-library--workouts) |
| 2 | Exercise seeder (~150 curated exercises, idempotent `updateOrCreate`) | 1 | [Database Seeding](database-seeding.md) |
| 3 | `GET /exercises` search/filter + `GET /exercises/{id}` + `POST /exercises` (custom) | 1, 2 | [Exercise Library § APIs](features/exercise-library.md#apis) |
| 4 | Migrations: `workouts`, `workout_exercises`, `workout_sets` | 1 | [Database Design § 3.2](04-database-design.md#32-exercise-library--workouts) |
| 5 | `WorkoutRepository` + `WorkoutService.logWorkout()` with `client_uuid` idempotent upsert | 4 | [Workout Tracking § APIs](features/workout-tracking.md#apis) |
| 6 | `PrDetectionService` (new-max detection at save time) | 5 | [Workout Tracking § Business Rules](features/workout-tracking.md#business-rules) |
| 7 | `POST /workouts`, `GET /workouts`, `PATCH/DELETE /workouts/{id}` endpoints | 5, 6 | [API Examples — Workouts](api-examples/workouts.md) |
| 8 | `POST /sync/workouts` batch upsert endpoint with per-item success/failure | 7 | [Mobile Architecture § Synchronization](08-mobile-architecture.md#6-synchronization) |
| 9 | Flutter: Drift schema for `workouts`/`workout_exercises`/`workout_sets` + local `SyncQueue` table | Sprint 1 #6 | [Mobile Architecture § 4–5](08-mobile-architecture.md#4-offline-first-strategy) |
| 10 | Flutter: `SyncEngine` with per-item retry + exponential backoff | 9 | [Mobile Architecture § 6](08-mobile-architecture.md#6-synchronization) |
| 11 | Flutter: Exercise Picker screen (search, filter, custom exercise creation) | 3 | [Exercise Library § Screen List](features/exercise-library.md#screen-list) |
| 12 | Flutter: Active Workout screen (Set Row entry, rest timer, PR celebration) | 9, 11 | [Screens — Workout](screens/workout.md) |
| 13 | Flutter: connectivity listener wired to trigger `SyncEngine` on reconnect | 10 | [Mobile Architecture § 4](08-mobile-architecture.md#4-offline-first-strategy) |
| 14 | `POST /templates`, `GET /templates`, `GET/PATCH/DELETE /templates/{id}` (manual templates only — AI-generate is Sprint 5) | 1 | [Workout Templates § APIs](features/workout-tracking.md#apis) |
| 15 | Pest tests: PR detection boundary cases, `client_uuid` idempotency, cross-user isolation | 5–8 | [Testing Strategy § 5](10-testing-strategy.md#5-api-testing) |
| 16 | Offline integration test: log workout fully offline, verify sync + server-ID reconciliation on reconnect | 10, 12, 13 | [SRS § 7 — canonical offline scenario](02-srs.md#7-acceptance-criteria-format) |
| 17 | Offline integration test: partial-batch sync failure, verify failed item stays queued and retries independently | 16 | [Testing Strategy § 6](10-testing-strategy.md#6-offline-sync-testing) |

---

## Sprint 4 — Tracking, Progress & Habits

Full sprint context: [Development Roadmap § Phase 1 · Sprint 4](16-development-roadmap.md#phase-1--sprint-4--tracking-progress--habits).

| # | Task | Depends on | Primary doc(s) |
|---|---|---|---|
| 1 | Migrations: `foods`, `meals`, `meal_items`, `water_logs` | Sprint 1 | [Database Design § 3.3](04-database-design.md#33-nutrition) |
| 2 | Food seeder (~200 common foods, idempotent) | 1 | [Database Seeding](database-seeding.md) |
| 3 | `GET /foods`, `POST /foods`, `POST /meals`, `GET/PATCH/DELETE /meals/{id}` | 1, 2 | [Nutrition § APIs](features/nutrition.md#apis) |
| 4 | `GET /nutrition/daily-summary` aggregation endpoint | 3 | [API Examples — Nutrition](api-examples/nutrition.md) |
| 5 | Calorie/macro target suggestion formula (deterministic, Mifflin-St Jeor-style) | 3 | [Calorie Tracker § F-CAL-01](features/calorie-tracker.md#functional-requirements) |
| 6 | `POST /water-logs` upsert-by-date endpoint | 1 | [Water Intake § APIs](features/water-intake.md#apis) |
| 7 | Migrations + endpoints: `body_measurements`, `progress_photos` (multipart upload, pre-signed URL) | Sprint 1 | [Database Design § 3.4](04-database-design.md#34-body-metrics) |
| 8 | `GET /body-measurements/trends` endpoint | 7 | [Body Measurements § APIs](features/body-measurements.md#apis) |
| 9 | Migrations + endpoints: `habits`, `habit_logs` + streak computation | Sprint 1 | [Database Design § 3.5](04-database-design.md#35-habits--goals) |
| 10 | Scheduled job: weekly streak-break evaluation (BR-7) | 9 | [Habits § Business Rules](features/habits.md#business-rules) |
| 11 | Migrations + endpoints: `goals` CRUD + auto-achievement check | Sprint 1 | [Goals § APIs](features/goals.md#apis) |
| 12 | Extend Drift schema + Sync Engine (Sprint 3) to cover meals/water/habits (reuse, don't rebuild) | Sprint 3 #9–10 | [Mobile Architecture § 4](08-mobile-architecture.md#4-offline-first-strategy) |
| 13 | Flutter: Nutrition screen (daily summary ring, meal list, water tile) | 12 | [Screens — Nutrition](screens/nutrition.md) |
| 14 | Flutter: Analytics/Progress screen scaffold — Body Measurements, Progress Photos, Habits, Goals sections | 12 | [Screens — Analytics](screens/analytics.md) |
| 15 | Flutter: Dashboard cards wired to real tracking data (still no AI card — Sprint 5) | 13, 14 | [Screens — Dashboard](screens/dashboard.md) |
| 16 | Object storage integration for progress photo uploads (S3-compatible, pre-signed URLs) | 7 | [Progress Photos § Business Rules](features/progress-photos.md#business-rules) |
| 17 | Pest tests: nutrition daily-summary math, streak reset job, goal auto-achievement | 4, 10, 11 | [Testing Strategy § 5](10-testing-strategy.md#5-api-testing) |
| 18 | Integration test: a full week of tracked data across all five domains logs and summarizes correctly | 15–17 | [IMPLEMENTATION_ORDER.md § Progress Tracking](IMPLEMENTATION_ORDER.md#9-progress-tracking) |

---

## Sprint 5 — AI Recommendations, Analytics & Notifications

Full sprint context: [Development Roadmap § Phase 1 · Sprint 5](16-development-roadmap.md#phase-1--sprint-5--ai-recommendations-analytics--notifications).

**This is the highest-risk sprint in Phase 1 — see [AI_DEVELOPMENT_GUIDE.md § Splitting Large Features](AI_DEVELOPMENT_GUIDE.md#splitting-large-features-into-multiple-prompts) before starting task 3.**

| # | Task | Depends on | Primary doc(s) |
|---|---|---|---|
| 1 | `AiProviderInterface` + `ClaudeProvider`, wired to real Claude Messages API (non-streaming first) | Sprint 1 | [AI Coaching Engine § 6](09-ai-coaching-engine.md#6-model-abstraction-layer) |
| 2 | `PersonaRegistry` + `ContextBuilderService` skeleton (`personal_trainer` persona only) | 1 | [AI Coaching Engine § 2–3](09-ai-coaching-engine.md#2-prompt-management) |
| 3 | Structured workout generation: `POST /templates/ai-generate`, exercise-library-grounded output validation | 2, Sprint 3 #14 | [AI Prompt — Workout Coach](ai/workout-coach.md) |
| 4 | Invalid-`exerciseSlug` retry-then-fallback-to-preset path | 3 | [AI Prompt — Workout Coach § Error Handling](ai/workout-coach.md#error-handling) |
| 5 | Lightweight exercise-explanation endpoint (single-turn, smaller model tier) | 2 | [Exercise Details § FR-604](features/exercise-details.md#functional-requirements) |
| 6 | `RateLimitAi` middleware + `ai_usage_logs`-backed daily token budget | 1 | [AI Coaching Engine § 9](09-ai-coaching-engine.md#9-rate-limiting) |
| 7 | Safety guardrail output filter (BR-9 disclaimer check/append) | 2 | [AI Coaching Engine § 7](09-ai-coaching-engine.md#7-safety-guardrails) |
| 8 | `DailyFitnessScoreService` (deterministic formula) + table-driven unit tests | Sprint 4 | [AI Coaching Engine § 5](09-ai-coaching-engine.md#5-recommendation-engine) |
| 9 | Timezone-bucketed scheduled job: `ComputeDailyFitnessScoreJob` | 8 | [Backend Architecture § 6](07-backend-architecture.md#6-scheduled-tasks-routesconsolephp--scheduler) |
| 10 | `GET /scores/today`, `GET /scores` endpoints | 9 | [API Examples — Daily Fitness Score](api-examples/daily-fitness-score.md) |
| 11 | `GenerateWeeklyReviewJob` (Progress Summary, batch-generated) | 2, 9 | [AI Prompt — Weekly Review](ai/weekly-review.md) |
| 12 | Migrations + endpoints: `notifications`, `notification_preferences` | Sprint 1 | [Database Design § 3.7](04-database-design.md#37-notifications) |
| 13 | FCM/APNs push dispatch service, category-preference-gated | 12 | [Notifications § Business Rules](features/notifications.md#business-rules) |
| 14 | Event listeners wiring notification triggers: PR detected, streak risk, goal achieved, review ready | 13, Sprint 3–4 | [Backend Architecture § 5](07-backend-architecture.md#5-events) |
| 15 | Flutter: Score Ring component + wired into Dashboard | 10 | [Components — Progress Ring](components/progress-ring.md) |
| 16 | Flutter: AI recommendation card on Dashboard, sourced from Weekly Review output | 11, 15 | [Dashboard § UI Flow](features/dashboard.md#ui-flow) |
| 17 | Flutter: Notification Center + Preferences screen | 13 | [Screens — Settings](screens/settings.md) |
| 18 | Activate onboarding's deferred AI step (Sprint 2 #6) using the now-live generation endpoint | 3, Sprint 2 #6 | [Onboarding § Dependencies](features/onboarding.md) |
| 19 | Adversarial-input guardrail tests (not just happy path) | 7 | [AI Prompt — Workout Coach § Guardrails](ai/workout-coach.md#guardrails) |
| 20 | Pest tests: rate limiting, budget exhaustion response shape, notification preference enforcement | 6, 13 | [API Examples — AI Coaching](api-examples/ai-coaching.md) |

---

## Sprint 6 — Testing, Performance & Security

Full sprint context: [Development Roadmap § Phase 1 · Sprint 6](16-development-roadmap.md#phase-1--sprint-6--testing-performance--security).

| # | Task | Depends on | Primary doc(s) |
|---|---|---|---|
| 1 | Run full [Production Hardening § 1 Security Checklist](14-production-hardening.md#1-security-checklist) against the codebase, file findings | Sprints 1–5 | [RELEASE_CHECKLIST.md § Security](RELEASE_CHECKLIST.md#security) |
| 2 | Remediate findings from task 1 | 1 | — |
| 3 | k6 load test scripts against staging (NFR-1/NFR-2 targets) | Sprints 1–5 | [Testing Strategy § 7](10-testing-strategy.md#7-performance-testing) |
| 4 | E2E device-lab test suite (Patrol/`integration_test` on Firebase Test Lab) | Sprints 1–5 | [Testing Strategy § 8](10-testing-strategy.md#8-load-testing) |
| 5 | Manual AI smoke suite against the real Claude API (fixed prompt set) | Sprint 5 | [Testing Strategy § 5](10-testing-strategy.md#5-api-testing) |
| 6 | Settings: notification-preferences UI finalized | Sprint 5 #17 | [Settings feature](features/settings.md) |
| 7 | Settings: data export flow (`POST /me/export`, queued job, pre-signed download link) | Sprint 1 | [Settings § APIs](features/settings.md#apis) |
| 8 | Settings: account deletion flow (soft-delete + 30-day grace period, BR-6) | Sprint 1 | [Settings § Business Rules](features/settings.md#business-rules) |
| 9 | Scheduled job: hard-delete accounts past grace period | 8 | [Backend Architecture § 6](07-backend-architecture.md#6-scheduled-tasks-routesconsolephp--scheduler) |
| 10 | `subscriptions` table migration + default-full-access entitlement check (no billing) | Sprint 1 | [Subscriptions § Release Phase](features/subscriptions.md) |
| 11 | Monitoring dashboards + alert rules finalized in staging/production | Sprints 1–5 | [Monitoring & Logging § 8–9](13-monitoring-logging.md#8-alerting) |
| 12 | Achievements (stretch): `achievements`/`user_achievements` tables + evaluator | Sprints 3–4 | [Achievements feature](features/achievements.md) |
| 13 | Backup verification: automated nightly restore-and-checksum job | Sprint 1 | [Production Hardening § 7](14-production-hardening.md#7-backup-verification) |
| 14 | Dependency vulnerability scan clean (or exceptions documented) | 1–13 | [CI/CD Pipeline § 4](11-cicd-pipeline.md#4-automated-testing-ci-gates) |

---

## Sprint 7 — UAT & Production Launch

Full sprint context: [Development Roadmap § Phase 1 · Sprint 7](16-development-roadmap.md#phase-1--sprint-7--uat--production-launch).

| # | Task | Depends on | Primary doc(s) |
|---|---|---|---|
| 1 | Closed beta build to TestFlight (iOS) and Play internal track (Android) | Sprint 6 | [CI/CD Pipeline § 5](11-cicd-pipeline.md#5-release-management--versioning) |
| 2 | Fastlane lanes configured for both platforms | 1 | [CI/CD Pipeline § 5](11-cicd-pipeline.md#5-release-management--versioning) |
| 3 | In-app help center content published from [User Documentation](15-user-documentation.md) | — | [User Documentation § 2–4](15-user-documentation.md#2-user-guide-help-center-article-outline) |
| 4 | Store listing assets: screenshots, icons, descriptions per [RELEASE_CHECKLIST.md § App Store](RELEASE_CHECKLIST.md#app-store) | — | [RELEASE_CHECKLIST.md](RELEASE_CHECKLIST.md) |
| 5 | Privacy Policy + Terms of Service published | — | [Production Hardening § 9](14-production-hardening.md#9-compliance-considerations) |
| 6 | Production deployment executed | Sprint 6 | [Deployment Guide](12-deployment-guide.md) |
| 7 | Rollback drill rehearsed successfully in production | 6 | [Deployment Guide § Rollback Procedures](12-deployment-guide.md#10-rollback-procedures) |
| 8 | Beta feedback triaged, blocking issues fixed | 1 | — |
| 9 | `v1.0.0` tagged and released | 6–8 | [Release Management § Release Process](release-management.md#release-process) |
| 10 | App Store + Play Store submission, review passed | 4, 5, 9 | [RELEASE_CHECKLIST.md § App Store](RELEASE_CHECKLIST.md#app-store) |
| 11 | Post-launch feedback collection mechanism live (in-app + support channel) | 9 | — |
| 12 | Post-launch monitoring watch (first 24–48h) | 6 | [MASTER_IMPLEMENTATION_PLAN.md § Deployment Checklist](../MASTER_IMPLEMENTATION_PLAN.md#deployment-checklist) |
| 13 | Phase 1 exit criteria review meeting; Phase 2 kickoff decision recorded | 9–12 | [Phased Release Strategy § Exit Criteria](PHASED_RELEASE_STRATEGY.md#exit-criteria-for-each-phase) |
