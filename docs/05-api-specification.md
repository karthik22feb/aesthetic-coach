# API Specification

**Product:** Aesthetic Coach
**Base URL:** `https://api.aestheticcoach.app/api/v1`
**Related documents:** [System Architecture](03-system-architecture.md) · [Database Design](04-database-design.md) · [Backend Architecture](07-backend-architecture.md) · [AI Coaching Engine](09-ai-coaching-engine.md) · [Phased Release Strategy](PHASED_RELEASE_STRATEGY.md) — see [§ 9 Phase Allocation](#9-phase-allocation) for which endpoints are live at each release phase

---

## 1. Versioning Strategy

- **URI versioning**: `/api/v1/...`. Breaking changes ship as `/api/v2` running alongside `v1` until the mobile client's minimum supported version no longer needs it (see [CI/CD Pipeline § Release Management](11-cicd-pipeline.md#5-release-management--versioning)).
- Non-breaking additive changes (new optional field, new endpoint) do **not** bump the version.
- Every response includes an `apiVersion` field for observability, independent of the URI version, to track minor contract revisions.
- Mobile app sends `X-App-Version` header on every request; backend can use this to serve compatibility shims during a forced-upgrade window.

## 2. Conventions

| Aspect | Convention |
|---|---|
| Payload casing | `camelCase` in JSON (translated from `snake_case` DB columns at the API Resource layer) |
| Dates/times | ISO 8601, UTC (`2026-08-06T14:30:00Z`); client converts to local timezone for display |
| IDs | Server-generated resource IDs are integers (as strings in JSON to avoid JS precision issues: `"id": "1024"`); client-generated idempotency keys (`clientUuid`) are UUIDv4 |
| Auth header | `Authorization: Bearer <accessToken>` |
| Content type | `application/json` for all requests/responses except file upload (`multipart/form-data`) and AI chat streaming (`text/event-stream`) |
| Idempotency | Mutating requests from offline-sync flows accept a `clientUuid`; replays with the same key are upserts, not duplicates |

## 3. Authentication Flow

**Phase:** all endpoints in this section are **Phase 1** (foundational, built [Phase 1 · Sprint 1](16-development-roadmap.md#phase-1--sprint-1--infrastructure-authentication--project-setup)) — see [§ 9 Phase Allocation](#9-phase-allocation).

See sequence diagram in [System Architecture § 3.1](03-system-architecture.md#31-authentication-login--token-refresh).

### `POST /auth/register`
```json
// Request
{ "name": "Priya Shah", "email": "priya@example.com", "password": "correct-horse-battery" }

// 201 Response
{
  "data": {
    "user": { "id": "8842", "name": "Priya Shah", "email": "priya@example.com", "emailVerified": false },
    "accessToken": "eyJhbGciOi...",
    "refreshToken": "8f3a2c...",
    "expiresIn": 900
  },
  "apiVersion": "1.4.0"
}
```

### `POST /auth/login`
Body: `{ "email": "...", "password": "..." }`. Response shape identical to register.

### `POST /auth/oauth/google` / `POST /auth/oauth/apple`
Body: `{ "idToken": "<provider-issued id token>", "deviceName": "iPhone 15" }`. Backend verifies the token server-side against the provider's public keys before issuing session tokens — see [System Architecture § Security Architecture](03-system-architecture.md#8-security-architecture).

### `POST /auth/refresh`
Body: `{ "refreshToken": "..." }` → new `accessToken` + rotated `refreshToken`. `401 { "error": { "code": "session_revoked" } }` if reuse of a rotated token is detected (BR-3).

### `POST /auth/logout`
Revokes the current device's refresh token.

### `GET /auth/sessions` / `DELETE /auth/sessions/{deviceId}`
List / revoke active device sessions (FR-106).

### `POST /auth/password/forgot` / `POST /auth/password/reset`
Standard reset-link flow (FR-105).

## 4. Error Response Format

All errors follow a single envelope:

```json
{
  "error": {
    "code": "validation_failed",
    "message": "The given data was invalid.",
    "details": {
      "email": ["The email field is required."]
    }
  },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3K7..."
}
```

| HTTP Status | `code` | Meaning |
|---|---|---|
| 400 | `bad_request` | Malformed request |
| 401 | `unauthenticated` / `session_revoked` | Missing/invalid/expired token |
| 403 | `forbidden` | Authenticated but not authorized for this resource |
| 404 | `not_found` | Resource doesn't exist or isn't owned by the caller |
| 409 | `conflict` | e.g. duplicate `clientUuid` with divergent payload |
| 422 | `validation_failed` | Form Request validation errors, field-level detail in `details` |
| 429 | `rate_limited` | Includes `Retry-After` header; used for both API throttling and AI token budget (NFR-12) |
| 500 | `internal_error` | Unexpected server error; `requestId` used to correlate with logs (see [Monitoring & Logging](13-monitoring-logging.md)) |

`requestId` is generated at the edge (middleware) and threaded through logs end-to-end — see [Monitoring & Logging § Log Aggregation](13-monitoring-logging.md#7-log-aggregation).

## 5. Pagination & Filtering

Cursor-based pagination for time-series lists (workouts, meals, coach messages); offset-based for small, stable lists (exercise library browse without search).

```
GET /workouts?limit=20&cursor=eyJpZCI6MTIzNH0
```

```json
{
  "data": [ /* workout objects */ ],
  "meta": {
    "nextCursor": "eyJpZCI6MTIwMH0",
    "hasMore": true
  },
  "apiVersion": "1.4.0"
}
```

**Filtering:** query params scoped per resource, e.g. `GET /workouts?from=2026-07-01&to=2026-08-01&status=completed`, `GET /exercises?search=squat&muscleGroup=quads&equipment=barbell`. Multi-value filters use repeated params: `?muscleGroup=quads&muscleGroup=hamstrings` (OR semantics within a field, AND across fields).

**Sorting:** `?sort=-startedAt` (`-` prefix = descending); default sort is always documented per endpoint below.

## 6. Endpoint Reference

### 6.1 Users & Profile
| Method | Path | Description | Phase |
|---|---|---|---|
| GET | `/me` | Current user profile | Phase 1 |
| PATCH | `/me` | Update profile (name, timezone, unit preference, dietary restrictions, etc.) | Phase 1 |
| DELETE | `/me` | Request account deletion (FR-108, BR-6) | Phase 1 |
| POST | `/me/export` | Queue a full data export; returns a job id, delivered via notification + pre-signed URL | Phase 1 |

### 6.2 Exercises
| Method | Path | Description | Phase |
|---|---|---|---|
| GET | `/exercises` | Search/browse library (default sort: `name` asc) | Phase 1 |
| GET | `/exercises/{id}` | Exercise detail | Phase 1 |
| POST | `/exercises` | Create custom exercise | Phase 1 |

### 6.3 Workout Templates
| Method | Path | Description | Phase |
|---|---|---|---|
| GET | `/templates` | List own + preset templates | Phase 1 |
| POST | `/templates` | Create template | Phase 1 |
| POST | `/templates/ai-generate` | AI-generated adaptive template (FR-206), **structured one-shot generation only** — see [AI Coaching Engine](09-ai-coaching-engine.md) and [PHASE1_SCOPE.md § AI Workout Recommendations](PHASE1_SCOPE.md#ai-workout-recommendations). Conversational plan adjustment on top of this is Phase 2 ([PHASE2_SCOPE.md § Adaptive Plans](PHASE2_SCOPE.md#adaptive-plans)), delivered via the § 6.10 chat endpoints once GA, not a new endpoint. | Phase 1 |
| GET/PATCH/DELETE | `/templates/{id}` | Detail / update / delete | Phase 1 |

### 6.4 Workouts
| Method | Path | Description | Phase |
|---|---|---|---|
| GET | `/workouts` | List, default sort `-startedAt` | Phase 1 |
| POST | `/workouts` | Log a workout (accepts `clientUuid` for idempotency) | Phase 1 |
| GET/PATCH/DELETE | `/workouts/{id}` | Detail / update / delete | Phase 1 |
| POST | `/sync/workouts` | Batch upsert for offline sync (see [Mobile Architecture § Synchronization](08-mobile-architecture.md#6-synchronization)) | Phase 1 |

**Example — `POST /workouts`:**
```json
// Request
{
  "clientUuid": "3fae9c2e-6c2b-4a9a-9e9e-1a2b3c4d5e6f",
  "name": "Push Day",
  "templateId": "412",
  "startedAt": "2026-08-06T09:00:00Z",
  "completedAt": "2026-08-06T09:52:00Z",
  "exercises": [
    {
      "exerciseId": "77",
      "order": 1,
      "sets": [
        { "setNumber": 1, "weightKg": 60, "reps": 8, "rpe": 7.5, "isWarmup": false }
      ]
    }
  ]
}

// 201 Response
{
  "data": {
    "id": "98123",
    "clientUuid": "3fae9c2e-6c2b-4a9a-9e9e-1a2b3c4d5e6f",
    "name": "Push Day",
    "status": "completed",
    "prsDetected": [ { "exerciseId": "77", "type": "weight", "value": 60 } ]
  },
  "apiVersion": "1.4.0"
}
```

### 6.5 Nutrition
| Method | Path | Description | Phase |
|---|---|---|---|
| GET | `/foods` | Search food database | Phase 1 |
| POST | `/foods` | Create custom food | Phase 1 |
| GET | `/meals` | List meals, filterable by date range | Phase 1 |
| POST | `/meals` | Log a meal (accepts `clientUuid`) | Phase 1 |
| GET/PATCH/DELETE | `/meals/{id}` | Detail / update / delete | Phase 1 |
| GET | `/nutrition/daily-summary?date=2026-08-06` | Aggregated macros/calories vs. targets | Phase 1 |
| POST | `/water-logs` | Increment water intake for a date | Phase 1 |

AI-generated meal suggestions (FR-304) are **Phase 2** and are not a separate endpoint — they're delivered via the § 6.10 chat endpoints once the Nutrition Coach persona is GA (see [PHASE2_SCOPE.md § Nutrition Coach](PHASE2_SCOPE.md#nutrition-coach)); the user still logs the resulting meal through `POST /meals` above, unchanged.

### 6.6 Body Metrics
| Method | Path | Description | Phase |
|---|---|---|---|
| GET/POST | `/body-measurements` | List / log | Phase 1 |
| GET | `/body-measurements/trends?metric=weightKg&range=90d` | Trend series for charting | Phase 1 |
| GET/POST | `/progress-photos` | List / upload (multipart, returns pre-signed storage reference) | Phase 1 |

### 6.7 Habits
| Method | Path | Description | Phase |
|---|---|---|---|
| GET/POST | `/habits` | List / create | Phase 1 |
| PATCH/DELETE | `/habits/{id}` | Update / deactivate | Phase 1 |
| POST | `/habits/{id}/logs` | Mark complete for a date | Phase 1 |

### 6.8 Goals
| Method | Path | Description | Phase |
|---|---|---|---|
| GET/POST | `/goals` | List / create | Phase 1 |
| GET/PATCH/DELETE | `/goals/{id}` | Detail / update / abandon | Phase 1 |

### 6.9 Daily Fitness Score
| Method | Path | Description | Phase |
|---|---|---|---|
| GET | `/scores/today` | Today's DFS + component breakdown + explanation | Phase 1 |
| GET | `/scores?from=&to=` | Historical scores for trend chart | Phase 1 |

### 6.10 AI Coaching
| Method | Path | Description | Phase |
|---|---|---|---|
| GET | `/coach/conversations` | List conversations, filterable by `persona` | **Phase 2** — general availability gated behind the Conversational Coach launch ([Development Roadmap § Phase 2 · Sprint 1](16-development-roadmap.md#phase-2--sprint-1--conversational-coach-foundation)); route exists from Phase 1 (backing `POST /templates/ai-generate` and reviews internally) but is not exposed as a user-facing conversation list until Phase 2 |
| POST | `/coach/conversations` | Start a new conversation | **Phase 2** (same gating as above) |
| GET | `/coach/conversations/{id}/messages` | Paginated message history | **Phase 2** |
| POST | `/coach/conversations/{id}/messages` | Send a message; response is `text/event-stream` (SSE) — see below | **Phase 2** — feature-flagged dark in Phase 1 for the underlying structured-generation/explanation calls, opened to open-ended user-authored conversation only in Phase 2 per [CI/CD Pipeline § Feature Flags](11-cicd-pipeline.md#6-feature-flags) |
| POST | `/coach/reviews/weekly` | Manually trigger (or fetch cached) weekly review | Phase 1 — non-conversational Progress Summary, see [PHASE1_SCOPE.md § Basic Analytics](PHASE1_SCOPE.md#basic-analytics) |

**Example — streaming chat (`POST /coach/conversations/{id}/messages`):**

Request:
```json
{ "content": "My knees hurt a bit after squats yesterday, should I train legs today?" }
```

Response (`text/event-stream`):
```
event: message_start
data: {"messageId":"msg_9182"}

event: content_delta
data: {"delta":"Given the knee discomfort you logged, I'd swap"}

event: content_delta
data: {"delta":" today's leg session for upper body and revisit legs in 48h..."}

event: message_stop
data: {"messageId":"msg_9182","tokensInput":842,"tokensOutput":156}
```

Full context-assembly and guardrail behavior behind this endpoint is documented in [AI Coaching Engine](09-ai-coaching-engine.md).

### 6.11 Notifications
| Method | Path | Description | Phase |
|---|---|---|---|
| GET | `/notifications` | List, filterable by `read` | Phase 1 |
| PATCH | `/notifications/{id}` | Mark read | Phase 1 |
| GET/PATCH | `/notification-preferences` | View / update per-category channel preferences | Phase 1 |
| POST | `/devices` | Register device push token | Phase 1 |

## 7. Rate Limiting

| Scope | Limit | Response on breach |
|---|---|---|
| General API (per user) | 120 req/min | `429 rate_limited` |
| Auth endpoints (per IP) | 10 req/min | `429 rate_limited` |
| AI chat (per user) | Token-budget based, not request-count — see [AI Coaching Engine § Rate Limiting](09-ai-coaching-engine.md#9-rate-limiting) | `429 rate_limited` with `details.resetAt` |

## 8. OpenAPI Specification

The canonical, always-up-to-date contract is a generated `openapi.yaml` (via `laravel-openapi`/`scramble` from route + Form Request + API Resource annotations — see [Backend Architecture § Coding Standards](07-backend-architecture.md#8-coding-standards)), published at `/api/v1/openapi.yaml` in non-production environments and checked into `docs/openapi/` for versioned review. Representative excerpt:

```yaml
openapi: 3.1.0
info:
  title: Aesthetic Coach API
  version: "1.4.0"
servers:
  - url: https://api.aestheticcoach.app/api/v1
paths:
  /workouts:
    get:
      summary: List workouts
      security: [{ bearerAuth: [] }]
      parameters:
        - name: limit
          in: query
          schema: { type: integer, default: 20, maximum: 100 }
        - name: cursor
          in: query
          schema: { type: string }
        - name: status
          in: query
          schema: { type: string, enum: [in_progress, completed] }
      responses:
        '200':
          description: Paginated workout list
          content:
            application/json:
              schema:
                type: object
                properties:
                  data:
                    type: array
                    items: { $ref: '#/components/schemas/Workout' }
                  meta:
                    $ref: '#/components/schemas/PaginationMeta'
    post:
      summary: Log a workout
      security: [{ bearerAuth: [] }]
      requestBody:
        required: true
        content:
          application/json:
            schema: { $ref: '#/components/schemas/WorkoutInput' }
      responses:
        '201':
          description: Created
        '422':
          $ref: '#/components/responses/ValidationError'
components:
  securitySchemes:
    bearerAuth: { type: http, scheme: bearer, bearerFormat: JWT }
  schemas:
    Workout:
      type: object
      properties:
        id: { type: string }
        name: { type: string }
        status: { type: string, enum: [in_progress, completed] }
        startedAt: { type: string, format: date-time }
        prsDetected:
          type: array
          items: { type: object }
    PaginationMeta:
      type: object
      properties:
        nextCursor: { type: string, nullable: true }
        hasMore: { type: boolean }
  responses:
    ValidationError:
      description: Validation failed
      content:
        application/json:
          schema:
            type: object
            properties:
              error:
                type: object
                properties:
                  code: { type: string }
                  message: { type: string }
                  details: { type: object }
```

Full generated spec covers every endpoint in § 6; this excerpt establishes the pattern engineers follow when adding new endpoints (route → Form Request → Resource → auto-generated schema — no hand-maintained duplicate spec).

## 9. Phase Allocation

**No endpoints in this specification are deleted or redesigned by the phased release strategy** — see [Phased Release Strategy](PHASED_RELEASE_STRATEGY.md) and [Database Design § 10](04-database-design.md#10-phased-implementation--architecture-validation) for the corresponding confirmation at the schema level. This section summarizes which endpoints are publicly live at each phase; per-endpoint detail is marked inline in each § 6 table above.

| Domain (§ 6) | Phase 1 (live at launch) | Phase 2 (activated later) |
|---|---|---|
| § 3 Auth | All endpoints | — |
| § 6.1 Users & Profile | All endpoints | — |
| § 6.2 Exercises | All endpoints | — |
| § 6.3 Workout Templates | All endpoints, including `POST /templates/ai-generate` (structured generation) | Conversational adjustment on top of a generated template (via § 6.10 once GA) |
| § 6.4 Workouts | All endpoints | — |
| § 6.5 Nutrition | All endpoints (core tracking) | AI meal suggestions (FR-304), delivered via § 6.10 |
| § 6.6 Body Metrics | All endpoints | — |
| § 6.7 Habits | All endpoints | — |
| § 6.8 Goals | All endpoints | AI Goal Recommendation (no dedicated endpoint yet — see [AI Prompt — Goal Recommendation](ai/goal-recommendation.md)) |
| § 6.9 Daily Fitness Score | All endpoints | Predictive/trajectory extensions (no dedicated endpoint yet — see [AI Prompt — Progress Analysis](ai/progress-analysis.md)) |
| § 6.10 AI Coaching | `POST /coach/reviews/weekly` only | `GET/POST /coach/conversations`, `GET/POST /coach/conversations/{id}/messages` — routes exist from Phase 1 (used internally by `POST /templates/ai-generate` and exercise-explanation calls) but are not exposed as a general-purpose, user-authored conversation surface until Phase 2 |
| § 6.11 Notifications | All endpoints | — |

**Mechanism:** Phase 2 endpoints that already exist in the route table (the `/coach/conversations*` family) ship **feature-flagged dark** in Phase 1 per [CI/CD Pipeline § Feature Flags](11-cicd-pipeline.md#6-feature-flags) and [Phased Release Strategy § Deployment Strategy](PHASED_RELEASE_STRATEGY.md#deployment-strategy) — this is a config/flag change to open general availability, not new endpoint development, consistent with the instruction that this migration only classifies and never redesigns the API.
