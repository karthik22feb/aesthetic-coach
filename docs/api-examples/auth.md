# API Examples — Authentication

**Related documents:** [API Specification § 3](../05-api-specification.md#3-authentication-flow) · [Authentication feature](../features/authentication.md)

## Table of Contents
- [POST /auth/register](#post-authregister)
- [POST /auth/login](#post-authlogin)
- [POST /auth/refresh](#post-authrefresh)
- [GET /auth/sessions](#get-authsessions)
- [Common Errors Reference](#common-errors-reference)

## POST /auth/register

**Request**
```http
POST /api/v1/auth/register
Content-Type: application/json

{ "name": "Priya Shah", "email": "priya@example.com", "password": "correct-horse-battery" }
```

**201 Success**
```json
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

**422 Validation Error**
```json
{
  "error": {
    "code": "validation_failed",
    "message": "The given data was invalid.",
    "details": {
      "email": ["The email has already been taken."],
      "password": ["The password must be at least 10 characters."]
    }
  },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3K7A1"
}
```

**401 Unauthorized** — not applicable (public endpoint).

**403 Forbidden** — not applicable.

**429 Rate Limited**
```json
{
  "error": { "code": "rate_limited", "message": "Too many requests from this IP.", "details": { "resetAt": "2026-08-06T14:35:00Z" } },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3K7A2"
}
```

**500 Internal Server Error**
```json
{
  "error": { "code": "internal_error", "message": "Something went wrong. Please try again." },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3K7A3"
}
```

## POST /auth/login

**Request**
```http
POST /api/v1/auth/login
Content-Type: application/json

{ "email": "priya@example.com", "password": "correct-horse-battery" }
```

**200 Success** — same shape as register's 201 (see above), status 200.

**401 Unauthorized**
```json
{
  "error": { "code": "unauthenticated", "message": "The provided credentials are incorrect." },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3K7B1"
}
```
Deliberately identical whether the email doesn't exist or the password is wrong (BR — prevents user enumeration, see [Authentication § Edge Cases](../features/authentication.md#edge-cases)).

**422/429/500** — same shapes as [register](#post-authregister) above.

## POST /auth/refresh

**Request**
```http
POST /api/v1/auth/refresh
Content-Type: application/json

{ "refreshToken": "8f3a2c..." }
```

**200 Success**
```json
{
  "data": { "accessToken": "eyJhbGciOi...(new)", "refreshToken": "9a1b4d...(rotated)", "expiresIn": 900 },
  "apiVersion": "1.4.0"
}
```

**401 Unauthorized — reused/revoked token**
```json
{
  "error": { "code": "session_revoked", "message": "This session has been revoked. Please log in again." },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3K7C1"
}
```
Per BR-3: this response fires when a refresh token that was already rotated is submitted again, indicating possible token theft — the entire session family is revoked as a side effect ([Authentication § Business Rules](../features/authentication.md#business-rules)).

## GET /auth/sessions

**Request**
```http
GET /api/v1/auth/sessions
Authorization: Bearer eyJhbGciOi...
```

**200 Success**
```json
{
  "data": [
    { "deviceId": "512", "deviceName": "iPhone 15 Pro", "platform": "ios", "lastActiveAt": "2026-08-06T09:12:00Z", "isCurrent": true },
    { "deviceId": "498", "deviceName": "Pixel 8", "platform": "android", "lastActiveAt": "2026-08-01T18:40:00Z", "isCurrent": false }
  ],
  "apiVersion": "1.4.0"
}
```

**401 Unauthorized**
```json
{
  "error": { "code": "unauthenticated", "message": "Your session has expired. Please log in again." },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3K7D1"
}
```

**403 Forbidden** — not applicable at this endpoint (a user can only ever list their own sessions; there is no cross-user path to attempt).

## Common Errors Reference

Every authenticated endpoint in every other domain file in this folder shares the **401 Unauthorized** and **429 Rate Limited** shapes shown above unless noted otherwise — not repeated verbatim in each subsequent file.
