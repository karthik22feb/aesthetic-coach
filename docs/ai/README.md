# AI Prompt Library

**Related documents:** [AI Coaching Engine](../09-ai-coaching-engine.md) (architectural source of truth for how these prompts are stored, versioned, and rendered) · [AI Coach feature](../features/ai-coach.md)

This folder contains the actual prompt content for every AI capability in Aesthetic Coach, organized by persona/capability per [AI Coaching Engine § 2 Prompt Management](../09-ai-coaching-engine.md#2-prompt-management). Each file corresponds to a template that would live under `resources/ai-prompts/{persona}/v{n}.md` in the backend codebase ([Backend Architecture § 1](../07-backend-architecture.md#1-folder-structure)) — these documents are the reviewed, version-controlled source that file is generated/copied from.

## Table of Contents

| Prompt | Release Phase | File |
|---|---|---|
| System Prompts (shared) | Phase 1 & 2 | [system-prompts.md](system-prompts.md) |
| Personal Trainer (Workout Coach) | Phase 1 (generation/explanation) · Phase 2 (chat/Adaptive Plans) | [workout-coach.md](workout-coach.md) |
| Nutrition Coach | Phase 2 | [nutrition-coach.md](nutrition-coach.md) |
| Recovery Coach | Phase 2 | [recovery-coach.md](recovery-coach.md) |
| Motivation Coach | Phase 2 (simple "Motivation" nudges ship Phase 1 outside this persona) | [motivation-coach.md](motivation-coach.md) |
| Progress Analysis | Phase 2 | [progress-analysis.md](progress-analysis.md) |
| Goal Recommendation | Phase 2 | [goal-recommendation.md](goal-recommendation.md) |
| Weekly Review | Phase 1 | [weekly-review.md](weekly-review.md) |
| Monthly Review | Phase 2 | [monthly-review.md](monthly-review.md) |
| Safety Prompts (shared guardrail clause) | Phase 1 & 2 | [safety-prompts.md](safety-prompts.md) |

## Conventions

- **Versioning:** every prompt file below has an implicit `v1` — when a prompt is materially revised, bump the version and keep the prior version's file (e.g., `workout-coach-v1.md` archived) since past `coach_messages` rows reference the prompt version they were generated under ([AI Coaching Engine § 2](../09-ai-coaching-engine.md#2-prompt-management)).
- **Variables:** written as `{{namespace.field}}`, matching the template syntax in [AI Coaching Engine § 2](../09-ai-coaching-engine.md#2-prompt-management). Variables are populated by the Context Builder ([AI Coaching Engine § 3](../09-ai-coaching-engine.md#3-context-management)) — never by concatenating raw user input into the system prompt.
- **Modularity:** [Safety Prompts](safety-prompts.md) is a shared clause appended to every persona's system prompt, not duplicated inline in each file — one place to update guardrail language across all personas.
- **Review process:** prompt changes go through the same PR review as code ([Backend Architecture § Coding Standards](../07-backend-architecture.md#8-coding-standards); [User Documentation § Admin Documentation](../15-user-documentation.md#6-admin-documentation)).
- **Provider neutrality:** prompt text itself is provider-agnostic; only the request-shaping (system/messages/tool-schema mapping) is Claude-specific, per [AI Coaching Engine § 6 Model Abstraction Layer](../09-ai-coaching-engine.md#6-model-abstraction-layer).

## Phase 1 vs. Phase 2

**Phase 1** activates **System Prompts**, **Safety Prompts**, **Workout Coach** (structured generation + lightweight explanation modes only — not open-ended chat), and **Weekly Review**. **Phase 2** activates **Nutrition Coach**, **Recovery Coach**, and a to-be-authored Habit Coach, plus **Progress Analysis**, **Goal Recommendation**, and **Monthly Review**, per [PHASE2_SCOPE.md](../PHASE2_SCOPE.md). The remaining files are written now as forward-looking scaffolding (consistent with [AI Coaching Engine § 10 Future Extensibility](../09-ai-coaching-engine.md#10-future-extensibility)) so Phase 2 implementation ([Development Roadmap § Phase 2](../16-development-roadmap.md#phase-2--ai-personal-coach)) has a concrete starting draft rather than a blank page — they are drafts pending product/clinical-tone review before activation, not final copy.
