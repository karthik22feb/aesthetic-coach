# Aesthetic Coach

**Aesthetic Coach** is an AI-powered fitness tracking and personal coaching mobile application. It combines workout tracking, nutrition guidance, recovery tracking, body measurements, habit tracking, a daily fitness score, goal planning, smart recommendations, progress analytics, gamification, wearable integrations, and an AI coaching engine built on the Claude API — into a single modular, scalable ecosystem.

This repository contains the **complete blueprint** for the application: product strategy, system architecture, database design, API contracts, design system, backend and mobile architecture, the AI coaching engine, testing, CI/CD, deployment, monitoring, security hardening, and user-facing documentation — plus feature-level specs, screen-level specs, a component library, an AI prompt library, worked API examples, and architecture decision records.

> **Status:** Documentation / planning phase. No application code has been written yet. This documentation is intended to be complete and precise enough that an experienced engineering team could implement the product from these documents alone.

> **Start here:** [NEXT_TASK.md](NEXT_TASK.md) always holds exactly one actionable task; copy [CLAUDE_SESSION_TEMPLATE.md](CLAUDE_SESSION_TEMPLATE.md) and fill it in with that task to actually run the session — this is the standard starting point for every implementation session from here forward. [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md) is the fuller control-center document for phase/sprint status and everything else.

---

## Release Strategy

Aesthetic Coach ships in **two public release phases**, not one big-bang launch — see [Phased Release Strategy](docs/PHASED_RELEASE_STRATEGY.md) for the full rationale.

- **Phase 1 — Intelligent Fitness Platform:** the production-ready MVP. Core tracking (workouts, nutrition, body metrics, habits, goals) plus targeted, single-purpose AI utilities (workout generation, exercise guidance, AI-generated progress summaries). This is what ships to app stores first. Full scope: [PHASE1_SCOPE.md](docs/PHASE1_SCOPE.md).
- **Phase 2 — AI Personal Coach:** begins only after Phase 1 launches successfully. Evolves the same app into a full conversational AI coaching platform — multi-persona chat, nutrition/recovery/habit coaching, long-term memory, predictive coaching, wearable integrations — built on the real user history Phase 1 collects. Full scope: [PHASE2_SCOPE.md](docs/PHASE2_SCOPE.md).

The underlying architecture, database schema, API design, Flutter app, and Laravel backend documented throughout this repository already support both phases without redesign — [Database Design § 10](docs/04-database-design.md#10-phased-implementation--architecture-validation) confirms this explicitly. Every feature spec, API endpoint, and AI capability across this repository is now tagged with its release phase — see [PHASE1_SCOPE.md](docs/PHASE1_SCOPE.md) and [PHASE2_SCOPE.md](docs/PHASE2_SCOPE.md) for the full allocation, and [Development Roadmap](docs/16-development-roadmap.md) for the sprint-by-sprint build sequence.

---

## Technology Stack Summary

| Layer | Choice | Notes |
|---|---|---|
| Mobile | Flutter (latest stable) | Android + iOS from one codebase — [ADR-0001](docs/adr/0001-flutter-for-mobile.md) |
| Mobile state management | Riverpod (code-gen, `flutter_riverpod` + `riverpod_generator`) | [Mobile Architecture § 1](docs/08-mobile-architecture.md#1-state-management) · [ADR-0004](docs/adr/0004-riverpod-for-state-management.md) |
| Local storage | Drift (typed SQL over SQLite) | [ADR-0008](docs/adr/0008-drift-for-local-storage.md) |
| Backend | Laravel (latest stable) | REST API, queues, scheduler, events, notifications — [ADR-0002](docs/adr/0002-laravel-for-backend.md) |
| Backend structure | Modular monolith | [ADR-0009](docs/adr/0009-modular-monolith.md) |
| Database | MySQL 8 | [Database Design](docs/04-database-design.md) · [ADR-0003](docs/adr/0003-mysql8-for-database.md) |
| Auth | JWT access token + rotating refresh token, Google Sign-In, Apple Sign-In | [System Architecture § Security](docs/03-system-architecture.md#8-security-architecture) · [ADR-0005](docs/adr/0005-jwt-refresh-token-auth.md) |
| AI Engine | Claude API (Anthropic), provider-abstracted | [AI Coaching Engine](docs/09-ai-coaching-engine.md) · [ADR-0006](docs/adr/0006-claude-ai-primary-provider.md) |
| Mobile data strategy | Offline-first | [ADR-0007](docs/adr/0007-offline-first-architecture.md) |
| Infra | Docker, Nginx, Redis, MySQL 8, S3-compatible object storage | [Deployment Guide](docs/12-deployment-guide.md) |
| CI/CD | GitHub Actions | [CI/CD Pipeline](docs/11-cicd-pipeline.md) |

---

## Document Index

### Product & Requirements
1. [Product Requirements Document (PRD)](docs/01-prd.md) — vision, personas, competitive analysis, roadmap, MVP scope
2. [Software Requirements Specification (SRS)](docs/02-srs.md) — detailed functional/non-functional requirements, business rules, acceptance criteria

### Architecture & Design
3. [System Architecture](docs/03-system-architecture.md) — high-level architecture, diagrams, deployment topology, scalability, security
4. [Database Design](docs/04-database-design.md) — ER diagrams, full schema, indexing, migration & backup strategy
5. [API Specification](docs/05-api-specification.md) — REST endpoints, auth flow, request/response contracts, OpenAPI outline
6. [UI/UX Design System](docs/06-ui-ux-design-system.md) — design philosophy, tokens, components, dark/light mode, accessibility

### Implementation Architecture
7. [Backend Architecture](docs/07-backend-architecture.md) — Laravel modules, services, jobs, coding standards
8. [Mobile Architecture](docs/08-mobile-architecture.md) — Flutter structure, state management, offline-first, sync
9. [AI Coaching Engine](docs/09-ai-coaching-engine.md) — prompt management, memory strategy, provider abstraction, guardrails

### Quality & Operations
10. [Testing Strategy](docs/10-testing-strategy.md) — unit, integration, widget, API, performance, security testing
11. [CI/CD Pipeline](docs/11-cicd-pipeline.md) — branching strategy, pipelines, release management
12. [Deployment Guide](docs/12-deployment-guide.md) — environments, Docker, Nginx, SSL, rollback
13. [Monitoring & Logging](docs/13-monitoring-logging.md) — observability stack, alerting, crash reporting
14. [Production Hardening](docs/14-production-hardening.md) — security checklist, secrets, DR, compliance
15. [User Documentation](docs/15-user-documentation.md) — onboarding, user guide, FAQ, admin docs

### Delivery Plan
16. [Development Roadmap](docs/16-development-roadmap.md) — milestone/sprint-driven roadmap for both release phases, dependencies, risks, suggested implementation prompts

### Release Planning
- [Phased Release Strategy](docs/PHASED_RELEASE_STRATEGY.md) — master reference: vision, business/technical justification, benefits, risks, success metrics, deployment strategy, timeline, exit criteria for each phase
- [PHASE1_SCOPE.md](docs/PHASE1_SCOPE.md) — the implementation contract for Version 1: every Phase 1 feature with priority, dependencies, complexity, sprint, and acceptance criteria
- [PHASE2_SCOPE.md](docs/PHASE2_SCOPE.md) — every advanced AI coaching capability, with rationale, Phase 1 data dependency, and technical considerations
- [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md) — the control-center document; open this first in any new session

### Detailed Specifications
- [Feature Specifications](docs/features/) — one document per major feature (22 total): functional/non-functional requirements, UI flow, business rules, APIs, database tables, edge cases, offline behavior, acceptance criteria for each of Authentication, Onboarding, Dashboard, Profile, Workout Tracking, Workout History, Exercise Library, Exercise Details, Nutrition, Calorie Tracker, Water Intake, Body Measurements, Progress Photos, Goals, Habits, AI Coach, Notifications, Achievements, Challenges *(Future)*, Subscriptions *(Future, unscoped)*, Settings, Wearable Integrations *(Future)*
- [Screen Specifications](docs/screens/) — layout, components, navigation, states, and accessibility for each of the 10 primary screens: Splash, Login, Signup, Dashboard, Workout, AI Coach, Profile, Analytics, Nutrition, Settings
- [Component Library](docs/components/) — purpose, variants, states, properties, accessibility, and Flutter implementation notes for the 12 core reusable UI components (Button, Card, Charts, Progress Ring, Workout Tile, AI Chat Bubble, Text Field, Modal, Bottom Sheet, Dialog, Badge, Progress Bar)
- [AI Prompt Library](docs/ai/) — the actual system/user prompt templates behind every coaching persona and AI capability, versioned and cross-referenced to [AI Coaching Engine](docs/09-ai-coaching-engine.md)
- [API Contract Examples](docs/api-examples/) — realistic request/response/error payloads for every endpoint, organized by domain, covering all 7 response categories (success, validation error, unauthorized, forbidden, rate limited, conflict, internal error)
- [Architecture Decision Records](docs/adr/) — the *why* behind the 10 foundational technology/architecture choices

### Engineering Process & Operations Reference
- [Database Seeding Strategy](docs/database-seeding.md) — what's seeded in dev/testing/staging/production, and what must never be seeded into production
- [Coding Standards](docs/coding-standards.md) — Laravel and Flutter line-level style guide, SOLID/DRY/Clean Code principles, commenting guidelines
- [Git Workflow](docs/git-workflow.md) — branch naming, Conventional Commits, code review, merge strategy, hotfix process
- [Release Management](docs/release-management.md) — release process, semantic versioning, changelog format, rollback, deployment approvals
- [Analytics & Events](docs/analytics-events.md) — the full product analytics event taxonomy and privacy considerations
- [Permissions Matrix](docs/permissions-matrix.md) — CRUD access per role (MVP has one real role; others are Future scaffolding, clearly flagged)
- [Future Integrations](docs/future-integrations.md) — Apple Health, Health Connect, Fitbit, Garmin, Strava, smart watches/scales, calendar, additional AI providers
- [Performance Budget](docs/performance-budget.md) — measurable engineering targets for startup, rendering, API/AI latency, battery, memory, network, and animation

### Execution Framework
- [Implementation Order](docs/IMPLEMENTATION_ORDER.md) — the 16-module build order with objectives, dependencies, and Definition of Done per module
- [Task Breakdown](docs/TASK_BREAKDOWN.md) — every Phase 1 sprint broken into hour-scale tasks
- [Module Dependencies](docs/MODULE_DEPENDENCIES.md) — dependency graphs, critical path, bottlenecks
- [Development Backlog](docs/DEVELOPMENT_BACKLOG.md) — MVP, post-launch, and Phase 2 items with priority/effort/value/risk
- [Release Checklist](docs/RELEASE_CHECKLIST.md) — production readiness checklist (backend, mobile, security, QA, app store)
- [Development Workflow](docs/DEVELOPMENT_WORKFLOW.md) — day-to-day git/PR/release process, feature/bug/hotfix workflows
- [AI Development Guide](docs/AI_DEVELOPMENT_GUIDE.md) — how to run Claude implementation sessions on this repository
- [Git Initialization Guide](GIT_INITIALIZATION.md) — repository setup, branch/tag scheme, reconciled with Git Workflow
- [Infrastructure Readiness Checklist](INFRASTRUCTURE_READINESS.md) — every credential/tool/account needed before coding starts

### Operational Control Documents
- [PROJECT_STATUS.md](PROJECT_STATUS.md) — the official project status dashboard (lifecycle status, risks, open decisions)
- [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md) — the control-center document; open this first in any new session
- [NEXT_TASK.md](NEXT_TASK.md) — always exactly one actionable task, the fastest way into a session
- [CLAUDE_SESSION_TEMPLATE.md](CLAUDE_SESSION_TEMPLATE.md) — the standard template every implementation session is run from
- [Development Log](DEVELOPMENT_LOG.md) — the append-only engineering journal, one entry per session
- [Implementation Progress](IMPLEMENTATION_PROGRESS.md) — dated Started/Completed tracker for every module
- [First Implementation Session](FIRST_IMPLEMENTATION_SESSION.md) — the pre-flight checklist for session one specifically
- [Sprint 1, Day 1 Checklist](SPRINT1_DAY1_CHECKLIST.md) — the concise, daily-reference checklist to run before any session
- [Version History](VERSION_HISTORY.md) — the official documentation release history
- [Engineering Decision Log](ENGINEERING_DECISION_LOG.md) — chronological record of implementation-level engineering decisions (not a replacement for ADRs)

---

## How to Use This Repository

Suggested reading paths by role — each path lists documents roughly in the order they're most useful, not an exhaustive list of everything relevant to that role.

**Product Manager**
[PRD](docs/01-prd.md) → [SRS](docs/02-srs.md) → [Feature Specifications](docs/features/) → [Development Roadmap](docs/16-development-roadmap.md) → [Analytics & Events](docs/analytics-events.md) → [Permissions Matrix](docs/permissions-matrix.md) (note the Subscriptions/monetization gap flagged there)

**UI/UX Designer**
[UI/UX Design System](docs/06-ui-ux-design-system.md) → [Screen Specifications](docs/screens/) → [Component Library](docs/components/) → [Feature Specifications](docs/features/) (for UI flow/business rules context) → [Performance Budget § Animation Frame Rate](docs/performance-budget.md#animation-frame-rate)

**Backend Developer (Laravel)**
[System Architecture](docs/03-system-architecture.md) → [Database Design](docs/04-database-design.md) → [API Specification](docs/05-api-specification.md) → [Backend Architecture](docs/07-backend-architecture.md) → [Coding Standards § Laravel](docs/coding-standards.md#laravel-standards) → [API Contract Examples](docs/api-examples/) → [Database Seeding Strategy](docs/database-seeding.md)

**Flutter Developer**
[API Specification](docs/05-api-specification.md) → [UI/UX Design System](docs/06-ui-ux-design-system.md) → [Mobile Architecture](docs/08-mobile-architecture.md) → [Screen Specifications](docs/screens/) → [Component Library](docs/components/) → [Coding Standards § Flutter](docs/coding-standards.md#flutter-standards) → [ADR-0004](docs/adr/0004-riverpod-for-state-management.md), [ADR-0007](docs/adr/0007-offline-first-architecture.md), [ADR-0008](docs/adr/0008-drift-for-local-storage.md)

**AI Engineer**
[AI Coaching Engine](docs/09-ai-coaching-engine.md) → [AI Prompt Library](docs/ai/) → [AI Coach feature](docs/features/ai-coach.md) → [API Contract Examples — AI Coaching](docs/api-examples/ai-coaching.md) → [ADR-0006](docs/adr/0006-claude-ai-primary-provider.md) → [AI Development Guide](docs/AI_DEVELOPMENT_GUIDE.md) (once actually implementing AI features via Claude sessions)

**DevOps / SRE**
[GIT_INITIALIZATION.md](GIT_INITIALIZATION.md) → [INFRASTRUCTURE_READINESS.md](INFRASTRUCTURE_READINESS.md) → [CI/CD Pipeline](docs/11-cicd-pipeline.md) → [Deployment Guide](docs/12-deployment-guide.md) → [Monitoring & Logging](docs/13-monitoring-logging.md) → [Production Hardening](docs/14-production-hardening.md) → [Release Management](docs/release-management.md) → [Git Workflow](docs/git-workflow.md) → [Performance Budget](docs/performance-budget.md)

**QA Engineer**
[SRS § Acceptance Criteria Format](docs/02-srs.md#7-acceptance-criteria-format) → [Testing Strategy](docs/10-testing-strategy.md) → [Feature Specifications](docs/features/) (every feature ends with Gherkin-style acceptance criteria) → [API Contract Examples](docs/api-examples/) → [Performance Budget](docs/performance-budget.md)

**New Team Member (any discipline)**
This README → [PROJECT_STATUS.md](PROJECT_STATUS.md) (where the project actually stands right now) → [PRD](docs/01-prd.md) → [System Architecture](docs/03-system-architecture.md) → [Development Roadmap](docs/16-development-roadmap.md) → then follow your discipline's path above. Picking up an implementation task specifically? Skip straight to [NEXT_TASK.md](NEXT_TASK.md) and [CLAUDE_SESSION_TEMPLATE.md](CLAUDE_SESSION_TEMPLATE.md) instead.

---

## Document Conventions

- All diagrams use [Mermaid](https://mermaid.js.org/) syntax and render natively on GitHub and most Markdown viewers.
- Every feature is tagged **[MVP]** or **[Future]** to distinguish the first shippable release from later phases. A small number of Future items (notably [Subscriptions](docs/features/subscriptions.md) and [Challenges](docs/features/challenges.md)) are explicitly flagged as **not yet scoped by Product** — these are placeholder drafts, not approved specs.
- Database identifiers use `snake_case`; API JSON payloads use `camelCase` (translated at the API Resource layer — see [Backend Architecture](docs/07-backend-architecture.md)).
- Cross-references use relative Markdown links between documents. Every new document added in this pass links back to at least one of the original 16 core documents and to its sibling documents where relevant, so the doc set reads as one connected graph rather than a flat file list.
- "Documentation is living": any architectural decision made during implementation that contradicts a document here should update that document in the same PR — see [Development Roadmap § Cross-Phase Notes](docs/16-development-roadmap.md#cross-phase-notes) and [Git Workflow § Pull Requests](docs/git-workflow.md#pull-requests).
