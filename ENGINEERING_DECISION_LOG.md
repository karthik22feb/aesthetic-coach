# Engineering Decision Log

**A chronological record of important engineering decisions made during implementation.**

## Purpose

This document is **not** a replacement for [Architecture Decision Records](docs/adr/). ADRs remain reserved for major architectural decisions — technology choices, system-level structure, and anything that would require a new ADR-numbered file to change (see [docs/adr/README.md](docs/adr/README.md)). This log is for everything one level down: the implementation-level decisions that come up in day-to-day development and are worth recording, but don't rise to architectural significance.

**When to add an entry here vs. an ADR:** if the decision changes *how the system is built or structured* in a way future engineers would need to know before touching related code — a package choice, a trade-off made under a real constraint, a workaround for an unexpected limitation — it belongs here. If it changes *what the architecture is* — a technology swap, a new module boundary, a reversal of something an existing ADR already decided — it needs a real ADR instead. See [DEVELOPMENT_WORKFLOW.md § When to Record an Engineering Decision](docs/DEVELOPMENT_WORKFLOW.md#when-to-record-an-engineering-decision) for the fuller trigger list.

This log is append-only, most-recent-entry-first, exactly like [DEVELOPMENT_LOG.md](DEVELOPMENT_LOG.md) — past entries are never edited to reflect later changes, only new entries are added (a later entry can supersede an earlier one, but should say so explicitly rather than silently rewriting history).

## Entry Template

Copy this template for every new entry:

```markdown
### YYYY-MM-DD — [Short Decision Title]

**Sprint:** Phase 1 · Sprint N (or Phase 2 · Sprint N)
**Task ID:** [reference into TASK_BREAKDOWN.md, e.g. "Sprint 1, Task 3"]
**Decision Summary:** [one sentence — what was decided]

**Background:**
[What situation prompted this decision — the constraint, question, or problem encountered during implementation.]

**Alternatives Considered:**
- [Option A — why it was or wasn't chosen]
- [Option B — why it was or wasn't chosen]

**Final Decision:**
[What was actually decided/implemented.]

**Reasoning:**
[Why this option over the alternatives — the actual justification, not just a restatement of the decision.]

**Impact:**
[What this affects — other modules, future work, performance, security posture, etc. Note explicitly if this decision constrains or informs later tasks.]

**Related Files:**
- `path/to/file`

**Related Documentation:**
- [Link to any spec, ADR, or other doc this decision touches or depends on]

**Git Commit:** `<short-sha>`

**Author:** [who made the call]
```

## Entries

*No entries yet. The first entry is added the first time an implementation session makes a decision meeting the criteria in [DEVELOPMENT_WORKFLOW.md § When to Record an Engineering Decision](docs/DEVELOPMENT_WORKFLOW.md#when-to-record-an-engineering-decision).*
