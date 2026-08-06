# Architecture Decision Records

**Related documents:** [System Architecture § 9](../03-system-architecture.md#9-architectural-decision-records-summary) (the original condensed ADR summary table — each file below is the full expanded record behind one of those entries)

## Index

| ADR | Decision | Status |
|---|---|---|
| [0001](0001-flutter-for-mobile.md) | Flutter for mobile | Accepted |
| [0002](0002-laravel-for-backend.md) | Laravel for backend | Accepted |
| [0003](0003-mysql8-for-database.md) | MySQL 8 for database | Accepted |
| [0004](0004-riverpod-for-state-management.md) | Riverpod for mobile state management | Accepted |
| [0005](0005-jwt-refresh-token-auth.md) | Custom JWT + rotating refresh token authentication | Accepted |
| [0006](0006-claude-ai-primary-provider.md) | Claude API as primary AI provider | Accepted |
| [0007](0007-offline-first-architecture.md) | Offline-first mobile architecture | Accepted |
| [0008](0008-drift-for-local-storage.md) | Drift for local storage | Accepted |
| [0009](0009-modular-monolith.md) | Modular monolith over microservices | Accepted |
| [0010](0010-repository-pattern.md) | Repository pattern (selective use) | Accepted |

## Format

Each ADR follows: **Context**, **Problem**, **Decision**, **Alternatives Considered**, **Pros**, **Cons**, **Consequences**, **Future Review Criteria** — the last section is deliberately not "never revisit," since every decision here is a fit for known constraints at a point in time, not a permanent truth.

## How to Add a New ADR

Number sequentially (`00NN-short-title.md`), add a row to the index above, and cross-link it from whichever primary document (System Architecture, Mobile Architecture, Backend Architecture, etc.) the decision most directly affects — ADRs record *why*, the primary docs record *what*, and both should point at each other.
