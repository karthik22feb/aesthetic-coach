# ADR-0006: Claude API as Primary AI Provider

**Status:** Accepted
**Related documents:** [AI Coaching Engine](../09-ai-coaching-engine.md) · [AI Coaching Engine § 6 Model Abstraction Layer](../09-ai-coaching-engine.md#6-model-abstraction-layer) · [PRD § AI Stack](../01-prd.md)

## Context
The product's core differentiator is AI coaching that reasons over structured user data, holds a coaching persona consistently, and streams responses at low latency. The stakeholder has an existing Claude Pro subscription for development and specified Claude API as the primary engine, with an explicit requirement that other providers (OpenAI, Gemini) be addable later "with minimal changes."

## Problem
Which LLM provider should the AI Coaching Engine be built against first, and how should the integration be structured so it isn't a rewrite if a second provider is added later?

## Decision
Use the Claude API as the sole implemented provider in MVP, accessed exclusively server-side, behind a provider-neutral `AiProviderInterface` ([AI Coaching Engine § 6](../09-ai-coaching-engine.md#6-model-abstraction-layer)) that no other part of the coaching pipeline (Context Builder, Persona Registry, Guardrail Filter) depends on directly.

## Alternatives Considered
| Option | Why not chosen |
|---|---|
| OpenAI as primary | Stakeholder specified Claude explicitly, with existing familiarity via a Claude Pro subscription; no product-specific driver to prefer OpenAI first |
| Multi-provider from day one (routing between providers per request) | Premature complexity — the abstraction is built to make this *possible* later, but implementing actual multi-provider routing before there's a concrete driver (cost, redundancy, capability gap) would be speculative engineering the project's own principles argue against |
| A self-hosted/open-weight model | Would require significant additional infrastructure (GPU hosting, model-serving stack) disproportionate to this project's scale and team size, and forgoes the frontier-model coaching-quality bar the product is explicitly aiming for ("one of the most intelligent... fitness ecosystems," [PRD](../01-prd.md)) |

## Pros
- Strong fit for the product's conversational-coaching-with-structured-context use case.
- The `AiProviderInterface` abstraction (§ 6 of the linked doc) means Persona Registry, Context Builder, and Guardrail Filter code is entirely provider-agnostic — a second provider is a new implementation class plus a config change, not a rewrite.
- Prompt caching support (referenced in [AI Coaching Engine § 8 Cost Optimization](../09-ai-coaching-engine.md#8-cost-optimization)) fits well with this product's stable-system-prompt-plus-per-turn-context prompt shape.

## Cons
- Single-provider dependency risk (outage, pricing change, rate-limit changes) — partially mitigated by the abstraction layer making a second provider addable without a redesign, though not instantaneously (still requires implementation work when the time comes).
- Production billing is metered API usage, distinct from the developer's personal Claude Pro subscription ([Production Hardening § Secrets Management](../14-production-hardening.md#3-encryption--secrets-management) makes this distinction explicit) — cost must be actively monitored, not assumed free from the existing subscription.

## Consequences
Every persona prompt in the [AI Prompt Library](../ai/) is written to be provider-neutral in content (only the request-shaping layer is Claude-specific); [AI Coaching Engine § 8–9](../09-ai-coaching-engine.md#8-cost-optimization) builds cost/rate-limit controls around Claude's specific API shape (streaming, prompt caching) while keeping the control logic itself (token budgets, usage recording) provider-agnostic.

## Future Review Criteria
Add a second provider when there's a concrete driver: a cost advantage for specific lighter-weight tasks (model-tier routing, already anticipated in [AI Coaching Engine § 8](../09-ai-coaching-engine.md#8-cost-optimization)), a redundancy requirement once AI coaching is critical-path for a large user base, or a capability gap Claude doesn't cover. Not driven by provider-preference alone.
