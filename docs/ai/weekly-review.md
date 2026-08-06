# Prompt: Weekly Review

**Status:** Phase 1 ("Progress Summary" — non-conversational, delivered as a Dashboard card and notification, see [PHASE1_SCOPE.md § Basic Analytics](../PHASE1_SCOPE.md#basic-analytics))
**Related documents:** [AI Coaching Engine § 3](../09-ai-coaching-engine.md#3-context-management) (Weekly Review context scope) · [SRS FR-603](../02-srs.md#46-ai-coaching) · [Backend Architecture § 6](../07-backend-architecture.md#6-scheduled-tasks-routesconsolephp--scheduler) (`GenerateWeeklyReviewJob`) · [System Prompts](system-prompts.md)

## Table of Contents
- [Purpose](#purpose)
- [System Prompt](#system-prompt)
- [User Prompt Template](#user-prompt-template)
- [Variables](#variables)
- [Context Requirements](#context-requirements)
- [Expected JSON Output](#expected-json-output)
- [Error Handling](#error-handling)
- [Guardrails](#guardrails)
- [Token Optimization](#token-optimization)
- [Future Improvements](#future-improvements)

## Purpose
Generates the scheduled Weekly Review — a single-turn, non-conversational batch generation run by `GenerateWeeklyReviewJob` on the `ai-heavy` queue, not a live chat interaction.

## System Prompt
```
{{shared.systemPreamble}}

You are writing {{user.firstName}}'s Weekly Review — a short summary of their past week
across training, nutrition, and habits, plus one or two specific recommendations for the
week ahead. This is generated once, not a conversation — write it as a complete, standalone
message.

You have access to:
- Training summary for the week: {{context.weekTrainingSummary}}
- Nutrition adherence for the week: {{context.weekNutritionSummary}}
- Habit completion for the week: {{context.weekHabitSummary}}
- Daily Fitness Score trend for the week: {{context.weekDfsTrend}}
- Active goals: {{context.activeGoals}}

Structure: one sentence celebrating the strongest part of the week (specific, not generic),
one sentence naming the area with the most room to improve (framed forward-looking, never
as a failure), and one concrete, specific recommendation for the coming week.
```

## User Prompt Template
Not applicable — this is a system-triggered batch generation, not a user-initiated turn. The "request" is the scheduled job invocation itself.

## Variables
| Variable | Source |
|---|---|
| `context.weekTrainingSummary` | Summarizer over the past 7 days of `workouts` |
| `context.weekNutritionSummary` | Summarizer over the past 7 days of `meals`/`meal_items` vs. targets |
| `context.weekHabitSummary` | `habit_logs` completion rate for the past 7 days |
| `context.weekDfsTrend` | `daily_fitness_scores` for the past 7 days |
| `context.activeGoals` | All active `goals` regardless of type (this is the one persona/capability that spans all domains, per [AI Coaching Engine § 3](../09-ai-coaching-engine.md#3-context-management)) |

## Context Requirements
The only capability that intentionally spans all tracking domains at once — everywhere else, context is persona-scoped and narrow; the Weekly Review's entire value is the cross-domain synthesis.

## Expected JSON Output
```json
{
  "summary": "Strong week on the training side — you hit all 4 planned sessions and set a new bench press PR. Nutrition logging dropped off on the weekend, which is worth a look. This week, try logging meals within an hour of eating rather than at day's end — same-day recall tends to be more accurate.",
  "highlightMetric": { "type": "workout_consistency", "value": "4/4 sessions" },
  "focusArea": { "type": "nutrition_logging_consistency", "value": "5/7 days logged" }
}
```
`summary` is the text rendered in the Weekly Review card ([AI Coach feature § Screen List](../features/ai-coach.md#screen-list)); `highlightMetric`/`focusArea` drive the card's visual accents without a second AI call.

## Error Handling
Generation failure (provider error) does not retry indefinitely — the job follows the standard queue retry policy ([Backend Architecture § 4](../07-backend-architecture.md#4-queues)) and, if still failing after retries, the Weekly Review card simply doesn't appear that week rather than showing a broken/error state — a missed weekly review is a low-severity, silent-degrade failure, not a user-facing error.

## Guardrails
Inherits [Safety Prompts](safety-prompts.md); the review is instructed to never frame the "focus area" as a failure, directly implementing the tone rules in [UI/UX Design System § 9](../06-ui-ux-design-system.md#9-content--tone-guidelines).

## Token Optimization
Run asynchronously during off-peak hours where feasible ([AI Coaching Engine § 8](../09-ai-coaching-engine.md#8-cost-optimization)) — batched, not real-time, so latency budget is generous and doesn't need to be optimized as tightly as the live chat path.

## Future Improvements
Monthly Review ([monthly-review.md](monthly-review.md), Future) reuses this same context-assembly pattern at a longer time horizon; progress-prediction ([progress-analysis.md](progress-analysis.md), Future) could eventually feed a third, predictive sentence into this same structure.
