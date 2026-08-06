# API Examples — Workouts

**Related documents:** [API Specification § 6.4](../05-api-specification.md#64-workouts) · [Workout Tracking feature](../features/workout-tracking.md) · common error shapes in [Auth Examples](auth.md#common-errors-reference)

## Table of Contents
- [POST /workouts](#post-workouts)
- [GET /workouts](#get-workouts)
- [POST /sync/workouts](#post-syncworkouts)

## POST /workouts

**Request**
```http
POST /api/v1/workouts
Authorization: Bearer eyJhbGciOi...
Content-Type: application/json

{
  "clientUuid": "3fae9c2e-6c2b-4a9a-9e9e-1a2b3c4d5e6f",
  "name": "Push Day",
  "templateId": "412",
  "startedAt": "2026-08-06T09:00:00Z",
  "completedAt": "2026-08-06T09:52:00Z",
  "exercises": [
    { "exerciseId": "77", "order": 1, "sets": [{ "setNumber": 1, "weightKg": 62.5, "reps": 8, "rpe": 8.0, "isWarmup": false }] }
  ]
}
```

**201 Success**
```json
{
  "data": {
    "id": "98123",
    "clientUuid": "3fae9c2e-6c2b-4a9a-9e9e-1a2b3c4d5e6f",
    "name": "Push Day",
    "status": "completed",
    "prsDetected": [{ "exerciseId": "77", "type": "weight", "value": 62.5 }]
  },
  "apiVersion": "1.4.0"
}
```

**422 Validation Error**
```json
{
  "error": {
    "code": "validation_failed",
    "message": "The given data was invalid.",
    "details": { "exercises.0.sets.0.reps": ["The reps field must be an integer between 0 and 999."] }
  },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3KBA1"
}
```

**409 Conflict — clientUuid replay with divergent payload**
```json
{
  "error": { "code": "conflict", "message": "A workout with this clientUuid already exists with different data." },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3KBA2"
}
```
An identical replay of the same `clientUuid` and payload is a silent idempotent success (200, not 409) — this 409 only fires if the same key is reused with genuinely different content, which indicates a client bug rather than a legitimate retry.

## GET /workouts

**Request**
```http
GET /api/v1/workouts?from=2026-08-01&to=2026-08-06&status=completed&limit=20
Authorization: Bearer eyJhbGciOi...
```

**200 Success**
```json
{
  "data": [
    { "id": "98123", "name": "Push Day", "status": "completed", "startedAt": "2026-08-06T09:00:00Z", "durationMinutes": 52 }
  ],
  "meta": { "nextCursor": null, "hasMore": false },
  "apiVersion": "1.4.0"
}
```

## POST /sync/workouts

**Request**
```http
POST /api/v1/sync/workouts
Authorization: Bearer eyJhbGciOi...
Content-Type: application/json

{
  "batch": [
    { "clientUuid": "3fae9c2e-...", "name": "Push Day", "startedAt": "2026-08-06T09:00:00Z", "completedAt": "2026-08-06T09:52:00Z", "exercises": [] },
    { "clientUuid": "9b21ff44-...", "name": "Pull Day", "startedAt": "2026-08-05T18:00:00Z", "completedAt": "2026-08-05T18:47:00Z", "exercises": [] }
  ]
}
```

**200 Success — partial batch failure**
```json
{
  "data": {
    "results": [
      { "clientUuid": "3fae9c2e-...", "status": "synced", "serverId": "98123" },
      { "clientUuid": "9b21ff44-...", "status": "failed", "error": { "code": "validation_failed", "details": { "startedAt": ["Must not be in the future."] } } }
    ]
  },
  "apiVersion": "1.4.0"
}
```
Per-item success/failure per [Mobile Architecture § Synchronization](../08-mobile-architecture.md#6-synchronization) — a failed item stays queued client-side and retries independently; successful items clear immediately.
