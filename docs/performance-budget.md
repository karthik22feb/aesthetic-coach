# Performance Budget

**Product:** Aesthetic Coach
**Related documents:** [SRS § 5 Non-Functional Requirements](02-srs.md#5-non-functional-requirements) (source of the API/AI latency targets restated here) · [Testing Strategy § Performance Testing](10-testing-strategy.md#7-performance-testing) · [Monitoring & Logging § Performance Metrics](13-monitoring-logging.md#4-performance-metrics) · [Mobile Architecture](08-mobile-architecture.md)

## Table of Contents
- [Purpose](#purpose)
- [Budget Table](#budget-table)
- [App Startup](#app-startup)
- [Screen Rendering](#screen-rendering)
- [API Response Time](#api-response-time)
- [AI Response Time](#ai-response-time)
- [Battery Usage](#battery-usage)
- [Network Usage](#network-usage)
- [Memory Usage](#memory-usage)
- [Offline Sync Duration](#offline-sync-duration)
- [Animation Frame Rate](#animation-frame-rate)
- [Monitoring Strategy](#monitoring-strategy)
- [Future Improvements](#future-improvements)

## Purpose
Consolidate every measurable performance target into one reference, cross-referencing where a target originates from an existing `NFR-xxx` in [SRS § 5](02-srs.md#5-non-functional-requirements) and adding the additional device-level budgets (battery, memory, network, animation) that document doesn't cover at that level of granularity.

## Budget Table

| Dimension | Target | Source |
|---|---|---|
| App cold start | < 2.5s on a mid-tier Android device | [SRS § 7 (PRD-derived)](01-prd.md#7-non-functional-requirements-summary) |
| App warm start | < 1s | New in this document |
| Screen transition (tab switch) | < 100ms perceived | New in this document |
| API p95 latency (non-AI) | < 300ms | NFR-1 |
| AI first-token latency | < 2s p95 | NFR-2 |
| Home screen first render (cached) | < 500ms | [Dashboard feature § Non-Functional Requirements](features/dashboard.md#non-functional-requirements) |
| Exercise/food search | < 300ms p95 | [Exercise Library § Non-Functional Requirements](features/exercise-library.md#non-functional-requirements) |
| Offline sync (typical batch, reconnect) | < 5s for a batch of ≤ 20 queued items on a normal connection | New in this document |
| Battery drain (1hr active workout logging session) | < 8% on a mid-tier device | New in this document |
| Memory footprint (steady state) | < 250MB resident | New in this document |
| Animation frame rate | Sustained 60fps (120fps on capable devices), no dropped frames > 1% of frames during scroll/transition | New in this document |

## App Startup

**Cold start** (process not resident) target < 2.5s to interactive Home/Login screen, per the PRD-level non-functional target already established in [PRD § 7](01-prd.md#7-non-functional-requirements-summary). Broken down: < 300ms to first frame (splash), remainder budgeted for session-check + initial data hydration ([Splash screen § Performance Considerations](screens/splash.md#performance-considerations)).

**Warm start** (process resident, app backgrounded) target < 1s to interactive — no splash re-shown, state restored from memory/Riverpod providers rather than re-initializing.

## Screen Rendering

Tab switches within the 5-tab bottom navigation ([UI/UX Design System § 4](06-ui-ux-design-system.md#4-navigation)) target < 100ms perceived transition, since each tab reads from local Drift cache first ([Mobile Architecture § 4](08-mobile-architecture.md#4-offline-first-strategy)) rather than waiting on network. Screens with heavier initial computation (Analytics/Progress, per [Analytics screen § Performance Considerations](screens/analytics.md#performance-considerations)) use skeleton states rather than blocking the transition itself.

## API Response Time

Restates NFR-1/NFR-2 verbatim as the binding contract; this document adds the **budget-vs-actual monitoring loop**: p95/p99 latency per route is tracked continuously via APM ([Monitoring & Logging § Performance Metrics](13-monitoring-logging.md#4-performance-metrics)), with the alert threshold in [Monitoring & Logging § Alerting](13-monitoring-logging.md#8-alerting) (2x target sustained 10 min) treated as this budget's enforcement mechanism, not merely descriptive.

## AI Response Time

First-token latency < 2s p95 (NFR-2); full-response completion time is intentionally **not** budgeted as tightly, since streaming means the user perceives progress from the first token onward — total generation time varies naturally with response length and is not a meaningful UX bottleneck once streaming has started, consistent with [AI Coach screen § Performance Considerations](screens/ai-coach.md#performance-considerations).

## Battery Usage

Target: an active 1-hour workout-logging session (screen on, rest timer running, periodic set entry) drains < 8% battery on a representative mid-tier device. Contributing factors budgeted individually:
- Rest timer implemented as a local scheduled notification, not a continuously-polling foreground timer loop ([Workout Tracking § Non-Functional Requirements](features/workout-tracking.md#non-functional-requirements)).
- Background sync ([Mobile Architecture § Synchronization](08-mobile-architecture.md#6-synchronization)) uses platform-native background-fetch scheduling (`workmanager`/`BGTaskScheduler`), which is battery-budget-aware by the OS itself, rather than a custom polling loop.
- No continuous GPS/location usage anywhere in the MVP feature set — flagged explicitly since it's the single largest battery-cost category apps commonly introduce unnecessarily.

## Network Usage

Target: a typical daily active-user session (checking Home, logging one workout, logging 2–3 meals, one AI coach exchange) consumes < 2MB of data, excluding progress photo uploads (which are user-initiated and inherently variable). Contributing design choices:
- Exercise/food library browsing served from local cache with TTL-based background refresh, not re-fetched per view ([Mobile Architecture § 5](08-mobile-architecture.md#5-local-storage)).
- Offline sync batches multiple queued mutations per request rather than one request per item ([Mobile Architecture § 6](08-mobile-architecture.md#6-synchronization)).
- Progress photos are client-side downscaled/compressed before upload ([Progress Photos § Edge Cases](features/progress-photos.md#edge-cases)).

## Memory Usage

Target: < 250MB resident memory in typical steady-state usage (Home/Train/Nutrition tabs), avoiding OS-level background eviction on mid-tier devices. Chart-heavy screens (Analytics/Progress) are allowed a higher transient peak but must return to baseline after navigating away — validated via Flutter DevTools memory profiling as part of the same performance-testing pass referenced in [Testing Strategy § Performance Testing](10-testing-strategy.md#7-performance-testing).

## Offline Sync Duration

Target: a queue of ≤ 20 pending mutations (a realistic worst case after, e.g., a multi-day gym trip with no connectivity) fully syncs within 5 seconds of connectivity being restored, on a normal (non-degraded) connection. Larger queues degrade linearly and communicate progress via the Offline Banner component ([UI/UX Design System § 3](06-ui-ux-design-system.md#3-core-components)) rather than appearing stalled.

## Animation Frame Rate

Target: sustained 60fps on all devices (120fps on ProMotion/high-refresh-rate displays where supported), with dropped frames kept under 1% during scroll and transition animations — directly enforces the "calm intelligence, not gamified noise" motion philosophy in [UI/UX Design System § 7](06-ui-ux-design-system.md#7-motion): restrained animations are also cheaper to render well. The Score Ring fill animation ([Progress Ring component § Flutter Implementation Notes](components/progress-ring.md#flutter-implementation-notes)) and streaming AI text render ([AI Chat Bubble § Flutter Implementation Notes](components/ai-chat-bubble.md#flutter-implementation-notes)) are the two highest-risk animation paths and receive dedicated profiling attention.

## Monitoring Strategy

| Layer | Tooling |
|---|---|
| Backend API latency | APM per [Monitoring & Logging § 2](13-monitoring-logging.md#2-application-monitoring-apm), alerted per [§ 8](13-monitoring-logging.md#8-alerting) |
| AI latency | Dedicated span isolated from general HTTP/DB time ([Monitoring & Logging § 2](13-monitoring-logging.md#2-application-monitoring-apm)) |
| Mobile cold start / frame timing | Flutter DevTools profiling in CI-adjacent performance runs ([Testing Strategy § Performance Testing](10-testing-strategy.md#7-performance-testing)), tracked per release |
| Mobile crash-free / ANR rate | Crash reporting SDK ([Monitoring & Logging § Crash Reporting](13-monitoring-logging.md#6-crash-reporting)) |
| Battery/memory/network | Manual profiling pass (Xcode Instruments / Android Studio Profiler) before each major release — not yet continuously automated (see Future Improvements) |

Every budget in this document that regresses beyond its stated threshold is treated as a release blocker at the same severity as a failing test, not a "nice to have" — enforced via the pre-release performance-testing gate in [Testing Strategy § Test Automation & CI Gates](10-testing-strategy.md#10-test-automation--ci-gates).

## Future Improvements
- Automated battery/memory/network regression testing in CI (currently a manual pre-release pass) once budget/tooling justifies the investment.
- Per-device-tier budgets (low/mid/high-end Android specifically) rather than a single mid-tier baseline, once real device-distribution telemetry is available post-launch.
