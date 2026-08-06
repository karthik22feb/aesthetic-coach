# ADR-0003: MySQL 8 for Database

**Status:** Accepted
**Related documents:** [Database Design](../04-database-design.md) · [PRD § Technology Stack](../01-prd.md)

## Context
The stakeholder has existing production experience with MySQL and specified it as a hard requirement. The schema needs to support relational data (workouts → exercises → sets), JSON columns for flexible fields (dietary restrictions, achievement explanation payloads), full-text search (exercise/food lookup), and future partitioning as data volume grows.

## Problem
Which relational database best fits a schema with meaningful relational integrity needs, moderate write volume (per-set logging), and an operator who already knows how to run it in production?

## Decision
Use MySQL 8.0 (InnoDB, `utf8mb4`) as the sole datastore, per [Database Design](../04-database-design.md).

## Alternatives Considered
| Option | Why not chosen |
|---|---|
| PostgreSQL | Arguably richer JSON/full-text/window-function support, but the stakeholder's existing MySQL operational expertise ([PRD § Assumptions](../01-prd.md#10-risks--assumptions)) outweighs Postgres's marginal feature advantages for this schema's actual needs — MySQL 8's JSON column and generated-column support are sufficient here |
| MongoDB / a document store | The data model is fundamentally relational (workouts have exercises have sets; users have many domains of tracked data with real foreign-key relationships) — a document store would require either heavy denormalization or application-level joins, working against the schema's natural shape |
| A managed multi-model/NewSQL database | Unjustified operational complexity and cost for a system that doesn't yet have a demonstrated need for horizontal write-scaling beyond what a well-indexed MySQL primary + read replica ([System Architecture § Scalability Strategy](../03-system-architecture.md#7-scalability-strategy)) provides |

## Pros
- Matches existing stakeholder operational expertise directly — faster incident response, known backup/restore tooling.
- MySQL 8's JSON column type covers the schema's semi-structured needs (`dietary_restrictions`, `explanation_json`) without needing a second datastore.
- Mature managed-hosting options (RDS-equivalent) simplify [Deployment Guide](../12-deployment-guide.md) and [Production Hardening § Backup Verification](../14-production-hardening.md#7-backup-verification).
- `ENUM` types map cleanly onto the many fixed-choice fields in the schema (workout status, meal type, persona, etc.).

## Cons
- Some advanced query patterns (recursive CTEs, certain window functions) have historically been less ergonomic in MySQL than Postgres, though MySQL 8 closed much of this gap.
- Full-text search (used for exercise/food lookup, [Database Design § 4](../04-database-design.md#4-indexing-strategy)) is less feature-rich than a dedicated search engine — acceptable at current scale, flagged as a future consideration if search quality/scale demands more.

## Consequences
Every table definition, index strategy, and migration convention in [Database Design](../04-database-design.md) is MySQL-8-specific (e.g., `ENUM` usage, `utf8mb4` collation choices). A future need for more sophisticated search (e.g., semantic exercise search) would likely be solved by a bolt-on search service reading from MySQL, not a database migration.

## Future Review Criteria
Revisit only if: write throughput genuinely outgrows a well-tuned primary + read-replica MySQL topology (not currently expected at the MAU targets in [PRD § Success Metrics](../01-prd.md#8-success-metrics)), or search requirements grow complex enough to need a dedicated search engine (Elasticsearch/Meilisearch) alongside — which would be additive, not a MySQL replacement.
