# API Examples — Workout Templates

**Related documents:** [API Specification § 6.3](../05-api-specification.md#63-workout-templates) · [Workout Tracking feature](../features/workout-tracking.md) · [AI Prompt — Workout Coach](../ai/workout-coach.md) · common error shapes in [Auth Examples](auth.md#common-errors-reference)

## Table of Contents
- [GET /templates](#get-templates)
- [POST /templates/ai-generate](#post-templatesai-generate)
- [PATCH /templates/{id}](#patch-templatesid)

## GET /templates

**Request**
```http
GET /api/v1/templates
Authorization: Bearer eyJhbGciOi...
```

**200 Success**
```json
{
  "data": [
    { "id": "412", "name": "Push Day - Strength Focus", "goal": "strength", "source": "ai", "exerciseCount": 5 }
  ],
  "apiVersion": "1.4.0"
}
```

## POST /templates/ai-generate

**Request**
```http
POST /api/v1/templates/ai-generate
Authorization: Bearer eyJhbGciOi...
Content-Type: application/json

{ "goalType": "strength", "experienceLevel": "intermediate", "equipment": ["barbell", "dumbbell"], "daysPerWeek": 4 }
```

**201 Success**
```json
{
  "data": {
    "id": "412",
    "name": "Push Day - Strength Focus",
    "goal": "strength",
    "source": "ai",
    "exercises": [
      { "exerciseId": "77", "order": 1, "targetSets": 4, "targetReps": "5-8", "targetRpe": 8.0, "restSeconds": 150 }
    ],
    "rationale": "Prioritizing bench press given your logged goal to hit a 100kg bench; volume kept moderate given last week's high training load."
  },
  "apiVersion": "1.4.0"
}
```
See [AI Prompt — Workout Coach § Expected JSON Output](../ai/workout-coach.md#expected-json-output) for the generation contract behind this endpoint.

**422 Validation Error**
```json
{
  "error": { "code": "validation_failed", "message": "The given data was invalid.", "details": { "daysPerWeek": ["The days per week must be between 1 and 7."] } },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3KAA1"
}
```

**403 Forbidden — unverified email**
```json
{
  "error": { "code": "forbidden", "message": "Please verify your email to use AI coaching features." },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3KAA2"
}
```
Enforces BR-2 via the `EnsureEmailVerified` middleware ([Backend Architecture § 3](../07-backend-architecture.md#3-middleware)).

**429 Rate Limited**
```json
{
  "error": { "code": "rate_limited", "message": "Daily coaching limit reached.", "details": { "resetAt": "2026-08-07T00:00:00Z" } },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3KAA3"
}
```

**500 Internal Server Error — provider failure**
```json
{
  "error": { "code": "internal_error", "message": "Your coach is temporarily unavailable. Please try again shortly." },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3KAA4"
}
```

## PATCH /templates/{id}

**Request**
```http
PATCH /api/v1/templates/412
Authorization: Bearer eyJhbGciOi...
Content-Type: application/json

{ "name": "Push Day - Updated" }
```

**200 Success** — same shape as [GET /templates](#get-templates) entry, updated.

**404 Not Found** — returned (not 403) if the template doesn't belong to the caller, per the IDOR-prevention pattern in [System Architecture § Security Architecture](../03-system-architecture.md#8-security-architecture) (existence is not confirmed to non-owners).
