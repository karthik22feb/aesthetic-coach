# Prompt: Monthly Review

**Status:** Phase 2, per [SRS FR-605](../02-srs.md#46-ai-coaching) and [Development Roadmap § Phase 2 · Sprint 4](../16-development-roadmap.md#phase-2--sprint-4--predictive-coaching--advanced-analytics) — **draft, not reviewed**
**Related documents:** [Weekly Review](weekly-review.md) (this persona reuses that pattern at a longer horizon) · [AI Coaching Engine § 10](../09-ai-coaching-engine.md#10-future-extensibility)

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
Draft scaffolding for a monthly-cadence review, structurally identical to [Weekly Review](weekly-review.md) but summarizing a longer window and surfacing trend-level (not just week-over-week) observations — e.g., a plateau across 4 weeks that no single week would reveal.

## System Prompt
```
{{shared.systemPreamble}}

You are writing {{user.firstName}}'s Monthly Review (draft). Unlike the Weekly Review,
focus on trend-level patterns across the full month rather than single-week events —
plateaus, consistent strengths, and the single highest-leverage change for next month.

Context (draft):
- Training summary for the month: {{context.monthTrainingSummary}}
- Nutrition adherence for the month: {{context.monthNutritionSummary}}
- Habit completion for the month: {{context.monthHabitSummary}}
- Daily Fitness Score trend for the month: {{context.monthDfsTrend}}
- Goals achieved/abandoned this month: {{context.monthGoalActivity}}
```

## User Prompt Template
Not applicable — system-triggered batch generation, same pattern as [Weekly Review § User Prompt Template](weekly-review.md#user-prompt-template), monthly cadence instead of weekly.

## Variables
| Variable | Source (anticipated) |
|---|---|
| `context.monthTrainingSummary` | Same summarizer as [Weekly Review](weekly-review.md#variables), 30-day window |
| `context.monthNutritionSummary` | 30-day window |
| `context.monthHabitSummary` | 30-day window |
| `context.monthDfsTrend` | 30-day `daily_fitness_scores` |
| `context.monthGoalActivity` | `goals` status changes in the window |

## Context Requirements
Same cross-domain scope as [Weekly Review § Context Requirements](weekly-review.md#context-requirements), longer window — the summarizer's fixed-size-output design ([AI Coaching Engine § 3](../09-ai-coaching-engine.md#3-context-management)) needs to be re-validated at this longer horizon before activation to confirm it still compresses well.

## Expected JSON Output
Anticipated to mirror [Weekly Review § Expected JSON Output](weekly-review.md#expected-json-output) with a `trendInsight` field added for the plateau/pattern observation unique to the monthly horizon — not finalized.

## Error Handling
Anticipated to follow [Weekly Review § Error Handling](weekly-review.md#error-handling)'s silent-degrade pattern (a missed monthly review is low severity).

## Guardrails
Inherits [Safety Prompts](safety-prompts.md); same anti-shaming framing requirement as [Weekly Review § Guardrails](weekly-review.md#guardrails), arguably more important at this horizon since a month-long plateau is exactly the kind of observation that could read as discouraging if worded carelessly.

## Token Optimization
Anticipated to follow [Weekly Review § Token Optimization](weekly-review.md#token-optimization)'s async, off-peak batch-generation approach — a monthly cadence has an even more generous latency budget than weekly, so cost/scheduling pressure here is lower, not higher.

## Future Improvements
This entire capability is future work; build directly on the Weekly Review job infrastructure ([Backend Architecture § 6](../07-backend-architecture.md#6-scheduled-tasks-routesconsolephp--scheduler)) rather than a parallel implementation.
