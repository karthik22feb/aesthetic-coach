# Future Integrations

**Product:** Aesthetic Coach
**Status:** All integrations in this document are Phase 2 — see [PRD § 5.5](01-prd.md#55-integrations), [PHASE2_SCOPE.md § Wearable Integrations](PHASE2_SCOPE.md#wearable-integrations), and [Development Roadmap § Phase 2](16-development-roadmap.md#phase-2--ai-personal-coach)
**Related documents:** [Wearable Integrations feature](features/wearable-integrations.md) (product framing) · [AI Coaching Engine § 6](09-ai-coaching-engine.md#6-model-abstraction-layer) (AI provider abstraction)

## Table of Contents
- [Purpose](#purpose)
- [Apple Health](#apple-health)
- [Health Connect (Android)](#health-connect-android)
- [Fitbit](#fitbit)
- [Garmin](#garmin)
- [Strava](#strava)
- [Smart Watches (Whoop, Oura)](#smart-watches-whoop-oura)
- [Smart Scales](#smart-scales)
- [Calendar](#calendar)
- [Additional AI Providers](#additional-ai-providers)
- [Cross-Integration Principles](#cross-integration-principles)
- [Future Roadmap Sequencing](#future-roadmap-sequencing)

## Purpose
Consolidate the technical integration detail (auth, sync mechanics, rate limits) for every planned third-party integration in one place, so [Wearable Integrations](features/wearable-integrations.md) can reference this document rather than duplicating provider-specific detail across feature docs.

## Apple Health

| Aspect | Detail |
|---|---|
| Purpose | Read (and optionally write) workouts, body measurements, and activity data on iOS without requiring a separate wearable account |
| Authentication | Native HealthKit permission dialog (on-device, not OAuth) — the app requests specific data-type read/write scopes (e.g., `HKQuantityTypeIdentifierBodyMass`, `HKWorkoutType`) |
| Data Synchronization | On-device via HealthKit APIs, not server-mediated — sync happens client-side (Flutter `health` package or platform channel), then the app POSTs relevant data through the normal authenticated API like any other client-originated write |
| Rate Limits | None (on-device API, no network rate limit); constrained instead by how frequently the app polls HealthKit for changes (recommend background delivery/observer queries, not polling) |
| Error Handling | Permission denial is a normal, expected state — degrades to manual entry (existing MVP behavior), never blocks the app |
| Security | Data never leaves the device without going through the same authenticated, TLS-protected API path as any other write — no direct HealthKit-to-third-party transfer |
| Future Roadmap | Natural first integration to build (no OAuth/webhook infrastructure needed) — the first wearable-adjacent item implemented, in [Development Roadmap § Phase 2 · Sprint 2](16-development-roadmap.md#phase-2--sprint-2--nutrition-coach--recovery-coach) |

## Health Connect (Android)

| Aspect | Detail |
|---|---|
| Purpose | Android equivalent of Apple Health — the platform-level health data aggregator |
| Authentication | Native Health Connect permission flow, same on-device model as Apple Health |
| Data Synchronization | On-device via the Health Connect SDK, same client-then-API pattern as Apple Health |
| Rate Limits | None (on-device) |
| Error Handling | Same graceful-degradation approach as Apple Health |
| Security | Same principle — data flows through the app's normal authenticated API, never a direct third-party path |
| Future Roadmap | Built alongside Apple Health as the Android-parity item in the same implementation phase |

## Fitbit

| Aspect | Detail |
|---|---|
| Purpose | Sleep, activity, and heart-rate data for users without a HealthKit/Health-Connect-syncing device |
| Authentication | OAuth 2.0 authorization code flow; access + refresh tokens stored server-side (encrypted at rest, per [Production Hardening § Encryption](14-production-hardening.md#3-encryption--secrets-management)), never on-device |
| Data Synchronization | Server-to-server: a scheduled job (per-user, staggered like the DFS computation job in [Backend Architecture § 6](07-backend-architecture.md#6-scheduled-tasks-routesconsolephp--scheduler)) polls the Fitbit Web API for new data since the last sync; webhook subscription API used instead of polling if/when implementation determines it's more efficient |
| Rate Limits | Fitbit enforces per-user hourly quotas (150 requests/hour at time of writing — verify current limits before implementation) — sync scheduling must respect this, batching requests rather than one call per data type |
| Error Handling | Expired/revoked OAuth token → connection marked disconnected in [Settings](features/settings.md), user re-prompted to reconnect; transient API errors retried with backoff, never surfaced as an app-breaking error |
| Security | Tokens encrypted at rest; scope requested is minimal (sleep + activity only, not full account access) |
| Future Roadmap | Second-priority integration after the native health stores, given the OAuth/webhook infrastructure investment required |

## Garmin

| Aspect | Detail |
|---|---|
| Purpose | Training load, sleep, and HRV data for users training with Garmin devices |
| Authentication | OAuth 1.0a (Garmin Connect's legacy auth model at time of writing — verify current Garmin Connect Developer Program requirements before implementation, as this may have changed) |
| Data Synchronization | Garmin's Health API is push-based (webhook/Ping notification model) rather than pull — requires a dedicated webhook receiver endpoint, distinct from the polling approach used for Fitbit |
| Rate Limits | Governed by Garmin's developer program terms; requires an approved developer application, not just API keys, before production use |
| Error Handling | Webhook delivery failures are Garmin's responsibility to retry per their platform; the receiver endpoint must respond quickly (2xx) and process asynchronously via a queued job, never synchronously in the webhook handler itself |
| Security | Webhook payloads verified via Garmin's signature mechanism before processing, to prevent spoofed data injection |
| Future Roadmap | Requires developer program approval lead time — flagged as a scheduling risk to account for before committing to a specific Phase 2 sub-milestone |

## Strava

| Aspect | Detail |
|---|---|
| Purpose | Cardio/endurance activity import (runs, rides) to complement Aesthetic Coach's strength-training-oriented logging |
| Authentication | OAuth 2.0, standard authorization code flow |
| Data Synchronization | Strava webhook subscription (activity created/updated events) preferred over polling, given Strava's well-documented webhook API |
| Rate Limits | Strava enforces both a 15-minute and daily request cap per application (not just per user) — sync design must account for a shared application-level budget, not just per-user pacing |
| Error Handling | Same graceful-disconnect pattern as Fitbit |
| Security | Same token-encryption-at-rest principle as Fitbit/Garmin |
| Future Roadmap | Lower priority than Fitbit/Garmin/wearables given Aesthetic Coach's strength-training core audience ([PRD § 3 Target Audience](01-prd.md#3-target-audience)) — cardio import is complementary, not core |

## Smart Watches (Whoop, Oura)

| Aspect | Detail |
|---|---|
| Purpose | The primary named targets for unlocking the Recovery Coach persona ([AI Coaching Engine § 10](09-ai-coaching-engine.md#10-future-extensibility)) — HRV, sleep stages, and recovery scores these platforms already compute |
| Authentication | OAuth 2.0 (both platforms) |
| Data Synchronization | Webhook-based where available (Whoop supports webhooks; verify Oura's current API offering at implementation time), server-side scheduled job as fallback |
| Rate Limits | Per-platform, to be confirmed against current developer documentation at implementation time — both platforms have historically had stricter limits than Fitbit given their more specialized developer programs |
| Error Handling | Same graceful-disconnect pattern as other OAuth integrations |
| Security | Recovery/HRV data is treated with the same sensitivity as body measurements ([Production Hardening § Compliance](14-production-hardening.md#9-compliance-considerations)) — encrypted at rest, never included in analytics events ([Analytics & Events § Privacy Considerations](analytics-events.md#privacy-considerations-global)) |
| Future Roadmap | This is the integration [Wearable Integrations § Purpose](features/wearable-integrations.md#purpose) is explicitly built around — sequenced immediately before or alongside the Recovery Coach persona itself |

## Smart Scales

| Aspect | Detail |
|---|---|
| Purpose | Automatic weight/body-fat-% sync to reduce manual [Body Measurements](features/body-measurements.md) logging friction |
| Authentication | Typically OAuth via the scale manufacturer's platform (e.g., Withings) rather than a direct device connection |
| Data Synchronization | Server-to-server polling or webhook, same pattern family as Fitbit |
| Rate Limits | Manufacturer-specific; generally lighter-weight than fitness-tracker APIs given lower data volume (one weigh-in event vs. continuous activity streams) |
| Error Handling | Same graceful-disconnect pattern |
| Security | Same encryption-at-rest principle; body composition data receives the same sensitivity treatment as manually-logged measurements |
| Future Roadmap | Natural pairing with the existing [Body Measurements](features/body-measurements.md) feature — low implementation complexity relative to activity/recovery integrations, a candidate for earlier Phase 2 sequencing despite being listed later here |

## Calendar

| Aspect | Detail |
|---|---|
| Purpose | Schedule workouts as calendar events, and/or read calendar availability to inform AI-generated workout timing suggestions |
| Authentication | Platform calendar permission (iOS EventKit / Android Calendar Provider), on-device like Apple Health/Health Connect — not a third-party OAuth integration |
| Data Synchronization | On-device only in the "write workout to calendar" direction (no server involvement needed); a "read availability" direction, if built, would need careful scoping to avoid ingesting unrelated personal calendar content |
| Rate Limits | Not applicable (on-device) |
| Error Handling | Permission denial degrades to no calendar integration, app fully functional without it |
| Security | If read access is ever implemented, calendar event titles/details are explicitly **not** stored or sent to the AI context pipeline — only free/busy time blocks, to avoid ingesting unrelated sensitive personal information into the app's data model |
| Future Roadmap | Lowest-priority item in this document — more of a convenience nicety than a data-enrichment integration like the others |

## Additional AI Providers

| Aspect | Detail |
|---|---|
| Purpose | OpenAI/Gemini support, per the explicit stakeholder requirement in [PRD](01-prd.md) that the AI layer support future providers with minimal changes |
| Authentication | Provider-specific API key, managed via the same secrets infrastructure as `ANTHROPIC_API_KEY` ([Production Hardening § Secrets Management](14-production-hardening.md#3-encryption--secrets-management)) |
| Data Synchronization | Not applicable (request/response API, not a sync integration) |
| Rate Limits | Provider-specific; the existing per-user token-budget system ([AI Coaching Engine § 9](09-ai-coaching-engine.md#9-rate-limiting)) already abstracts this at the product level regardless of which provider serves a given request |
| Error Handling | Same guardrail/error-envelope pattern as Claude, since `AiProviderInterface` implementations share a contract ([AI Coaching Engine § 6](09-ai-coaching-engine.md#6-model-abstraction-layer)) |
| Security | Same "server-side only, never client-exposed" principle as the Claude integration |
| Future Roadmap | Pursued only if there's a concrete driver (cost, redundancy, capability gap) — the abstraction exists so this is *possible*, not scheduled by default, per [AI Coaching Engine § 10](09-ai-coaching-engine.md#10-future-extensibility) and [PHASE2_SCOPE.md § Architecture Impact](PHASE2_SCOPE.md#architecture-impact) — not assigned to any specific Phase 2 sprint |

## Cross-Integration Principles

These apply to every third-party integration in this document, not repeated per-row above:
1. **Server-side token custody** — OAuth tokens for server-mediated integrations (Fitbit, Garmin, Strava, smart scales) are never exposed to the mobile client; the client only ever sees a connected/disconnected status.
2. **Graceful degradation** — every integration is additive; its absence or failure never blocks core app functionality, mirroring the manual-entry-as-fallback principle already established for recovery input in [Wearable Integrations § Business Rules](features/wearable-integrations.md#business-rules).
3. **Data minimization** — only the specific data fields the product actually uses are requested/stored, never a full-account data dump from any provider.
4. **User-initiated disconnect** — every integration is disconnectable from [Settings](features/settings.md) at any time, with previously-synced historical data retained (not deleted) unless the user separately requests deletion.

## Future Roadmap Sequencing

Recommended relative order (not committed dates): **Apple Health / Health Connect** (lowest integration cost, on-device) → **Smart Scales** (low complexity, clear product fit) → **Whoop/Oura** (unlocks Recovery Coach, the highest-value unlock named in [AI Coaching Engine § 10](09-ai-coaching-engine.md#10-future-extensibility)) → **Fitbit/Garmin** → **Strava** → **Calendar**. Additional AI providers are decoupled from this sequencing entirely, pursued independently if/when a concrete driver emerges.
