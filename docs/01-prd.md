# Product Requirements Document (PRD)

**Product:** Aesthetic Coach
**Document owner:** Product
**Related documents:** [SRS](02-srs.md) · [System Architecture](03-system-architecture.md) · [AI Coaching Engine](09-ai-coaching-engine.md) · [Development Roadmap](16-development-roadmap.md)

---

## 1. Vision

Most fitness apps are logbooks: they record sets, reps, and calories, and leave interpretation to the user. Aesthetic Coach is designed to behave like a **full-time personal coach that never forgets your history and never runs out of patience** — one that tracks the same data traditional apps track, but continuously interprets it, adapts plans around it, and proactively tells the user what to do next and why.

The long-term vision is an **AI-native fitness ecosystem**: workouts, nutrition, recovery, habits, and body metrics feed a single coaching brain that produces a daily fitness score, adaptive programming, and conversational guidance, with wearables and (eventually) a community layer extending its reach.

## 2. Objectives

| # | Objective | How we measure it |
|---|---|---|
| O1 | Replace static workout plans with adaptive, AI-generated programming | % of active users on an AI-adjusted plan by week 4 |
| O2 | Make daily engagement effortless (log a workout/meal in <30s) | Median time-to-log per entry |
| O3 | Give users a single daily number that reflects trajectory, not just today | Daily Fitness Score adoption / daily opens |
| O4 | Build a data model and AI layer that scales to new coaching domains without rearchitecture | New coaching persona shippable in <1 sprint |
| O5 | Reach production-grade reliability and security from the first release | Uptime, crash-free sessions, zero critical security findings |

## 3. Target Audience

**Primary:** Adults 18–45 who already exercise with some regularity (2+ times/week) but want structure, accountability, and personalization beyond what a spreadsheet or a generic app gives them. Comfortable with mobile apps and subscriptions; likely already tried MyFitnessPal, Strong, Hevy, or a wearable's native app and found the "intelligence" layer missing.

**Secondary:** Beginners who want a coach-like on-ramp instead of a blank logging screen, and intermediate/advanced lifters who want AI-assisted programming without paying for a human coach.

### 3.1 User Personas

**Persona 1 — "Structured Striver" (primary)**
Priya, 29, product manager. Trains 4x/week, tracks macros loosely, has tried 3 fitness apps and abandoned each within 2 months because logging felt like a chore and none of them told her *why* to change anything. Wants a plan that adapts automatically and a daily signal she can trust.

**Persona 2 — "Comeback Athlete"**
Marcus, 37, former college athlete returning to training after years off. Knows how to train but not how to pace recovery at his current age/lifestyle. Wants recovery-aware coaching and injury-prevention nudges, not just a workout log.

**Persona 3 — "Guided Beginner"**
Ana, 24, new to structured fitness. Intimidated by blank-slate apps that assume she already knows what to do. Needs the AI coach to lead — tell her what workout to do today, in plain language, with form/exercise explanations on demand.

**Persona 4 — "Data-Driven Optimizer"**
Wei, 33, wears a smartwatch, wants every metric (HRV, sleep, workouts, nutrition) synthesized into one score and trend, and wants monthly AI-generated reviews rather than raw charts.

### 3.2 Non-goals (explicitly out of scope for this product)

- Becoming a social network first — community is a **[Future]** layer, not core to the loop.
- Replacing medical/clinical nutrition or physical-therapy advice — the AI coach explicitly stays in a wellness/coaching lane (see [AI Coaching Engine § Safety Guardrails](09-ai-coaching-engine.md#7-safety-guardrails)).
- Building a marketplace for human trainers in MVP.

## 4. Competitive Analysis

| Product | Strength | Gap Aesthetic Coach targets |
|---|---|---|
| Strong / Hevy | Best-in-class workout logging UX | No AI coaching, no nutrition/recovery synthesis |
| MyFitnessPal | Huge food database | Logging-only; no adaptive programming, dated UX |
| Whoop / Oura | Strong recovery/HRV signal | Not a training or nutrition app; no conversational coach |
| Future / Freeletics | AI-flavored coaching | Human-coach-in-the-loop (Future) or rigid pre-built programs (Freeletics), not truly adaptive per-user LLM reasoning |
| Fitbod | Adaptive workout generation | Workout-only; no nutrition, recovery, or conversational coaching |

**Differentiation:** Aesthetic Coach is the only product in this set that unifies workout, nutrition, recovery, and habit data behind a single LLM-driven coaching layer that explains its reasoning, remembers user context long-term, and produces one daily actionable score instead of a dashboard of disconnected charts.

## 5. Feature Roadmap

Legend: **[MVP]** ships in v1.0. **[Future]** is scoped architecturally but not built in MVP.

### 5.1 Core Tracking
- **[MVP]** Workout tracking (exercises, sets, reps, weight, RPE, rest timer)
- **[MVP]** Exercise library with instructions and media
- **[MVP]** Body measurements (weight, body fat %, circumferences, progress photos)
- **[MVP]** Nutrition logging (meals, macros, calories, water)
- **[MVP]** Habit tracking (custom + suggested habits, streaks)
- **[MVP]** Daily Fitness Score (composite of training load, recovery, nutrition adherence, habit consistency)
- **[Future]** Recovery tracking via wearable HRV/sleep ingestion (manual entry supported in MVP; automated sync is Future)

### 5.2 AI Coaching
- **[MVP]** Personal trainer persona (adaptive workout generation, exercise substitution, explanation on demand)
- **[MVP]** Nutrition coach persona (meal suggestions, macro guidance)
- **[MVP]** Weekly review (AI-generated summary + recommendations)
- **[Future]** Recovery coach, motivation coach, habit coach personas
- **[Future]** Monthly review, goal recommendation engine, progress prediction, injury-prevention suggestions

### 5.3 Planning & Analytics
- **[MVP]** Goal setting (strength, body composition, habit, event-based)
- **[MVP]** Progress analytics (trend charts, PR tracking, volume tracking)
- **[Future]** Predictive trajectory modeling ("at this rate you reach goal X on date Y")

### 5.4 Engagement
- **[MVP]** Streaks, milestones, achievement badges
- **[Future]** Leaderboards, social feed, challenges, friend following

### 5.5 Integrations
- **[Future]** Apple Health / Google Fit sync
- **[Future]** Wearable integrations (Whoop, Oura, Garmin, Fitbit)

### 5.6 Platform
- **[MVP]** Email/password + Google + Apple auth, multi-device session management
- **[MVP]** Push notifications (reminders, streak risk, AI check-ins)
- **[Future]** Web companion dashboard

## 6. Functional Requirements (summary)

Detailed, numbered functional requirements with acceptance criteria live in the [SRS](02-srs.md#4-functional-requirements). Summary by domain:

- **Auth & Account:** registration, login (password/Google/Apple), email verification, password reset, device/session management, account deletion.
- **Workout Tracking:** create/log workouts from templates or ad hoc, exercise library search, rest timer, PR detection.
- **Nutrition:** log meals/foods, macro/calorie targets, water intake, barcode scan **[Future]**.
- **Body Metrics:** weight/measurement logging, progress photos, trend charts.
- **Habits:** create/track custom and suggested habits, streaks.
- **AI Coaching:** conversational coach, adaptive plan generation, weekly review generation.
- **Goals:** create/track goals linked to metrics; AI recommends adjustments.
- **Daily Fitness Score:** computed daily from training, nutrition, recovery, habit inputs; shown with a plain-language explanation.
- **Notifications:** reminders, streaks, AI-triggered nudges.

## 7. Non-Functional Requirements (summary)

Full detail in [SRS § 5](02-srs.md#5-non-functional-requirements). Headline targets:

| Category | Target |
|---|---|
| Availability | 99.5% API uptime (MVP), 99.9% target post-MVP |
| API latency | p95 < 300ms for non-AI endpoints; AI endpoints stream first token < 2s |
| Mobile cold start | < 2.5s on mid-tier Android device |
| Offline support | Workout logging fully usable offline, syncs on reconnect |
| Security | OWASP ASVS L2 baseline; see [Production Hardening](14-production-hardening.md) |
| Data privacy | GDPR/CCPA-aligned data export & deletion |
| Scalability | Architecture supports 100k MAU without redesign (horizontal scaling of stateless API + queue workers) |

## 8. Success Metrics

| Metric | MVP target (90 days post-launch) |
|---|---|
| D1 retention | ≥ 40% |
| D30 retention | ≥ 20% |
| Weekly active logging rate (among retained users) | ≥ 4 days/week |
| AI coach interaction rate | ≥ 60% of WAU interact with AI coach weekly |
| Crash-free sessions | ≥ 99.5% |
| App Store / Play Store rating | ≥ 4.5 |

## 9. MVP vs. Future Phases

| Phase | Scope |
|---|---|
| **MVP (v1.0)** | Core tracking (workout, nutrition, body metrics, habits), Daily Fitness Score, AI personal trainer + nutrition coach + weekly review, goals, auth (email/Google/Apple), push notifications, offline-first mobile |
| **Phase 2** | Recovery coach, motivation/habit coach personas, monthly review, wearable integrations (read-only sync), progress prediction |
| **Phase 3** | Community features (feed, challenges, friends), web dashboard, marketplace/human-coach hybrid exploration |

See [Development Roadmap](16-development-roadmap.md) for milestone-level breakdown and sequencing.

## 10. Risks & Assumptions

| Risk | Mitigation |
|---|---|
| AI coaching cost scales with engagement, threatening unit economics | Prompt/context budget controls, caching, model-tier routing — see [AI Coaching Engine § Cost Optimization](09-ai-coaching-engine.md#8-cost-optimization) |
| Users distrust AI-generated health guidance | Explicit guardrails, disclaimers, escalation to "consult a professional" for medical-adjacent queries |
| Offline-first + AI features are in tension (AI needs connectivity) | Core logging works fully offline; AI features degrade gracefully with clear "queued" states |
| Multi-provider LLM ambition adds complexity before it's needed | Abstraction layer designed up front but only Claude implemented in MVP — see [AI Coaching Engine § Model Abstraction Layer](09-ai-coaching-engine.md#6-model-abstraction-layer) |

**Assumptions:** Claude Pro subscription is used for development/prompt-iteration only; production traffic uses metered Claude API billing. MySQL 8 is a hard requirement (existing operational expertise). Flutter and Laravel are hard requirements (stated by stakeholder).
