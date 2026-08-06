# Feature: Challenges

**Related documents:** [PRD § 5.4](../01-prd.md#54-engagement) · [Achievements](achievements.md) · [PHASE2_SCOPE.md](../PHASE2_SCOPE.md) · [Development Roadmap § Phase 2 · Sprint 5](../16-development-roadmap.md#phase-2--sprint-5--wearable-integrations-community-challenges--leaderboards)

## Release Phase

| Field | Value |
|---|---|
| **Status** | Phase 2 |
| **Priority** | Medium |
| **Estimated Sprint** | [Phase 2 · Sprint 5](../16-development-roadmap.md#phase-2--sprint-5--wearable-integrations-community-challenges--leaderboards) — first deliverable is a dedicated design pass, not code |
| **Dependencies** | [Achievements](achievements.md) (Phase 1 data), an established post-launch user base |

## Table of Contents
- [Overview](#overview)
- [Purpose](#purpose)
- [User Stories](#user-stories-directional-not-committed)
- [Functional Requirements](#functional-requirements)
- [Non-Functional Requirements](#non-functional-requirements)
- [UI Flow](#ui-flow)
- [Screen List](#screen-list)
- [Business Rules](#business-rules)
- [Validation Rules](#validation-rules)
- [APIs](#apis)
- [Database Tables](#database-tables)
- [Edge Cases](#edge-cases)
- [Error Handling](#error-handling)
- [Offline Behavior](#offline-behavior)
- [Acceptance Criteria](#acceptance-criteria)
- [Future Improvements](#future-improvements)

## Overview
Competitive/social engagement — leaderboards, group challenges, and friend-following — explicitly named as Future in [PRD § 5.4](../01-prd.md#54-engagement) and [§ 9](../01-prd.md#9-mvp-vs-future-phases) (Phase 3, alongside a social feed). This document is a **scoping placeholder**, not a build-ready spec, per [PRD § Non-goals](../01-prd.md#32-non-goals-explicitly-out-of-scope-for-this-product) — "becoming a social network first" is explicitly rejected for MVP, and challenges is the feature most directly implicated by that non-goal.

## Purpose
Sketch enough of the shape of this feature that Phase 2 · Sprint 5 planning ([Development Roadmap](../16-development-roadmap.md#phase-2--sprint-5--wearable-integrations-community-challenges--leaderboards)) has a starting point, without committing implementation detail this far ahead of real usage data.

## User Stories (directional, not committed)
- As a user, I want to join a time-boxed challenge (e.g., "30 workouts in 30 days") with friends or the broader community.
- As a user, I want an opt-in leaderboard, never a default-visible one (privacy-first).
- As a user, I want challenge participation to feel additive to my personal tracking, not a replacement for it.

## Functional Requirements
Not yet specified at `FR-xxx` level — deferred to a dedicated architecture pass before implementation, per [Development Roadmap § Phase 2 · Sprint 5](../16-development-roadmap.md#phase-2--sprint-5--wearable-integrations-community-challenges--leaderboards) ("this sprint's first deliverable is that design pass, not code").

## Non-Functional Requirements
Whatever shape this takes, it must not compromise the privacy stance already established for [Body Measurements](body-measurements.md) and [Progress Photos](progress-photos.md) — any social surface is opt-in per data type, never a default-on broadcast of tracked data.

## UI Flow
Not yet designed.

## Screen List
Not yet designed.

## Business Rules
To be defined; anticipated tension to resolve at design time: streak/achievement logic (§ [Achievements](achievements.md#business-rules)) is currently private and non-comparative — challenges will need a distinct, explicitly-opt-in data path rather than exposing the existing personal achievement model directly.

## Validation Rules
Not yet defined.

## APIs
Not yet defined — will require new endpoints outside the current [API Specification](../05-api-specification.md) scope.

## Database Tables
Not yet defined — will require new tables (e.g., `challenges`, `challenge_participants`) outside the current [Database Design](../04-database-design.md) scope.

## Edge Cases
To be enumerated during the dedicated design pass; flagged concerns to address then: users who delete their account mid-challenge, challenge abandonment, and how (or whether) challenge data is included in the data export/deletion flows from [Production Hardening § 9](../14-production-hardening.md#9-compliance-considerations).

## Error Handling
Not yet defined.

## Offline Behavior
Not yet defined — likely tension: challenges imply real-time-ish comparative state, in some conflict with the offline-first, locally-authoritative read model used elsewhere ([Mobile Architecture § 4](../08-mobile-architecture.md#4-offline-first-strategy)); this is exactly the kind of design question this placeholder exists to flag before commitment.

## Acceptance Criteria
Not applicable — no implementation committed yet.

## Future Improvements
This entire feature *is* the future improvement; when prioritized, promote this document to a full spec following the template used by [Achievements](achievements.md) and the other MVP feature docs in this folder.
