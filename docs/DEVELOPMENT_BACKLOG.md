# Development Backlog

**Product:** Aesthetic Coach
**Purpose:** the prioritized backlog across all three time horizons — what ships at launch, what's a near-term polish item once Phase 1 is live, and what's the larger Phase 2 investment. This document adds **Business Value** and **Technical Risk** to the scope/priority data already established in [PHASE1_SCOPE.md](PHASE1_SCOPE.md) and [PHASE2_SCOPE.md](PHASE2_SCOPE.md) — it doesn't redefine scope, it reformats it for backlog grooming.
**Related documents:** [PHASE1_SCOPE.md](PHASE1_SCOPE.md) · [PHASE2_SCOPE.md](PHASE2_SCOPE.md) · [Phased Release Strategy](PHASED_RELEASE_STRATEGY.md)

## Table of Contents
- [Legend](#legend)
- [MVP (Phase 1)](#mvp-phase-1)
- [Post-Launch Improvements](#post-launch-improvements)
- [Phase 2](#phase-2)

## Legend

**Priority:** Critical / High / Medium / Low (matches [PHASE1_SCOPE.md](PHASE1_SCOPE.md#feature-matrix) exactly for Phase 1 items). **Estimated Effort:** S/M/L/XL (relative complexity, matching the scale used throughout [Development Roadmap](16-development-roadmap.md)). **Business Value:** High/Medium/Low — impact on the [PRD § Success Metrics](01-prd.md#8-success-metrics)/[Phased Release Strategy § Success Metrics](PHASED_RELEASE_STRATEGY.md#success-metrics) targets. **Technical Risk:** High/Medium/Low — likelihood of the item taking meaningfully longer or breaking something else than its effort estimate suggests.

## MVP (Phase 1)

Full spec, acceptance criteria, and sprint assignment for every row: [PHASE1_SCOPE.md § Feature Matrix](PHASE1_SCOPE.md#feature-matrix).

| Item | Priority | Effort | Business Value | Technical Risk | Dependencies |
|---|---|---|---|---|---|
| Authentication | Critical | L | High — nothing ships without it | Medium (refresh-token rotation correctness) | None |
| Profile | High | S | Medium | Low | Authentication |
| AI Onboarding | Critical | M | High — drives activation ([PRD Objective O2](01-prd.md#2-objectives)) | Low (Phase 1's simplified, non-conversational form) | Authentication, Workout Engine, AI Recommendations |
| Dashboard | Critical | M | High — the app's primary daily touchpoint | Low | Tracking domains, DFS, AI Recommendations |
| Workout Tracking | Critical | XL | High — core product loop | **High** (offline sync correctness) | Authentication, Exercise Library |
| Exercise Library | Critical | M | High | Low | Database Seeding |
| Workout History | High | M | Medium | Low | Workout Tracking |
| Progress Tracking (Goals) | Medium | M | Medium | Low | Authentication |
| Body Measurements | High | S | Medium | Low | Authentication |
| Progress Photos | Medium | S | Medium | Low | Object storage infra |
| Habit Tracking | High | M | Medium-High (retention driver) | Low | Authentication |
| Water Intake | Medium | S | Low-Medium | Low | Nutrition domain |
| Nutrition (core tracking) | High | M (part of Sprint 4 XL) | High | Low | Authentication |
| Calorie Tracker | Medium | S | Medium | Low | Nutrition, Goals |
| Basic Analytics (Daily Fitness Score) | High | M | High — the product's signature feature | Medium (formula tuning is inherently iterative) | All tracking domains |
| AI Workout Recommendations | High | L | High — first real AI differentiator | **High** (guardrails, exercise-grounding correctness) | Claude API, Exercise Library |
| Exercise Guidance (AI explanation) | Medium | S | Medium | Low | Claude API, Exercise Library |
| Notifications | High | M | Medium-High (re-engagement) | Low | FCM/APNs setup |
| Offline Support | Critical | XL (cross-cutting) | High — core to the product's usability promise | **High** (the single riskiest engineering item in Phase 1) | Drift schema, Sync Engine |
| Subscription Foundation | Low | M | Low now / High later (unblocks monetization) | Low | None (scaffolding only) |
| Settings | Critical | M | High (compliance-required export/deletion) | Low | Authentication, Notifications |
| Achievements (stretch) | Low | S | Low-Medium | Low | Habits, Workout Tracking, Goals |
| Monitoring | Critical | M | High (operational necessity) | Low | Deployment infra |
| CI/CD | Critical | M | High (velocity + safety) | Low | Repository/tooling setup |
| Deployment | Critical | L | High | Low | CI/CD |
| Testing | Critical | L | High (quality gate) | Low | N/A — continuous |
| Production Hardening | Critical | L | High (security/compliance) | Medium | Feature-complete build |

## Post-Launch Improvements

Smaller enhancements surfaced in individual feature specs' own **Future Improvements** sections — not required for launch, not large enough to warrant a dedicated [PHASE2_SCOPE.md](PHASE2_SCOPE.md) entry, and not blocked on Phase 2's AI/conversational infrastructure. Candidates for the first few post-launch minor releases (`v1.1`, `v1.2`, ...), prioritized opportunistically based on real Phase 1 usage data per [Phased Release Strategy § Business Justification](PHASED_RELEASE_STRATEGY.md#business-justification).

| Item | Priority | Effort | Business Value | Technical Risk | Dependencies | Source |
|---|---|---|---|---|---|---|
| Volume/tonnage trend chart per exercise | Medium | S | Medium | Low | Workout History | [Workout History § Future Improvements](features/workout-history.md#future-improvements) |
| Bulk export of workout history | Low | S | Low | Low | Workout History | [Workout History § Future Improvements](features/workout-history.md#future-improvements) |
| Community-curated promotion path for custom exercises | Low | M | Low | Low | Exercise Library | [Exercise Library § Future Improvements](features/exercise-library.md#future-improvements) |
| Embedded exercise video demonstrations | Medium | M | Medium | Low | Exercise Details | [Exercise Details § Future Improvements](features/exercise-details.md#future-improvements) |
| Plate-calculator helper for barbell exercises | Low | S | Low | Low | Workout Tracking | [Workout Tracking § Future Improvements](features/workout-tracking.md#future-improvements) |
| Voice-logged sets (hands-free entry) | Low | L | Low | Medium | Workout Tracking | [Workout Tracking § Future Improvements](features/workout-tracking.md#future-improvements) |
| Recipe/multi-ingredient meal builder | Medium | L | Medium | Low | Nutrition | [Nutrition § Future Improvements](features/nutrition.md#future-improvements) |
| Barcode food scanning | Medium | M | Medium | Low | Nutrition | [Nutrition § Future Improvements](features/nutrition.md#future-improvements) |
| Smart water reminders based on time-since-last-log | Low | S | Low | Low | Water Intake, Notifications | [Water Intake § Future Improvements](features/water-intake.md#future-improvements) |
| Macro-cycling support (training vs. rest day targets) | Low | M | Low | Low | Calorie Tracker | [Calorie Tracker § Future Improvements](features/calorie-tracker.md#future-improvements) |
| Optional progress-photo face-blurring tool | Medium | S | Medium (privacy-adjacent) | Low | Progress Photos | [Progress Photos § Future Improvements](features/progress-photos.md#future-improvements) |
| Multi-metric composite goals | Low | M | Low | Low | Goals | [Goals § Future Improvements](features/goals.md#future-improvements) |
| Optional streak-grace (miss one day without breaking streak) | Medium | S | Medium (retention-adjacent) | Low | Habits | [Habits § Future Improvements](features/habits.md#future-improvements) |
| User-visible "next milestone" progress bars | Low | S | Low | Low | Achievements | [Achievements § Future Improvements](features/achievements.md#future-improvements) |
| Personalized onboarding branch for returning users | Low | M | Low | Low | Onboarding | [Onboarding § Future Improvements](features/onboarding.md#future-improvements) |
| Profile picture upload | Low | S | Low | Low | Profile | [Profile § Future Improvements](features/profile.md#future-improvements) |
| Self-service account recovery within deletion grace period | Medium | M | Medium (support-load reduction) | Low | Settings | [Settings § Future Improvements](features/settings.md#future-improvements) |
| Customizable Dashboard card ordering | Low | M | Low | Low | Dashboard | [Dashboard § Future Improvements](features/dashboard.md#future-improvements) |
| Rich push notifications with inline quick-actions | Medium | M | Medium | Medium (platform-specific) | Notifications | [Notifications § Future Improvements](features/notifications.md#future-improvements) |
| Smart notification send-time optimization | Low | M | Medium | Low | Notifications, Analytics & Events | [Notifications § Future Improvements](features/notifications.md#future-improvements) |
| Automated battery/memory/network regression testing in CI | Medium | M | Low (engineering quality) | Low | Performance Budget tooling | [Performance Budget § Future Improvements](performance-budget.md#future-improvements) |

## Phase 2

Full spec, rationale, and sprint assignment for every row: [PHASE2_SCOPE.md § Capability Matrix](PHASE2_SCOPE.md#capability-matrix).

| Item | Priority | Effort | Business Value | Technical Risk | Dependencies |
|---|---|---|---|---|---|
| AI Coach (Conversational) | Critical | L | High — flagship Phase 2 deliverable | High (open-ended conversation quality/guardrails) | Phase 1 complete, live user history |
| Nutrition Coach | High | M | High | Medium | Conversational Coach infra |
| Recovery Coach | High | L | Medium-High | High (medical-adjacent guardrails) | Wearable Integrations |
| Habit Coach | Medium | M | Medium | Medium | Conversational Coach infra, Habits history |
| Predictive AI | Medium | L | Medium-High (differentiator) | High (unresolved confidence-language methodology) | Multi-week trend data |
| Lifestyle Coaching | Low | L | Medium | High (depends on 3 other personas existing) | Nutrition/Habit/Motivation Coach |
| Conversational Coaching (infrastructure) | Critical | L | High (shared foundation) | High | Phase 1 AI pipeline |
| Context Memory (long-term) | Medium | L | Medium | High (new retrieval infra) | Phase 2's own conversation volume |
| Adaptive Plans | Medium | M | Medium | Medium | Conversational Coach infra |
| Wearable Integrations | High | XL | Medium-High (unlocks Recovery Coach) | Medium (per-provider OAuth/webhook complexity) | None (forward dependency only) |
| Community | Medium | XL | Medium (long-term engagement) | Medium | Established user base |
| Challenges | Medium | XL | Medium | High (undefined data model — needs design pass) | Achievements, Community |
| Leaderboards | Low | M | Low-Medium | Low | Community, Challenges |
| Advanced Analytics | Medium | L | Medium | High (same methodology risk as Predictive AI) | Predictive AI |
