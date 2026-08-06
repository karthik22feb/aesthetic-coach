# Next Task

**This file always contains exactly one actionable development task — the next thing to do, right now.** Claude updates this file at the end of every development session per [AI_DEVELOPMENT_GUIDE.md § Definition of Done](docs/AI_DEVELOPMENT_GUIDE.md#definition-of-done-before-moving-to-the-next-task). Read this file first, before [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md), when picking up work — it's the single-task version of that document's broader tracker.

**To actually start the session:** copy [CLAUDE_SESSION_TEMPLATE.md](CLAUDE_SESSION_TEMPLATE.md) and fill in its Session Information, Objective, and other sections using the task below.

---

## Task

**Create the Laravel project and scaffold the `app/Modules/*` structure.**

## Context

- Module: [Infrastructure (Module 1)](docs/IMPLEMENTATION_ORDER.md#1-infrastructure)
- Sprint: [Phase 1 · Sprint 1 — Infrastructure, Authentication & Project Setup](docs/16-development-roadmap.md#phase-1--sprint-1--infrastructure-authentication--project-setup)
- Task reference: [TASK_BREAKDOWN.md § Sprint 1, Task 1](docs/TASK_BREAKDOWN.md#sprint-1--infrastructure-authentication--project-setup)
- This is the first task of the first module of Phase 1 — nothing else in the repository has started yet (see [PROJECT_STATUS.md](PROJECT_STATUS.md)).

## Primary Documents

- [Backend Architecture § 1 Folder Structure](docs/07-backend-architecture.md#1-folder-structure)
- [Coding Standards § Laravel Standards](docs/coding-standards.md#laravel-standards)

## Definition of Done

- [ ] Laravel project created (latest stable version)
- [ ] `app/Modules/*` directory structure scaffolded per [Backend Architecture § 1](docs/07-backend-architecture.md#1-folder-structure), including the `Shared/` and `Providers/` folders and the `ModuleServiceProvider` auto-discovery pattern
- [ ] An empty `Auth` module exists as the first module (structure only — implementation is Task 9+ in the same sprint)
- [ ] Project builds and runs locally

## After Completing This Task

1. Confirm the Definition of Done above is fully met — see [AI_DEVELOPMENT_GUIDE.md § Definition of Done](docs/AI_DEVELOPMENT_GUIDE.md#definition-of-done-before-moving-to-the-next-task).
2. Update [MASTER_IMPLEMENTATION_PLAN.md](MASTER_IMPLEMENTATION_PLAN.md)'s Sprint Tracker / Module Progress.
3. Replace this file's **Task**, **Context**, **Primary Documents**, and **Definition of Done** with the *next* task — [TASK_BREAKDOWN.md § Sprint 1, Task 2](docs/TASK_BREAKDOWN.md#sprint-1--infrastructure-authentication--project-setup) ("Configure Docker") — following the same structure as this entry.
4. Update the **Last updated** line below.

---

**Last updated:** 2026-08-06 · **Session:** Initial task set (pre-implementation) · **Status:** Not started
