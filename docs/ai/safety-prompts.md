# Safety Prompts (Shared Guardrail Clause)

**Status:** Phase 1 & Phase 2 (shared guardrail clause, applies to every persona activated in either phase — see [AI Coaching Engine § 11 Phased Rollout](../09-ai-coaching-engine.md#11-phased-rollout))
**Related documents:** [AI Coaching Engine § 7](../09-ai-coaching-engine.md#7-safety-guardrails) · [SRS BR-9](../02-srs.md#6-business-rules) · [System Prompts](system-prompts.md) · [Production Hardening § 9](../14-production-hardening.md#9-compliance-considerations)

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
The single, shared guardrail clause injected into every persona's system prompt (via [System Prompts § safety.guardrailClause](system-prompts.md#variables)) implementing BR-9 — one place to update safety language across all personas rather than duplicating it per file.

## System Prompt
```
Safety boundaries (apply to every response):
- You do not diagnose injuries or medical conditions, prescribe medication or supplements,
  or provide guidance specific to eating disorders or disordered eating patterns.
- If the user describes symptoms suggesting injury, illness, or a concerning relationship
  with food or exercise, acknowledge their concern warmly, avoid speculating on a cause or
  diagnosis, and recommend they consult an appropriate professional (a doctor, physical
  therapist, or registered dietitian as relevant) before continuing with that specific
  concern. Continue to help with anything else they've asked that's within scope.
- Do not use alarming, clinical, or diagnostic language. Stay warm and calm.
- If asked to role-play as a licensed professional (doctor, therapist, dietitian) or to
  make a claim of medical certainty, decline and restate your role as a fitness/wellness
  coach.
```

## User Prompt Template
Not applicable — this is a fixed clause, not a per-turn template; it does not interpolate user input.

## Variables
None — deliberately static so its content is fully auditable and never influenced by user-provided text (mitigates prompt-injection risk per [AI Coaching Engine § 7](../09-ai-coaching-engine.md#7-safety-guardrails)).

## Context Requirements
None.

## Expected JSON Output
Not applicable.

## Error Handling
Not applicable at the prompt level — the corresponding **output-side** enforcement (the deterministic guardrail filter that checks/appends the referral disclaimer if the model's response omits it despite this instruction) is implemented in code, described in [AI Coaching Engine § 7](../09-ai-coaching-engine.md#7-safety-guardrails), not here — this file defines the *input* instruction only.

## Guardrails
This file **is** the guardrail definition; see [AI Coaching Engine § 7](../09-ai-coaching-engine.md#7-safety-guardrails) for the full defense-in-depth picture (system-prompt instruction + output-side pattern filter + tone guidance from [UI/UX Design System § 9](../06-ui-ux-design-system.md#9-content--tone-guidelines)).

## Token Optimization
Fixed, short, and part of the stable cached prefix ([System Prompts § Token Optimization](system-prompts.md#token-optimization)) — its cost is effectively paid once per conversation, not per turn.

## Future Improvements
Phase 2+ human-in-the-loop escalation for repeated at-risk conversation patterns (self-harm/disordered-eating signals) is explicitly deferred in [AI Coaching Engine § 7](../09-ai-coaching-engine.md#7-safety-guardrails) pending real usage data — when scoped, the detection/escalation logic would live in the output-side guardrail filter, with this input-side clause updated only if the escalation behavior requires the model to behave differently going in (e.g., explicitly surfacing a crisis-resource message).
