# ADR-0010: Repository Pattern (Selective Use)

**Status:** Accepted
**Related documents:** [Backend Architecture § 2](../07-backend-architecture.md#2-layering--responsibilities) (original condensed rationale) · [Coding Standards § Repositories](../coding-standards.md#repositories)

## Context
Laravel's Eloquent ORM already provides an ActiveRecord-style query interface directly on models, which is often sufficient on its own. The PRD explicitly requests "Repository Pattern where appropriate" rather than universally, and the project's stated engineering principle throughout this doc set is to avoid introducing abstraction that doesn't earn its keep (no premature abstraction, three similar lines beats a forced shared helper).

## Problem
Should every module use a Repository layer between Services and Eloquent models, or only where it provides real value — and if selective, what's the actual criterion?

## Decision
Use Repositories only in modules with non-trivial query complexity or meaningful reuse potential — currently `Workouts`, `Nutrition`, and `Coaching` ([Backend Architecture § 2](../07-backend-architecture.md#2-layering--responsibilities)). Simple CRUD modules (`Habits`, `Goals`) query Eloquent directly from the Service layer, with no Repository indirection.

## Alternatives Considered
| Option | Why not chosen |
|---|---|
| Repository on every module, universally | Directly contradicts the project's explicit anti-over-engineering principle — a `HabitRepository` that only ever wraps `Habit::where('user_id', $id)->get()` adds an indirection layer with no testability or reuse benefit over calling Eloquent directly from the Service, since the Service is already the unit being tested and mocked at that boundary |
| No Repository layer anywhere, Eloquent called directly from every Service | Loses real value in the domains where query logic is genuinely complex/reused — e.g., the Workouts module's exercise-history queries and PR-detection lookups are used from multiple call sites (the workout-save path, the Exercise Detail screen's history view, the AI Personal Trainer's context assembly) and benefit from a single, tested, named query surface rather than duplicated `where()` chains |
| A generic `Repository<T>` base class enforced everywhere | Generic base-repository patterns tend to either leak Eloquent-specific concerns through an abstraction meant to hide them, or become a dumping ground of unrelated query methods — a named, domain-specific Repository per module (not a generic base class) keeps each one's API meaningful and grep-able |

## Pros
- Applied only where it earns its cost: complex/reused queries get a tested, named home; simple CRUD stays simple.
- Keeps the codebase's abstraction level honest — a new engineer reading `HabitService` sees Eloquent calls directly, not an unnecessary indirection to trace through.
- Where used (Workouts, Nutrition, Coaching), Repositories provide a single point to enforce the `user_id`-scoping security discipline described in [System Architecture § Security Architecture](../03-system-architecture.md#8-security-architecture), reducing the chance of an unscoped query slipping through in a complex domain.

## Cons
- Inconsistency across modules (some have a Repository layer, some don't) requires new engineers to learn the *criterion* rather than a single blanket rule — mitigated by this ADR and [Coding Standards § Repositories](../coding-standards.md#repositories) stating the criterion explicitly.
- If a currently-simple module (e.g., `Habits`) grows more complex query needs later, introducing a Repository at that point is a small refactor, not a day-one cost — an accepted tradeoff given the alternative (building it everywhere up front) is the more expensive default.

## Consequences
[Backend Architecture § 1](../07-backend-architecture.md#1-folder-structure)'s folder structure only shows a `Repositories/` subfolder for the three modules using this pattern; other modules' folder listings omit it, and that omission is intentional, not an inconsistency to "fix."

## Future Review Criteria
Add a Repository to a currently-simple module the moment its query needs grow non-trivial (multiple call sites reusing the same complex query, or query logic that needs independent unit testing beyond what testing the Service already covers) — evaluated per-module as it happens, not as a wholesale policy change.
