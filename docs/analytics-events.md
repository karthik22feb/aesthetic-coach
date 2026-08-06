# Analytics & Events

**Product:** Aesthetic Coach
**Related documents:** [PRD § 8 Success Metrics](01-prd.md#8-success-metrics) · [Monitoring & Logging § Dashboards](13-monitoring-logging.md#9-dashboards) · [Production Hardening § Compliance](14-production-hardening.md#9-compliance-considerations) · relevant [Feature Specifications](features/)

## Table of Contents
- [Purpose](#purpose)
- [Event Naming Convention](#event-naming-convention)
- [Common Parameters](#common-parameters)
- [Authentication & Onboarding Events](#authentication--onboarding-events)
- [Workout Events](#workout-events)
- [Nutrition Events](#nutrition-events)
- [Body Metrics Events](#body-metrics-events)
- [Goals & Habits Events](#goals--habits-events)
- [AI Coach Events](#ai-coach-events)
- [Engagement Events](#engagement-events)
- [Subscription Events](#subscription-events)
- [Privacy Considerations (Global)](#privacy-considerations-global)
- [Future Improvements](#future-improvements)

## Purpose
Defines the product analytics event taxonomy that instruments the metrics in [PRD § 8 Success Metrics](01-prd.md#8-success-metrics) (retention, logging frequency, AI interaction rate) and feeds the Business/Product dashboard in [Monitoring & Logging § Dashboards](13-monitoring-logging.md#9-dashboards). This is distinct from application logs/APM ([Monitoring & Logging](13-monitoring-logging.md)) — analytics events are product-behavior signals sent to a product analytics tool (e.g., Amplitude/Mixpanel/PostHog — vendor not yet selected, tool-agnostic naming used throughout), not operational telemetry.

## Event Naming Convention
`snake_case`, `{noun}_{past_tense_verb}` (e.g., `workout_completed`, not `complete_workout` or `workoutCompleted`) — consistent, greppable, and matches the convention already used for backend Events in [Backend Architecture § 5](07-backend-architecture.md#5-events) (though these are a distinct, product-analytics-specific event stream, not the same dispatch as Laravel domain events).

## Common Parameters
Sent with every event, not repeated per event below:

| Parameter | Description |
|---|---|
| `userId` | Pseudonymized/hashed identifier, never raw email — see [Privacy Considerations](#privacy-considerations-global) |
| `platform` | `ios` / `android` |
| `appVersion` | |
| `sessionId` | |
| `timestamp` | |

## Authentication & Onboarding Events

| Event | Trigger | Parameters | Analytics Purpose |
|---|---|---|---|
| `signup_completed` | Account creation succeeds ([Authentication § FR-101–103](features/authentication.md#functional-requirements)) | `method` (email/google/apple) | Acquisition funnel, method preference |
| `onboarding_completed` | User reaches Home after [Onboarding](features/onboarding.md) | `goalType`, `experienceLevel`, `durationSeconds` | Activation funnel, drop-off analysis (ties to [Onboarding § Future Improvements](features/onboarding.md#future-improvements)) |
| `onboarding_step_skipped` | User skips a skippable onboarding step | `step` | Identifies friction points |

## Workout Events

| Event | Trigger | Parameters | Analytics Purpose |
|---|---|---|---|
| `workout_started` | User begins an active workout ([Workout Tracking](features/workout-tracking.md)) | `source` (template/ai/adhoc), `templateId?` | Engagement frequency, template vs. ad hoc usage |
| `workout_completed` | Workout saved with `status=completed` | `durationMinutes`, `exerciseCount`, `prCount`, `source` | Core engagement metric feeding [PRD § 8](01-prd.md#8-success-metrics) weekly logging rate |
| `workout_skipped` | User dismisses/skips a planned workout from Dashboard without starting it | `templateId` | Adherence signal, informs future adaptive-programming tuning |
| `pr_detected` | PR flagged during workout save (FR-204) | `exerciseId`, `type` (weight/reps/volume) | Milestone frequency, feeds [Achievements](features/achievements.md) analysis |

## Nutrition Events

| Event | Trigger | Parameters | Analytics Purpose |
|---|---|---|---|
| `meal_logged` | Meal saved ([Nutrition FR-301](features/nutrition.md#functional-requirements)) | `mealType`, `source` (search/custom/ai-suggested) | Logging consistency, AI-suggestion adoption rate |
| `water_logged` | Water increment logged | — | Lightweight-engagement signal |
| `ai_meal_suggestion_used` | User taps "log this" on an AI-suggested meal ([Nutrition Coach](ai/nutrition-coach.md)) | `conversationId` | Measures whether AI suggestions convert to actual logs, not just conversation volume |

## Body Metrics Events

| Event | Trigger | Parameters | Analytics Purpose |
|---|---|---|---|
| `body_measurement_added` | Measurement logged ([Body Measurements FR-401](features/body-measurements.md#functional-requirements)) | `metricsIncluded` (list, e.g., `["weightKg","bodyFatPct"]`) | Tracking-depth signal (users who log more than weight alone) |
| `progress_photo_uploaded` | Photo upload succeeds ([Progress Photos FR-402](features/progress-photos.md#functional-requirements)) | `angle` | Feature adoption — no image data or content descriptor ever included (see Privacy) |

## Goals & Habits Events

| Event | Trigger | Parameters | Analytics Purpose |
|---|---|---|---|
| `goal_created` | Goal saved ([Goals FR-701](features/goals.md#functional-requirements)) | `type` | Goal-type popularity, informs roadmap prioritization |
| `goal_completed` | Goal status transitions to `achieved` ([Goals § Business Rules](features/goals.md#business-rules)) | `type`, `daysToComplete` | Outcome metric — validates whether the product actually helps users achieve stated goals |
| `goal_abandoned` | Goal status transitions to `abandoned` | `type`, `daysActive` | Identifies goal types that need better AI support or realism-checking ([Goal Recommendation](ai/goal-recommendation.md), Future) |
| `habit_checked_in` | Habit marked complete ([Habits FR-502](features/habits.md#functional-requirements)) | `habitId`, `currentStreak` | Habit engagement, streak-length distribution |
| `habit_streak_broken` | Streak resets to 0 (BR-7) | `habitId`, `previousStreakLength` | Informs whether streak-risk notifications ([Notifications](features/notifications.md)) are effective |

## AI Coach Events

| Event | Trigger | Parameters | Analytics Purpose |
|---|---|---|---|
| `ai_chat_started` | New conversation created ([AI Coach FR-601](features/ai-coach.md#functional-requirements)) | `persona` | Persona popularity, feeds [PRD § 8](01-prd.md#8-success-metrics) AI interaction rate |
| `ai_message_sent` | User sends a chat message | `persona`, `conversationId` | Conversation depth/engagement |
| `ai_response_completed` | Streaming response finishes | `persona`, `tokensOutput`, `latencyMs` | Cross-referenced with [Monitoring & Logging § AI Coaching dashboard](13-monitoring-logging.md#9-dashboards) for product-vs-ops correlation |
| `ai_rate_limited` | User hits the daily token budget ([AI Coaching Engine § 9](09-ai-coaching-engine.md#9-rate-limiting)) | `persona` | Signal for whether budgets are too restrictive for engaged users — informs tuning and any future tiering ([Subscriptions](features/subscriptions.md), Future) |
| `weekly_review_viewed` | User opens a generated Weekly Review card | — | Feature engagement, distinct from generation (which happens regardless of viewing) |

## Engagement Events

| Event | Trigger | Parameters | Analytics Purpose |
|---|---|---|---|
| `achievement_unlocked` | Badge awarded ([Achievements § F-ACH-01](features/achievements.md#functional-requirements)) | `achievementId` | Milestone distribution |
| `daily_score_viewed` | DFS Score Ring tapped for detail | `score` | Correlates score-checking behavior with retention |
| `notification_opened` | User taps a push notification | `category` | Notification-category effectiveness, informs [Notifications § Future Improvements](features/notifications.md#future-improvements) |

## Subscription Events

**Status:** Future — see [Subscriptions feature](features/subscriptions.md) for the explicit note that no monetization model is yet approved. These event definitions are placeholders mirroring the requested taxonomy, not implemented.

| Event | Trigger | Parameters | Analytics Purpose |
|---|---|---|---|
| `subscription_started` | Purchase verified ([Subscriptions § APIs](features/subscriptions.md#apis), Future) | `productId`, `platform` | Conversion funnel |
| `subscription_cancelled` | Cancellation event received from platform webhook | `productId`, `reason?` | Churn analysis |

## Privacy Considerations (Global)

- `userId` sent to the analytics tool is a pseudonymized identifier, never a raw email — consistent with [Production Hardening § Compliance](14-production-hardening.md#9-compliance-considerations) treating tracked health-adjacent data as sensitive.
- **No event ever carries free-text content** — `ai_message_sent` carries metadata (persona, conversation ID, length) never the message text itself; `meal_logged` carries category/source, never the food name if it could be sensitive (this is a deliberate conservative default, revisitable if product needs justify richer food-name analytics with appropriate review).
- Progress photo events carry no image data, URL, or visual descriptor whatsoever — only that an upload of a given angle occurred, per the same privacy stance as [Progress Photos § Non-Functional Requirements](features/progress-photos.md#non-functional-requirements) (never used for any purpose beyond display to the owning user — analytics is no exception).
- Users who opt out of analytics (if/when such a control is added to [Settings](features/settings.md) — not yet present in that spec, flagged as a gap) must have event collection suppressed client-side, not merely excluded from reporting.
- Analytics data is excluded from the AI coaching context pipeline entirely ([AI Coaching Engine § 3](09-ai-coaching-engine.md#3-context-management)) — these are two independent systems that must not cross-contaminate.

## Future Improvements
- An analytics-opt-out control in [Settings](features/settings.md) (currently a gap, noted above).
- Funnel and cohort dashboards built on this taxonomy once a specific analytics vendor is selected (out of scope for this document, which defines the event contract independent of vendor).
