# Database Seed Strategy

**Product:** Aesthetic Coach
**Related documents:** [Database Design § 6](04-database-design.md#6-migration-strategy) · [Backend Architecture](07-backend-architecture.md) · [CI/CD Pipeline](11-cicd-pipeline.md) · [Testing Strategy](10-testing-strategy.md) · [Deployment Guide](12-deployment-guide.md)

## Table of Contents
- [Purpose](#purpose)
- [Seed Categories](#seed-categories)
- [Environment Differences](#environment-differences)
- [Seeder Implementation Notes](#seeder-implementation-notes)
- [Edge Cases](#edge-cases)
- [Future Improvements](#future-improvements)

## Purpose
Define what data each environment needs pre-loaded, and — critically — what must **never** be seeded into production, extending the brief seeding mention in [Database Design § 6 Migration Strategy](04-database-design.md#6-migration-strategy) into a full strategy.

## Seed Categories

| Category | Dev | Testing (CI) | Staging | Production |
|---|---|---|---|---|
| **Reference: Exercises** | ~150 curated exercises | Minimal fixture set (~10, only what tests need) | Full curated set, same as production | Full curated set (~150+), idempotent `updateOrCreate` on `slug` |
| **Reference: Foods** | ~200 common foods | Minimal fixture set | Full curated set | Full curated set, idempotent on `barcode`/`name+brand` |
| **Demo user accounts** | 3–5 accounts covering each persona in [PRD § 3.1](01-prd.md#31-user-personas), pre-populated with weeks of realistic history | One throwaway user per test, created and torn down per test via factories, never a shared fixture account | 1–2 demo accounts for QA/stakeholder walkthroughs, clearly labeled (e.g., `demo+trainer@aestheticcoach.app`) | **Never seeded** — production contains only real user-created accounts |
| **Sample workouts/meals** | Generated for demo accounts via factories, spanning several weeks to make trend charts/DFS meaningful | Generated per-test via factories, minimal | Generated for the 1–2 demo accounts only | Never seeded |
| **AI conversation/template samples** | A few pre-seeded `coach_conversations` for demo accounts so the Coach tab isn't empty on first run | Not seeded — AI endpoints are tested against `FakeClaudeProvider` fixtures per [Testing Strategy § API Testing](10-testing-strategy.md#5-api-testing), not seeded conversation rows | Not seeded — staging exercises real AI generation | Never seeded |
| **Achievements catalog** | Full catalog (criteria definitions) | Full catalog (deterministic, needed for achievement-evaluation tests) | Full catalog | Full catalog — this is application config data, seeded in every environment identically |
| **Sample goals/habits** | Seeded for demo accounts | Per-test factories | Seeded for demo accounts | Never seeded |
| **Sample notifications** | A few seeded for demo accounts to preview the Notification Center UI | Per-test factories | Seeded for demo accounts | Never seeded |

## Environment Differences

- **Development:** optimized for a realistic, exploratory local experience — demo accounts have enough history (several weeks) that every chart, trend, and DFS breakdown has meaningful data to display, so a developer building UI doesn't need to manually log dozens of workouts first.
- **Testing (CI):** optimized for speed and determinism — Pest Feature tests use model factories to create exactly the data a given test needs, not the shared demo-account fixtures; this keeps tests isolated and fast (per [Testing Strategy § API Testing](10-testing-strategy.md#5-api-testing), each test runs in its own transaction against a real MySQL instance).
- **Staging:** mirrors production's reference data exactly (same exercise/food catalog, same achievement definitions) plus a small number of clearly-labeled demo accounts for QA and stakeholder review — never real user data (see [Production Hardening § Compliance](14-production-hardening.md#9-compliance-considerations) on data handling).
- **Production:** **only** reference data (exercises, foods, achievement catalog) is seeded — anything resembling a user account, workout, or conversation is real user-generated data, never seeded. This is a hard rule, not a convention: seeders that create user-like rows are environment-gated (`app()->environment('production')` guard that refuses to run) so a misconfigured deploy pipeline can't accidentally seed fake accounts into production.

## Seeder Implementation Notes

- All reference-data seeders use `updateOrCreate` keyed on a stable natural key (`slug` for exercises, `barcode`/`name+brand` for foods) so re-running a seeder in any environment is idempotent — never `truncate`-then-insert, which would break foreign keys from already-logged user data referencing those rows.
- Demo-account seeders (dev/staging only) are clearly namespaced (e.g., `DemoAccountSeeder`) and excluded from the default `DatabaseSeeder::run()` call in production's deploy pipeline step — [Deployment Guide § Database Migrations on Deploy](12-deployment-guide.md#8-database-migrations-on-deploy) only ever invokes the reference-data seeders in production.
- Historical/trend-generating seed data (weeks of workouts/meals for demo accounts) uses factories with realistic variance (not perfectly identical values every day) so charts and the DFS breakdown look like real usage, not obviously synthetic flat lines.

## Edge Cases
- A developer resets their local database → all seeders re-run cleanly from empty, including demo-account history generation, with no manual steps beyond `php artisan migrate:fresh --seed`.
- Reference data changes (e.g., a corrected exercise instruction) → re-running the seeder in any environment updates the existing row in place (via the `updateOrCreate` key) rather than creating a duplicate.
- A staging demo account's password/credentials leak → demo accounts hold no real personal data by design, limiting blast radius; credentials are still treated as a secret per [Production Hardening § Secrets Management](14-production-hardening.md#3-encryption--secrets-management), not hardcoded in the seeder source.

## Future Improvements
- A staging "reset to known state" command for QA, re-running just the demo-account seeders without a full database reset.
- Synthetic-but-larger staging datasets (hundreds of demo accounts) if load testing ever needs to run against realistically-populated staging rather than purely synthetic k6 payloads.
