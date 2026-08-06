# Prompt: Goal Recommendation

**Status:** Phase 2, per [PHASE2_SCOPE.md § Adaptive Plans](../PHASE2_SCOPE.md#adaptive-plans) (adjacent capability) — **draft, not reviewed**
**Related documents:** [Goals feature](../features/goals.md) · [AI Coaching Engine § 10](../09-ai-coaching-engine.md#10-future-extensibility)

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
Draft scaffolding for AI-suggested goal adjustments — e.g., recommending a more realistic target date, or suggesting a new goal once an existing one is achieved ([Goals § FR-701 auto-achievement](../features/goals.md#business-rules)).

## System Prompt
```
{{shared.systemPreamble}}

You are recommending a goal adjustment or next goal for {{user.firstName}} (draft).

Context (draft):
- Current and recently-achieved goals: {{context.goalHistory}}
- Recent training/nutrition consistency: {{context.consistencySummary}}
```

## User Prompt Template
Draft — likely triggered from the Goal Detail screen ("this goal seems ambitious, want a suggestion?") or automatically offered when a goal is marked `achieved`, not yet decided.

## Variables
| Variable | Source (anticipated) |
|---|---|
| `context.goalHistory` | `goals` (active + recently achieved/abandoned) |
| `context.consistencySummary` | Same summarizer pattern as [Motivation Coach](motivation-coach.md#variables) |

## Context Requirements
Not yet defined.

## Expected JSON Output
Anticipated shape (draft, unreviewed):
```json
{
  "recommendationType": "new_goal | adjust_target_date | adjust_target_value",
  "rationale": "string",
  "suggestedGoal": { "type": "strength", "targetMetric": "string", "targetValue": 0, "targetDate": "YYYY-MM-DD" }
}
```

## Error Handling
Not yet defined.

## Guardrails
Inherits [Safety Prompts](safety-prompts.md); should avoid recommending targets that would require unsafe rate-of-change (e.g., an aggressive weight-loss timeline) — this is a concrete guardrail case worth codifying explicitly (a rate-of-change sanity bound) before activation, not just relying on general model judgment.

## Token Optimization
Not yet defined.

## Future Improvements
This entire capability is future work; natural pairing with [Progress Analysis](progress-analysis.md) once both are scoped together, since a realistic goal recommendation depends on the same trajectory data.
