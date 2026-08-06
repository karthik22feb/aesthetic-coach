# ADR-0007: Offline-First Mobile Architecture

**Status:** Accepted
**Related documents:** [Mobile Architecture § 4](../08-mobile-architecture.md#4-offline-first-strategy) (original condensed rationale) · [SRS NFR-5](../02-srs.md#5-non-functional-requirements) · [Workout Tracking feature](../features/workout-tracking.md)

## Context
Workout logging happens predominantly in gyms, which frequently have poor or no cellular/WiFi connectivity, and often in basements or dense buildings that degrade signal further. The product's core value (fast, frictionless logging, [PRD Objective O2](../01-prd.md#2-objectives)) would be undermined if logging a set required a live network connection.

## Problem
How should the mobile app be architected so that core tracking functionality (workouts, nutrition, habits) works reliably regardless of connectivity, while still supporting server-side features (AI coaching, cross-device sync) that inherently require a network?

## Decision
Make the local on-device database the source of truth for the UI; the network is a sync target, not a read path. Every screen renders from local storage ([ADR-0008](0008-drift-for-local-storage.md)) via reactive providers; writes commit locally first and queue for background sync ([Mobile Architecture § 4](../08-mobile-architecture.md#4-offline-first-strategy)).

## Alternatives Considered
| Option | Why not chosen |
|---|---|
| Online-first with local caching only for read performance | Doesn't meet NFR-5 (full offline logging) — a cache-only approach still fails writes when offline, which is the actual failure mode this product needs to handle (gym connectivity) |
| Optimistic UI without true local persistence (in-memory queue only) | Loses queued mutations if the app is killed while offline — unacceptable given workout sessions can run 45–90 minutes, well within the window of an OS background-kill on a memory-constrained device |
| Full CRDT/operational-transform-based sync | Substantially more engineering complexity than this product's actual conflict profile justifies — most tracked records are single-device-authored and append-only (see [Mobile Architecture § Synchronization](../08-mobile-architecture.md#6-synchronization)), so simple last-write-wins with idempotent upserts is sufficient |

## Pros
- Directly satisfies NFR-5 and the "logging must just work regardless of connectivity" user story family across [Workout Tracking](../features/workout-tracking.md), [Nutrition](../features/nutrition.md), and [Habits](../features/habits.md).
- UI responsiveness is decoupled from network latency entirely for core logging flows — the app feels instant because it *is* local.
- `client_uuid`-based idempotent upserts ([Database Design § 1](../04-database-design.md#1-naming-conventions)) make retried/replayed syncs safe by construction.

## Cons
- Genuine architectural complexity: every core-domain feature needs a local schema, a sync queue entry, and conflict-handling logic, not just a simple API call.
- AI features cannot be offline by nature, creating an intentional UX inconsistency between "always works" (tracking) and "needs connectivity" (coaching) that must be communicated clearly rather than papered over ([Mobile Architecture § 4](../08-mobile-architecture.md#4-offline-first-strategy), [AI Coach feature § Offline Behavior](../features/ai-coach.md#offline-behavior)).

## Consequences
[Development Roadmap § Phase 1 · Sprint 3](../16-development-roadmap.md#phase-1--sprint-3--workout-engine--exercise-library) explicitly calls this out as one of the two highest-technical-risk sprints in the entire Phase 1 build, warranting deliberate, unhurried implementation and testing rather than being treated as routine CRUD work.

## Future Review Criteria
Revisit the conflict-resolution strategy specifically (currently last-write-wins) if real usage data shows meaningful multi-device concurrent-edit conflicts on the same record — not expected given the current single-device-authored-per-record usage pattern, but worth monitoring once telemetry exists.
