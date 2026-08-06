# ADR-0001: Flutter for Mobile

**Status:** Accepted
**Related documents:** [Mobile Architecture](../08-mobile-architecture.md) · [PRD § Technology Stack](../01-prd.md)

## Context
Aesthetic Coach targets both Android and iOS from day one ([PRD](../01-prd.md)), with a single, relatively small engineering team expected to own the mobile client. The stakeholder specified Flutter as a hard requirement at the outset.

## Problem
How should the mobile client be built to hit both platforms without doubling engineering effort, while supporting a rich, custom, animation-involved UI (Score Ring, streaming chat, offline-first sync) rather than a generic form-based app?

## Decision
Build the mobile client in Flutter (latest stable), targeting Android and iOS from one codebase.

## Alternatives Considered
| Option | Why not chosen |
|---|---|
| Native (Swift + Kotlin, two codebases) | Doubles engineering effort for a small team; two UIs to keep visually/behaviorally in sync with the design system in [UI/UX Design System](../06-ui-ux-design-system.md) |
| React Native | Viable alternative with a large ecosystem, but weaker fit for the highly custom animated components (Score Ring, streaming chat rendering) without dropping to native modules more often than Flutter's `CustomPainter` model requires |
| Kotlin Multiplatform Mobile | Less mature UI-sharing story at the time of this decision (still often paired with fully native UI layers per platform); doesn't meet the single-UI-codebase goal as directly as Flutter |

## Pros
- Single codebase for UI + business logic across both platforms.
- Strong custom-rendering story (`CustomPainter`) for the Score Ring and other bespoke components.
- Hot reload speeds iteration during development.
- Mature offline-first tooling ecosystem (Drift, Riverpod) that this doc set builds on directly ([ADR-0004](0004-riverpod-for-state-management.md), [ADR-0008](0008-drift-for-local-storage.md)).

## Cons
- Larger app binary size than fully native.
- Occasional lag adopting brand-new platform-specific OS features on day one of their release.
- Team needs Dart expertise, a smaller talent pool than JS/TS or native Swift/Kotlin.

## Consequences
The entire [Mobile Architecture](../08-mobile-architecture.md) document — folder structure, state management, offline sync, navigation — is built on Flutter idioms. A future decision to add a web client ([PRD § 5.6](../01-prd.md#56-platform), Future) could reuse Flutter Web, though that tradeoff would need its own review given Flutter Web's different maturity profile for content-heavy vs. app-like UIs.

## Future Review Criteria
Revisit only if: Flutter's cross-platform parity degrades significantly relative to alternatives, the team's skill composition shifts heavily toward native/web specialists, or a hard platform requirement emerges that Flutter cannot meet (e.g., deep OS-level integration Flutter's plugin ecosystem doesn't yet cover well).
