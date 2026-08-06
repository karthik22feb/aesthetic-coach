# ADR-0009: Modular Monolith over Microservices

**Status:** Accepted
**Related documents:** [System Architecture § 1 & § 9](../03-system-architecture.md#1-high-level-architecture) (original condensed rationale) · [Backend Architecture § 1](../07-backend-architecture.md#1-folder-structure)

## Context
The backend has several distinct domains (Auth, Workouts, Nutrition, Habits, Goals, Scoring, Coaching, Notifications) that could plausibly be separate services, but is built and operated by a single, relatively small engineering team, with significant cross-domain read requirements (the Daily Fitness Score and AI coaching context both read across nearly every domain in one request).

## Problem
Should the backend be structured as microservices (one deployable per domain) or as a single deployable with strong internal module boundaries?

## Decision
Build a modular monolith: one Laravel deployable, internally organized into strict module boundaries (`app/Modules/*`, [Backend Architecture § 1](../07-backend-architecture.md#1-folder-structure)) that mirror what would be service boundaries in a microservices architecture, but sharing one database and one deployment pipeline.

## Alternatives Considered
| Option | Why not chosen |
|---|---|
| Microservices (one service per domain) | The Daily Fitness Score ([AI Coaching Engine § 5](../09-ai-coaching-engine.md#5-recommendation-engine)) and AI context assembly ([AI Coaching Engine § 3](../09-ai-coaching-engine.md#3-context-management)) both require consistent, low-latency reads across Workouts, Nutrition, Habits, and Goals in a single computation — in a microservices split, this becomes either a distributed-transaction/eventual-consistency problem or a chatty cross-service call pattern, neither of which is justified by this team's actual scale or headcount |
| A single AI-Coaching microservice, monolith for everything else | Considered as a middle ground, but the AI module's context assembly reads from every other domain's data just as heavily as the DFS calculation does — splitting it out would introduce the same cross-service consistency problem for exactly the feature most sensitive to fresh, consistent data |
| Serverless functions per endpoint | Would fragment the Service/Repository layering this doc set relies on for testability and coding standards ([Coding Standards](../coding-standards.md)), and complicates the queue/scheduler infrastructure Laravel provides natively ([Backend Architecture § 4 & § 6](../07-backend-architecture.md#4-queues)) |

## Pros
- Single-database consistency for cross-domain reads (DFS, AI context) without distributed-systems complexity.
- Faster iteration for a small team — one deployable, one CI pipeline, no service-mesh/inter-service-contract overhead.
- Module boundaries (`app/Modules/*`) still give the *option* to extract a module into a separate service later if scale demands it, without a full rewrite — the boundaries are real, just not yet deployment boundaries.

## Cons
- A single deployable means the whole backend scales as one unit at the infrastructure level (though queue workers already scale independently from the web tier, [Backend Architecture § 4](../07-backend-architecture.md#4-queues), partially mitigating this).
- Risk of module boundaries eroding over time without service-level enforcement (a microservice architecture forces boundary discipline via network calls; a monolith requires code-review discipline instead) — mitigated by the strict folder-per-module convention and PR review process in [Git Workflow](../git-workflow.md).

## Consequences
[System Architecture § ADR-1](../03-system-architecture.md#9-architectural-decision-records-summary) already names the reconsideration trigger; this ADR expands it. Every new feature is added as a module following [Backend Architecture § 1](../07-backend-architecture.md#1-folder-structure)'s pattern, keeping the "could become a microservice later" option live without paying its cost now.

## Future Review Criteria
Revisit if: the team grows beyond roughly 15 engineers (coordination overhead within one deployable starts to outweigh its benefits), or a specific module's scaling profile diverges sharply enough from the rest of the system (e.g., AI Coaching needing independent scaling/deployment cadence) that extraction becomes clearly justified — per the same trigger already stated in [System Architecture § 9](../03-system-architecture.md#9-architectural-decision-records-summary).
