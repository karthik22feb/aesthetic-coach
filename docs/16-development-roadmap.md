# Development Roadmap

**Product:** Aesthetic Coach
**Purpose:** milestone-driven, sprint-level implementation plan for both public release phases. This document supersedes the single-track, implementation-order roadmap this repository originally shipped with — see [Superseded Structure](#superseded-structure) below for what changed and why.
**Related documents:** [Phased Release Strategy](PHASED_RELEASE_STRATEGY.md) · [PHASE1_SCOPE.md](PHASE1_SCOPE.md) · [PHASE2_SCOPE.md](PHASE2_SCOPE.md) · [MASTER_IMPLEMENTATION_PLAN.md](../MASTER_IMPLEMENTATION_PLAN.md) — all other documents across this repository, as referenced per sprint below.

---

## How to Read This Roadmap

Each sprint lists **Objectives**, **Deliverables**, **Dependencies**, **Estimated Complexity** (S/M/L/XL, relative effort not calendar time), **Risks**, and **Suggested Claude Prompts** — starting prompts an engineer can hand to Claude (with the relevant doc(s) attached as context) to begin implementation. Sprints are sequential within each phase; Phase 2 does not begin until [Phased Release Strategy § Phase 1 Exit Criteria](PHASED_RELEASE_STRATEGY.md#exit-criteria-for-each-phase) are met. Feature-level detail for every item mentioned here lives in [PHASE1_SCOPE.md](PHASE1_SCOPE.md) and [PHASE2_SCOPE.md](PHASE2_SCOPE.md) — this document sequences that scope into sprints, it does not redefine it.

---

## Phase 1 — Intelligent Fitness Platform (MVP)

### Phase 1 · Sprint 1 — Infrastructure, Authentication & Project Setup

**Objectives:** stand up the repositories, tooling, and full authentication system — the foundation every later sprint depends on.

**Deliverables:**
- Laravel + Flutter project scaffolding per [Backend Architecture § 1](07-backend-architecture.md#1-folder-structure) and [Mobile Architecture § 2](08-mobile-architecture.md#2-folder-organization).
- Docker Compose dev environment ([Deployment Guide § 2](12-deployment-guide.md#2-development-environment)); staging environment provisioned and CI/CD pipeline green ([CI/CD Pipeline](11-cicd-pipeline.md)).
- Full [Authentication](features/authentication.md) feature: registration, login, Google/Apple sign-in, email verification, password reset, JWT + refresh token rotation, session/device management.
- Baseline monitoring/logging wired ([Monitoring & Logging § 1–2](13-monitoring-logging.md#1-observability-principles)) — foundation only, dashboards finalized in Sprint 6.

**Dependencies:** none (first sprint of Phase 1).

**Estimated complexity:** XL (CI/CD + auth security-critical work combined).

**Risks:** refresh-token rotation/reuse-detection bugs are security-critical and easy to get subtly wrong — allocate explicit test time per [Testing Strategy § API Testing](10-testing-strategy.md#5-api-testing) before moving on; treat "staging deploy works end-to-end" as this sprint's actual done-criterion, not "code compiles locally."

**Suggested Claude prompts:**
- "Using docs/07-backend-architecture.md § 1 and docs/03-system-architecture.md, scaffold a Laravel project with the app/Modules structure described, an empty Auth module, and the ModuleServiceProvider auto-discovery pattern."
- "Using docs/02-srs.md § 4.1, docs/03-system-architecture.md § 3.1 and § 8, and docs/04-database-design.md § 3.1, implement the Auth module: users, oauth_identities, devices, auth_refresh_tokens tables/migrations, and AuthService with register/login/refresh/logout."
- "Write Pest Feature tests for refresh token rotation and reuse-detection per BR-3 in docs/02-srs.md § 6."
- "Scaffold a Flutter project per docs/08-mobile-architecture.md § 2, Riverpod wired, go_router configured for the 5 bottom-nav tabs, and implement the Auth feature including the Dio AuthInterceptor that transparently refreshes on 401."

---

### Phase 1 · Sprint 2 — User Profile & AI Onboarding

**Objectives:** ship the profile data model and the guided onboarding flow that produces a user's first AI-generated workout — the first real (if narrow) AI touchpoint in the product.

**Deliverables:** [Profile](features/profile.md) full CRUD; [Onboarding](features/onboarding.md) flow per its Phase 1 scope note in [PHASE1_SCOPE.md § AI Onboarding](PHASE1_SCOPE.md#ai-onboarding) (single structured AI generation call + written welcome, not open-ended chat); basic [Settings](features/settings.md) screen (theme, units — full settings finalized Sprint 6).

**Dependencies:** Sprint 1 (Authentication).

**Estimated complexity:** M.

**Risks:** onboarding's AI step has a hard dependency on the Workout Engine (Sprint 3) and Claude API integration (Sprint 5) both being functional — build onboarding's UI/flow now, but its AI-generation call may need to be feature-flagged off until those land; sequence carefully or accept a short cross-sprint integration gap.

**Suggested Claude prompts:**
- "Implement the Profile module (GET/PATCH /me) per docs/features/profile.md and docs/05-api-specification.md § 6.1."
- "Implement the Onboarding flow screens per docs/features/onboarding.md, with the AI-generation step feature-flagged until Sprint 3/5 dependencies are ready."
- "Implement basic Settings (theme, units) per docs/features/settings.md, deferring notification preferences and data export/deletion to Sprint 6."

---

### Phase 1 · Sprint 3 — Workout Engine & Exercise Library

**Objectives:** build the core logging domain — the single largest, highest-risk feature cluster in Phase 1.

**Deliverables:** [Exercise Library](features/exercise-library.md) with seeded catalog ([Database Seeding](database-seeding.md)); [Workout Tracking](features/workout-tracking.md) (logging, PR detection, templates); [Workout History](features/workout-history.md); [Exercise Details](features/exercise-details.md) screen (AI explanation wired in Sprint 5); offline-first Drift schema and Sync Engine foundation for this domain per [Mobile Architecture § 4–6](08-mobile-architecture.md#4-offline-first-strategy).

**Dependencies:** Sprint 1 (Authentication).

**Estimated complexity:** XL.

**Risks:** this is the sprint where [Offline Support](PHASE1_SCOPE.md#offline-support) — the single highest-technical-risk item in Phase 1 per [ADR-0007](adr/0007-offline-first-architecture.md#consequences) — gets its foundational implementation. Budget explicit time for partial-failure/retry edge cases in [Mobile Architecture § 6](08-mobile-architecture.md#6-synchronization), not just the happy path.

**Suggested Claude prompts:**
- "Using docs/04-database-design.md § 3.2 and docs/02-srs.md § 4.2, implement the Workouts module: migrations, models, WorkoutRepository, WorkoutService with PR detection, and endpoints per docs/05-api-specification.md § 6.4, including client_uuid idempotent upsert."
- "Write a seeder for a starter exercise library (~150 common exercises), idempotent via updateOrCreate on slug, per docs/database-seeding.md."
- "Implement the Drift schema for workouts/workout_exercises/workout_sets, the SyncQueue table, and a SyncEngine with per-item retry, per docs/08-mobile-architecture.md § 4–6."
- "Implement the Train tab screens (workout list, active workout logging) per docs/screens/workout.md, reading from Drift via Riverpod stream providers."

---

### Phase 1 · Sprint 4 — Tracking, Progress & Habits

**Objectives:** round out the remaining tracking domains that Basic Analytics and the Dashboard depend on.

**Deliverables:** [Nutrition](features/nutrition.md) and [Calorie Tracker](features/calorie-tracker.md) (core tracking only — FR-304 AI suggestions deferred to Phase 2, see [PHASE1_SCOPE.md § Notes on Judgment Calls](PHASE1_SCOPE.md#notes-on-judgment-calls)); [Water Intake](features/water-intake.md); [Body Measurements](features/body-measurements.md); [Progress Photos](features/progress-photos.md); [Habits](features/habits.md); [Goals](features/goals.md); offline support extended to these domains per the Sprint 3 foundation; Dashboard scaffold (data display, AI card wired in Sprint 5).

**Dependencies:** Sprint 1 (Authentication), Sprint 3 (offline sync foundation reused, not rebuilt).

**Estimated complexity:** XL (five tracking domains, individually well-understood).

**Risks:** scope creep into Future features (barcode scan, wearable auto-sync) — hold the line at Phase 1 scope per [PHASE1_SCOPE.md](PHASE1_SCOPE.md).

**Suggested Claude prompts:**
- "Implement the Nutrition module (foods, meals, meal_items, water_logs) per docs/04-database-design.md § 3.3 and docs/05-api-specification.md § 6.5, including the daily-summary aggregation endpoint. Do not implement AI meal suggestions (FR-304) — that's Phase 2."
- "Implement Body Measurements, Progress Photos, Habits, and Goals modules per docs/04-database-design.md § 3.4–3.5 and docs/05-api-specification.md § 6.6–6.8."
- "Implement the Nutrition, Progress, and Habits mobile screens per docs/screens/nutrition.md and docs/screens/analytics.md, reusing the offline-sync pattern from Sprint 3."
- "Scaffold the Dashboard screen per docs/screens/dashboard.md with skeleton states for the AI recommendation card, to be wired live in Sprint 5."

---

### Phase 1 · Sprint 5 — AI Recommendations, Analytics & Notifications

**Objectives:** activate Phase 1's actual AI surface and the Daily Fitness Score, and wire notifications — this is the sprint where the app starts feeling "intelligent," per [Phased Release Strategy § Product Vision](PHASED_RELEASE_STRATEGY.md#product-vision).

**Deliverables:**
- `AiProviderInterface` + `ClaudeProvider` per [AI Coaching Engine § 6](09-ai-coaching-engine.md#6-model-abstraction-layer), wired to the real Claude API.
- **AI Workout Recommendations** (`POST /templates/ai-generate`, structured generation only — see [PHASE1_SCOPE.md § AI Workout Recommendations](PHASE1_SCOPE.md#ai-workout-recommendations)) using [AI Prompt — Workout Coach](ai/workout-coach.md)'s generation mode.
- **Exercise Guidance** (single-turn explanation, [AI Prompt — Workout Coach](ai/workout-coach.md) lightweight mode) wired into [Exercise Details](features/exercise-details.md).
- **Progress Summary** (Weekly Review) per [AI Prompt — Weekly Review](ai/weekly-review.md), delivered as a Dashboard card and notification — not inside a conversational thread.
- Daily Fitness Score deterministic formula ([AI Coaching Engine § 5](09-ai-coaching-engine.md#5-recommendation-engine)) and its scheduled computation job.
- [Notifications](features/notifications.md) full implementation (push + in-app, category preferences).
- Onboarding's AI step (Sprint 2, feature-flagged) goes live now that its dependencies exist.

**Dependencies:** Sprint 3 (Exercise Library, Workout Tracking), Sprint 4 (Nutrition, Habits, Goals — DFS inputs).

**Estimated complexity:** XL — highest product-risk sprint in Phase 1.

**Risks:** cost overruns without token budgets in place from day one — build [AI Coaching Engine § 8–9](09-ai-coaching-engine.md#8-cost-optimization) (rate limiting, usage recording) *with* the first AI call, not after; guardrail gaps in the exercise-explanation and workout-generation prompts — test adversarial/edge-case inputs, not just the happy path, per [AI Prompt — Workout Coach § Error Handling](ai/workout-coach.md#error-handling).

**Suggested Claude prompts:**
- "Implement AiProviderInterface and ClaudeProvider per docs/09-ai-coaching-engine.md § 6, wired to the real Claude Messages API."
- "Implement structured workout generation (POST /templates/ai-generate) per docs/ai/workout-coach.md, with server-side exerciseSlug validation and the retry/fallback path on invalid output."
- "Implement the lightweight exercise-explanation endpoint per docs/ai/workout-coach.md and docs/features/exercise-details.md § FR-604."
- "Implement DailyFitnessScoreService per the formula in docs/09-ai-coaching-engine.md § 5, with a table-driven unit test suite and a timezone-bucketed scheduled job."
- "Implement GenerateWeeklyReviewJob per docs/ai/weekly-review.md, delivered as a Dashboard card and notification."
- "Implement RateLimitAi middleware and the ai_usage_logs-backed daily token budget per docs/09-ai-coaching-engine.md § 9."
- "Implement push notification dispatch per docs/features/notifications.md and docs/07-backend-architecture.md § 7."

---

### Phase 1 · Sprint 6 — Testing, Performance & Security

**Objectives:** harden the feature-complete Phase 1 build before it faces real users.

**Deliverables:** full [Testing Strategy](10-testing-strategy.md) pass (load testing, E2E device-lab suite, AI smoke suite); [Production Hardening § 1 Security Checklist](14-production-hardening.md#1-security-checklist) complete; [Monitoring & Logging § 8–9](13-monitoring-logging.md#8-alerting) dashboards/alerts finalized; [Settings](features/settings.md) finalized (notification preferences, data export, account deletion); [Subscription Foundation](features/subscriptions.md) scaffolding (schema + entitlement hooks, no billing UI) per [PHASE1_SCOPE.md § Subscription Foundation](PHASE1_SCOPE.md#subscription-foundation); [Achievements](features/achievements.md) stretch item if capacity allows.

**Dependencies:** Sprints 1–5 (feature-complete build required).

**Estimated complexity:** L.

**Risks:** treated as "nice to have if time allows" is the single biggest way this sprint fails — sequence it explicitly before Sprint 7 launch prep, not compressed into it; a security/performance gap found during launch week is far more expensive than one found here.

**Suggested Claude prompts:**
- "Run through docs/14-production-hardening.md § 1 against the current codebase and report gaps."
- "Set up k6 load test scripts against staging per docs/10-testing-strategy.md § 7–8."
- "Implement the Settings notification-preferences, data-export, and account-deletion flows per docs/features/settings.md."
- "Scaffold the subscriptions table and a default-full-access entitlement check per docs/features/subscriptions.md — no billing integration, no pricing UI."

---

### Phase 1 · Sprint 7 — UAT & Production Launch

**Objectives:** close the loop from documentation to a live public release.

**Deliverables:** closed beta via TestFlight/Play internal track; [User Documentation](15-user-documentation.md) content published to the in-app help center; store listing assets; Fastlane release automation per [CI/CD Pipeline § 5](11-cicd-pipeline.md#5-release-management--versioning); production deployment and rollback drill per [Deployment Guide](12-deployment-guide.md); `v1.0.0` tagged and released; post-launch feedback collection mechanism live; **Phase 2 planning kickoff**, gated on [Phased Release Strategy § Phase 1 Exit Criteria](PHASED_RELEASE_STRATEGY.md#exit-criteria-for-each-phase).

**Dependencies:** all prior Phase 1 sprints.

**Estimated complexity:** M.

**Risks:** app store review timelines are outside team control — build in buffer, and use feature flags ([CI/CD Pipeline § 6](11-cicd-pipeline.md#6-feature-flags)) to decouple "code merged" from "feature live" if review timing is tight. Phase 2 kickoff must not be treated as automatic — see exit criteria.

**Suggested Claude prompts:**
- "Run through docs/PHASE1_SCOPE.md and confirm every feature's acceptance criteria (linked from each Category Detail entry) has a corresponding passing automated test."
- "Set up Fastlane lanes for Android and iOS per docs/11-cicd-pipeline.md § 5."
- "Generate in-app help center content from docs/15-user-documentation.md § 2–4."
- "Review docs/PHASED_RELEASE_STRATEGY.md § Exit Criteria for Each Phase and report which Phase 1 exit criteria are met and which are outstanding."

---

## Phase 2 — AI Personal Coach

Begins only after Phase 1's exit criteria are confirmed met — see [Phased Release Strategy § Exit Criteria for Each Phase](PHASED_RELEASE_STRATEGY.md#exit-criteria-for-each-phase). Every sprint below assumes a live, populated production database of real Phase 1 user history.

### Phase 2 · Sprint 1 — Conversational Coach Foundation

**Objectives:** build the full multi-turn Coach tab experience on top of the AI pipeline that's already been running in production since Phase 1 Sprint 5.

**Deliverables:** full [AI Coach screen](screens/ai-coach.md) (persona switcher, streaming chat UI, [AI Chat Bubble](components/ai-chat-bubble.md)); backend general-availability of sustained multi-turn conversation on the `personal_trainer` persona (already partially live for structured generation since Phase 1); [AI Coach feature](features/ai-coach.md) FR-601/602 fully activated.

**Dependencies:** Phase 1 complete and live with real user history ([PHASE2_SCOPE.md § AI Coach](PHASE2_SCOPE.md#ai-coach-conversational)).

**Estimated complexity:** L (mobile-heavy — most backend plumbing already exists).

**Risks:** conversation quality is now tested against real (not synthetic) user data for the first time — budget a dedicated prompt-tuning pass using real Phase 1 usage patterns, not just the original unit-test fixtures.

**Suggested Claude prompts:**
- "Implement the full Coach tab per docs/screens/ai-coach.md, including the persona switcher and streaming AI Chat Bubble component."
- "Enable sustained multi-turn conversation on the personal_trainer persona per docs/PHASE2_SCOPE.md § Conversational Coaching (infrastructure)."
- "Write adversarial-prompt guardrail tests per docs/09-ai-coaching-engine.md § 7 against real (anonymized) Phase 1 usage patterns."

---

### Phase 2 · Sprint 2 — Nutrition Coach & Recovery Coach

**Objectives:** activate the first two new personas.

**Deliverables:** Nutrition Coach persona live per [AI Prompt — Nutrition Coach](ai/nutrition-coach.md), including FR-304 AI meal suggestions (deferred from Phase 1); Wearable Integrations first-wave (Apple Health, Health Connect, Smart Scales per [Future Integrations](future-integrations.md#future-roadmap-sequencing)) to unlock Recovery Coach; Recovery Coach persona live per [AI Prompt — Recovery Coach](ai/recovery-coach.md) once wearable data is flowing.

**Dependencies:** Phase 2 Sprint 1 (Conversational Coach infrastructure).

**Estimated complexity:** XL (two personas plus wearable integration work).

**Risks:** Recovery Coach's prompt is currently an unreviewed draft — schedule the tone/safety review named in [AI Prompt — Recovery Coach § Guardrails](ai/recovery-coach.md#guardrails) before activation, not after.

**Suggested Claude prompts:**
- "Activate the Nutrition Coach persona per docs/ai/nutrition-coach.md and implement FR-304 AI meal suggestions per docs/features/nutrition.md."
- "Implement Apple Health and Health Connect on-device sync per docs/future-integrations.md § Apple Health / Health Connect."
- "Implement Smart Scale integration (Withings-style OAuth) per docs/future-integrations.md § Smart Scales."
- "Draft the production-reviewed Recovery Coach prompt per docs/ai/recovery-coach.md once wearable recovery data is available, and activate the persona."

---

### Phase 2 · Sprint 3 — Habit Coach, Context Memory & Adaptive Plans

**Objectives:** round out the persona roster and upgrade the memory/planning layer.

**Deliverables:** Habit Coach persona authored and activated (new prompt, following the pattern in [AI Prompt — Motivation Coach](ai/motivation-coach.md)); Adaptive Plans (conversational workout adjustment) enabled on the `personal_trainer` persona per [PHASE2_SCOPE.md § Adaptive Plans](PHASE2_SCOPE.md#adaptive-plans); Context Memory retrieval layer (`MemoryRetrieverInterface`) per [AI Coaching Engine § 4](09-ai-coaching-engine.md#4-user-memory-strategy), built against real Phase 2 conversation volume.

**Dependencies:** Phase 2 Sprint 1 (chat infrastructure), Sprint 2 (persona-activation pattern established).

**Estimated complexity:** L.

**Risks:** Context Memory is the one Phase 2 capability that depends on Phase 2's *own* data rather than Phase 1's — sequence it last within this sprint, after enough Phase 2 conversation volume exists to justify it.

**Suggested Claude prompts:**
- "Author and activate a Habit Coach persona prompt following the pattern in docs/ai/motivation-coach.md, scoped per docs/PHASE2_SCOPE.md § Habit Coach."
- "Enable conversational Adaptive Plans on the personal_trainer persona per docs/PHASE2_SCOPE.md § Adaptive Plans."
- "Implement a MemoryRetrieverInterface and embedding-based retrieval over coach_messages per docs/09-ai-coaching-engine.md § 4."

---

### Phase 2 · Sprint 4 — Predictive Coaching & Advanced Analytics

**Objectives:** ship the data-depth-gated predictive capabilities that couldn't responsibly ship earlier.

**Deliverables:** Predictive AI / progress prediction per [AI Prompt — Progress Analysis](ai/progress-analysis.md), with the confidence-language/methodology question finally resolved using real Phase 1+2 data; Advanced Analytics extension to [Analytics screen](screens/analytics.md); Goal Recommendation AI activated per [AI Prompt — Goal Recommendation](ai/goal-recommendation.md).

**Dependencies:** Sprints 1–3 (persona infrastructure), sufficient accumulated multi-week trend data across the user base.

**Estimated complexity:** L.

**Risks:** the guardrail concern flagged in [AI Prompt — Progress Analysis § Guardrails](ai/progress-analysis.md#guardrails) (avoiding overconfident predictions) is a launch-blocking review item for this sprint, not a nice-to-have.

**Suggested Claude prompts:**
- "Resolve the prediction-methodology and confidence-language open question in docs/ai/progress-analysis.md using real aggregated (anonymized) Phase 1/2 usage data, then implement the capability."
- "Implement Advanced Analytics trend/prediction extensions to docs/screens/analytics.md."
- "Activate Goal Recommendation AI per docs/ai/goal-recommendation.md, including the rate-of-change safety bound flagged in its Guardrails section."

---

### Phase 2 · Sprint 5 — Wearable Integrations, Community, Challenges & Leaderboards

**Objectives:** complete the remaining wearable providers and ship the social/engagement layer reclassified into Phase 2 by this strategy.

**Deliverables:** remaining wearable providers (Fitbit, Garmin, Strava, Calendar) per [Future Integrations § Future Roadmap Sequencing](future-integrations.md#future-roadmap-sequencing); Community, Challenges, and Leaderboards — **note:** [Challenges feature](features/challenges.md) explicitly requires its own dedicated architecture/design pass before implementation begins (its database tables and API surface are not yet specified) — this sprint's first deliverable is that design pass, not code.

**Dependencies:** Phase 2 Sprint 2 (wearable integration pattern established); an established Phase 1+2 user base for Community/Challenges to be meaningful.

**Estimated complexity:** XL (largest Phase 2 sprint — new social data model plus remaining integrations).

**Risks:** Community/Challenges is the least-specified item in this entire roadmap — do not let implementation start before the dedicated design pass produces a real feature spec, database schema, and API contract following the established patterns in this repository.

**Suggested Claude prompts:**
- "Implement Fitbit, Garmin, and Strava OAuth + sync per docs/future-integrations.md."
- "Conduct a design pass for Community, Challenges, and Leaderboards following the template used by docs/features/*.md, docs/04-database-design.md, and docs/05-api-specification.md, respecting the privacy-by-default principles in docs/features/challenges.md § Business Rules."
- "Once the design pass is reviewed, implement the Challenges module per its new specification."

---

### Phase 2 · Sprint 6 — Testing, Hardening & Phase 2 Launch

**Objectives:** validate Phase 2 at production scale and release it.

**Deliverables:** full guardrail/safety review for every newly-activated persona per [AI Coaching Engine § 7](09-ai-coaching-engine.md#7-safety-guardrails); AI cost-per-active-user validated against [AI Coaching Engine § 8](09-ai-coaching-engine.md#8-cost-optimization) using real usage; load testing at Phase 2's higher AI-traffic mix; `v2.0.0` tagged and released per [Release Management](release-management.md).

**Dependencies:** Sprints 1–5.

**Estimated complexity:** L.

**Risks:** same "don't compress hardening into launch week" risk as Phase 1 Sprint 6 — treat this as a full sprint, not a checklist appended to Sprint 5.

**Suggested Claude prompts:**
- "Run the full guardrail test suite from docs/09-ai-coaching-engine.md § 7 against every activated Phase 2 persona."
- "Run docs/PHASED_RELEASE_STRATEGY.md § Exit Criteria for Each Phase (Phase 2 section) and report status."
- "Prepare the v2.0.0 release per docs/release-management.md."

---

## Superseded Structure

This roadmap previously organized implementation into a single flat sequence (old "Phase 0" through "Phase 8," an *implementation-order* numbering unrelated to product releases). That structure is superseded by the two-phase **release** structure above, introduced by [Phased Release Strategy](PHASED_RELEASE_STRATEGY.md). Mapping for anyone following old cross-references: old Phase 0 (Foundations) → Phase 1 · Sprint 1; old Phase 1 (Auth) → Phase 1 · Sprint 1; old Phase 2 (Core Tracking Backend) → Phase 1 · Sprints 3–4; old Phase 3 (Mobile Offline Sync) → Phase 1 · Sprints 3–4; old Phase 4 (DFS & Analytics) → Phase 1 · Sprint 5; old Phase 5 (AI Coaching MVP) → split across Phase 1 · Sprint 5 (narrow AI utilities) and Phase 2 · Sprints 1–3 (full conversational coaching); old Phase 6 (Hardening/Observability) → Phase 1 · Sprint 6; old Phase 7 (Launch) → Phase 1 · Sprint 7; old Phase 8 (Post-MVP) → Phase 2 in full.

## Cross-Phase Notes

- **Documentation is living.** Any architectural decision made during implementation that contradicts a document in this repository should update the document in the same PR, not drift silently — keeps the blueprint trustworthy for the next sprint.
- **Every sprint's "done" includes its tests**, per [Testing Strategy](10-testing-strategy.md) — no sprint is complete with feature code merged but tests deferred to "later."
- **Security and offline-sync correctness (Phase 1 · Sprint 1 and Sprint 3) remain the two highest-technical-risk areas** in Phase 1 — both justify slower, more deliberate review than their line-count would suggest.
- **AI guardrail review is launch-blocking for every newly-activated persona**, in both phases — never treated as a post-launch follow-up.
- **[MASTER_IMPLEMENTATION_PLAN.md](../MASTER_IMPLEMENTATION_PLAN.md) is the live tracker** for which sprint is currently active — this document defines the plan, that one tracks execution against it.
