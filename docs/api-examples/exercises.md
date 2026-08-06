# API Examples — Exercises

**Related documents:** [API Specification § 6.2](../05-api-specification.md#62-exercises) · [Exercise Library feature](../features/exercise-library.md) · common error shapes in [Auth Examples](auth.md#common-errors-reference)

## Table of Contents
- [GET /exercises](#get-exercises)
- [GET /exercises/{id}](#get-exercisesid)
- [POST /exercises](#post-exercises)

## GET /exercises

**Request**
```http
GET /api/v1/exercises?search=squat&muscleGroup=quads&equipment=barbell&limit=20
Authorization: Bearer eyJhbGciOi...
```

**200 Success**
```json
{
  "data": [
    {
      "id": "77",
      "name": "Barbell Back Squat",
      "slug": "barbell-back-squat",
      "primaryMuscleGroup": "quads",
      "equipment": "barbell",
      "difficulty": "intermediate",
      "isCustom": false
    }
  ],
  "meta": { "nextCursor": null, "hasMore": false },
  "apiVersion": "1.4.0"
}
```

## GET /exercises/{id}

**Request**
```http
GET /api/v1/exercises/77
Authorization: Bearer eyJhbGciOi...
```

**200 Success**
```json
{
  "data": {
    "id": "77",
    "name": "Barbell Back Squat",
    "slug": "barbell-back-squat",
    "primaryMuscleGroup": "quads",
    "secondaryMuscleGroups": ["glutes", "hamstrings"],
    "equipment": "barbell",
    "difficulty": "intermediate",
    "instructions": "Set the bar on your upper back...",
    "videoUrl": null,
    "isCustom": false
  },
  "apiVersion": "1.4.0"
}
```

**404 Not Found**
```json
{
  "error": { "code": "not_found", "message": "Exercise not found." },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3K9A1"
}
```

## POST /exercises

**Request**
```http
POST /api/v1/exercises
Authorization: Bearer eyJhbGciOi...
Content-Type: application/json

{ "name": "Landmine Press", "primaryMuscleGroup": "shoulders", "equipment": "barbell", "instructions": "Load one end of a barbell..." }
```

**201 Success**
```json
{
  "data": { "id": "5021", "name": "Landmine Press", "slug": "landmine-press-8842", "isCustom": true, "createdByUserId": "8842" },
  "apiVersion": "1.4.0"
}
```
Slug is disambiguated with the creating user's ID suffix since custom exercises are private per user ([Exercise Library § Business Rules](../features/exercise-library.md#business-rules)) and could otherwise collide across users.

**422 Validation Error**
```json
{
  "error": {
    "code": "validation_failed",
    "message": "The given data was invalid.",
    "details": { "primaryMuscleGroup": ["The selected primary muscle group is invalid."] }
  },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3K9B1"
}
```

**403 Forbidden** — not applicable; any authenticated, email-verified user may create a custom exercise.
