# API Examples — AI Coaching

**Related documents:** [API Specification § 6.10](../05-api-specification.md#610-ai-coaching) · [AI Coach feature](../features/ai-coach.md) · [AI Coaching Engine](../09-ai-coaching-engine.md) · common error shapes in [Auth Examples](auth.md#common-errors-reference)

## Table of Contents
- [POST /coach/conversations](#post-coachconversations)
- [POST /coach/conversations/{id}/messages](#post-coachconversationsidmessages)
- [POST /coach/reviews/weekly](#post-coachreviewsweekly)

## POST /coach/conversations

**Request**
```http
POST /api/v1/coach/conversations
Authorization: Bearer eyJhbGciOi...
Content-Type: application/json

{ "persona": "personal_trainer" }
```

**201 Success**
```json
{ "data": { "id": "conv_5521", "persona": "personal_trainer", "createdAt": "2026-08-06T09:00:00Z" }, "apiVersion": "1.4.0" }
```

**403 Forbidden — unverified email**
See [Workout Templates Examples § POST /templates/ai-generate](workout-templates.md#post-templatesai-generate) for the identical BR-2 shape, shared across every AI endpoint.

**403 Forbidden — disabled persona**
```json
{
  "error": { "code": "forbidden", "message": "This coaching persona is not yet available." },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3KHA1"
}
```
Returned for Future personas (`recovery_coach`, `motivation_coach`) before they're activated — the mobile client normally prevents this by showing "Coming soon" in the persona switcher, but the server enforces it independently per [AI Coach feature § Validation Rules](../features/ai-coach.md#validation-rules).

## POST /coach/conversations/{id}/messages

**Request**
```http
POST /api/v1/coach/conversations/conv_5521/messages
Authorization: Bearer eyJhbGciOi...
Content-Type: application/json

{ "content": "My knees hurt a bit after squats yesterday, should I train legs today?" }
```

**200 Success (`text/event-stream`)**
```
event: message_start
data: {"messageId":"msg_9182"}

event: content_delta
data: {"delta":"Given the knee discomfort you logged, I'd swap"}

event: content_delta
data: {"delta":" today's leg session for upper body and revisit legs in 48h. If the discomfort persists beyond a few days or worsens, it's worth checking in with a physical therapist."}

event: message_stop
data: {"messageId":"msg_9182","tokensInput":842,"tokensOutput":156}
```
The trailing sentence demonstrates the guardrail-appended professional-referral note per [AI Coaching Engine § 7](../09-ai-coaching-engine.md#7-safety-guardrails) and [Safety Prompts](../ai/safety-prompts.md) — rendered as a normal part of the streamed response, styled distinctly client-side per [AI Chat Bubble § Variants](../components/ai-chat-bubble.md#variants).

**422 Validation Error**
```json
{
  "error": { "code": "validation_failed", "message": "The given data was invalid.", "details": { "content": ["The content must not be greater than 2000 characters."] } },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3KHA2"
}
```

**429 Rate Limited — token budget**
```json
{
  "error": { "code": "rate_limited", "message": "You've reached today's coaching limit.", "details": { "resetAt": "2026-08-07T00:00:00Z" } },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3KHA3"
}
```

**500 Internal Server Error — provider outage**
```json
{
  "error": { "code": "internal_error", "message": "Your coach is temporarily unavailable. Please try again shortly." },
  "apiVersion": "1.4.0",
  "requestId": "req_01HZY3KHA4"
}
```

## POST /coach/reviews/weekly

**Request**
```http
POST /api/v1/coach/reviews/weekly
Authorization: Bearer eyJhbGciOi...
```

**200 Success — cached review**
```json
{
  "data": {
    "weekOf": "2026-07-31",
    "summary": "Strong week on the training side — you hit all 4 planned sessions and set a new bench press PR. Nutrition logging dropped off on the weekend, which is worth a look.",
    "highlightMetric": { "type": "workout_consistency", "value": "4/4 sessions" },
    "focusArea": { "type": "nutrition_logging_consistency", "value": "5/7 days logged" }
  },
  "apiVersion": "1.4.0"
}
```
See [AI Prompt — Weekly Review § Expected JSON Output](../ai/weekly-review.md#expected-json-output) for the generation contract behind this response.

**202 Accepted — not yet generated**
```json
{ "data": { "status": "generating" }, "apiVersion": "1.4.0" }
```
