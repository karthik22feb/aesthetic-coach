# API Examples — Nutrition

**Related documents:** [API Specification § 6.5](../05-api-specification.md#65-nutrition) · [Nutrition feature](../features/nutrition.md) · [Calorie Tracker](../features/calorie-tracker.md) · [Water Intake](../features/water-intake.md) · common error shapes in [Auth Examples](auth.md#common-errors-reference)

## Table of Contents
- [GET /foods](#get-foods)
- [POST /meals](#post-meals)
- [GET /nutrition/daily-summary](#get-nutritiondaily-summary)
- [POST /water-logs](#post-water-logs)

## GET /foods

**Request**
```http
GET /api/v1/foods?search=greek+yogurt&limit=10
Authorization: Bearer eyJhbGciOi...
```

**200 Success**
```json
{
  "data": [
    { "id": "3391", "name": "Greek Yogurt, Plain", "brand": null, "servingSize": 170, "servingUnit": "g", "calories": 100, "proteinG": 17, "carbsG": 6, "fatG": 0.7 }
  ],
  "meta": { "nextCursor": null, "hasMore": false },
  "apiVersion": "1.4.0"
}
```

## POST /meals

**Request**
```http
POST /api/v1/meals
Authorization: Bearer eyJhbGciOi...
Content-Type: application/json

{
  "clientUuid": "b1a2c3d4-e5f6-4a7b-8c9d-0e1f2a3b4c5d",
  "mealType": "breakfast",
  "loggedAt": "2026-08-06T07:30:00Z",
  "items": [{ "foodId": "3391", "quantity": 1.5 }]
}
```

**201 Success**
```json
{
  "data": {
    "id": "56201",
    "mealType": "breakfast",
    "loggedAt": "2026-08-06T07:30:00Z",
    "items": [{ "foodId": "3391", "quantity": 1.5, "calories": 150, "proteinG": 25.5, "carbsG": 9, "fatG": 1.05 }]
  },
  "apiVersion": "1.4.0"
}
```
Macros are snapshotted onto `meal_items` at log time per [Database Design § 3.3](../04-database-design.md#33-nutrition) — later edits to the `foods` catalog entry never rewrite this historical log.

**422 Validation Error**
```json
{
  "error": { "code": "validation_failed", "message": "The given data was invalid.", "details": { "items.0.quantity": ["The quantity must be greater than 0."] } },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3KCA1"
}
```

## GET /nutrition/daily-summary

**Request**
```http
GET /api/v1/nutrition/daily-summary?date=2026-08-06
Authorization: Bearer eyJhbGciOi...
```

**200 Success**
```json
{
  "data": {
    "date": "2026-08-06",
    "target": { "calories": 2000, "proteinG": 140, "carbsG": 200, "fatG": 65 },
    "logged": { "calories": 1150, "proteinG": 95, "carbsG": 110, "fatG": 40 },
    "remaining": { "calories": 850, "proteinG": 45, "carbsG": 90, "fatG": 25 }
  },
  "apiVersion": "1.4.0"
}
```

## POST /water-logs

**Request**
```http
POST /api/v1/water-logs
Authorization: Bearer eyJhbGciOi...
Content-Type: application/json

{ "date": "2026-08-06", "amountMl": 250 }
```

**200 Success**
```json
{ "data": { "date": "2026-08-06", "totalMl": 750 }, "apiVersion": "1.4.0" }
```
Upserted per `(user_id, logged_date)` per [Water Intake feature § Business Rules](../features/water-intake.md#business-rules) — this response reflects the new running total, not a new row.
