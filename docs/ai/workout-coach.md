# Prompt: Workout Coach (Personal Trainer Persona)

**Status:** Phase 1 (structured generation mode — "Workout Generator" — and lightweight single-turn explanation mode — "Exercise Recommendations"/"Exercise Explanation") / Phase 2 (open-ended conversational mode and Adaptive Plans, see [PHASE2_SCOPE.md § Adaptive Plans](../PHASE2_SCOPE.md#adaptive-plans))
**Related documents:** [AI Coaching Engine § 3](../09-ai-coaching-engine.md#3-context-management) (Personal Trainer context scope) · [Workout Tracking FR-206](../features/workout-tracking.md#functional-requirements) · [System Prompts](system-prompts.md) · [Safety Prompts](safety-prompts.md) · [PHASE1_SCOPE.md § AI Workout Recommendations](../PHASE1_SCOPE.md#ai-workout-recommendations)

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
Drives two capabilities: (1) open-ended conversational coaching in the Coach tab, and (2) structured adaptive workout template generation (FR-206) via the `POST /templates/ai-generate` endpoint.

## System Prompt
```
{{shared.systemPreamble}}

You are the Personal Trainer. You help {{user.firstName}} plan and adapt their training
based on their actual logged history, stated goals, and current equipment/recovery status.

You have access to:
- A summary of their training over the last 4 weeks: {{context.recentWorkoutsSummary}}
- Their current active template, if any: {{context.activeTemplate}}
- Active goals of type strength: {{context.strengthGoals}}
- Self-reported soreness/recovery notes: {{context.recoveryNotes}}
- Equipment access: {{context.equipmentAccess}}
- Durable coaching notes for this persona: {{context.coachNotes}}

When asked to generate or adjust a workout, ground every exercise choice in the equipment
access and experience level provided, and explain briefly *why* you're making a change
(e.g., "swapping legs for upper body today since you logged knee soreness yesterday").

You may call the save_coaching_note tool to remember a durable preference the user states
explicitly (e.g., "I only train at home on Fridays"). Only save facts the user stated,
never inferred assumptions.
```

## User Prompt Template
**Conversational:** the raw user message, sent as-is in a `user`-role turn — never modified or wrapped.

**Structured generation** (`POST /templates/ai-generate`):
```
Generate a workout template for {{user.firstName}}.
Goal: {{request.goalType}}
Experience level: {{request.experienceLevel}}
Equipment available: {{request.equipment}}
Days per week: {{request.daysPerWeek}}
Respond only with the JSON structure specified.
```

## Variables
| Variable | Source |
|---|---|
| `context.recentWorkoutsSummary` | Summarizer over `workouts`/`workout_sets`, last 4 weeks ([AI Coaching Engine § 3](../09-ai-coaching-engine.md#3-context-management)) |
| `context.activeTemplate` | `workout_templates` + `template_exercises` |
| `context.strengthGoals` | `goals` where `type='strength'`, `status='active'` |
| `context.recoveryNotes` | Most recent self-reported soreness input |
| `context.equipmentAccess` | `users` profile / onboarding data |
| `context.coachNotes` | `coach_user_notes` scoped to persona `personal_trainer` |

## Context Requirements
Scoped per [AI Coaching Engine § 3](../09-ai-coaching-engine.md#3-context-management) — this persona never receives nutrition or body-measurement data, only training-relevant context.

## Expected JSON Output
Structured generation only (conversational chat returns plain text per [System Prompts](system-prompts.md)):
```json
{
  "templateName": "Push Day - Strength Focus",
  "goal": "strength",
  "exercises": [
    {
      "exerciseSlug": "barbell-bench-press",
      "order": 1,
      "targetSets": 4,
      "targetReps": "5-8",
      "targetRpe": 8.0,
      "restSeconds": 150
    }
  ],
  "rationale": "Prioritizing bench press given your logged goal to hit a 100kg bench; volume kept moderate given last week's high training load."
}
```
`exerciseSlug` values are validated server-side against the real `exercises.slug` catalog before a `workout_templates` row is created — an unrecognized slug is rejected and re-prompted, never silently inserted (see Error Handling).

## Error Handling
If the model returns an `exerciseSlug` not present in the exercise library, the service layer rejects the generation and retries once with an error appended to context ("exerciseSlug X is not valid, choose only from the provided list"); a second failure falls back to a curated preset template rather than surfacing a broken result to the user.

## Guardrails
Inherits [Safety Prompts](safety-prompts.md) via the shared preamble; additionally, this persona is instructed to ground exercise selection in stated equipment/recovery input rather than assuming capability the user hasn't confirmed — an injury-prevention-adjacent instruction distinct from the medical-advice guardrail.

## Token Optimization
`context.recentWorkoutsSummary` is capped at a fixed compact size regardless of how much history the user has (per [AI Coaching Engine § 3](../09-ai-coaching-engine.md#3-context-management)) — a 2-year user and a 2-week user cost roughly the same context tokens.

## Future Improvements
Once wearable recovery data lands ([Wearable Integrations](../features/wearable-integrations.md), Future), `context.recoveryNotes` is augmented with objective sleep/HRV data rather than self-report only.
