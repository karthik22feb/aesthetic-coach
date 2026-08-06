# Git Initialization Guide

**How to initialize the Aesthetic Coach repository for implementation.** This document operationalizes the branching, commit, and release conventions already frozen in [Git Workflow](docs/git-workflow.md) and [Release Management](docs/release-management.md) — it does not define new conventions, it applies them to the specific, one-time act of standing up the repository. See [Reconciliation Note](#reconciliation-note) below for one place this document's tag scheme is more precise than a literal reading of a generic git-init template would suggest.

---

## Table of Contents
- [Initial Repository Setup](#initial-repository-setup)
- [Recommended Branches](#recommended-branches)
- [Recommended Initial Tags](#recommended-initial-tags)
- [Future Tags](#future-tags)
- [Commit Convention](#commit-convention)
- [Branch Naming Convention](#branch-naming-convention)
- [Merge Policy](#merge-policy)
- [Release Policy](#release-policy)
- [Reconciliation Note](#reconciliation-note)

## Initial Repository Setup

1. `git init` (or clone from an already-created empty remote — either order works).
2. Add a `.gitignore` appropriate to both codebases before the first commit (Laravel: `vendor/`, `.env`, `storage/*.key`; Flutter: `build/`, `.dart_tool/`, platform-specific ignores) — per [Production Hardening § Secrets Management](docs/14-production-hardening.md#3-encryption--secrets-management), `.env` must never be committed.
3. First commit: the documentation baseline itself (all 117 files as of [VERSION_HISTORY.md § Version 1.0](VERSION_HISTORY.md#version-10--documentation-baseline)). Commit message: `docs: initial v1.0 documentation baseline` per [Commit Convention](#commit-convention).
4. Push to `main` on the remote. `main` is the only long-lived branch from this point forward, per [Git Workflow § Branch Naming](docs/git-workflow.md#branch-naming) — there is no separate initialization step for other branches; they're created per-feature as work begins.
5. Apply branch protection on `main`: require CI green and at least one approving review before merge, per [Git Workflow § Pull Requests](docs/git-workflow.md#pull-requests) — configure this as part of [Infrastructure module](docs/IMPLEMENTATION_ORDER.md#1-infrastructure), once CI itself exists to protect against.
6. Apply the first tag: [`v1.0.0-docs-freeze`](#recommended-initial-tags).

## Recommended Branches

Per the already-established [Git Workflow § Branch Naming](docs/git-workflow.md#branch-naming) — **trunk-based, no long-lived `develop` branch** (a deliberate choice, not an oversight; see [Reconciliation Note](#reconciliation-note)):

| Branch | Long-lived? | Purpose |
|---|---|---|
| `main` | Yes — the only one | Always deployable; auto-deploys to staging on merge |
| `feature/*` | No — short-lived | New functionality, per [Development Workflow § Feature Workflow](docs/DEVELOPMENT_WORKFLOW.md#feature-workflow) |
| `fix/*` | No — short-lived | Bug fixes, per [Development Workflow § Bug Workflow](docs/DEVELOPMENT_WORKFLOW.md#bug-workflow) |
| `chore/*`, `docs/*` | No — short-lived | Tooling, dependencies, documentation-only changes |
| `hotfix/*` | No — short-lived | Urgent production fixes, branched from the production tag not `main`, per [Development Workflow § Hotfix Workflow](docs/DEVELOPMENT_WORKFLOW.md#hotfix-workflow) |

No `develop` branch and no `bugfix/*` prefix (the established convention uses `fix/`) — see [Reconciliation Note](#reconciliation-note) for why.

## Recommended Initial Tags

**`v1.0.0-docs-freeze`** — applied to the first commit (the documentation baseline). This is a semver **pre-release** identifier (the `-docs-freeze` suffix), which sorts before the plain `v1.0.0` release under semantic versioning rules — meaning it correctly reserves `v1.0.0` itself for the actual Phase 1 public launch tag, exactly as already established in [Release Management](docs/release-management.md), [PHASE1_SCOPE.md](docs/PHASE1_SCOPE.md), and [RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md).

## Future Tags

Milestone checkpoint tags during Phase 1 implementation, each a pre-release of the eventual `v1.0.0` launch — **not** MINOR version bumps (which would collide with `v1.0.0` meaning "Phase 1 launch" everywhere else in this repository; see [Reconciliation Note](#reconciliation-note)):

| Tag | Milestone |
|---|---|
| `v1.0.0-docs-freeze` | Documentation baseline (this initialization) |
| `v1.0.0-infrastructure` | [Module 1: Infrastructure](docs/IMPLEMENTATION_ORDER.md#1-infrastructure) complete |
| `v1.0.0-auth` | [Module 2: Authentication](docs/IMPLEMENTATION_ORDER.md#2-authentication) complete |
| `v1.0.0-workout-engine` | [Module 6: Workout Engine](docs/IMPLEMENTATION_ORDER.md#6-workout-engine) complete (offline sync validated) |
| `v1.0.0-tracking` | [Module 9: Progress Tracking](docs/IMPLEMENTATION_ORDER.md#9-progress-tracking) + [Module 10: Habits](docs/IMPLEMENTATION_ORDER.md#10-habits) complete |
| `v1.0.0-ai` | [Module 13: AI Recommendations](docs/IMPLEMENTATION_ORDER.md#13-ai-recommendations) complete |
| `v1.0.0-rc1` | [Module 14: Testing](docs/IMPLEMENTATION_ORDER.md#14-testing) complete — feature-complete, hardening pass done |
| `v1.0.0` | **Public launch** — [Module 16: Production Launch](docs/IMPLEMENTATION_ORDER.md#16-production-launch), per [RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md) sign-off |
| `v1.1.0`, `v1.2.0`, ... | Post-launch minor releases per [DEVELOPMENT_BACKLOG.md § Post-Launch Improvements](docs/DEVELOPMENT_BACKLOG.md#post-launch-improvements), following normal [Release Management § Semantic Versioning](docs/release-management.md#semantic-versioning) rules from this point forward |
| `v2.0.0` | Phase 2 — full Conversational Coach launch, per [Development Roadmap § Phase 2 · Sprint 6](docs/16-development-roadmap.md#phase-2--sprint-6--testing-hardening--phase-2-launch) |

Not every module needs its own tag — tag at meaningful checkpoints (roughly: end of each Sprint, per [Development Roadmap](docs/16-development-roadmap.md)), not after every single module.

## Commit Convention

Conventional Commits, full spec: [Git Workflow § Conventional Commits](docs/git-workflow.md#conventional-commits). Format: `type(scope): description` — `feat`, `fix`, `chore`, `docs`, `refactor`, `test`, `perf`. Squash-merged, so the PR title *is* the eventual commit message on `main`.

## Branch Naming Convention

Full spec: [Git Workflow § Branch Naming](docs/git-workflow.md#branch-naming) — `type/short-kebab-case-description`, optionally ticket-referenced (`fix/1042-refresh-token-race-condition`). Matches the [Recommended Branches](#recommended-branches) prefixes above exactly.

## Merge Policy

Squash-merge only, per [Git Workflow § Merge Strategy](docs/git-workflow.md#merge-strategy). One approving review for standard changes, two for changes touching authentication, database migrations, or (once scoped) payments/subscriptions, per [Git Workflow § Code Reviews](docs/git-workflow.md#code-reviews). CI must be green — never merge on a red pipeline.

## Release Policy

Full spec: [Release Management](docs/release-management.md). Staging auto-deploys on merge to `main`; production deploys are tag-triggered and require manual approval, per [Release Management § Deployment Approvals](docs/release-management.md#deployment-approvals). Hotfixes follow the expedited path in [Development Workflow § Hotfix Workflow](docs/DEVELOPMENT_WORKFLOW.md#hotfix-workflow).

## Reconciliation Note

Two details in this document are deliberately **not** a literal application of a generic "initialize a git repo" template, because this repository already has frozen, considered decisions on both:

1. **No `develop` branch.** [Git Workflow § Git Workflow & Branching Strategy](docs/git-workflow.md#branch-naming) explicitly rejects a long-lived `develop` branch: "avoided deliberately to prevent drift/merge-hell between two long-lived branches." Introducing one now for repository setup would silently reverse that documented decision. If a `develop`-style integration branch is ever genuinely needed (e.g., team size or release cadence changes), that's a decision to make explicitly and update [Git Workflow](docs/git-workflow.md) for — not something to introduce quietly through a setup guide.
2. **Milestone tags use pre-release suffixes (`v1.0.0-infrastructure`), not MINOR bumps (`v1.1.0`).** [Release Management § Deployment Strategy](docs/PHASED_RELEASE_STRATEGY.md#deployment-strategy), [PHASE1_SCOPE.md](docs/PHASE1_SCOPE.md), and [RELEASE_CHECKLIST.md](docs/RELEASE_CHECKLIST.md) all already establish `v1.0.0` as the specific, meaningful tag for Phase 1's public launch. A tag sequence that reaches `v1.1.0` *before* Phase 1 ships would consume that version number early and force the actual launch to be mislabeled `v1.2.0` or later — confusing for no benefit. The pre-release suffix scheme above achieves the same "tag progress checkpoints" goal without that collision, and is standard, tooling-recognized semver behavior.

Both adaptations preserve the letter of what was asked (a git initialization guide with recommended branches and a tag progression) while keeping this document consistent with the rest of the frozen v1.0 baseline, per this task's own instruction not to redesign established process.
