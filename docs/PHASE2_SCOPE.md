# Phase 2 Scope — AI Personal Coach

**Status:** Begins only after [PHASE1_SCOPE.md](PHASE1_SCOPE.md)'s exit criteria are met (see [Phased Release Strategy § Exit Criteria](PHASED_RELEASE_STRATEGY.md#exit-criteria-for-each-phase)). This document is the target scope for the `v2.0.0` line of releases, not a fixed contract in the same binding sense as Phase 1 — capability sequencing within Phase 2 may reorder based on what Phase 1 usage data shows.
**Related documents:** [Phased Release Strategy](PHASED_RELEASE_STRATEGY.md) · [PHASE1_SCOPE.md](PHASE1_SCOPE.md) · [Development Roadmap § Phase 2](16-development-roadmap.md#phase-2--ai-personal-coach) · [AI Coaching Engine](09-ai-coaching-engine.md) · [MASTER_IMPLEMENTATION_PLAN.md](../MASTER_IMPLEMENTATION_PLAN.md)

## Table of Contents
- [How to Read This Document](#how-to-read-this-document)
- [Capability Matrix](#capability-matrix)
- [Capability Detail](#capability-detail)
- [Why Phase 2, Not Phase 1](#why-phase-2-not-phase-1)
- [Architecture Impact](#architecture-impact)

## How to Read This Document

Every capability below already exists as an architecture-level concept in [AI Coaching Engine § 10 Future Extensibility](09-ai-coaching-engine.md#10-future-extensibility) and/or an existing feature/prompt spec — this document does not invent new capability, it schedules already-designed capability and states explicitly why it waits for Phase 1 data. "Dependency on Phase 1 Data" describes *what specific Phase 1 output* each capability consumes — this is the mechanism referenced throughout [Phased Release Strategy](PHASED_RELEASE_STRATEGY.md) by which "the coaching engine leverages user history collected during Phase 1."

## Capability Matrix

| # | Capability | Primary Doc(s) | Why Phase 2 | Dependency on Phase 1 Data | AI Complexity |
|---|---|---|---|---|---|
| 1 | AI Coach (Conversational) | [AI Coach feature](features/ai-coach.md), [AI Coach screen](screens/ai-coach.md) | Full multi-turn, persona-switching chat UI is the core "second release" experience | Needs weeks of workout/nutrition/habit history to give grounded, specific answers rather than generic ones | High |
| 2 | Nutrition Coach | [AI Prompt — Nutrition Coach](ai/nutrition-coach.md) | Conversational nutrition guidance depends on the Conversational Coach UI shipping first | 7+ days of meal-logging history per persona's own context requirements ([AI Prompt — Nutrition Coach § Context Requirements](ai/nutrition-coach.md#context-requirements)) | Medium |
| 3 | Recovery Coach | [AI Prompt — Recovery Coach](ai/recovery-coach.md) | Explicitly depends on Wearable Integrations, itself Phase 2 | Recovery/HRV/sleep data that doesn't exist until Wearable Integrations ships | High |
| 4 | Habit Coach | [AI Coaching Engine § 10](09-ai-coaching-engine.md#10-future-extensibility) | New persona, not yet drafted in the AI Prompt Library — first Phase 2 persona to author from scratch | Habit streak history accumulated across Phase 1 | Medium |
| 5 | Predictive AI | [AI Prompt — Progress Analysis](ai/progress-analysis.md) | Explicit open design question in the original doc (confidence-language, methodology) requiring real data to validate against | Multi-week trend data across goals/measurements — a goal created last week produces "not enough data yet," by design | High |
| 6 | Lifestyle Coaching | [AI Coaching Engine § 10](09-ai-coaching-engine.md#10-future-extensibility) (cross-persona synthesis, not yet a named persona in the prompt library) | Synthesizes across Motivation, Habit, and Nutrition coaching — needs those personas live first | Cross-domain Phase 1 history, same as Weekly/Monthly Review | High |
| 7 | Conversational Coaching (infrastructure) | [AI Coaching Engine § 1](09-ai-coaching-engine.md#1-ai-architecture) | The multi-turn chat *pipeline* underlying capability #1 — listed separately since it's the shared infrastructure every persona-chat capability depends on | N/A (infrastructure, not data-dependent) | High |
| 8 | Context Memory (long-term) | [AI Coaching Engine § 4](09-ai-coaching-engine.md#4-user-memory-strategy) | The Future retrieval-layer upgrade path already named in the original doc ("if conversation volume grows...") — only justified once real conversation volume exists | Requires Phase 2's *own* conversation history to accumulate before it's needed — a genuinely Phase-2-internal dependency | High |
| 9 | Adaptive Plans | [AI Prompt — Workout Coach](ai/workout-coach.md) (conversational adjustment, beyond Phase 1's one-shot generation) | Phase 1 ships one-shot generation only; ongoing conversational plan adaptation ("swap today's leg day...") needs the Conversational Coach | Rolling multi-week training load history | Medium |
| 10 | Wearable Integrations | [Wearable Integrations feature](features/wearable-integrations.md), [Future Integrations](future-integrations.md) | OAuth/webhook infrastructure investment not justified until core product-market fit is validated in Phase 1 | None directly — unlocks *future* data collection rather than consuming Phase 1 data, but is sequenced early in Phase 2 since Recovery Coach depends on it | Low (integration complexity, not AI complexity) |
| 11 | Community | [PRD § 5.4](01-prd.md#54-engagement) (not yet a dedicated feature doc — see [Notes](#why-phase-2-not-phase-1)) | Reclassified into Phase 2 per this strategy (previously "Phase 3" in the original PRD) | Benefits from an established user base post-Phase-1-launch | N/A (not an AI capability) |
| 12 | Challenges | [Challenges feature](features/challenges.md) | Reclassified into Phase 2 per this strategy; the feature doc's own placeholder status is unchanged — see [Notes](#why-phase-2-not-phase-1) | Benefits from Achievements data already accumulating since Phase 1 | N/A (not an AI capability) |
| 13 | Leaderboards | [PRD § 5.4](01-prd.md#54-engagement) (not yet a dedicated feature doc) | Depends on Community/Challenges shipping first within Phase 2 | User-generated Phase 1+2 activity data | N/A (not an AI capability) |
| 14 | Advanced Analytics | [Analytics screen](screens/analytics.md) (predictive extensions) | Builds directly on Predictive AI (#5) | Same multi-week trend data dependency as Predictive AI | High |

## Capability Detail

### AI Coach (Conversational)
**Why Phase 2:** this is the flagship Phase 2 deliverable — the full [AI Coach screen](screens/ai-coach.md) persona switcher and multi-turn chat experience that Phase 1 deliberately ships without (Phase 1 ships only the narrow, single-purpose AI utilities described in [PHASE1_SCOPE.md](PHASE1_SCOPE.md)).
**Dependency on Phase 1 data:** the Context Builder ([AI Coaching Engine § 3](09-ai-coaching-engine.md#3-context-management)) summarizes 4 weeks of workout history and 7 days of nutrition history by design — a brand-new Phase-2-day-one user has none of that, so this capability is genuinely more valuable the longer Phase 1 has been live before Phase 2 launches.
**Technical considerations:** no new pipeline — this activates the `personal_trainer` persona's conversational mode (structured generation, already live since Phase 1, plus open-ended chat) via the existing `AiProviderInterface` pipeline. Primarily a mobile-side UI build (Coach tab, streaming chat bubble) plus enabling the already-built backend chat endpoint for general availability.
**Expected AI complexity:** High — open-ended conversation quality, multi-turn context retention, and guardrail robustness against a much wider input space than Phase 1's structured/single-turn calls.

### Nutrition Coach
**Why Phase 2:** conversational meal guidance naturally follows the Conversational Coach UI; FR-304 (AI meal suggestions) is deferred from its original MVP classification specifically for this reason — see [Nutrition feature](features/nutrition.md) metadata.
**Dependency on Phase 1 data:** [AI Prompt — Nutrition Coach § Context Requirements](ai/nutrition-coach.md#context-requirements) already specifies a 7-day meal-logging window; Phase 1's nutrition tracking (shipped Sprint 4) is exactly what populates it.
**Technical considerations:** prompt template already drafted and reviewed ([AI Prompt — Nutrition Coach](ai/nutrition-coach.md)); activation is a persona-registry config change plus mobile persona-switcher entry, not new pipeline work.
**Expected AI complexity:** Medium — narrower domain than the general Conversational Coach, well-bounded by dietary restrictions and macro targets already in the schema.

### Recovery Coach
**Why Phase 2:** explicitly gated on Wearable Integrations (#10) — see [AI Prompt — Recovery Coach § Purpose](ai/recovery-coach.md#purpose), which states this directly.
**Dependency on Phase 1 data:** none from Phase 1 tracking directly; depends entirely on Wearable Integrations data that doesn't exist until later in Phase 2.
**Technical considerations:** prompt is currently a draft, unreviewed for production tone ([AI Prompt — Recovery Coach](ai/recovery-coach.md)) — needs a dedicated tone/safety review pass before activation, flagged in that document already.
**Expected AI complexity:** High — recovery/sleep topics sit close to the medical-adjacent guardrail boundary (BR-9), requiring careful review.

### Habit Coach
**Why Phase 2:** not yet drafted at all in the AI Prompt Library (only Recovery, Motivation, Progress Analysis, and Goal Recommendation have Phase-2 draft prompts) — this is new authoring work for Phase 2, using the same template pattern as [AI Prompt — Motivation Coach](ai/motivation-coach.md).
**Dependency on Phase 1 data:** habit streak and completion-rate history from [Habits feature](features/habits.md), live since Phase 1 Sprint 4.
**Technical considerations:** follows the exact persona-addition pattern already documented in [AI Coaching Engine § 10](09-ai-coaching-engine.md#10-future-extensibility) — prompt template + persona-registry entry + context-builder query, no pipeline change.
**Expected AI complexity:** Medium.

### Predictive AI
**Why Phase 2:** [AI Prompt — Progress Analysis](ai/progress-analysis.md) already flags an unresolved product question (how to communicate prediction uncertainty) that requires real usage patterns to answer responsibly — shipping this in Phase 1 with insufficient data would risk presenting noise as a confident forecast.
**Dependency on Phase 1 data:** explicitly data-depth-gated — the prompt's own error-handling section requires an honest "not enough data yet" response for new goals, meaning this capability literally cannot function meaningfully without weeks of Phase 1 history.
**Technical considerations:** methodology (simple linear trend vs. more sophisticated modeling) is an open decision for Phase 2 planning, not resolved by this document.
**Expected AI complexity:** High — the guardrail concern (avoiding overconfident predictions) is as significant as the modeling problem itself.

### Lifestyle Coaching
**Why Phase 2:** a cross-persona synthesis capability that only makes sense once Nutrition Coach, Habit Coach, and Motivation Coach are all live to synthesize across.
**Dependency on Phase 1 data:** full cross-domain history, same pattern as [AI Prompt — Weekly Review](ai/weekly-review.md) but persona-conversational rather than batch-generated.
**Technical considerations:** not yet drafted; likely the last Phase 2 persona to build given its dependency on the others.
**Expected AI complexity:** High.

### Conversational Coaching (infrastructure)
**Why Phase 2:** listed as its own line item because it's the shared multi-turn chat *mechanism* (SSE streaming already built and tested in Phase 1 for the structured-generation and lightweight-explanation calls) — Phase 2's job is enabling sustained multi-turn conversations against it, not building new plumbing.
**Dependency on Phase 1 data:** none directly — this is the infrastructure other Phase 2 capabilities depend on.
**Technical considerations:** [AI Coaching Engine § 1](09-ai-coaching-engine.md#1-ai-architecture)'s pipeline (budget check → context assembly → persona prompt → provider call → guardrail → usage recording) already supports this; Phase 2 work is primarily mobile UI (full Coach tab) and widening the conversation-turn budget/UX.
**Expected AI complexity:** High (see AI Coach above — this is the same underlying complexity, listed separately for planning granularity).

### Context Memory (long-term)
**Why Phase 2:** the original AI Coaching Engine doc already names this as a Future upgrade path contingent on real conversation volume existing — a condition Phase 1 alone cannot satisfy since it has no conversational surface at all.
**Dependency on Phase 1 data:** none from Phase 1; depends on Phase 2's *own* accumulated conversation history, making this appropriately the latest-sequenced Phase 2 capability.
**Technical considerations:** architected as an additive `MemoryRetrieverInterface` per [AI Coaching Engine § 4](09-ai-coaching-engine.md#4-user-memory-strategy) — does not require reworking the Context Builder that ships with Conversational Coach.
**Expected AI complexity:** High (retrieval/embedding infrastructure is new engineering surface, not just a prompt change).

### Adaptive Plans
**Why Phase 2:** Phase 1's AI Workout Recommendations is one-shot generation only (`POST /templates/ai-generate`); ongoing conversational adjustment ("swap today's session," "I'm sore, adjust this week") requires the Conversational Coach.
**Dependency on Phase 1 data:** rolling multi-week training load, the same summarization already built for Phase 1's structured generation ([AI Prompt — Workout Coach § Context Requirements](ai/workout-coach.md#context-requirements)) — this capability reuses that context assembly, just through a conversational surface instead of a single API call.
**Technical considerations:** no new context-building work; this is primarily enabling the `personal_trainer` persona's conversational mode, same activation pattern as Nutrition Coach.
**Expected AI complexity:** Medium.

### Wearable Integrations
**Why Phase 2:** [Wearable Integrations feature § Status](features/wearable-integrations.md) already scopes this as Future/Phase 2; OAuth and webhook infrastructure per provider ([Future Integrations](future-integrations.md)) is a meaningful build investment sequenced early in Phase 2 specifically to unlock Recovery Coach.
**Dependency on Phase 1 data:** none — this is a forward dependency (Recovery Coach depends on it), not a consumer of Phase 1 tracked data.
**Technical considerations:** full per-provider detail already documented in [Future Integrations](future-integrations.md); recommended build order there (Apple Health/Health Connect → Smart Scales → Whoop/Oura → Fitbit/Garmin → Strava → Calendar) still applies unchanged.
**Expected AI complexity:** N/A — integration engineering, not an AI capability itself.

### Community, Challenges, Leaderboards
**Why Phase 2:** reclassified from the original PRD's "Phase 3" framing into this strategy's Phase 2 per the new product direction — see [Notes](#why-phase-2-not-phase-1) below for the explicit callout of this change.
**Dependency on Phase 1 data:** benefits from (but doesn't strictly require) an established Phase 1 user base and the Achievements data already accumulating since Phase 1 Sprint 6.
**Technical considerations:** [Challenges feature § Database Tables](features/challenges.md#database-tables) still correctly notes no schema exists yet — this remains a placeholder requiring its own dedicated design pass before implementation, exactly as the original document states. Being "in Phase 2" here means it's scheduled, not yet spec-ready.
**Expected AI complexity:** N/A.

### Advanced Analytics
**Why Phase 2:** builds directly on Predictive AI; "advanced" specifically means the predictive/trajectory layer beyond Phase 1's [Basic Analytics](PHASE1_SCOPE.md#basic-analytics).
**Dependency on Phase 1 data:** same multi-week trend-depth requirement as Predictive AI.
**Technical considerations:** extends the existing [Analytics screen](screens/analytics.md) rather than introducing a new screen.
**Expected AI complexity:** High.

## Why Phase 2, Not Phase 1

Every capability in this document shares at least one of two properties that justifies deferral:

1. **It needs Phase 1 history to be good**, not just to function (Nutrition Coach, Habit Coach, Predictive AI, Lifestyle Coaching, Adaptive Plans) — shipping these at Phase 1 launch would mean shipping them at their weakest, undermining the product's own "intelligent coach" positioning rather than strengthening it.
2. **It's a genuinely large, separable investment** better sequenced after core product-market fit is validated (Wearable Integrations, Community/Challenges/Leaderboards, Context Memory infrastructure) — deferring these protects the Phase 1 launch timeline without sacrificing them from the roadmap.

**Explicit reclassification note:** Community, Challenges, and Leaderboards were framed as "Phase 3" in the original [PRD § 9](01-prd.md#9-mvp-vs-future-phases) before this two-phase strategy existed. This document folds them into Phase 2 per the new strategy's explicit instruction; no content in [Challenges feature](features/challenges.md) needed to change as a result — it was already correctly scoped as a placeholder pending its own design pass, which remains true regardless of which phase number it's filed under.

## Architecture Impact

**None required.** Every capability in this document activates existing, already-designed architecture:
- New personas: prompt template + `PersonaRegistry` entry + context-builder query — the exact addition pattern [AI Coaching Engine § 10](09-ai-coaching-engine.md#10-future-extensibility) was written to support.
- New integrations: implement `AiProviderInterface`-equivalent boundary work already scoped in [Future Integrations](future-integrations.md).
- New tables (wearables, community/challenges, long-term memory retrieval): purely additive migrations, per [Database Design § 10](04-database-design.md#10-phased-implementation--architecture-validation).

See [Phased Release Strategy § Technical Justification](PHASED_RELEASE_STRATEGY.md#technical-justification) for the full architecture validation summary.
