# Software Requirements Specification (SRS)

**Product:** Aesthetic Coach
**Related documents:** [PRD](01-prd.md) · [System Architecture](03-system-architecture.md) · [API Specification](05-api-specification.md) · [Database Design](04-database-design.md)

This document translates the [PRD](01-prd.md) into precise, testable requirements. Requirement IDs (`FR-xxx`, `NFR-xxx`, `BR-xxx`) are referenced from architecture and testing documents for traceability.

---

## 1. System Overview

Aesthetic Coach is a three-tier system:

1. **Mobile client** (Flutter, iOS + Android) — the sole user-facing surface in MVP.
2. **Backend API** (Laravel, REST, MySQL 8) — owns all business logic, data persistence, and orchestrates the AI layer.
3. **AI Coaching Engine** (Claude API via an abstracted provider layer) — invoked server-side only; the mobile client never calls the AI provider directly.

See [System Architecture](03-system-architecture.md) for component and deployment diagrams.

## 2. Definitions

| Term | Meaning |
|---|---|
| DFS | Daily Fitness Score — composite 0–100 score computed once per user per day |
| Persona | A named AI coaching role (e.g., Personal Trainer, Nutrition Coach) with its own system prompt and tool access |
| Session | An authenticated device session, represented by a refresh token |
| Workout | A logged training session containing one or more exercise entries |
| Template | A reusable, user- or AI-defined workout blueprint |

## 3. Constraints & Assumptions

**Constraints:**
- Mobile: Flutter, targeting Android and iOS only in MVP (no web/desktop client).
- Backend: Laravel + MySQL 8 (stakeholder hard requirement, existing operational expertise).
- AI: Claude API as primary/only implemented provider in MVP; architecture must not preclude adding others later.
- Must support fully offline workout logging.

**Assumptions:**
- Users have intermittent but eventually-available internet connectivity (sync model assumes eventual consistency, not permanent offline).
- Initial scale target is low hundreds of thousands of MAU, not tens of millions — architecture favors a well-indexed monolith + queue workers over microservices at MVP stage (see [System Architecture § Scalability](03-system-architecture.md#7-scalability-strategy)).

## 4. Functional Requirements

Each requirement has an ID, description, and acceptance criteria. Priority: **M**=MVP, **F**=Future.

### 4.1 Authentication & Account Management

| ID | Requirement | Acceptance Criteria | Pri |
|---|---|---|---|
| FR-101 | User can register with email + password | Given a unique email and password meeting policy (§ Business Rules BR-1), account is created and verification email sent | M |
| FR-102 | User can sign in with Google | OAuth flow returns verified Google identity; account auto-created on first login | M |
| FR-103 | User can sign in with Apple | Sign in with Apple flow supported per Apple guidelines (including private relay email) | M |
| FR-104 | User can verify email | Clicking verification link marks `email_verified_at`; unverified users have limited feature access per BR-2 | M |
| FR-105 | User can reset password | Reset link expires in 60 minutes, single use | M |
| FR-106 | User can view and revoke active sessions/devices | Session list shows device name, platform, last active; revoke invalidates that device's refresh token immediately | M |
| FR-107 | User can log out of current device | Refresh token for that session is revoked | M |
| FR-108 | User can delete their account | Soft-delete immediately, hard-delete + data purge after 30-day grace period (BR-6) | M |
| FR-109 | System issues short-lived JWT access token + rotating refresh token per device | See [System Architecture § Security Architecture](03-system-architecture.md#8-security-architecture) | M |

### 4.2 Workout Tracking

| ID | Requirement | Acceptance Criteria | Pri |
|---|---|---|---|
| FR-201 | User can browse/search exercise library | Search by name, muscle group, equipment; results < 300ms p95 | M |
| FR-202 | User can log a workout with exercises, sets, reps, weight, RPE | Workout persists with per-set data; supports supersets and rest timers | M |
| FR-203 | User can start a workout from a template (own, AI-generated, or preset) | Template pre-fills exercises/target sets | M |
| FR-204 | System detects and flags personal records (PRs) | New max weight/reps/volume for an exercise is flagged at save time | M |
| FR-205 | User can log a workout fully offline | Workout is stored locally and syncs when connectivity returns (see [Mobile Architecture § Offline-First Strategy](08-mobile-architecture.md#4-offline-first-strategy)) | M |
| FR-206 | AI can generate an adaptive workout template for the user | Considers goal, recent training history, recovery/soreness input, available equipment | M |

### 4.3 Nutrition Tracking

| ID | Requirement | Acceptance Criteria | Pri |
|---|---|---|---|
| FR-301 | User can log meals/foods with macros and calories | Supports manual entry and food search | M |
| FR-302 | User can log water intake | Simple increment/decrement UI | M |
| FR-303 | System computes daily macro/calorie totals vs. targets | Updates in real time as entries are logged | M |
| FR-304 | AI can suggest meals based on remaining macro budget and preferences | Suggestion respects dietary restrictions set in profile | M |
| FR-305 | User can scan a barcode to log food | Future | F |

### 4.4 Body Measurements

| ID | Requirement | Acceptance Criteria | Pri |
|---|---|---|---|
| FR-401 | User can log weight and body measurements over time | Trend chart available for each metric | M |
| FR-402 | User can upload progress photos | Stored privately, associated with a date; not shared without explicit action | M |

### 4.5 Habits

| ID | Requirement | Acceptance Criteria | Pri |
|---|---|---|---|
| FR-501 | User can create custom habits or adopt suggested ones | Habit has frequency target (e.g., daily, 3x/week) | M |
| FR-502 | User can mark a habit complete for a day | Streak counter updates; streak resets per BR-7 | M |

### 4.6 AI Coaching

| ID | Requirement | Acceptance Criteria | Pri |
|---|---|---|---|
| FR-601 | User can converse with the AI coach in a chat interface | Streaming response; conversation history persisted per user | M |
| FR-602 | AI coach has access to the user's recent tracked data as context | Personal Trainer persona sees workout history; Nutrition persona sees food log — scoped per [AI Coaching Engine § Context Management](09-ai-coaching-engine.md#3-context-management) | M |
| FR-603 | System generates a Weekly Review | Scheduled job produces summary + recommendations, delivered as notification + in-app card | M |
| FR-604 | AI coach can explain an exercise on request | Returns explanation grounded in exercise library data | M |
| FR-605 | System generates a Monthly Review | Future | F |
| FR-606 | AI coach provides recovery/motivation/habit coaching personas | Future | F |
| FR-607 | AI coach flags potential overtraining/injury risk patterns | Future | F |

### 4.7 Goals & Daily Fitness Score

| ID | Requirement | Acceptance Criteria | Pri |
|---|---|---|---|
| FR-701 | User can set a goal (strength, body composition, habit-based, event date) | Goal linked to tracked metric(s) for progress computation | M |
| FR-702 | System computes a Daily Fitness Score (0–100) once per day per user | Deterministic function of training load, nutrition adherence, recovery input, habit consistency (see BR-8) | M |
| FR-703 | DFS is shown with a plain-language explanation of contributing factors | Explanation generated from the same inputs as the score, not a separate AI call in MVP (cost control) | M |

### 4.8 Notifications

| ID | Requirement | Acceptance Criteria | Pri |
|---|---|---|---|
| FR-801 | User receives push notifications for reminders, streak risk, AI check-ins | Respects per-category notification preferences | M |
| FR-802 | User can configure notification preferences per category | Stored per user, enforced server-side before dispatch | M |

## 5. Non-Functional Requirements

| ID | Category | Requirement |
|---|---|---|
| NFR-1 | Performance | API p95 latency < 300ms for non-AI endpoints under nominal load (see [Testing Strategy § Performance Testing](10-testing-strategy.md#7-performance-testing)) |
| NFR-2 | Performance | AI chat endpoint streams first token in < 2s p95 |
| NFR-3 | Availability | API uptime ≥ 99.5% monthly (MVP) |
| NFR-4 | Scalability | Stateless API layer horizontally scalable behind a load balancer; no in-process session state |
| NFR-5 | Offline | Workout logging, viewing recent history, and habit check-ins function fully offline |
| NFR-6 | Security | All traffic over TLS 1.2+; access tokens expire ≤ 15 minutes; refresh tokens rotate on use |
| NFR-7 | Security | Passwords hashed with bcrypt/argon2id; never logged in plaintext |
| NFR-8 | Privacy | User can export all personal data (JSON) and request deletion within the app |
| NFR-9 | Observability | All API errors logged with correlation/request ID traceable end-to-end (see [Monitoring & Logging](13-monitoring-logging.md)) |
| NFR-10 | Localization | Text externalized for future i18n even though MVP ships English-only |
| NFR-11 | Accessibility | Mobile UI meets WCAG 2.1 AA-equivalent contrast and tap-target sizing (see [UI/UX Design System § Accessibility](06-ui-ux-design-system.md#8-accessibility)) |
| NFR-12 | Cost control | AI token usage per user per day is capped and monitored (see [AI Coaching Engine § Rate Limiting](09-ai-coaching-engine.md#9-rate-limiting)) |

## 6. Business Rules

| ID | Rule |
|---|---|
| BR-1 | Password policy: minimum 10 characters, at least 1 letter and 1 number. No maximum-complexity theater rules. |
| BR-2 | Unverified email accounts can log workouts/nutrition but cannot use AI coaching features (abuse/cost control). |
| BR-3 | A refresh token is single-use; reuse of an already-rotated token revokes the entire session family (breach detection). |
| BR-4 | Access tokens are stateless JWTs valid for 15 minutes; refresh tokens are opaque, stored hashed server-side, valid for 30 days sliding. |
| BR-5 | A user may have at most 10 concurrent active device sessions; oldest is revoked when exceeded. |
| BR-6 | Account deletion: soft-delete immediately (data hidden from user, excluded from AI context), hard-delete of PII after 30 days, aggregate/anonymized analytics may be retained. |
| BR-7 | A habit streak resets to 0 if a scheduled day is missed; grace is not applied automatically in MVP. |
| BR-8 | Daily Fitness Score formula and weights are defined in [AI Coaching Engine § Recommendation Engine](09-ai-coaching-engine.md#5-recommendation-engine) and versioned; changing the formula requires a version bump so historical scores remain explainable. |
| BR-9 | AI coach responses that touch medical, injury-diagnosis, or eating-disorder-adjacent topics must include a professional-referral disclaimer and avoid diagnostic language (see [AI Coaching Engine § Safety Guardrails](09-ai-coaching-engine.md#7-safety-guardrails)). |

## 7. Acceptance Criteria Format

All feature work implementing an `FR-xxx` must be validated against a Gherkin-style scenario before being marked done, e.g.:

```gherkin
Feature: Workout logging offline
  Scenario: User logs a workout with no connectivity
    Given the device is offline
    And the user has an active workout session
    When the user completes and saves the workout
    Then the workout is persisted to local storage
    And a "pending sync" indicator is shown
    When connectivity is restored
    Then the workout is uploaded and the indicator clears
```

This format is the baseline contract referenced by [Testing Strategy](10-testing-strategy.md).
