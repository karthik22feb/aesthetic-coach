# Sprint 1, Day 1 Checklist

**The practical checklist to follow immediately before beginning development.** Concise and actionable — for full detail on any item, follow the link. Suitable for daily reference at the start of a work session, not just once.

---

## Development Machine

- [ ] PHP 8.3+ installed
- [ ] Composer installed
- [ ] Flutter SDK (latest stable) installed
- [ ] Docker Desktop installed and running
- [ ] Git installed
- [ ] Node / npm installed

Full detail: [INFRASTRUCTURE_READINESS.md § Development Machine](INFRASTRUCTURE_READINESS.md#development-machine)

## Required Software

- [ ] Android Studio (Android builds/emulator)
- [ ] Xcode (iOS builds/simulator — macOS only)
- [ ] Laravel Installer (optional convenience)
- [ ] MySQL / Redis client (optional, Docker-provided services are sufficient without one)

Full detail: [INFRASTRUCTURE_READINESS.md § Development Machine](INFRASTRUCTURE_READINESS.md#development-machine)

## Required Accounts

- [ ] Git hosting account with push access to this repository
- [ ] Cloud/hosting provider account for staging
- [ ] Container registry access (if deploying via pushed images)
- [ ] Apple Developer Account (needed later this sprint, not Day 1)
- [ ] Google Play Console (needed later, not Day 1)
- [ ] Apple App Store Connect (needed later, not Day 1)

Full detail: [INFRASTRUCTURE_READINESS.md § Platform & Distribution Accounts](INFRASTRUCTURE_READINESS.md#platform--distribution-accounts)

## Required Credentials

**Not needed for Day 1** (Infrastructure module has no third-party credential dependency) — needed later in Sprint 1:

- [ ] Google OAuth Credentials — needed by Task 12
- [ ] Apple Sign-In Credentials — needed by Task 13
- [ ] Claude API Key (production, distinct from any personal subscription) — needed in Sprint 5
- [ ] Firebase Project (push notifications) — needed in Sprint 5
- [ ] Apple Push Notification (APNs) key — needed in Sprint 5
- [ ] Android Signing Key — needed by Sprint 7 (generate and back up securely once needed)

Full detail: [INFRASTRUCTURE_READINESS.md § Third-Party Credentials](INFRASTRUCTURE_READINESS.md#third-party-credentials)

## Repository Status

- [ ] Confirm current state: `git status` (or, if no repository exists yet, follow [GIT_INITIALIZATION.md § Initial Repository Setup](GIT_INITIALIZATION.md#initial-repository-setup))
- [ ] Confirm on `main`, up to date with remote: `git pull origin main`
- [ ] Confirm working tree is clean before starting new work

## Branch Creation

- [ ] Create the session branch per [GIT_INITIALIZATION.md § Branch Naming Convention](GIT_INITIALIZATION.md#branch-naming-convention):
  ```
  git checkout -b feature/infra-laravel-scaffold
  ```
- [ ] One branch per [TASK_BREAKDOWN.md](docs/TASK_BREAKDOWN.md) task or small task group — not one branch for all of Sprint 1

## Environment Variables

- [ ] `.env.example` reviewed (once it exists, from Task 1)
- [ ] Local `.env` created from `.env.example`, never committed
- [ ] Confirm `.env` is listed in `.gitignore` before first commit

## Database

- [ ] MySQL 8 reachable via Docker Compose (`docker compose up mysql`)
- [ ] Confirm connection from the app container/local PHP process

## Docker

- [ ] `docker compose up` brings up app, MySQL 8, Redis, Mailhog without manual intervention
- [ ] `docker compose ps` shows all services healthy

## Flutter

- [ ] `flutter doctor` reports no blocking issues
- [ ] `flutter pub get` succeeds on the scaffolded project

## Laravel

- [ ] `composer install` succeeds
- [ ] `php artisan serve` (or Docker equivalent) boots without error

## IDE

- [ ] Editor configured with PHP and Dart/Flutter language support
- [ ] Linters (Pint, `dart format`/`flutter analyze`) run correctly from the IDE, matching [Coding Standards](docs/coding-standards.md)

## Testing Tools

- [ ] Pest (PHP) runs: `php artisan test` or `./vendor/bin/pest`
- [ ] Flutter test runs: `flutter test`

## Git

- [ ] User name/email configured (`git config user.name` / `user.email`)
- [ ] Commit signing configured, if required by repository policy
- [ ] Conventional Commits format understood — see [Git Workflow § Conventional Commits](docs/git-workflow.md#conventional-commits)

## Claude API

- [ ] **Not required for Day 1** — needed starting Sprint 5 ([AI Recommendations module](docs/IMPLEMENTATION_ORDER.md#13-ai-recommendations))

## Google OAuth

- [ ] **Not required for Day 1** — needed by Sprint 1, Task 12

## Apple Sign-In

- [ ] **Not required for Day 1** — needed by Sprint 1, Task 13

## Firebase

- [ ] **Not required for Day 1** — needed starting Sprint 5 (Notifications module)

## Verification Steps

Before writing any implementation code:

1. [ ] `git status` clean, on the correct feature branch
2. [ ] `docker compose up` succeeds
3. [ ] Backend boots and responds to a basic request
4. [ ] Flutter app builds and runs on at least one target (emulator or simulator)
5. [ ] [NEXT_TASK.md](NEXT_TASK.md) read, and a copy of [CLAUDE_SESSION_TEMPLATE.md](CLAUDE_SESSION_TEMPLATE.md) filled in for the session about to start

## Success Criteria

Day 1 is successful when:

- [ ] The development machine can run both codebases locally without unresolved errors
- [ ] The first feature branch exists and is checked out
- [ ] The first [CLAUDE_SESSION_TEMPLATE.md](CLAUDE_SESSION_TEMPLATE.md) session begins against [TASK_BREAKDOWN.md § Sprint 1, Task 1](docs/TASK_BREAKDOWN.md#sprint-1--infrastructure-authentication--project-setup) ("Create Laravel project, scaffold `app/Modules/*` structure")
- [ ] Nothing on this checklist marked required is left unchecked

---

**This checklist doesn't change sprint-to-sprint** — re-run the relevant sections (Repository Status, Branch Creation, Verification Steps) at the start of every session, not just once on the literal first day.
