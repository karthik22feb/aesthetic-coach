# AI Development Guide

**Product:** Aesthetic Coach
**Purpose:** exactly how future AI-assisted (Claude) development sessions should be conducted on this repository, so implementation stays consistent, high-quality, and faithful to the documentation set regardless of which session or which engineer is driving. **This is the document to read before opening a Claude session to write code against this repository.**
**Related documents:** [MASTER_IMPLEMENTATION_PLAN.md](../MASTER_IMPLEMENTATION_PLAN.md) (session starting point) · [TASK_BREAKDOWN.md](TASK_BREAKDOWN.md) (task-sized units of work) · [Coding Standards](coding-standards.md) · [Development Workflow](DEVELOPMENT_WORKFLOW.md)

## Table of Contents
- [Planning Complete — Implementation Focus](#planning-complete--implementation-focus)
- [How to Start a Claude Session](#how-to-start-a-claude-session)
- [How Much Context to Provide](#how-much-context-to-provide)
- [Which Documentation Files to Include](#which-documentation-files-to-include)
- [Prompt Templates](#prompt-templates)
- [Coding Standards to Reference](#coding-standards-to-reference)
- [How to Review Generated Code](#how-to-review-generated-code)
- [How to Request Bug Fixes](#how-to-request-bug-fixes)
- [How to Request Refactoring](#how-to-request-refactoring)
- [How to Avoid Context Drift](#how-to-avoid-context-drift)
- [Splitting Large Features into Multiple Prompts](#splitting-large-features-into-multiple-prompts)
- [Backend-Only Sessions](#backend-only-sessions)
- [Frontend-Only Sessions](#frontend-only-sessions)
- [Full-Stack Sessions](#full-stack-sessions)
- [Example Prompts](#example-prompts)
- [Definition of Done Before Moving to the Next Task](#definition-of-done-before-moving-to-the-next-task)

---

## Planning Complete — Implementation Focus

**Planning is complete. Architecture is frozen at Documentation Version v1.0** (see [VERSION_HISTORY.md](../VERSION_HISTORY.md) and [PROJECT_STATUS.md](../PROJECT_STATUS.md)). Every future session governed by this guide should assume the following, without re-litigating it each time:

- **Every session from this point forward is an implementation session**, not a planning session — start from [CLAUDE_SESSION_TEMPLATE.md](../CLAUDE_SESSION_TEMPLATE.md), not a blank page.
- **Documentation is updated only when implementation genuinely requires it** — a spec gap or error the code revealed, corrected in the same PR per [Development Workflow § Documentation Updates](DEVELOPMENT_WORKFLOW.md#documentation-updates). Documentation is not expanded speculatively, and no new planning documents are created unless explicitly requested — the execution framework (this guide included) is itself now part of the frozen baseline, not a work-in-progress.
- **Do not redesign architecture or revisit previously approved technical decisions** — the technology choices, schema, API contracts, and module boundaries documented across [System Architecture](03-system-architecture.md) through the [ADRs](adr/) reflect deliberate, closed decisions. If a session's work seems to call one into question, that's a signal to stop and flag it explicitly (per [How to Avoid Context Drift](#how-to-avoid-context-drift)), not to quietly design around it or propose an alternative unprompted.
- **Small, single-objective sessions are the standard**, not the exception — [CLAUDE_SESSION_TEMPLATE.md](../CLAUDE_SESSION_TEMPLATE.md)'s Stop Condition is not a suggestion; a session that meets its Definition of Done stops there, reports its deliverables, and hands off to the next session via [NEXT_TASK.md](../NEXT_TASK.md).

## How to Start a Claude Session

1. **Open [MASTER_IMPLEMENTATION_PLAN.md](../MASTER_IMPLEMENTATION_PLAN.md) first**, every time, even mid-task. It states the current sprint, current module, and the [Next Recommended Task](../MASTER_IMPLEMENTATION_PLAN.md#next-recommended-task) — don't rely on memory of a previous session for this.
2. **Identify the task** in [TASK_BREAKDOWN.md](TASK_BREAKDOWN.md) — one row, a few hours of work. If what you want to do doesn't map to an existing row, that's a signal to check [DEVELOPMENT_BACKLOG.md](DEVELOPMENT_BACKLOG.md) or [PHASE1_SCOPE.md](PHASE1_SCOPE.md) before proceeding — don't invent scope mid-session.
3. **Gather the "Primary doc(s)"** listed for that task — see [Which Documentation Files to Include](#which-documentation-files-to-include) for how to expand this into a full context set.
4. **State the goal in one sentence before the detailed prompt** — "Implement task 5 of Sprint 3: `WorkoutRepository` + `WorkoutService.logWorkout()` with client_uuid idempotent upsert" — so the session has an unambiguous target from the first message, not something to be inferred from a wall of pasted docs.
5. **One task per session is the default.** A session that starts Sprint 3 task 5 and drifts into task 6, 7, and 8 without explicit checkpoints is exactly the failure mode [How to Avoid Context Drift](#how-to-avoid-context-drift) exists to prevent.

## How Much Context to Provide

Provide **exactly what the task needs, not the whole repository.** This repo is large (108+ documents) by design — that's a strength for humans browsing it, but pasting all of it into one session dilutes attention and increases the chance of the model conflating unrelated details.

| Context sizing | When |
|---|---|
| 1–3 documents | The default. Most `TASK_BREAKDOWN.md` rows list 1–2 "Primary doc(s)" — that's usually sufficient plus the relevant Coding Standards section |
| 4–6 documents | Cross-cutting tasks (e.g., anything touching offline sync, which spans Mobile Architecture, the specific feature spec, and Testing Strategy § 6) |
| A targeted excerpt, not a whole document | Large reference documents (Database Design, API Specification) — point to the specific `§` section, don't paste the entire 300+ line file when you need one table |
| Never: the whole `docs/` folder | If a task seems to need everything, the task is too large — see [Splitting Large Features into Multiple Prompts](#splitting-large-features-into-multiple-prompts) |

## Which Documentation Files to Include

By task type — start here, then add the specific feature/module doc for what you're building:

| Task type | Always include | Add for this specific task |
|---|---|---|
| New Laravel endpoint | [Backend Architecture § 2](07-backend-architecture.md#2-layering--responsibilities), [Coding Standards § Laravel](coding-standards.md#laravel-standards) | The feature spec, the relevant [API Specification § 6](05-api-specification.md#6-endpoint-reference) subsection, the relevant [Database Design § 3](04-database-design.md#3-table-by-table-documentation) tables |
| New Flutter screen | [Mobile Architecture § 2](08-mobile-architecture.md#2-folder-organization), [Coding Standards § Flutter](coding-standards.md#flutter-standards) | The screen spec under [`docs/screens/`](screens/), any [Component Library](components/) entries it uses |
| Database migration | [Database Design § 1 & § 6](04-database-design.md#1-naming-conventions) | The specific `§ 3` table definition |
| AI/prompt work | [AI Coaching Engine](09-ai-coaching-engine.md), [Coding Standards § General Principles](coding-standards.md#general-principles) | The specific [AI Prompt Library](ai/) file, [AI Coaching Engine § 7 Guardrails](09-ai-coaching-engine.md#7-safety-guardrails) |
| Offline/sync work | [Mobile Architecture § 4–6](08-mobile-architecture.md#4-offline-first-strategy) | [Testing Strategy § 6](10-testing-strategy.md#6-offline-sync-testing), the feature spec's Offline Behavior section |
| Tests only | [Testing Strategy](10-testing-strategy.md) | The Acceptance Criteria section of the feature being tested |
| Bug fix | The original feature spec | See [How to Request Bug Fixes](#how-to-request-bug-fixes) |

## Prompt Templates

Use these as starting structures, filled in per task — not copied verbatim without adaptation.

**New backend module/endpoint:**
```
Using [feature spec path] and [API Specification § X.X], implement [specific piece —
e.g., "the WorkoutService.logWorkout() method and POST /workouts endpoint"].

Follow the layering in docs/07-backend-architecture.md § 2 (thin Controller → Form
Request → Service → Repository/Model) and the conventions in docs/coding-standards.md
§ Laravel Standards.

Write Pest Feature tests covering: happy path, validation failure, cross-user isolation,
and [any idempotency/edge case named in the spec's Edge Cases section].
```

**New Flutter screen:**
```
Using docs/screens/[screen].md and docs/06-ui-ux-design-system.md, implement the
[ScreenName] screen. Use the existing components from docs/components/ where listed
in the screen spec's Components section — don't create ad hoc alternatives.

State management: Riverpod per docs/08-mobile-architecture.md § 1 and
docs/coding-standards.md § Riverpod Patterns. The screen reads from [local
cache/Drift / API] per the screen spec's Offline Behavior section.

Write a widget test covering the loading, populated, empty, and error states listed
in the screen spec.
```

**AI/prompt work:**
```
Using docs/ai/[persona].md and docs/09-ai-coaching-engine.md § [relevant section],
implement [specific capability]. Use the exact system prompt and variable list from
the AI prompt doc — don't rewrite the prompt content, wire it into the
AiProviderInterface pipeline per § 6.

Ensure the safety guardrail filter (§ 7) runs on every response, and that token usage
is recorded per § 9 before this is considered done.
```

## Coding Standards to Reference

Always in scope, regardless of task type — link, don't restate:

- [Coding Standards § General Principles](coding-standards.md#general-principles) — SOLID applied pragmatically, DRY with judgment, no premature abstraction
- [Coding Standards § Laravel Standards](coding-standards.md#laravel-standards) or [§ Flutter Standards](coding-standards.md#flutter-standards) depending on task
- [Coding Standards § Documentation & Commenting](coding-standards.md#documentation--commenting) — comments explain *why*, not *what*; no docblock restating the method name
- [Git Workflow § Conventional Commits](git-workflow.md#conventional-commits) — the PR title this work will eventually become

## How to Review Generated Code

Review AI-generated code exactly as you would human-written code — **against the spec it claims to implement, not against "does this look plausible."** Specifically:

1. **Re-open the feature spec's Acceptance Criteria section** and check each one against the actual generated behavior — not against the code's structure looking reasonable.
2. **Check the Edge Cases section** was actually handled, not just the happy path the prompt implicitly described.
3. **Run the tests** — don't trust a description of tests passing; a session can be wrong about test results the same way it can be wrong about anything else.
4. **Check for scope creep**: did the session add anything not in the task (an extra field, an extra endpoint, a "nice to have" abstraction)? Per [Coding Standards § General Principles](coding-standards.md#general-principles), unrequested scope is a defect, not a bonus — flag it for removal.
5. **Check cross-references**: if the code should have updated a doc per [Development Workflow § Documentation Updates](DEVELOPMENT_WORKFLOW.md#documentation-updates), confirm that happened.
6. Treat this the same as any other code review under [Development Workflow § Code Reviews](DEVELOPMENT_WORKFLOW.md#code-reviews) — the fact that Claude wrote it doesn't change the review bar.

## How to Request Bug Fixes

Follow [Development Workflow § Bug Workflow](DEVELOPMENT_WORKFLOW.md#bug-workflow). When prompting Claude specifically:

```
There's a bug in [file/module]: [precise description of observed vs. expected behavior,
with a reproduction step if possible].

First write a failing test that reproduces this in isolation, confirm it fails for the
stated reason, then fix it. Reference [original feature spec] to confirm the fix aligns
with the actual specified behavior — if the spec itself is ambiguous or wrong here, say
so explicitly rather than guessing.
```

**Never** prompt with just "fix this bug" and a stack trace with no context — that invites a plausible-looking patch that doesn't address the root cause. Always point back to the spec that defines correct behavior.

## How to Request Refactoring

Refactoring prompts need an explicit **non-goal** statement, since "clean this up" is otherwise unbounded:

```
Refactor [file/module] to [specific goal — e.g., "extract the duplicated PR-detection
logic in WorkoutService into PrDetectionService per docs/07-backend-architecture.md § 1"].

Do not change external behavior — all existing tests must continue to pass unmodified.
Do not expand scope beyond this specific extraction (no renaming unrelated things, no
"while I'm here" changes).
```

This mirrors the project-wide instruction against premature abstraction in [Coding Standards § General Principles](coding-standards.md#general-principles) — a refactor should have one stated purpose, not become a general tidy-up pass.

## How to Avoid Context Drift

Context drift — a session's understanding gradually diverging from the actual spec as a conversation runs long — is the single biggest quality risk in AI-assisted development on a repository this size. Mitigations:

1. **One task per session, by default** (see [How to Start a Claude Session](#how-to-start-a-claude-session)). A session that has been going for hours across multiple unrelated tasks is more likely to have quietly forgotten an early constraint.
2. **Re-state the spec reference, not just "continue"**, when resuming work — "continuing task 6, per docs/features/workout-tracking.md's Business Rules on PR detection" beats "keep going," because it re-anchors the session to the source of truth rather than to its own prior (possibly drifted) summary of it.
3. **If a session's output contradicts the spec, stop and re-share the spec excerpt** rather than trying to verbally correct the model's understanding — a fresh, precise re-read of the actual document is more reliable than a conversational correction layered on top of an already-wrong mental model.
4. **Long features get split** (see next section) specifically so no single session's context window has to hold the entire feature's worth of decisions at once.
5. **Watch for the model inventing scope** not in the task — this is a drift symptom, not a bonus; redirect immediately per [How to Review Generated Code](#how-to-review-generated-code) point 4.

## Splitting Large Features into Multiple Prompts

Any [TASK_BREAKDOWN.md](TASK_BREAKDOWN.md) row is already sized to "a few hours" — but a handful of tasks (notably Sprint 3's offline sync foundation and Sprint 5's AI Recommendations work) are flagged as the highest-risk items in Phase 1 and deserve deliberate splitting even within their nominal task boundaries:

1. **Split by layer, not by half-finished feature.** For a full endpoint-to-screen feature: (a) migration + model, (b) service/business logic, (c) API endpoint + Form Request + Resource, (d) backend tests, (e) Flutter data layer, (f) Flutter UI, (g) Flutter tests — each as its own prompt/session, each independently reviewable and mergeable if the project allows incremental PRs for a larger feature.
2. **Split Sprint 5 AI work by concern, explicitly**: provider integration → context assembly → guardrails → rate limiting → the specific persona/capability. Building all of these in one prompt risks the guardrail and rate-limiting logic getting less attention than the "interesting" generation logic — split them out to force explicit review of each.
3. **Split Sprint 3 offline sync by: local schema → sync queue → sync engine happy path → sync engine failure/retry paths → UI integration.** The failure/retry path is where most of the real risk lives per [ADR-0007 § Consequences](adr/0007-offline-first-architecture.md#consequences) — don't let it become an afterthought appended to the happy-path prompt.
4. **A task that keeps needing "just one more thing" mid-session is a signal to stop and re-scope**, not to keep extending the same prompt — return to [TASK_BREAKDOWN.md](TASK_BREAKDOWN.md) and add/split rows if the granularity was wrong, rather than letting one session balloon.

## Backend-Only Sessions

Scope to `app/Modules/*` and `database/migrations`. Context: [Backend Architecture](07-backend-architecture.md), [Coding Standards § Laravel](coding-standards.md#laravel-standards), the relevant feature spec and API Specification section. **Do not** ask a backend-only session to also design the Flutter UI "for context" — if the API contract is already documented (it is, for every Phase 1 endpoint), the backend session doesn't need the UI to build correctly against the contract. Output should be reviewable purely against [API Contract Examples](api-examples/) — if the actual response shape doesn't match the documented example, that's a defect regardless of whether any UI exists yet.

## Frontend-Only Sessions

Scope to `lib/features/*`. Context: [Mobile Architecture](08-mobile-architecture.md), [Coding Standards § Flutter](coding-standards.md#flutter-standards), the relevant screen spec, [Component Library](components/) entries. Frontend sessions should build against the **documented** API contract ([API Specification](05-api-specification.md), [API Contract Examples](api-examples/)) using mocked responses if the backend isn't built yet — this is explicitly enabled by [IMPLEMENTATION_ORDER.md § Parallel Development Opportunities](IMPLEMENTATION_ORDER.md#parallel-development-opportunities). Don't block frontend work on backend completion when the contract is already frozen.

## Full-Stack Sessions

Reserved for genuinely small, tightly-coupled features where splitting backend/frontend would be artificial (e.g., a single new settings toggle end-to-end). Even then, structure the prompt to build backend-then-frontend sequentially within the session, not interleaved — verify the API works (via a quick manual/test call) before writing the Flutter code against it, so any bugs are attributable to one layer at a time.

## Example Prompts

**Effective (specific, spec-anchored, bounded):**
> "Using docs/features/habits.md and docs/04-database-design.md § 3.5, implement the `habits` and `habit_logs` migrations, the `HabitService` with `checkIn()` and streak-computation methods, and the three endpoints in docs/05-api-specification.md § 6.7. Streak logic must implement BR-7 exactly (reset to 0 on a missed scheduled day, no automatic grace). Write Pest tests for the streak-reset scheduled job specifically, including the `weekly_n` frequency-type edge case described in the feature spec's Business Rules section."

**Ineffective (vague, unbounded, no spec anchor):**
> "Add habit tracking to the app."

The difference isn't length — it's that the effective version names the exact docs, the exact business rule ID, and the exact edge case to test, leaving no room for the session to guess at scope or behavior.

## Definition of Done Before Moving to the Next Task

A task from [TASK_BREAKDOWN.md](TASK_BREAKDOWN.md) is done — and it's safe to start the next one — only when:

- [ ] The implementation matches its spec's Acceptance Criteria, verified by re-reading them against the actual behavior (not assumed from the code looking right)
- [ ] Tests exist and pass, per [Development Workflow § Testing Requirements](DEVELOPMENT_WORKFLOW.md#testing-requirements)
- [ ] No unrequested scope was added (checked per [How to Review Generated Code](#how-to-review-generated-code))
- [ ] Any frozen documentation gap the task revealed was corrected in the same PR, per [Development Workflow § Documentation Updates](DEVELOPMENT_WORKFLOW.md#documentation-updates)
- [ ] The PR is reviewed and merged per [Development Workflow § Feature Workflow](DEVELOPMENT_WORKFLOW.md#feature-workflow)
- [ ] [MASTER_IMPLEMENTATION_PLAN.md](../MASTER_IMPLEMENTATION_PLAN.md)'s Sprint Tracker / Feature Completion Checklist / Next Recommended Task are updated

Only then does the next session start the next task fresh, per [How to Start a Claude Session](#how-to-start-a-claude-session) — never mid-task, never on an assumption that the prior task "was probably fine."
