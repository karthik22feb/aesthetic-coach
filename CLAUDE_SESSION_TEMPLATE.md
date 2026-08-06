# Claude Session Template

**The standard template for every future implementation session.** Copy this entire document into the start of a new Claude session (or a session-tracking file/PR description), fill in every bracketed placeholder, and follow it through to its Stop Condition. This is the mechanism that keeps implementation consistent, prevents context drift, and keeps every session's output small, reviewable, and predictable — see [AI_DEVELOPMENT_GUIDE.md](docs/AI_DEVELOPMENT_GUIDE.md) for the fuller reasoning behind each rule below; this document is the compact, fill-in form of that guide's practices.

**Do not start implementation work without a filled-out copy of this template.** One template = one session = one task.

---

## 1. Session Information

| Field | Value |
|---|---|
| **Date** | `[YYYY-MM-DD]` |
| **Sprint** | `[e.g. Phase 1 · Sprint 1]` — see [MASTER_IMPLEMENTATION_PLAN.md § Sprint Tracker](MASTER_IMPLEMENTATION_PLAN.md#sprint-tracker) |
| **Module** | `[e.g. Infrastructure]` — see [IMPLEMENTATION_ORDER.md](docs/IMPLEMENTATION_ORDER.md) |
| **Task ID** | `[e.g. Sprint 1, Task 3]` — see [TASK_BREAKDOWN.md](docs/TASK_BREAKDOWN.md); must reference a row in that document or be added there first, not invented ad hoc |
| **Current Branch** | `[e.g. feature/infra-docker-compose]` — per [GIT_INITIALIZATION.md § Branch Naming Convention](GIT_INITIALIZATION.md#branch-naming-convention) |
| **Estimated Duration** | `[a few hours — if this session looks larger, split it per AI_DEVELOPMENT_GUIDE.md § Splitting Large Features]` |

## 2. Objective

`[One sentence. One objective. If you find yourself writing "and" to join two deliverables, split this into two sessions/templates instead.]`

**Example (do not copy literally — replace with the actual objective):** "Implement the `WorkoutService.logWorkout()` method and its `POST /workouts` endpoint with `client_uuid` idempotent upsert."

## 3. Relevant Documentation

List only the documents this specific task needs — see [AI_DEVELOPMENT_GUIDE.md § Which Documentation Files to Include](docs/AI_DEVELOPMENT_GUIDE.md#which-documentation-files-to-include) for guidance on sizing this list. Delete rows that don't apply; do not attach documents "just in case."

| Type | Document | Applies? |
|---|---|---|
| Feature Specification | `[docs/features/____.md]` | `[yes/no]` |
| API Specification | `[docs/05-api-specification.md § ____]` | `[yes/no]` |
| Database Design | `[docs/04-database-design.md § ____]` | `[yes/no]` |
| Coding Standards | `[docs/coding-standards.md § ____]` | `[yes/no]` |
| UI Specification | `[docs/screens/____.md or docs/components/____.md]` | `[yes/no]` |
| AI Prompt Specification | `[docs/ai/____.md]` | `[yes/no]` |
| Other | `[____]` | `[yes/no]` |

## 4. Files Allowed to Modify

List the **exact** files this session is expected to touch. Anything not listed here is out of scope for this session — if the work reveals a need to touch something else, stop and either update this list deliberately (and note why) or split the additional work into a new session.

```
[path/to/file/one]
[path/to/file/two]
[path/to/test/file]
```

## 5. Files That Must Not Change

The frozen v1.0 baseline and anything outside this session's explicit scope. Unless this session was explicitly instructed otherwise:

- Architecture documents (`docs/03-system-architecture.md`, `docs/04-database-design.md`, `docs/05-api-specification.md`, `docs/07-backend-architecture.md`, `docs/08-mobile-architecture.md`, `docs/09-ai-coaching-engine.md`)
- `docs/01-prd.md`, `docs/02-srs.md`
- `docs/16-development-roadmap.md`, [PHASE1_SCOPE.md](docs/PHASE1_SCOPE.md), [PHASE2_SCOPE.md](docs/PHASE2_SCOPE.md)
- Any [ADR](docs/adr/)
- Completed features (anything already checked off in [MASTER_IMPLEMENTATION_PLAN.md § Feature Completion Checklist](MASTER_IMPLEMENTATION_PLAN.md#feature-completion-checklist))
- `[any other file specifically out of bounds for this session]`

Per [AI_DEVELOPMENT_GUIDE.md § Planning Complete — Implementation Focus](docs/AI_DEVELOPMENT_GUIDE.md#planning-complete--implementation-focus): do not redesign architecture or revisit previously approved technical decisions in this session unless explicitly instructed.

## 6. Coding Standards

Reference, don't repeat — full standards live in [Coding Standards](docs/coding-standards.md). Reminders for this session:

- Laravel work follows [Coding Standards § Laravel Standards](docs/coding-standards.md#laravel-standards) and the layering in [Backend Architecture § 2](docs/07-backend-architecture.md#2-layering--responsibilities)
- Flutter work follows [Coding Standards § Flutter Standards](docs/coding-standards.md#flutter-standards) and [Mobile Architecture § 2](docs/08-mobile-architecture.md#2-folder-organization)
- Keep code modular — one responsibility per class/widget, matching the existing module boundaries
- Avoid duplication — check whether similar logic already exists before writing new logic
- Write readable code — names that make comments unnecessary, per [Coding Standards § Documentation & Commenting](docs/coding-standards.md#documentation--commenting)
- Maintain consistency with the surrounding codebase's existing patterns, not a new pattern introduced for this session alone

## 7. Testing Requirements

Check off what applies to this task — leave unchecked items that genuinely don't apply, don't skip ones that do:

- [ ] Unit tests (Services, Notifiers, formulas)
- [ ] Integration tests (offline sync, multi-step flows)
- [ ] Widget tests (new/changed Flutter UI)
- [ ] API tests (happy path, validation, auth, cross-user isolation, idempotency)
- [ ] AI guardrail tests (if this task touches any AI persona)

Full detail: [Testing Strategy](docs/10-testing-strategy.md), [Development Workflow § Testing Requirements](docs/DEVELOPMENT_WORKFLOW.md#testing-requirements).

## 8. Definition of Done

This session is not complete until **all** of the following are true:

- [ ] Code completed, matching the [Objective](#2-objective) exactly — nothing more, nothing less
- [ ] Tests passing (per [§ 7](#7-testing-requirements))
- [ ] Documentation updated **only if implementation genuinely required it** (e.g., a spec gap the code revealed) — not speculative doc expansion
- [ ] No unrelated changes outside [§ 4 Files Allowed to Modify](#4-files-allowed-to-modify)
- [ ] No `TODO` placeholders left in code unless explicitly approved and recorded in [§ 9 Known Limitations](#9-deliverables)

## 9. Deliverables

At the end of the session, provide:

1. **Summary of work completed** — what was built, in plain language
2. **Files modified** — exact list, matching [§ 4](#4-files-allowed-to-modify)
3. **Database migrations** (if any) — migration name(s) and what they change
4. **APIs added or changed** — endpoint(s), method(s), and how they map to [API Specification](docs/05-api-specification.md)
5. **Testing performed** — which tests were written/run and their result
6. **Known limitations** — anything deferred, approved `TODO`s, or edge cases not yet handled
7. **Suggested commit message** — Conventional Commits format, per [Git Workflow § Conventional Commits](docs/git-workflow.md#conventional-commits)
8. **Recommendation for the next task** — what [NEXT_TASK.md](NEXT_TASK.md) should point to next, per [TASK_BREAKDOWN.md](docs/TASK_BREAKDOWN.md)

## 10. Stop Condition

**Stop immediately once the Definition of Done (§ 8) is met.** Do not continue on to the next task, do not implement additional features "while already in the area," and do not expand scope beyond [§ 2 Objective](#2-objective) — even if the next task seems obvious or small. Report the [§ 9 Deliverables](#9-deliverables), update [NEXT_TASK.md](NEXT_TASK.md), [DEVELOPMENT_LOG.md](DEVELOPMENT_LOG.md), and [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md) per [AI_DEVELOPMENT_GUIDE.md § Definition of Done Before Moving to the Next Task](docs/AI_DEVELOPMENT_GUIDE.md#definition-of-done-before-moving-to-the-next-task), and end the session there. The next session starts fresh with a new copy of this template.
