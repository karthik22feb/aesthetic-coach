# Permissions Matrix

**Product:** Aesthetic Coach
**Related documents:** [System Architecture § Security Architecture](03-system-architecture.md#8-security-architecture) · [Backend Architecture § Policies](07-backend-architecture.md#3-middleware) · [User Documentation § Admin Documentation](15-user-documentation.md#6-admin-documentation) · [Subscriptions feature](features/subscriptions.md)

## Table of Contents
- [Purpose](#purpose)
- [Roles](#roles)
- [Permissions Matrix](#permissions-matrix-1)
- [Notes on Enforcement](#notes-on-enforcement)
- [Future Improvements](#future-improvements)

## Purpose
Document CRUD access per role across every resource in the app. **Important scoping note:** as of the current architecture, [SRS](02-srs.md) and [Backend Architecture](07-backend-architecture.md) define exactly **one** authenticated role — every registered user has identical permissions over their own data, enforced via `user_id`-scoped ownership checks ([System Architecture § Security Architecture](03-system-architecture.md#8-security-architecture)), not a role hierarchy. The additional roles below (Premium, Coach, Moderator, Admin, Super Admin) are **not yet implemented** — this matrix defines them as forward-looking scaffolding, consistent with how [Subscriptions](features/subscriptions.md) and [User Documentation § Admin Documentation](15-user-documentation.md#6-admin-documentation) already flag them as Future.

## Roles

| Role | Status | Definition |
|---|---|---|
| **Guest** | MVP | Unauthenticated — can only reach `/auth/*` public endpoints |
| **Registered User** | MVP | Any authenticated, email-verified-or-not user — the only role that exists in the current data model |
| **Premium User** | Future | Depends on a Product-approved tiering decision — see [Subscriptions § Business Rules](features/subscriptions.md#business-rules) |
| **Coach** | Future, not scoped | A human-coach account type is explicitly named in the PRD only as a Phase 3 exploration ("marketplace/human-coach hybrid," [PRD § 9](01-prd.md#9-mvp-vs-future-phases)) — no data model or permission boundary has been designed; included here only to satisfy this document's requested scope |
| **Moderator** | Future | Would govern the community layer ([Challenges](features/challenges.md), Future) — content moderation of user-generated community content, not present until that feature is scoped |
| **Admin** | Future (Phase 2+) | Internal support/ops role per [User Documentation § 6](15-user-documentation.md#6-admin-documentation) |
| **Super Admin** | Future | Elevated Admin with destructive/irreversible privileges (e.g., hard-delete outside the normal grace-period flow, secrets/config access) |

## Permissions Matrix

Legend: **C**reate, **R**ead, **U**pdate, **D**elete, **O** = own records only, **A** = all records, **–** = no access.

| Resource | Guest | Registered User | Premium User | Coach | Moderator | Admin | Super Admin |
|---|---|---|---|---|---|---|---|
| Own account/profile ([Profile](features/profile.md)) | – | CRUD (O) | CRUD (O) | CRUD (O) | CRUD (O) | CRUD (O) | CRUD (O) |
| Other users' profiles | – | – | – | R (assigned clients only, Future) | – | R (A, support context only) | RUD (A) |
| Workouts, nutrition, habits, goals, body metrics, progress photos ([Feature Specifications](features/)) | – | CRUD (O) | CRUD (O) | R (assigned clients only, Future) | – | R (O, support diagnosis only, per [User Documentation § 6](15-user-documentation.md#6-admin-documentation)) | RUD (A) |
| Exercise library (system entries) | R | R | R | R | R | CRUD (A) | CRUD (A) |
| Exercise library (custom, own) | – | CRUD (O) | CRUD (O) | CRUD (O) | – | R (O) | RUD (A) |
| Food database (system entries) | – | R | R | R | R | CRUD (A) | CRUD (A) |
| AI Coach conversations ([AI Coach](features/ai-coach.md)) | – | CRUD (O) | CRUD (O), higher token budget (Future) | – | – | – | R (O, abuse investigation only, per [AI Coaching Engine § Safety Guardrails](09-ai-coaching-engine.md#7-safety-guardrails)) |
| Achievements catalog | R | R | R | R | R | CRUD (A) | CRUD (A) |
| Notifications (own) | – | CRUD (O) | CRUD (O) | CRUD (O) | CRUD (O) | CRUD (O) | CRUD (O) |
| Own subscription ([Subscriptions](features/subscriptions.md), Future) | – | – | RUD (O) | RUD (O) | – | R (O, support only) | RUD (A) |
| Community content ([Challenges](features/challenges.md), Future) | – | CRUD (O), R (A, opt-in visible content) | CRUD (O), R (A) | R (A) | RUD (A, moderation actions) | RUD (A) | RUD (A) |
| AI prompt templates ([AI Prompt Library](ai/)) | – | – | – | – | – | R (A) | CRUD (A) |
| Feature flags ([CI/CD Pipeline § Feature Flags](11-cicd-pipeline.md#6-feature-flags)) | – | – | – | – | – | RU (A) | CRUD (A) |
| Backend config/secrets ([Production Hardening § Secrets Management](14-production-hardening.md#3-encryption--secrets-management)) | – | – | – | – | – | – | RU (A, via secret manager, audit-logged) |

## Notes on Enforcement

- For the two roles that actually exist today (Guest, Registered User), access is enforced exactly as described in [System Architecture § Security Architecture](03-system-architecture.md#8-security-architecture): every resource query is `user_id`-scoped at the repository level, not merely policy-checked, so there is no code path capable of returning another user's data even by mistake ([Backend Architecture § Policies](07-backend-architecture.md#3-middleware)).
- Every Future role's "A" (all-records) access shown above is a **design intent**, not an implemented capability — when any of these roles is actually built, it requires: (1) a distinct auth/session type per [User Documentation § 6](15-user-documentation.md#6-admin-documentation) ("Access to admin tooling requires a distinct elevated-privilege auth path, audit-logged for every action — never the same session/token type as regular user auth"), and (2) audit logging of every elevated-access read/write, not just standard request logging.
- Admin/Super Admin read access to user tracked-data is scoped to **support diagnosis** even where marked "R (A)" — general browsing of user data without a specific support context is not intended, and should be enforced by requiring a ticket/reason reference at the tooling level when built, not left to policy alone.

## Future Improvements
- This matrix should be revisited and formalized (with real Policy classes and tests per [Testing Strategy § API Testing](10-testing-strategy.md#5-api-testing)) the moment any Future role above is actually scoped for implementation — treat this document as the starting draft for that work, not a finished spec.
- Coach and Moderator roles in particular need their own dedicated feature-scoping pass (data model, screens, business rules) before this matrix's entries for them can be considered more than placeholders.
