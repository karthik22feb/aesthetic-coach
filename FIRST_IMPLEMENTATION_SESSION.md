# First Implementation Session

**The checklist for the first coding session on Aesthetic Coach.** Read this once, in full, before opening an editor or a Claude session for the first time. Every later session follows the lighter-weight [AI_DEVELOPMENT_GUIDE.md § How to Start a Claude Session](docs/AI_DEVELOPMENT_GUIDE.md#how-to-start-a-claude-session) instead — this document exists because session one has no prior git history, no running environment, and no established rhythm to fall back on.

---

## Table of Contents
- [Project Overview](#project-overview)
- [Current Status](#current-status)
- [Current Sprint](#current-sprint)
- [Current Module: Infrastructure](#current-module-infrastructure)
- [Objectives](#objectives)
- [Success Criteria](#success-criteria)
- [Required Documentation](#required-documentation)
- [Required Credentials](#required-credentials)
- [Required Software](#required-software)
- [Development Environment](#development-environment)
- [Estimated Session Duration](#estimated-session-duration)
- [Definition of Done](#definition-of-done)
- [Git Branch Name Recommendation](#git-branch-name-recommendation)
- [Expected Deliverables](#expected-deliverables)
- [Testing Requirements](#testing-requirements)
- [Next Session Preview](#next-session-preview)

## Project Overview

Aesthetic Coach is an AI-powered fitness tracking and personal coaching app — Flutter + Laravel + MySQL 8, with an AI Coaching Engine on the Claude API, shipping in two phases ([Phased Release Strategy](docs/PHASED_RELEASE_STRATEGY.md)). Full context: [README.md](README.md) → [PRD](docs/01-prd.md) → [System Architecture](docs/03-system-architecture.md).

## Current Status

**Planning Complete. Documentation Frozen (v1.0). Repository Ready. Implementation Pending.** See [PROJECT_STATUS.md](PROJECT_STATUS.md) and [VERSION_HISTORY.md](VERSION_HISTORY.md) for the full baseline this session builds on.

## Current Sprint

**Phase 1 · Sprint 1 — Infrastructure, Authentication & Project Setup** ([Development Roadmap](docs/16-development-roadmap.md#phase-1--sprint-1--infrastructure-authentication--project-setup))

## Current Module: Infrastructure

**Module 1 of 16** ([IMPLEMENTATION_ORDER.md § 1](docs/IMPLEMENTATION_ORDER.md#1-infrastructure)) — the first module of Phase 1. Nothing else in the project can start until this session's deliverables exist.

## Objectives

1. Scaffold the Laravel backend and Flutter mobile app.
2. Stand up the local Docker development environment.
3. Configure CI (lint + test skeleton) for both codebases.
4. Provision staging and deploy a health-check endpoint through the full pipeline end-to-end.

## Success Criteria

- [ ] `docker compose up` brings up app, MySQL 8, Redis, and Mailhog locally without manual intervention
- [ ] Both CI pipelines (backend, mobile) run and pass on a trivial commit
- [ ] A health-check endpoint is reachable on staging, deployed through the same pipeline production will use
- [ ] The folder structures in both codebases match [Backend Architecture § 1](docs/07-backend-architecture.md#1-folder-structure) and [Mobile Architecture § 2](docs/08-mobile-architecture.md#2-folder-organization) exactly — this is the template every later module builds on, so it's worth getting right now rather than retrofitting later

## Required Documentation

Have these open for this session, per [AI_DEVELOPMENT_GUIDE.md § Which Documentation Files to Include](docs/AI_DEVELOPMENT_GUIDE.md#which-documentation-files-to-include):

- [Backend Architecture § 1](docs/07-backend-architecture.md#1-folder-structure)
- [Mobile Architecture § 2](docs/08-mobile-architecture.md#2-folder-organization)
- [Deployment Guide § 2](docs/12-deployment-guide.md#2-development-environment)
- [CI/CD Pipeline](docs/11-cicd-pipeline.md)
- [Coding Standards](docs/coding-standards.md)
- [TASK_BREAKDOWN.md § Sprint 1, Tasks 1–8](docs/TASK_BREAKDOWN.md#sprint-1--infrastructure-authentication--project-setup) (this session covers infrastructure only — Tasks 1–8; Auth implementation, Tasks 9–20, is a separate session)

## Required Credentials

Full detail and configuration status: [INFRASTRUCTURE_READINESS.md](INFRASTRUCTURE_READINESS.md). For **this specific session**, you need:

- [ ] Git hosting access (push permission to the repository)
- [ ] Cloud/hosting provider account for staging (per [Deployment Guide § 3](docs/12-deployment-guide.md#3-staging--production-infrastructure))
- [ ] Container registry access, if deploying via pushed images

Not needed yet this session (needed later in Sprint 1): Google/Apple OAuth credentials, Claude API key, FCM/APNs credentials — see [INFRASTRUCTURE_READINESS.md](INFRASTRUCTURE_READINESS.md) for when each is actually required.

## Required Software

Full checklist: [INFRASTRUCTURE_READINESS.md](INFRASTRUCTURE_READINESS.md). Minimum for this session: PHP (matching [Backend Architecture](docs/07-backend-architecture.md) target version), Composer, Flutter SDK, Docker Desktop, Git, Node/npm (for frontend tooling), Laravel installer.

## Development Environment

Local only for this session — no staging secrets touch a developer machine. Follow [Deployment Guide § 2](docs/12-deployment-guide.md#2-development-environment) exactly for the `docker-compose.yml` shape (app, MySQL 8, Redis, Mailhog). Do not deviate from the documented service list without updating that doc in the same PR, per [Development Workflow § Documentation Updates](docs/DEVELOPMENT_WORKFLOW.md#documentation-updates).

## Estimated Session Duration

This module is rated **Complexity L** in [IMPLEMENTATION_ORDER.md § 1](docs/IMPLEMENTATION_ORDER.md#1-infrastructure) — expect this to span multiple sessions across [TASK_BREAKDOWN.md § Sprint 1, Tasks 1–8](docs/TASK_BREAKDOWN.md#sprint-1--infrastructure-authentication--project-setup), each individually a few hours, per [AI_DEVELOPMENT_GUIDE.md § How Much Context to Provide](docs/AI_DEVELOPMENT_GUIDE.md#how-much-context-to-provide). Do not try to complete all 8 tasks in one sitting — split per [AI_DEVELOPMENT_GUIDE.md § Splitting Large Features](docs/AI_DEVELOPMENT_GUIDE.md#splitting-large-features-into-multiple-prompts) if momentum tempts you to keep going past task 2–3.

## Definition of Done

Per [AI_DEVELOPMENT_GUIDE.md § Definition of Done](docs/AI_DEVELOPMENT_GUIDE.md#definition-of-done-before-moving-to-the-next-task), applied to this module specifically:

- [ ] All [Success Criteria](#success-criteria) above are met
- [ ] No unrequested scope was added (no Auth implementation yet — that's Sprint 1 Tasks 9+, a separate set of sessions)
- [ ] [MASTER_IMPLEMENTATION_PLAN.md § Module Progress](MASTER_IMPLEMENTATION_PLAN.md#module-progress) updated to reflect Infrastructure as complete
- [ ] [DEVELOPMENT_LOG.md](DEVELOPMENT_LOG.md) has its first entry
- [ ] [NEXT_TASK.md](NEXT_TASK.md) updated to point at Sprint 1, Task 9 (Auth migrations)

## Git Branch Name Recommendation

Per [Git Workflow § Branch Naming](docs/git-workflow.md#branch-naming) and [GIT_INITIALIZATION.md](GIT_INITIALIZATION.md):

```
feature/infrastructure-scaffold
```

Given the size of this module, consider one branch per [TASK_BREAKDOWN.md](docs/TASK_BREAKDOWN.md) task (e.g., `feature/infra-docker-compose`, `feature/infra-ci-backend`) rather than one large branch for the whole module — smaller, faster-reviewed PRs per [Git Workflow § Code Reviews](docs/git-workflow.md#code-reviews).

## Expected Deliverables

- Laravel project with `app/Modules/*` scaffold (empty `Auth` module only — no logic yet)
- Flutter project with `lib/{app,core,features,shared}` scaffold and a placeholder 5-tab shell
- `docker-compose.yml` at repo root
- `.github/workflows/*` (or equivalent) for both backend and mobile CI
- Staging environment provisioned, health-check endpoint live

## Testing Requirements

Per [Development Workflow § Testing Requirements](docs/DEVELOPMENT_WORKFLOW.md#testing-requirements) — for infrastructure specifically:

- [ ] CI itself is the primary test artifact this session — a red CI run on a trivial commit means the pipeline isn't correctly configured yet
- [ ] A basic health-check test exists and passes (confirms the test runner itself works, not just that the app boots)

## Next Session Preview

After this module: **Sprint 1, Tasks 9–20 — Authentication** ([TASK_BREAKDOWN.md § Sprint 1](docs/TASK_BREAKDOWN.md#sprint-1--infrastructure-authentication--project-setup), [Authentication feature](docs/features/authentication.md)). This is security-critical work (refresh-token rotation and reuse detection) — read [ADR-0005](docs/adr/0005-jwt-refresh-token-auth.md) before starting it. [NEXT_TASK.md](NEXT_TASK.md) will be updated to point there once this module's Definition of Done is met.
