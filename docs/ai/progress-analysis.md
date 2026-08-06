# Prompt: Progress Analysis (Progress Prediction)

**Status:** Phase 2 ("Predictive Coaching" / "Advanced Analytics", per [PHASE2_SCOPE.md § Predictive AI](../PHASE2_SCOPE.md#predictive-ai)) — **draft, not reviewed**
**Related documents:** [AI Coaching Engine § 5](../09-ai-coaching-engine.md#5-recommendation-engine) · [Goals feature](../features/goals.md) · [Weekly Review](weekly-review.md)

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
Draft scaffolding for trajectory prediction ("at this rate you reach goal X on date Y," per [PRD § 5.2](../01-prd.md#52-ai-coaching)) — an explicit **open design question** noted in the PRD as needing product definition of what "prediction" means and how confident/hedged the language should be, not yet resolved here.

## System Prompt
```
{{shared.systemPreamble}}

You are analyzing {{user.firstName}}'s progress trajectory toward an active goal (draft —
requires product decision on confidence-language and disclaiming appropriately, this is
not a statistical guarantee and must never be presented as one).

Context (draft):
- Goal: {{context.goal}}
- Historical rate of progress toward the goal's metric: {{context.progressRate}}
```

## User Prompt Template
Draft — likely a structured, on-demand request from the Goal Detail screen rather than free conversation; exact trigger not yet decided.

## Variables
| Variable | Source (anticipated) |
|---|---|
| `context.goal` | `goals` row |
| `context.progressRate` | Trend computed from `body_measurements`/`workout_sets` depending on goal type |

## Context Requirements
Not yet defined — depends on the prediction methodology chosen (simple linear trend vs. something more sophisticated), which is itself an open product/engineering decision.

## Expected JSON Output
Not yet defined.

## Error Handling
Not yet defined. Flagged concern: insufficient history (a goal created last week) must produce an honest "not enough data yet" response, never a confident-sounding prediction from noise.

## Guardrails
Whatever ships here must avoid presenting probabilistic/uncertain projections as guarantees — this is as much a guardrail concern as a UX one, and should be reviewed alongside [Safety Prompts](safety-prompts.md) even though it's not medical-adjacent, because overconfident predictions could mislead users' expectations and effort allocation.

## Token Optimization
Not yet defined.

## Future Improvements
This entire capability is future work; recommend resolving the "what does prediction mean and how is uncertainty communicated" product question before drafting the real prompt.
