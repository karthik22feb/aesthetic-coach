# API Examples — Goals

**Related documents:** [API Specification § 6.8](../05-api-specification.md#68-goals) · [Goals feature](../features/goals.md) · common error shapes in [Auth Examples](auth.md#common-errors-reference)

## Table of Contents
- [POST /goals](#post-goals)
- [GET /goals](#get-goals)
- [PATCH /goals/{id}](#patch-goalsid)

## POST /goals

**Request**
```http
POST /api/v1/goals
Authorization: Bearer eyJhbGciOi...
Content-Type: application/json

{ "type": "strength", "title": "100kg Bench Press", "targetMetric": "bench_press_1rm", "targetValue": 100, "targetDate": "2027-01-01" }
```

**201 Success**
```json
{ "data": { "id": "1180", "type": "strength", "title": "100kg Bench Press", "targetMetric": "bench_press_1rm", "targetValue": 100, "targetDate": "2027-01-01", "status": "active", "currentValue": 87.5 }, "apiVersion": "1.4.0" }
```

**422 Validation Error**
```json
{
  "error": { "code": "validation_failed", "message": "The given data was invalid.", "details": { "targetDate": ["The target date must be a date after today."] } },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3KFA1"
}
```

## GET /goals

**Request**
```http
GET /api/v1/goals?status=active
Authorization: Bearer eyJhbGciOi...
```

**200 Success**
```json
{
  "data": [
    { "id": "1180", "type": "strength", "title": "100kg Bench Press", "status": "active", "currentValue": 87.5, "targetValue": 100 }
  ],
  "apiVersion": "1.4.0"
}
```

## PATCH /goals/{id}

**Request — abandon a goal**
```http
PATCH /api/v1/goals/1180
Authorization: Bearer eyJhbGciOi...
Content-Type: application/json

{ "status": "abandoned" }
```

**200 Success**
```json
{ "data": { "id": "1180", "status": "abandoned" }, "apiVersion": "1.4.0" }
```

**403 Forbidden — invalid status transition**
```json
{
  "error": { "code": "forbidden", "message": "Cannot reactivate an achieved goal directly; create a new goal instead." },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3KFA2"
}
```
Reflects [Goals feature § Business Rules](../features/goals.md#business-rules): `achieved` is a terminal state reached automatically, not user-settable, and not reversible via this endpoint.
