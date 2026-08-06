# API Examples — Daily Fitness Score

**Related documents:** [API Specification § 6.9](../05-api-specification.md#69-daily-fitness-score) · [Dashboard feature](../features/dashboard.md) · [AI Coaching Engine § 5](../09-ai-coaching-engine.md#5-recommendation-engine) · common error shapes in [Auth Examples](auth.md#common-errors-reference)

## Table of Contents
- [GET /scores/today](#get-scorestoday)
- [GET /scores](#get-scores)

## GET /scores/today

**Request**
```http
GET /api/v1/scores/today
Authorization: Bearer eyJhbGciOi...
```

**200 Success**
```json
{
  "data": {
    "scoreDate": "2026-08-06",
    "score": 78,
    "components": { "training": 85, "nutrition": 70, "recovery": 75, "habit": 80 },
    "formulaVersion": "v1",
    "explanation": "Strong training consistency this week. Nutrition logging dropped slightly over the weekend."
  },
  "apiVersion": "1.4.0"
}
```

**200 Success — not yet computed today**
```json
{
  "data": {
    "scoreDate": "2026-08-05",
    "score": 74,
    "components": { "training": 80, "nutrition": 72, "recovery": 70, "habit": 75 },
    "formulaVersion": "v1",
    "explanation": "Strong training consistency this week. Nutrition logging dropped slightly over the weekend.",
    "isStale": true
  },
  "apiVersion": "1.4.0"
}
```
`isStale: true` signals the client to show yesterday's score with the "computing today's score" state described in [Dashboard § Edge Cases](../features/dashboard.md#edge-cases), rather than a 404 or a misleading zero.

## GET /scores

**Request**
```http
GET /api/v1/scores?from=2026-07-08&to=2026-08-06
Authorization: Bearer eyJhbGciOi...
```

**200 Success**
```json
{
  "data": [
    { "scoreDate": "2026-08-04", "score": 76 },
    { "scoreDate": "2026-08-05", "score": 74 },
    { "scoreDate": "2026-08-06", "score": 78 }
  ],
  "apiVersion": "1.4.0"
}
```

**422 Validation Error**
```json
{
  "error": { "code": "validation_failed", "message": "The given data was invalid.", "details": { "to": ["The to date must be after or equal to from."] } },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3KGA1"
}
```
