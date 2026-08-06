# Server Setup Report

**The record of the development environment migration from local Windows/XAMPP to the Linux development server.** This is a point-in-time report, not a living tracker — see [PROJECT_STATUS.md](PROJECT_STATUS.md) for current operational status and [ENGINEERING_DECISION_LOG.md](ENGINEERING_DECISION_LOG.md) for the environment-specific decisions this migration produced.

**Date:** 2026-08-06
**Performed by:** Claude (AI Software Engineer), via SSH

---

## Server Specifications

| Field | Value |
|---|---|
| Hostname | `ubuntu-20-04` (legacy hostname; actual OS is newer — see below) |
| Operating System | Ubuntu 24.04.3 LTS (Noble Numbat) |
| Kernel | 6.8.0-90-generic |
| CPU | Intel(R) Xeon(R) Gold 6542Y, 2 vCPUs |
| RAM | 3.8 GiB total — **only ~847 MiB available** (1.0 GiB buff/cache, 134 MiB free) |
| Swap | 1.3 GiB total — **~1.3 GiB used (nearly full)** |
| Disk | 246 GB total, 12 GB used, 225 GB available (`/`) |
| Target project path | `/var/www/html/aesthetic-coach` |

**⚠️ This is a shared, multi-tenant server, not a dedicated box for this project.** `/var/www/html` hosts numerous other live projects and services under the same `administrator`/`www-data` accounts (Frappe, Ghost-adjacent, WordPress, Drupal, n8n, Snipe-IT, phpList, and several client-named directories). System users include `root`, `administrator`, `eservicesadmin`, `chennai36`, `ghost`, `frappe`. This materially changes the risk profile of any environment change — see [Recommendations](#recommendations-before-sprint-1) below.

## Installed Software & Versions

All versions confirmed by direct execution on the server (not assumed):

| Software | Version | Status vs. requirement | Notes |
|---|---|---|---|
| PHP | 8.3.6 (CLI, NTS) | ✅ Meets [Backend Architecture](docs/07-backend-architecture.md) target (PHP 8.3+) | Already installed — no action needed |
| Composer | 2.9.3 | ✅ | Runs against PHP 8.3.6, no version conflict |
| MySQL | 8.0.46-0ubuntu0.24.04.3 | ✅ Meets [ADR-0003](docs/adr/0003-mysql8-for-database.md) (MySQL 8) | Service active, bound to `127.0.0.1:3306` |
| Redis | 7.0.15 | ✅ | Service active, bound to `127.0.0.1:6379`, responds to `PING` |
| Node.js | v18.20.8 | ⚠️ Present, but Node 18 is past its standard LTS support window | See [Recommendations](#recommendations-before-sprint-1) — **not upgraded**, shared-server risk |
| npm | 10.8.2 | ✅ | Paired with the installed Node version |
| Docker | 28.1.1 | ✅ | Service active; `administrator` is in the `docker` group (no `sudo` needed for `docker` commands) |
| Docker Compose | v2.32.4 (plugin) | ✅ | |
| Git | 2.43.0 | ✅ | |
| Nginx | 1.24.0 (Ubuntu) | ✅ | Already serving other tenants' sites on port 80 — **no vhost changes made** |
| Supervisor | **4.2.5 — newly installed** | ✅ | The only genuinely missing package; installed via `apt-get install -y supervisor`, now enabled and active |

**Nothing else was installed or upgraded.** PHP, Composer, MySQL, Redis, Node, npm, Docker, Docker Compose, Git, and Nginx were all already present and already meet or exceed the documented requirements — touching any of them on a server hosting other live tenants would have been out of scope and risky, so they were left untouched.

## Directory Layout

```
/var/www/html/aesthetic-coach/
├── backend/          (placeholder, empty — Sprint 1 will scaffold Laravel here)
├── mobile/           (placeholder, empty — Sprint 1 will scaffold Flutter here)
├── docker/           (placeholder, empty — for docker-compose.yml etc.)
├── docs/             (all 116 documentation files, migrated intact)
├── .gitignore
└── [13 root-level operational .md files]
```

`backend/`, `mobile/`, and `docker/` were created fresh as empty placeholders (each with a `.gitkeep`) per the recommended workspace structure — no existing files in `/var/www/html` conflicted with these names.

## Permissions

All project files owned by `administrator:administrator`, mode `755` on directories / `644` on files — consistent with the ownership pattern already used by the other `administrator`-owned projects on this server. No ownership or permission changes were made outside `/var/www/html/aesthetic-coach`.

## Git Status

| Item | Status |
|---|---|
| Repository initialized | ✅ Yes — no prior `.git` existed at the target path |
| Default branch | `main` (renamed from Git's default `master` to match [Git Workflow](docs/git-workflow.md) and [GIT_INITIALIZATION.md](GIT_INITIALIZATION.md)) |
| Initial commit | `8dd7299` — `docs: initial v1.0 documentation baseline` (130 files: 126 `.md` + `.gitignore` + 3 `.gitkeep`) |
| **Documentation baseline tag** | **`v1.0.0-docs-freeze` — confirmed present** (`git tag -l`) |
| Remote | `origin` → `git@github-aesthetic-coach:karthik22feb/aesthetic-coach.git` (per user request), via a dedicated deploy key |
| Push status | **Pending** — a project-specific SSH deploy key was generated (`~/.ssh/aesthetic_coach_deploy`) following the same per-project deploy-key convention already used on this server for its other repos; awaiting the public key being added to the GitHub repo's Deploy Keys with write access before `git push` can succeed |
| Working tree | Clean (`git status --short` empty after the initial commit) |

## Migration Verification

The repository content was **already present** at `/var/www/html/aesthetic-coach` before this session began (timestamps showed today's date), suggesting an existing sync mechanism between the local Windows working copy and this path predates this task. This was verified rather than assumed:

- File list diff (local vs. remote, sorted `find *.md`): **identical**, 126 files both sides
- Content checksum spot-check (`README.md`, `PROJECT_STATUS.md`, `docs/04-database-design.md`): **MD5 identical** on all three
- `git ls-files "*.md" | wc -l` after commit: **126**, matching

No files were lost or altered during migration.

## Validation Results

| Check | Result |
|---|---|
| MySQL service active | ✅ `systemctl is-active mysql` → `active` |
| Redis service active + responsive | ✅ `active`, `PING` → `PONG` |
| Docker service active | ✅ `active` |
| Docker usable without `sudo` | ✅ `docker ps` succeeds as `administrator` |
| Nginx service active | ✅ `active` |
| PHP executes | ✅ `PHP 8.3.6 (cli)` |
| Composer executes | ✅ `Composer version 2.9.3` |
| Node executes | ✅ |
| npm executes | ✅ |
| Git functions correctly | ✅ Proven directly — real `init`/`commit`/`tag` succeeded |
| Supervisor installed and running | ✅ `enabled`, `active` |

## Remaining Setup Tasks

- [ ] **Add the `aesthetic_coach_deploy` public key to the GitHub repo's Deploy Keys (with write access)**, then push `main` and the `v1.0.0-docs-freeze` tag — this is the only incomplete item from this session
- [ ] Laravel scaffold in `backend/` (Sprint 1, Task 1 — separate implementation session, per [NEXT_TASK.md](NEXT_TASK.md))
- [ ] Flutter scaffold in `mobile/` (Sprint 1, Task 5)
- [ ] `docker-compose.yml` in `docker/` or repo root, per [Deployment Guide § 2](docs/12-deployment-guide.md#2-development-environment) (Sprint 1, Task 2)

## Recommendations Before Sprint 1

1. **RAM/swap headroom is tight.** 847 MiB available, swap nearly full. A Laravel + MySQL + Redis + Docker dev workflow on top of everything else already running here may be constrained. Worth monitoring (`free -h`) once backend/mobile scaffolding actually starts, and considering whether this server has room to grow, or whether Docker-based local dev (per [Deployment Guide](docs/12-deployment-guide.md)) should run more conservatively (fewer containers, tighter memory limits) than a dedicated box would need.
2. **Node.js 18 is past standard LTS support.** Left untouched deliberately — this server has other live Node-dependent services, and a global Node upgrade risks breaking them. If the mobile/AI tooling needs a newer Node later, consider a version manager (`nvm`) scoped to this project rather than a system-wide upgrade.
3. **A kernel update is available** (running `6.8.0-90-generic`, `6.8.0-136-generic` available) — `apt` flagged this during the Supervisor install. **Not applied** — a reboot of a shared production server is outside this task's scope and needs explicit, separately-scheduled approval, not a side effect of environment setup.
4. **Complete the GitHub deploy key step** to unblock the push — everything else is ready and waiting on it.
5. Once the repository is pushed, treat `/var/www/html/aesthetic-coach` on this server as the canonical working copy going forward, per this task's own objective — the original Windows/XAMPP path remains as the authoring location for this session, but Sprint 1 implementation work should happen against the server.
