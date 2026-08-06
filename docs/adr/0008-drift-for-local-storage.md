# ADR-0008: Drift for Local Storage

**Status:** Accepted
**Related documents:** [Mobile Architecture § 5](../08-mobile-architecture.md#5-local-storage) (original condensed rationale) · [ADR-0007](0007-offline-first-architecture.md) · [ADR-0004](0004-riverpod-for-state-management.md)

## Context
The offline-first architecture ([ADR-0007](0007-offline-first-architecture.md)) requires a local on-device datastore capable of relational queries (workouts → exercises → sets joins), schema migrations as the app evolves, and reactive streams that Riverpod providers can subscribe to.

## Problem
Which local storage layer best supports relational offline data with type-safe queries and reactive read streams, consistent with the project's broader preference for compile-time safety?

## Decision
Use Drift (a typed SQL layer over SQLite) for local storage, per [Mobile Architecture § 5](../08-mobile-architecture.md#5-local-storage).

## Alternatives Considered
| Option | Why not chosen |
|---|---|
| `sqflite` directly | Raw SQL strings with no compile-time query safety — every query is a stringly-typed risk, working against the same compile-time-safety preference that drove [ADR-0004](0004-riverpod-for-state-management.md) |
| Hive / Isar (NoSQL/object-box-style local stores) | Fast for simple key-value or flat-object storage, but the actual local data shape is genuinely relational (workouts have exercises have sets) — using a NoSQL local store would mean either denormalizing awkwardly or hand-rolling join logic in Dart, working against the data's natural shape |
| Realm | Viable relational local database, but Drift's SQL-first, migrations-as-code model maps more directly onto the same mental model engineers already use for the MySQL backend schema ([Database Design](../04-database-design.md)), reducing cognitive overhead switching between server and client schema work |

## Pros
- Generated, type-safe query API — compile-time errors instead of runtime SQL string mistakes.
- Real relational joins for the workouts→exercises→sets hierarchy, matching the data's actual shape.
- Migrations-as-code, mirroring the discipline already established for the backend in [Database Design § Migration Strategy](../04-database-design.md#6-migration-strategy).
- Reactive query streams integrate directly with Riverpod `StreamProvider`s, so UI updates automatically when local data changes (from either a local write or a completed sync) — the mechanism underlying [Mobile Architecture § 4](../08-mobile-architecture.md#4-offline-first-strategy)'s "UI renders from local cache" principle.

## Cons
- Requires maintaining a second schema (local Drift schema, distinct from but related to the MySQL schema) — explicitly **not** a 1:1 mirror ([Mobile Architecture § 5](../08-mobile-architecture.md#5-local-storage) notes reference tables like `exercises`/`foods` are a denormalized local cache, not a full relational copy), which adds a small amount of schema-design overhead per feature.
- Slightly more boilerplate than a schemaless local store for very simple, non-relational data (mitigated by only using Drift for the domains that actually need offline relational support, not force-fitting every local concern through it).

## Consequences
Every offline-critical feature ([Workout Tracking](../features/workout-tracking.md), [Nutrition](../features/nutrition.md), [Habits](../features/habits.md)) defines a Drift table set in its `data/` layer ([Mobile Architecture § 2](../08-mobile-architecture.md#2-folder-organization)); the Sync Queue itself is also Drift-backed (not in-memory) so queued mutations survive app kills.

## Future Review Criteria
Revisit only if Drift's maintenance/ecosystem health degrades significantly, or if a local data domain emerges that is genuinely better served by a non-relational store (at which point that specific domain could use a different local mechanism alongside Drift, rather than replacing it wholesale).
