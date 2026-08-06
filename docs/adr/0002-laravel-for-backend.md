# ADR-0002: Laravel for Backend

**Status:** Accepted
**Related documents:** [Backend Architecture](../07-backend-architecture.md) · [PRD § Technology Stack](../01-prd.md)

## Context
The backend needs to support a REST API, queue-based background processing (AI reviews, notifications), a scheduler (daily DFS computation, weekly reviews), events/listeners, and a service-layer architecture — all specified as hard requirements in the [PRD](../01-prd.md), with Laravel named explicitly as the framework.

## Problem
Which backend framework best supports this feature set with a small-to-medium team, while giving strong batteries-included support for queues/scheduling/notifications rather than requiring bespoke infrastructure for each?

## Decision
Build the backend in Laravel (latest stable), organized as a modular monolith ([ADR-0009](0009-modular-monolith.md)).

## Alternatives Considered
| Option | Why not chosen |
|---|---|
| Node.js (NestJS/Express) | Comparable capability, but the stakeholder's existing expertise and the PRD's explicit requirement point to Laravel/PHP; NestJS would require rebuilding queue/scheduler/notification infrastructure Laravel provides out of the box |
| Django (Python) | Similar batteries-included profile to Laravel, but not the stakeholder's specified stack; would also require a different AI-SDK ecosystem fit for the Claude integration |
| Go (custom framework) | Excellent performance characteristics, but significantly more infrastructure (queues, scheduler, ORM migrations) would need to be hand-assembled or third-party-composed, adding development time disproportionate to this project's actual scale requirements ([System Architecture § Scalability Strategy](../03-system-architecture.md#7-scalability-strategy) targets hundreds of thousands of MAU, not a scale that demands Go's performance ceiling) |

## Pros
- Queues, Scheduler, Events/Listeners, Notifications, and API Resources are first-class, well-documented framework features — directly matching the PRD's requirement list rather than needing bespoke implementations.
- Eloquent ORM's migration system underpins the entire [Database Design § Migration Strategy](../04-database-design.md#6-migration-strategy).
- Large ecosystem for the specific integrations needed (OAuth verification, S3-compatible storage, Redis).
- Strong fit with the stakeholder's stated MySQL production experience ([ADR-0003](0003-mysql8-for-database.md)) — Eloquent/MySQL is a well-trodden combination.

## Cons
- PHP's ecosystem for cutting-edge AI/LLM tooling is less mature than Python's — mitigated by the fact that the Claude integration is a straightforward HTTPS API client ([AI Coaching Engine § 6](../09-ai-coaching-engine.md#6-model-abstraction-layer)), not a dependency on Python-specific ML tooling.
- Horizontal scaling of a PHP-FPM app tier requires more deliberate stateless-design discipline than some alternatives — addressed directly via the JWT-stateless auth decision ([ADR-0005](0005-jwt-refresh-token-auth.md)).

## Consequences
[Backend Architecture](../07-backend-architecture.md)'s entire folder structure, layering (Controller → Service → Repository), and coding standards are Laravel-idiomatic. The AI Coaching module ([AI Coaching Engine](../09-ai-coaching-engine.md)) is built as a Laravel module rather than a separate Python microservice, keeping the system a single deployable per [ADR-0009](0009-modular-monolith.md).

## Future Review Criteria
Revisit only if: a specific module's performance profile diverges sharply enough to justify extraction into a different runtime (e.g., the AI Coaching module needing Python-specific ML libraries beyond simple API calls), or team composition shifts away from PHP expertise.
