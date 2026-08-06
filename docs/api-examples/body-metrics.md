# API Examples — Body Metrics

**Related documents:** [API Specification § 6.6](../05-api-specification.md#66-body-metrics) · [Body Measurements feature](../features/body-measurements.md) · [Progress Photos feature](../features/progress-photos.md) · common error shapes in [Auth Examples](auth.md#common-errors-reference)

## Table of Contents
- [POST /body-measurements](#post-body-measurements)
- [GET /body-measurements/trends](#get-body-measurementstrends)
- [POST /progress-photos](#post-progress-photos)

## POST /body-measurements

**Request**
```http
POST /api/v1/body-measurements
Authorization: Bearer eyJhbGciOi...
Content-Type: application/json

{ "measuredAt": "2026-08-06T07:00:00Z", "weightKg": 62.4, "bodyFatPct": 22.1 }
```

**201 Success**
```json
{ "data": { "id": "7710", "measuredAt": "2026-08-06T07:00:00Z", "weightKg": 62.4, "bodyFatPct": 22.1 }, "apiVersion": "1.4.0" }
```

**422 Validation Error**
```json
{
  "error": { "code": "validation_failed", "message": "The given data was invalid.", "details": { "weightKg": ["The weight kg must be between 20 and 400."] } },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3KDA1"
}
```

## GET /body-measurements/trends

**Request**
```http
GET /api/v1/body-measurements/trends?metric=weightKg&range=90d
Authorization: Bearer eyJhbGciOi...
```

**200 Success**
```json
{
  "data": {
    "metric": "weightKg",
    "points": [
      { "date": "2026-05-08", "value": 64.1 },
      { "date": "2026-06-08", "value": 63.2 },
      { "date": "2026-08-06", "value": 62.4 }
    ]
  },
  "apiVersion": "1.4.0"
}
```

## POST /progress-photos

**Request**
```http
POST /api/v1/progress-photos
Authorization: Bearer eyJhbGciOi...
Content-Type: multipart/form-data; boundary=----WebKitFormBoundary

------WebKitFormBoundary
Content-Disposition: form-data; name="angle"

front
------WebKitFormBoundary
Content-Disposition: form-data; name="takenAt"

2026-08-06T07:05:00Z
------WebKitFormBoundary
Content-Disposition: form-data; name="photo"; filename="progress.jpg"
Content-Type: image/jpeg

<binary data>
------WebKitFormBoundary--
```

**201 Success**
```json
{ "data": { "id": "3301", "angle": "front", "takenAt": "2026-08-06T07:05:00Z", "url": "https://storage.aestheticcoach.app/signed/....(expires in 15 min)" }, "apiVersion": "1.4.0" }
```
`url` is always a short-lived pre-signed link, never a permanent public path — per [Progress Photos § Business Rules](../features/progress-photos.md#business-rules).

**422 Validation Error — invalid file**
```json
{
  "error": { "code": "validation_failed", "message": "The given data was invalid.", "details": { "photo": ["The photo must be a file of type: jpeg, png, heic.", "The photo must not be greater than 15360 kilobytes."] } },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3KDA2"
}
```
