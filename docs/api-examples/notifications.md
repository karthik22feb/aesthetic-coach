# API Examples — Notifications

**Related documents:** [API Specification § 6.11](../05-api-specification.md#611-notifications) · [Notifications feature](../features/notifications.md) · common error shapes in [Auth Examples](auth.md#common-errors-reference)

## Table of Contents
- [GET /notifications](#get-notifications)
- [PATCH /notifications/{id}](#patch-notificationsid)
- [GET/PATCH /notification-preferences](#getpatch-notification-preferences)
- [POST /devices](#post-devices)

## GET /notifications

**Request**
```http
GET /api/v1/notifications?read=false&limit=20
Authorization: Bearer eyJhbGciOi...
```

**200 Success**
```json
{
  "data": [
    { "id": "9010", "category": "pr_detected", "title": "New PR! 🏋️", "body": "You just hit a new best on Barbell Bench Press: 62.5kg x 8.", "readAt": null, "createdAt": "2026-08-06T09:52:10Z" }
  ],
  "meta": { "nextCursor": null, "hasMore": false },
  "apiVersion": "1.4.0"
}
```

## PATCH /notifications/{id}

**Request**
```http
PATCH /api/v1/notifications/9010
Authorization: Bearer eyJhbGciOi...
Content-Type: application/json

{ "readAt": "2026-08-06T10:00:00Z" }
```

**200 Success**
```json
{ "data": { "id": "9010", "readAt": "2026-08-06T10:00:00Z" }, "apiVersion": "1.4.0" }
```

## GET/PATCH /notification-preferences

**GET Request**
```http
GET /api/v1/notification-preferences
Authorization: Bearer eyJhbGciOi...
```

**200 Success**
```json
{
  "data": [
    { "category": "streak_risk", "channelPush": true, "channelEmail": false },
    { "category": "weekly_review_ready", "channelPush": true, "channelEmail": false }
  ],
  "apiVersion": "1.4.0"
}
```

**PATCH Request**
```http
PATCH /api/v1/notification-preferences
Authorization: Bearer eyJhbGciOi...
Content-Type: application/json

{ "category": "streak_risk", "channelPush": false }
```

**200 Success**
```json
{ "data": { "category": "streak_risk", "channelPush": false, "channelEmail": false }, "apiVersion": "1.4.0" }
```

## POST /devices

**Request**
```http
POST /api/v1/devices
Authorization: Bearer eyJhbGciOi...
Content-Type: application/json

{ "platform": "ios", "deviceName": "iPhone 15 Pro", "pushToken": "fcm_abc123..." }
```

**200 Success**
```json
{ "data": { "deviceId": "512", "platform": "ios", "deviceName": "iPhone 15 Pro" }, "apiVersion": "1.4.0" }
```

**422 Validation Error**
```json
{
  "error": { "code": "validation_failed", "message": "The given data was invalid.", "details": { "platform": ["The selected platform is invalid."] } },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3KIA1"
}
```
