# Development Workflow

**Product:** Aesthetic Coach
**Purpose:** the day-to-day process for turning a [TASK_BREAKDOWN.md](TASK_BREAKDOWN.md) item into merged, released code. This document is the narrative "how the day goes" layer; [Git Workflow](git-workflow.md), [Coding Standards](coding-standards.md), and [Release Management](release-management.md) remain the authoritative reference for conventions this document only summarizes and links to.
**Related documents:** [Git Workflow](git-workflow.md) · [Coding Standards](coding-standards.md) · [Release Management](release-management.md) · [Testing Strategy](10-testing-strategy.md) · [AI_DEVELOPMENT_GUIDE.md](AI_DEVELOPMENT_GUIDE.md)

## Table of Contents
- [Git Flow](#git-flow)
- [Branch Strategy](#branch-strategy)
- [Code Reviews](#code-reviews)
- [Commit Standards](#commit-standards)
- [Testing Requirements](#testing-requirements)
- [Merge Rules](#merge-rules)
- [Documentation Updates](#documentation-updates)
- [When to Record an Engineering Decision](#when-to-record-an-engineering-decision)
- [Release Process](#release-process)
- [Feature Workflow](#feature-workflow)
- [Bug Workflow](#bug-workflow)
- [Hotfix Workflow](#hotfix-workflow)

## Git Flow

Trunk-based, per [Git Workflow](git-workflow.md#branch-naming) and [CI/CD Pipeline § 1](11-cicd-pipeline.md#1-git-workflow--branching-strategy): `main` is always deployable, feature branches are short-lived (target < 3 days open), no long-lived `develop` branch. Deploys to staging automatically on merge to `main`; production deploys are tag-triggered and manually approved.

## Branch Strategy

Full convention: [Git Workflow § Branch Naming](git-workflow.md#branch-naming). Quick reference:

| Prefix | Use |
|---|---|
| `feature/` | New functionality — see [Feature Workflow](#feature-workflow) |
| `fix/` | Bug fix — see [Bug Workflow](#bug-workflow) |
| `hotfix/` | Urgent production fix — see [Hotfix Workflow](#hotfix-workflow) |
| `chore/`, `docs/` | Tooling, dependencies, documentation-only |

## Code Reviews

Full convention: [Git Workflow § Code Reviews](git-workflow.md#code-reviews). One approver for standard changes, two for auth/migrations/payments. Reviewers check correctness first, then [Coding Standards](coding-standards.md) adherence, then style (style nitpicks not already caught by Pint/`dart format` are optional, non-blocking comments). Same-business-day turnaround target.

**When reviewing AI-assisted code specifically** (see [AI_DEVELOPMENT_GUIDE.md § How to Review Generated Code](AI_DEVELOPMENT_GUIDE.md#how-to-review-generated-code)): review it exactly as you would human-written code — against the spec it claims to implement, not against "does this look plausible." Claude-generated code that compiles and passes tests can still implement the wrong acceptance criteria if the prompt was underspecified.

## Commit Standards

Conventional Commits, full spec: [Git Workflow § Conventional Commits](git-workflow.md#conventional-commits). Format: `type(scope): description`. Squash-merged, so the PR title *is* the commit message — get it right before merge, not after.

## Testing Requirements

Every PR must satisfy the tier of the [Testing Checklist](../MASTER_IMPLEMENTATION_PLAN.md#testing-checklist) relevant to what it touches — at minimum, unit tests for new Service/Notifier logic and an API Feature test for any new/changed endpoint, per [Testing Strategy](10-testing-strategy.md). CI blocks merge on lint, static analysis, and the automated test suite per [CI/CD Pipeline § 4](11-cicd-pipeline.md#4-automated-testing-ci-gates) — a red CI run is never overridden to merge.

## Merge Rules

Squash-merge only, per [Git Workflow § Merge Strategy](git-workflow.md#merge-strategy) — one commit per PR on `main`, full discussion preserved on the PR itself. No merge commits, no rebase-merge.

## Documentation Updates

Per [Development Roadmap § Cross-Phase Notes](16-development-roadmap.md#cross-phase-notes) ("documentation is living") and [PROJECT_STATUS.md § Change Management Process](../PROJECT_STATUS.md#change-management-process):

- **A frozen v1.0 document turns out to be wrong or incomplete once you implement against it** → fix it in the *same PR* as the code change. This is expected and normal, not a process violation.
- **A genuinely new scope/architecture decision is made** → update the relevant scope document ([PHASE1_SCOPE.md](PHASE1_SCOPE.md), [PHASE2_SCOPE.md](PHASE2_SCOPE.md), [DEVELOPMENT_BACKLOG.md](DEVELOPMENT_BACKLOG.md)) or add an [ADR](adr/), don't let the code silently diverge from the docs.
- **A task completes** → update [MASTER_IMPLEMENTATION_PLAN.md § Sprint Tracker / Feature Completion Checklist](../MASTER_IMPLEMENTATION_PLAN.md#sprint-tracker) in the same PR or immediately after, so the tracker never lags reality by more than one merged PR.

## When to Record an Engineering Decision

Not every choice made during implementation needs a record — but some are worth capturing so the next session (or the next engineer) doesn't have to rediscover the reasoning. Record an entry in [ENGINEERING_DECISION_LOG.md](../ENGINEERING_DECISION_LOG.md) — using the template defined there, not repeated here — when a session involves:

- **An implementation trade-off** (e.g., choosing eventual consistency over a stronger guarantee for a specific query, accepting a simpler-but-less-flexible approach under time pressure)
- **A package replacement** (swapping a library named or implied in the docs for a different one, or picking a specific package where the docs left the choice open)
- **A performance optimization** that changes how something is built, not just a tuning parameter (e.g., introducing a cache layer, denormalizing a query path)
- **A security improvement** beyond what [Production Hardening](14-production-hardening.md) already mandates
- **An unexpected technical limitation** discovered mid-implementation (a framework constraint, a third-party API behavior that doesn't match its docs, a platform-specific quirk) and how it was worked around

This is distinct from [Documentation Updates](#documentation-updates) above: a spec gap gets *the spec itself* corrected; an implementation-level decision that doesn't change the spec but is still worth remembering gets a log entry instead. If a decision turns out to have architectural weight (it changes a technology choice or a documented module boundary), it needs a real [ADR](adr/), not just a log entry — see [ENGINEERING_DECISION_LOG.md § Purpose](../ENGINEERING_DECISION_LOG.md#purpose) for that distinction.

## Release Process

Full detail: [Release Management](release-management.md). Summary: `main` (green CI) → auto-deploy staging → smoke test → annotated tag → manual approval → production. Backend and mobile share a version tag but release on independent timelines (mobile gated by store review).

## Feature Workflow

For a new [TASK_BREAKDOWN.md](TASK_BREAKDOWN.md) item or backlog feature:

1. **Confirm the spec exists and is current** — every feature has a doc under [`docs/features/`](features/) with acceptance criteria; if the task doesn't map cleanly to an existing spec, stop and clarify before writing code (see [AI_DEVELOPMENT_GUIDE.md § How to Avoid Context Drift](AI_DEVELOPMENT_GUIDE.md#how-to-avoid-context-drift)).
2. Branch `feature/<short-description>` from `main`.
3. Implement against the spec, following [Coding Standards](coding-standards.md) and the layering in [Backend Architecture § 2](07-backend-architecture.md#2-layering--responsibilities) / [Mobile Architecture](08-mobile-architecture.md).
4. Write tests per [Testing Requirements](#testing-requirements) — ideally alongside the implementation, not after.
5. Self-review against the feature's own **Acceptance Criteria** section before opening the PR.
6. Open a PR following [Git Workflow § Pull Requests](git-workflow.md#pull-requests) (links the spec, states what changed and why, testing performed).
7. Address review feedback, get approval, squash-merge.
8. Update [MASTER_IMPLEMENTATION_PLAN.md](../MASTER_IMPLEMENTATION_PLAN.md) per [Documentation Updates](#documentation-updates) above.

## Bug Workflow

1. **Reproduce and classify** — is this a spec gap (the docs describe the wrong behavior) or an implementation bug (the code doesn't match the spec)? This determines whether the fix PR also touches `docs/`.
2. Branch `fix/<short-description>` from `main`.
3. Write a failing test that reproduces the bug *before* fixing it — this is what turns a one-off fix into a permanent regression guard.
4. Fix the bug; confirm the new test passes and no existing tests regressed.
5. If the bug revealed a genuine spec gap, correct the relevant document in the same PR per [Documentation Updates](#documentation-updates).
6. Standard PR/review/merge per [Feature Workflow](#feature-workflow) steps 6–8, with the PR description noting root cause, not just the symptom fixed.

## Hotfix Workflow

For a production-breaking issue that cannot wait for the normal cycle — full process: [Git Workflow § Hotfix Process](git-workflow.md#hotfix-process). Summary: branch `hotfix/<description>` from the currently-deployed production tag (not `main`), fix with the same test-first discipline as [Bug Workflow](#bug-workflow), expedited single-reviewer approval, tag and deploy immediately through the standard (but expedited) [Deployment Guide](12-deployment-guide.md) approval gate, then merge back to `main`. Always followed by a brief root-cause note, per [Git Workflow § Hotfix Process](git-workflow.md#hotfix-process) step 5.
