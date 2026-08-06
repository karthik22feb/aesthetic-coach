# Git Workflow

**Product:** Aesthetic Coach
**Related documents:** [CI/CD Pipeline § 1–2](11-cicd-pipeline.md#1-git-workflow--branching-strategy) (branching strategy and PR guidelines are defined there — this document adds the granular, day-to-day conventions built on top of it) · [Release Management](release-management.md) · [Coding Standards](coding-standards.md)

## Table of Contents
- [Branch Naming](#branch-naming)
- [Conventional Commits](#conventional-commits)
- [Pull Requests](#pull-requests)
- [Code Reviews](#code-reviews)
- [Merge Strategy](#merge-strategy)
- [Release Tags](#release-tags)
- [Hotfix Process](#hotfix-process)
- [Versioning](#versioning)
- [Future Improvements](#future-improvements)

## Branch Naming

Format: `<type>/<short-kebab-case-description>`, branched from `main` per [CI/CD Pipeline § 1](11-cicd-pipeline.md#1-git-workflow--branching-strategy).

| Type | Usage | Example |
|---|---|---|
| `feature/` | New functionality | `feature/habit-streak-tracking` |
| `fix/` | Bug fix | `fix/refresh-token-race-condition` |
| `chore/` | Tooling, deps, non-behavioral changes | `chore/upgrade-flutter-3-25` |
| `docs/` | Documentation-only changes | `docs/update-ai-coaching-engine` |
| `hotfix/` | Urgent production fix (see [Hotfix Process](#hotfix-process)) | `hotfix/coach-endpoint-500` |

Branch names reference an issue/ticket number when one exists (`fix/1042-refresh-token-race-condition`), but the descriptive suffix is always present — bare ticket numbers as branch names aren't searchable/self-explanatory in `git log`.

## Conventional Commits

Commit messages (and squash-merge PR titles, since squash-merge is the merge strategy — see [Merge Strategy](#merge-strategy)) follow [Conventional Commits](https://www.conventionalcommits.org/):

```
<type>(<scope>): <description>

[optional body]
```

| Type | Usage |
|---|---|
| `feat` | New feature (triggers a MINOR version bump per [Release Management § Semantic Versioning](release-management.md#semantic-versioning)) |
| `fix` | Bug fix (PATCH) |
| `chore` | Tooling/deps, no behavior change |
| `docs` | Documentation only |
| `refactor` | No behavior change, code structure only |
| `test` | Test-only changes |
| `perf` | Performance improvement |

Scope matches the module/feature affected: `feat(workouts): add PR detection for bodyweight exercises`, `fix(auth): correct refresh token reuse detection window`. This scoped format is what [Release Management § Changelog Format](release-management.md#changelog-format) generates the changelog from.

## Pull Requests

Extends [CI/CD Pipeline § 2](11-cicd-pipeline.md#2-pull-request-guidelines) with the concrete checklist a PR description must satisfy before requesting review:

- [ ] Title follows Conventional Commits format (it becomes the squash-merge commit message)
- [ ] Description covers **What/Why**, **Testing performed**, **Screenshots** (mobile UI changes only), **Rollback plan** (only for risky changes — migrations, auth changes)
- [ ] Linked to the `FR-xxx`/`NFR-xxx` or feature doc it implements, where applicable (e.g., links to [Workout Tracking](features/workout-tracking.md))
- [ ] CI is green (see [CI/CD Pipeline § 4](11-cicd-pipeline.md#4-automated-testing-ci-gates))
- [ ] New/changed behavior has tests per [Testing Strategy](10-testing-strategy.md)
- [ ] Any architectural deviation from the docs in this repository is called out explicitly and the relevant doc is updated in the same PR (per [Development Roadmap § Cross-Phase Notes](16-development-roadmap.md#cross-phase-notes) — "documentation is living")

## Code Reviews

- One approving review required for standard changes; **two** for changes touching authentication, database migrations, or (once scoped) payments/subscriptions — per [CI/CD Pipeline § 2](11-cicd-pipeline.md#2-pull-request-guidelines).
- Reviewers check correctness first, then adherence to [Coding Standards](coding-standards.md), then style — style nitpicks that aren't already caught by Pint/`dart format` in CI are optional comments, not blocking.
- Author resolves or responds to every comment before merge; reviewer re-approves after substantive changes (not required for a typo fix following an approval).
- Review turnaround target: same business day, to keep feature branches short-lived (< 3 days open, per [CI/CD Pipeline § 1](11-cicd-pipeline.md#1-git-workflow--branching-strategy)).

## Merge Strategy

**Squash-merge only** to `main` — one commit per PR, commit message equals the PR title (Conventional Commits format), full discussion history preserved on the PR itself rather than cluttering `git log`. No merge commits, no rebase-merge (keeps `main`'s history linear and each commit independently revertable).

## Release Tags

Tags follow `vMAJOR.MINOR.PATCH` (see [Versioning](#versioning)), created from `main` at the release commit per [CI/CD Pipeline § 5](11-cicd-pipeline.md#5-release-management--versioning) and [Release Management § Release Process](release-management.md#release-process). Tags are annotated (`git tag -a`), never lightweight, so they carry a message describing the release.

## Hotfix Process

For a production-breaking issue that cannot wait for the normal `main → staging → tag → production` flow ([CI/CD Pipeline § 5](11-cicd-pipeline.md#5-release-management--versioning)):

1. Branch `hotfix/<description>` directly from the currently-deployed production tag (not from `main`, which may contain unreleased changes).
2. Fix, test locally, open a PR against `main` as normal — **hotfixes still go through CI and review**, just expedited (single reviewer, same-hour turnaround target).
3. Once merged to `main`, tag immediately as a new PATCH release and deploy through the standard (but expedited) approval gate in [Deployment Guide](12-deployment-guide.md).
4. If `main` has diverged significantly from production (several unreleased features ahead), the hotfix commit is cherry-picked onto a release branch cut from the production tag instead of waiting for all of `main` to be release-ready — this is the one case where a short-lived release branch is justified, as an explicit exception to the no-long-lived-branches rule in [CI/CD Pipeline § 1](11-cicd-pipeline.md#1-git-workflow--branching-strategy).
5. Post-incident: a brief retrospective note captures root cause, consistent with the incident-learning spirit of [Monitoring & Logging § Alerting](13-monitoring-logging.md#8-alerting).

## Versioning

See [Release Management § Semantic Versioning](release-management.md#semantic-versioning) for the authoritative policy; this document only notes the Git-level mechanics: version bumps are computed from the Conventional Commit types merged since the last tag (breaking-change commits use a `!` suffix, e.g., `feat(auth)!: ...`, mapping to MAJOR).

## Future Improvements
Automated branch-name and commit-message linting in CI (reject a PR whose title doesn't parse as a valid Conventional Commit) rather than relying on review-time correction.
