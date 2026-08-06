# Phase 1 Scope — Intelligent Fitness Platform

**Status:** This is the **implementation contract for Version 1** (`v1.0.0`). Every feature listed here ships at launch; nothing listed here is optional.
**Related documents:** [Phased Release Strategy](PHASED_RELEASE_STRATEGY.md) · [PHASE2_SCOPE.md](PHASE2_SCOPE.md) · [Development Roadmap § Phase 1](16-development-roadmap.md#phase-1--intelligent-fitness-platform-mvp) · [SRS](02-srs.md) · [MASTER_IMPLEMENTATION_PLAN.md](../MASTER_IMPLEMENTATION_PLAN.md)

## Table of Contents
- [How to Read This Document](#how-to-read-this-document)
- [Feature Matrix](#feature-matrix)
- [Category Detail](#category-detail)
- [Explicitly Out of Phase 1](#explicitly-out-of-phase-1)
- [Notes on Judgment Calls](#notes-on-judgment-calls)

## How to Read This Document

Each category below corresponds to an existing, unchanged specification elsewhere in this repository — this document does not redefine any feature, it allocates already-specified features to Phase 1 and adds the planning metadata (priority, dependencies, complexity, sprint, acceptance criteria) needed to execute against it. Priority uses the same vocabulary as [SRS](02-srs.md): **Critical** (launch-blocking), **High** (expected at launch, degraded launch possible without it), **Medium** (should ship, not launch-blocking in isolation), **Low** (stretch — ships if sprint capacity allows).

## Feature Matrix

| # | Category | Primary Doc(s) | Priority | Complexity | Sprint | Dependencies |
|---|---|---|---|---|---|---|
| 1 | Authentication | [Authentication](features/authentication.md) | Critical | L | 1 | None (foundational) |
| 2 | Profile | [Profile](features/profile.md) | High | S | 2 | Authentication |
| 3 | AI Onboarding | [Onboarding](features/onboarding.md) | Critical | M | 2 | Authentication, Workout Engine (Sprint 3), AI Workout Recommendations (Sprint 5, for the AI step specifically) |
| 4 | Dashboard | [Dashboard](features/dashboard.md), [Dashboard screen](screens/dashboard.md) | Critical | M | 4 (scaffold) / 5 (finalize) | Tracking domains, DFS computation, AI Recommendations |
| 5 | Workout Tracking | [Workout Tracking](features/workout-tracking.md), [Workout screen](screens/workout.md) | Critical | XL | 3 | Authentication, Exercise Library |
| 6 | Exercise Library | [Exercise Library](features/exercise-library.md) | Critical | M | 3 | Database Seeding |
| 7 | Workout History | [Workout History](features/workout-history.md) | High | M | 3 | Workout Tracking |
| 8 | Progress Tracking | [Goals](features/goals.md), [Analytics screen](screens/analytics.md) | Medium | M | 4 | Body Measurements, Habits, Workout Tracking |
| 9 | Body Measurements | [Body Measurements](features/body-measurements.md) | High | S | 4 | Authentication |
| 10 | Progress Photos | [Progress Photos](features/progress-photos.md) | Medium | S | 4 | Object storage infra ([Deployment Guide](12-deployment-guide.md)) |
| 11 | Habit Tracking | [Habits](features/habits.md) | High | M | 4 | Authentication |
| 12 | Water Intake | [Water Intake](features/water-intake.md) | Medium | S | 4 | Authentication |
| 13 | Basic Analytics | [Analytics screen](screens/analytics.md), [Daily Fitness Score — AI Coaching Engine § 5](09-ai-coaching-engine.md#5-recommendation-engine) | High | M | 5 | All Sprint 3–4 tracking domains |
| 14 | AI Workout Recommendations | [Workout Tracking § FR-206](features/workout-tracking.md#functional-requirements), [AI Prompt — Workout Coach](ai/workout-coach.md) | High | L | 5 | Claude API integration, Exercise Library |
| 15 | Exercise Guidance | [Exercise Details § FR-604](features/exercise-details.md#functional-requirements) | Medium | S | 5 | Claude API integration, Exercise Library |
| 16 | Notifications | [Notifications](features/notifications.md) | High | M | 5 | FCM/APNs setup ([Backend Architecture § 7](07-backend-architecture.md#7-notifications)) |
| 17 | Offline Support | [Mobile Architecture § 4](08-mobile-architecture.md#4-offline-first-strategy) (cross-cutting, not a standalone feature doc) | Critical | XL | 3–4 (built alongside Workout Tracking & Nutrition) | Drift local schema, Sync Engine |
| 18 | Subscription Foundation | [Subscriptions](features/subscriptions.md) | Low | M | 6 | None — scaffolding only, no billing integration live |
| 19 | Settings | [Settings](features/settings.md) | Critical | M | 2 (basic) / 6 (finalized) | Authentication, Notifications |
| 20 | Monitoring | [Monitoring & Logging](13-monitoring-logging.md) | Critical | M | 1 (foundation) / 6 (dashboards/alerts finalized) | Deployment infra |
| 21 | CI/CD | [CI/CD Pipeline](11-cicd-pipeline.md) | Critical | M | 1 | Repository/tooling setup |
| 22 | Deployment | [Deployment Guide](12-deployment-guide.md) | Critical | L | 1 (dev/staging) / 7 (production launch) | CI/CD |
| 23 | Testing | [Testing Strategy](10-testing-strategy.md) | Critical | L | Every sprint (continuous) / 6 (hardening pass) | N/A |
| 24 | Production Hardening | [Production Hardening](14-production-hardening.md) | Critical | L | 6 | Feature-complete build |

**Additional items beyond the requested category list, included by extension** — see [Notes on Judgment Calls](#notes-on-judgment-calls) for why each is in Phase 1 despite not being separately named in the original phase-scoping brief:

| # | Category | Primary Doc(s) | Priority | Complexity | Sprint | Dependencies |
|---|---|---|---|---|---|---|
| 25 | Nutrition (core tracking) | [Nutrition](features/nutrition.md) | High | M | 4 | Authentication |
| 26 | Calorie Tracker | [Calorie Tracker](features/calorie-tracker.md) | Medium | S | 4 | Nutrition, Goals |
| 27 | Achievements (stretch) | [Achievements](features/achievements.md) | Low | S | 6 (stretch) | Habits, Workout Tracking, Goals |

## Category Detail

Each entry below gives the acceptance criteria that gate calling the category "done" for Phase 1 — these are launch gates, not exhaustive feature-level acceptance criteria (which already exist per-feature in each linked spec's own **Acceptance Criteria** section).

### Authentication
Acceptance: FR-101–FR-109 all pass their existing [Authentication § Acceptance Criteria](features/authentication.md#acceptance-criteria); refresh-token rotation and reuse detection specifically load-tested per [ADR-0005 § Future Review Criteria](adr/0005-jwt-refresh-token-auth.md#future-review-criteria).

### Profile
Acceptance: profile fields read/write correctly and propagate to AI context per [Profile § Acceptance Criteria](features/profile.md#acceptance-criteria).

### AI Onboarding
**Phase 1 scope note:** the "Meet Your Coach" onboarding step ([Onboarding § UI Flow](features/onboarding.md#ui-flow)) is simplified from the original design — it triggers the Phase 1 **AI Workout Recommendations** capability (a single structured generation call producing a first `workout_templates` row) plus a short AI-written welcome message, **not** an open-ended back-and-forth conversation. The full conversational "Meet Your Coach" experience is a Phase 2 enhancement once the Conversational Coach ships. Acceptance: [Onboarding § Acceptance Criteria](features/onboarding.md#acceptance-criteria), read with this simplification in mind.

### Dashboard
Acceptance: [Dashboard § Acceptance Criteria](features/dashboard.md#acceptance-criteria); AI recommendation card sources content from the Sprint 5 Progress Summary / AI Workout Recommendations output, not a live conversational call.

### Workout Tracking
Acceptance: [Workout Tracking § Acceptance Criteria](features/workout-tracking.md#acceptance-criteria), including the full offline-logging Gherkin scenario in [SRS § 7](02-srs.md#7-acceptance-criteria-format).

### Exercise Library
Acceptance: [Exercise Library § Acceptance Criteria](features/exercise-library.md#acceptance-criteria); seeded with the full curated exercise catalog per [Database Seeding](database-seeding.md).

### Workout History
Acceptance: [Workout History § Acceptance Criteria](features/workout-history.md#acceptance-criteria).

### Progress Tracking
Acceptance: [Goals § Acceptance Criteria](features/goals.md#acceptance-criteria); trend charts render correctly per [Analytics screen § Performance Considerations](screens/analytics.md#performance-considerations).

### Body Measurements
Acceptance: [Body Measurements § Acceptance Criteria](features/body-measurements.md#acceptance-criteria).

### Progress Photos
Acceptance: [Progress Photos § Acceptance Criteria](features/progress-photos.md#acceptance-criteria), including the privacy/pre-signed-URL test.

### Habit Tracking
Acceptance: [Habits § Acceptance Criteria](features/habits.md#acceptance-criteria).

### Water Intake
Acceptance: [Water Intake § Acceptance Criteria](features/water-intake.md#acceptance-criteria).

### Basic Analytics
Scope: Daily Fitness Score (deterministic formula, [AI Coaching Engine § 5](09-ai-coaching-engine.md#5-recommendation-engine)) plus trend charts for weight, workout volume, and DFS history. **Excludes** predictive trajectory analysis (Phase 2 "Advanced Analytics," see [PHASE2_SCOPE.md](PHASE2_SCOPE.md)). Acceptance: DFS formula unit-tested per [Testing Strategy § Unit Testing](10-testing-strategy.md#3-unit-testing); score computes correctly for a full test cohort before launch.

### AI Workout Recommendations
Scope: `POST /templates/ai-generate` structured generation only ([API Examples — Workout Templates](api-examples/workout-templates.md#post-templatesai-generate)) — **not** the open-ended conversational Personal Trainer chat, which is Phase 2's Conversational Coach. Acceptance: generation produces valid, exercise-library-grounded templates per [AI Prompt — Workout Coach § Error Handling](ai/workout-coach.md#error-handling) (invalid `exerciseSlug` retry/fallback path tested).

### Exercise Guidance
Scope: the single-turn "Ask about this exercise" entry point ([Exercise Details § FR-604](features/exercise-details.md#functional-requirements)) — explicitly already scoped in the original doc as lightweight and non-conversational, which is exactly why it belongs in Phase 1 rather than Phase 2. Acceptance: [Exercise Details § Acceptance Criteria](features/exercise-details.md#acceptance-criteria).

### Notifications
Scope: reminders, streak risk, PR detected, goal achieved, weekly progress summary ready — all deterministic or Phase-1-AI-sourced triggers ([Notifications § Business Rules](features/notifications.md#business-rules)). Acceptance: [Notifications § Acceptance Criteria](features/notifications.md#acceptance-criteria); category preferences enforced server-side, verified by test.

### Offline Support
Scope: full offline logging for Workout Tracking, Nutrition, and Habits per [Mobile Architecture § 4](08-mobile-architecture.md#4-offline-first-strategy) — this is the single highest-technical-risk item in Phase 1 (see [ADR-0007 § Consequences](adr/0007-offline-first-architecture.md#consequences)) and is treated with dedicated sprint time, not folded silently into feature work. Acceptance: the offline sync integration test suite in [Testing Strategy § 6](10-testing-strategy.md#6-offline-sync-testing) passes in full, including partial-batch-failure scenarios.

### Subscription Foundation
Scope: the `subscriptions` table and entitlement-check hooks described in [Subscriptions § Database Tables](features/subscriptions.md#database-tables) are scaffolded so Phase 2+ monetization doesn't require a schema migration — **no real billing integration, no App Store/Play Store receipt validation, no pricing UI ships in Phase 1.** This directly matches [Subscriptions § Status](features/subscriptions.md) already stating the feature is "not yet scoped by Product" — Phase 1 lays plumbing only, it does not resolve that open question. Acceptance: entitlement-check function exists and defaults every user to full access (no gated features in Phase 1); schema reviewed but not user-facing.

### Settings
Acceptance: [Settings § Acceptance Criteria](features/settings.md#acceptance-criteria), including data export and account deletion — both explicitly launch-blocking per [Production Hardening § 9](14-production-hardening.md#9-compliance-considerations) compliance requirements, not deferrable.

### Monitoring
Acceptance: dashboards and alerts in [Monitoring & Logging § 8–9](13-monitoring-logging.md#8-alerting) are live in production before public launch, not added post-launch.

### CI/CD
Acceptance: full pipeline per [CI/CD Pipeline](11-cicd-pipeline.md) green and enforced (branch protection) before Sprint 2 begins — this is infrastructure other sprints depend on, so it lands earliest.

### Deployment
Acceptance: production environment provisioned and validated per [Deployment Guide](12-deployment-guide.md) with a successful rollback drill performed before launch ([Deployment Guide § Rollback Procedures](12-deployment-guide.md#10-rollback-procedures)).

### Testing
Acceptance: coverage across all layers per [Testing Strategy](10-testing-strategy.md) for every Phase 1 feature; no feature is considered "done" without its tests, per the standing rule in [Development Roadmap § Cross-Phase Notes](16-development-roadmap.md#cross-phase-notes).

### Production Hardening
Acceptance: full [Production Hardening § 1 Security Checklist](14-production-hardening.md#1-security-checklist) passed, including a penetration test pass before public launch.

## Explicitly Out of Phase 1

To avoid ambiguity, everything below is **not** in Phase 1, even where a related capability is:

- The full Coach tab / open-ended conversational chat UI ([AI Coach feature](features/ai-coach.md), [AI Coach screen](screens/ai-coach.md)) — Phase 2.
- Nutrition Coach, Recovery Coach, Habit Coach, Motivation Coach personas — Phase 2.
- Monthly Review, Predictive Coaching, Goal Recommendation AI — Phase 2.
- Wearable Integrations — Phase 2.
- Community, Challenges, Leaderboards — Phase 2.
- Full subscription billing/monetization — Phase 2+ (pending Product pricing decision).
- Barcode food scanning ([Nutrition § Future Improvements](features/nutrition.md#future-improvements)) — remains Future beyond both phases, unchanged from original scoping.

## Notes on Judgment Calls

The original phase-scoping brief's Phase 1 category list did not explicitly name **Nutrition** or **Calorie Tracker**, while explicitly naming **Water Intake**. Given Water Intake is a sub-feature of the same Nutrition domain, and the Daily Fitness Score's `nutrition` component ([AI Coaching Engine § 5](09-ai-coaching-engine.md#5-recommendation-engine)) requires meal-logging data to function at all, both [Nutrition](features/nutrition.md) and [Calorie Tracker](features/calorie-tracker.md) are included in Phase 1 by necessary implication (Priority High and Medium respectively, Sprint 4) — omitting them would leave Water Intake and Basic Analytics unable to function as specified. **The one Nutrition sub-feature explicitly deferred is FR-304 (AI-generated meal suggestions)**, which depends on the Nutrition Coach persona and is correctly Phase 2 — see [Nutrition feature](features/nutrition.md) metadata block.

**Goals** was similarly not explicitly named but is included in Phase 1 (Medium priority) because "Progress Tracking" — which *was* explicitly named — has no meaningful implementation without it.

**Achievements** is included as a Low-priority Phase 1 stretch item (row 27 in the [Feature Matrix](#feature-matrix) above) rather than pushed to Phase 2, since it has no AI or Phase-2-capability dependency and directly serves Phase 1's own retention success metrics.
