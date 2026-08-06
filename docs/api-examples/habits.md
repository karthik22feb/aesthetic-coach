# API Examples — Habits

**Related documents:** [API Specification § 6.7](../05-api-specification.md#67-habits) · [Habits feature](../features/habits.md) · common error shapes in [Auth Examples](auth.md#common-errors-reference)

## Table of Contents
- [POST /habits](#post-habits)
- [GET /habits](#get-habits)
- [POST /habits/{id}/logs](#post-habitsidlogs)

## POST /habits

**Request**
```http
POST /api/v1/habits
Authorization: Bearer eyJhbGciOi...
Content-Type: application/json

{ "name": "Mobility work", "frequencyType": "weekly_n", "frequencyTarget": 3 }
```

**201 Success**
```json
{ "data": { "id": "610", "name": "Mobility work", "frequencyType": "weekly_n", "frequencyTarget": 3, "isActive": true, "currentStreak": 0 }, "apiVersion": "1.4.0" }
```

**422 Validation Error**
```json
{
  "error": { "code": "validation_failed", "message": "The given data was invalid.", "details": { "frequencyTarget": ["The frequency target must be between 1 and 7."] } },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3KEA1"
}
```

## GET /habits

**Request**
```http
GET /api/v1/habits
Authorization: Bearer eyJhbGciOi...
```

**200 Success**
```json
{
  "data": [
    { "id": "610", "name": "Mobility work", "frequencyType": "weekly_n", "frequencyTarget": 3, "currentStreak": 2, "completedToday": false }
  ],
  "apiVersion": "1.4.0"
}
```

## POST /habits/{id}/logs

**Request**
```http
POST /api/v1/habits/610/logs
Authorization: Bearer eyJhbGciOi...
Content-Type: application/json

{ "logDate": "2026-08-06" }
```

**201 Success**
```json
{ "data": { "habitId": "610", "logDate": "2026-08-06", "currentStreak": 3 }, "apiVersion": "1.4.0" }
```

**404 Not Found**
```json
{
  "error": { "code": "not_found", "message": "Habit not found." },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3KEA2"
}
```
Returned uniformly whether the habit doesn't exist or belongs to another user — see the IDOR-prevention rationale in [Workout Templates Examples § PATCH /templates/{id}](workout-templates.md#patch-templatesid).
