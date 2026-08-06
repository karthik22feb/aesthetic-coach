# API Contract Examples

**Related documents:** [API Specification](../05-api-specification.md) (canonical endpoint reference — these files provide realistic worked examples, not a redefinition of the contract)

## Purpose

The [API Specification](../05-api-specification.md) defines the contract (endpoints, conventions, versioning). This folder provides **realistic, complete request/response examples for every response category** — success, validation error, unauthorized, forbidden, rate limited, and internal server error — organized by domain to match [API Specification § 6](../05-api-specification.md#6-endpoint-reference), rather than one file per individual endpoint (41 endpoints would produce 41 mostly-repetitive files; domain grouping keeps this navigable while still covering every endpoint).

## Table of Contents

| Domain | Endpoints Covered | File |
|---|---|---|
| Authentication | `/auth/*` | [auth.md](auth.md) |
| Users & Profile | `/me*` | [users-profile.md](users-profile.md) |
| Exercises | `/exercises*` | [exercises.md](exercises.md) |
| Workout Templates | `/templates*` | [workout-templates.md](workout-templates.md) |
| Workouts | `/workouts*`, `/sync/workouts` | [workouts.md](workouts.md) |
| Nutrition | `/foods*`, `/meals*`, `/nutrition/*`, `/water-logs` | [nutrition.md](nutrition.md) |
| Body Metrics | `/body-measurements*`, `/progress-photos*` | [body-metrics.md](body-metrics.md) |
| Habits | `/habits*` | [habits.md](habits.md) |
| Goals | `/goals*` | [goals.md](goals.md) |
| Daily Fitness Score | `/scores*` | [daily-fitness-score.md](daily-fitness-score.md) |
| AI Coaching | `/coach/*` | [ai-coaching.md](ai-coaching.md) |
| Notifications | `/notifications*`, `/notification-preferences`, `/devices` | [notifications.md](notifications.md) |

## Conventions

- Every domain file's primary endpoint shows all seven response categories: **request, success, validation error, unauthorized, forbidden, rate limited, internal server error**. Secondary endpoints in the same domain show success + the error categories that meaningfully differ from the primary example, to avoid repeating an identical 401/403/429/500 shape a dozen times.
- All error responses follow the single envelope defined in [API Specification § 4](../05-api-specification.md#4-error-response-format) — these examples are realistic instances of that envelope, not a new format.
- `Authorization: Bearer <accessToken>` is assumed on every authenticated example and omitted from the request block for brevity unless the example is specifically about auth.
- IDs, tokens, and timestamps in examples are illustrative, not real values.
