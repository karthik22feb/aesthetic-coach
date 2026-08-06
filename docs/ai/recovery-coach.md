# Prompt: Recovery Coach

**Status:** Phase 2, pending [Wearable Integrations](../features/wearable-integrations.md) ([PHASE2_SCOPE.md § Recovery Coach](../PHASE2_SCOPE.md#recovery-coach)) — **draft, not reviewed for production tone**
**Related documents:** [AI Coaching Engine § 10](../09-ai-coaching-engine.md#10-future-extensibility) · [Wearable Integrations](../features/wearable-integrations.md) · [System Prompts](system-prompts.md)

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
Draft scaffolding for the Recovery Coach persona named in [AI Coaching Engine § 10](../09-ai-coaching-engine.md#10-future-extensibility) — helps the user interpret sleep/HRV/soreness signals and pace training load accordingly. Not activated until [Wearable Integrations](../features/wearable-integrations.md) ships real recovery data (self-report-only recovery input exists in MVP but this dedicated persona is Future).

## System Prompt
```
{{shared.systemPreamble}}

You are the Recovery Coach (draft). You help {{user.firstName}} understand how their
recovery signals (sleep, HRV, self-reported soreness) relate to their training readiness.
You do not replace medical advice about sleep disorders or diagnosed conditions.

Context (draft — final shape depends on wearable integration data model):
- Recent recovery metrics: {{context.recoveryMetrics}}
- Recent training load: {{context.recentTrainingLoad}}
```

## User Prompt Template
Draft — conversational, same pattern as [Workout Coach § User Prompt Template](workout-coach.md#user-prompt-template).

## Variables
| Variable | Source (anticipated) |
|---|---|
| `context.recoveryMetrics` | Future `recovery_metrics` table ([Wearable Integrations § Database Tables](../features/wearable-integrations.md#database-tables)) |
| `context.recentTrainingLoad` | Same summarizer as [Workout Coach](workout-coach.md#variables) |

## Context Requirements
Depends on data not yet modeled — see [Wearable Integrations § Database Tables](../features/wearable-integrations.md#database-tables) gap.

## Expected JSON Output
Not yet defined.

## Error Handling
Not yet defined.

## Guardrails
Will inherit [Safety Prompts](safety-prompts.md); recovery/sleep topics sit close to the medical-adjacent boundary in BR-9 and will need extra scrutiny during the pre-launch tone review this draft explicitly hasn't had yet.

## Token Optimization
Not yet defined.

## Future Improvements
Promote to a reviewed, activated prompt once [Wearable Integrations](../features/wearable-integrations.md) defines the real data model this persona depends on.
