# ADR-0004: Riverpod for Mobile State Management

**Status:** Accepted
**Related documents:** [Mobile Architecture § 1](../08-mobile-architecture.md#1-state-management) (original condensed rationale — this ADR is the full record) · [ADR-0001](0001-flutter-for-mobile.md)

## Context
The mobile app is CRUD-heavy (workout/nutrition/habit logging) with significant async state (loading/data/error per screen), needs to compose cleanly with an offline-first sync architecture ([Mobile Architecture § 4](../08-mobile-architecture.md#4-offline-first-strategy)), and must be testable without heavy widget-pumping overhead given the project's emphasis on real, meaningful tests over superficial ones.

## Problem
Which state-management approach best fits a large number of similar-shaped screens (list/detail/form patterns across Workouts, Nutrition, Habits, Goals) while remaining testable and avoiding `BuildContext`-coupled global state?

## Decision
Use Riverpod (`flutter_riverpod` + `riverpod_generator`, `AsyncNotifier`/`Notifier`) as both the state-management and dependency-injection mechanism ([Mobile Architecture § 8](../08-mobile-architecture.md#8-dependency-injection)).

## Alternatives Considered
| Option | Why not chosen |
|---|---|
| Provider (plain) | No compile-time safety on provider types; `BuildContext`-scoped lookups are easy to misuse; effectively superseded by Riverpod from the same author lineage |
| BLoC | Excellent discipline for complex event-sourcing-style flows, but disproportionate boilerplate (events/states/mappers) for the CRUD-dominant screens that make up most of this app |
| GetX | Convenient but weak compile-time safety and service-locator-style globals that encourage tight coupling; smaller, less consistent long-term maintenance track record for a production app at this scope |
| MobX | Viable, but its code-gen/observable model doesn't map as cleanly onto the offline-first read-from-local-cache pattern this app relies on as Riverpod's stream-provider composition does |

## Pros
- Compile-time-safe: no `BuildContext` needed to read a provider, catching a whole class of runtime errors at build time.
- First-class async support: `AsyncValue` maps directly onto the loading/data/error states nearly every screen needs.
- Testable in isolation via `ProviderContainer` overrides, without widget pumping — directly supports the unit-testing approach in [Testing Strategy § Unit Testing](../10-testing-strategy.md#3-unit-testing).
- Doubles as the DI mechanism ([Mobile Architecture § 8](../08-mobile-architecture.md#8-dependency-injection)), avoiding a second competing DI system (`get_it`) layered on top.
- Composes cleanly with the offline-first architecture: `Notifier` classes own both local-cache reads and remote-sync triggers.

## Cons
- Code-gen (`@riverpod`) adds a build-runner step to the development loop.
- Steeper initial learning curve than simpler options (Provider, GetX) for engineers new to the ecosystem.

## Consequences
Every feature's `application/` layer ([Mobile Architecture § 2](../08-mobile-architecture.md#2-folder-organization)) is built around Riverpod `Notifier`/`AsyncNotifier` classes; [Coding Standards § Riverpod Patterns](../coding-standards.md#riverpod-patterns) codifies the specific conventions (naming, `family` usage, read/watch discipline) engineers follow day-to-day.

## Future Review Criteria
Revisit only if the Flutter ecosystem shifts significantly (e.g., a new state-management approach becomes clearly dominant with strong migration tooling) — not expected to change based on currently foreseeable requirements.
