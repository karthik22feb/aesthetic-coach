# API Examples — Users & Profile

**Related documents:** [API Specification § 6.1](../05-api-specification.md#61-users--profile) · [Profile feature](../features/profile.md) · [Settings feature](../features/settings.md) · common error shapes in [Auth Examples § Common Errors Reference](auth.md#common-errors-reference)

## Table of Contents
- [GET /me](#get-me)
- [PATCH /me](#patch-me)
- [DELETE /me](#delete-me)
- [POST /me/export](#post-meexport)

## GET /me

**Request**
```http
GET /api/v1/me
Authorization: Bearer eyJhbGciOi...
```

**200 Success**
```json
{
  "data": {
    "id": "8842",
    "name": "Priya Shah",
    "email": "priya@example.com",
    "emailVerified": true,
    "timezone": "Asia/Kolkata",
    "unitPreference": "metric",
    "dateOfBirth": "1997-03-14",
    "sex": "female",
    "heightCm": 165.0,
    "dietaryRestrictions": ["vegetarian"]
  },
  "apiVersion": "1.4.0"
}
```

**401 Unauthorized** — see [Auth Examples](auth.md#common-errors-reference).

## PATCH /me

**Request**
```http
PATCH /api/v1/me
Authorization: Bearer eyJhbGciOi...
Content-Type: application/json

{ "unitPreference": "imperial", "dietaryRestrictions": ["vegetarian", "gluten_free"] }
```

**200 Success** — same shape as [GET /me](#get-me) with updated fields.

**422 Validation Error**
```json
{
  "error": {
    "code": "validation_failed",
    "message": "The given data was invalid.",
    "details": { "heightCm": ["The height cm must be between 50 and 250."] }
  },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3K8A1"
}
```

**403 Forbidden** — not applicable; `/me` always resolves to the authenticated caller, so there is no other-user path to forbid.

## DELETE /me

**Request**
```http
DELETE /api/v1/me
Authorization: Bearer eyJhbGciOi...
```

**200 Success**
```json
{ "data": { "status": "scheduled_for_deletion", "gracePeriodEndsAt": "2026-09-05T00:00:00Z" }, "apiVersion": "1.4.0" }
```
Implements BR-6 per [Settings feature § Acceptance Criteria](../features/settings.md#acceptance-criteria).

## POST /me/export

**Request**
```http
POST /api/v1/me/export
Authorization: Bearer eyJhbGciOi...
```

**202 Accepted**
```json
{ "data": { "jobId": "exp_9f21", "status": "queued" }, "apiVersion": "1.4.0" }
```
Completion is delivered via a `notifications` row + push (category `data_export_ready`) containing a pre-signed download URL, not returned synchronously — see [Settings feature § Edge Cases](../features/settings.md#edge-cases).

**429 Rate Limited**
```json
{
  "error": { "code": "rate_limited", "message": "You can request one export per day.", "details": { "resetAt": "2026-08-07T00:00:00Z" } },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3K8B1"
}
```
