# Production Hardening

**Product:** Aesthetic Coach
**Related documents:** [System Architecture](03-system-architecture.md) · [Database Design](04-database-design.md) · [Deployment Guide](12-deployment-guide.md) · [Monitoring & Logging](13-monitoring-logging.md)

---

## 1. Security Checklist

Pre-launch and recurring (quarterly) checklist, aligned to OWASP ASVS Level 2 as the baseline (per [PRD § Non-Functional Requirements](01-prd.md#7-non-functional-requirements-summary)):

- [ ] All traffic forced to HTTPS/TLS 1.2+; HSTS enabled ([Deployment Guide § SSL](12-deployment-guide.md#6-ssl))
- [ ] Access tokens ≤ 15 min TTL, refresh tokens rotated + reuse-detected (BR-3, BR-4)
- [ ] Every resource endpoint has an explicit cross-user IDOR test ([Testing Strategy § API Testing](10-testing-strategy.md#5-api-testing))
- [ ] All mutation endpoints validated via Form Requests, no raw `$request->all()` mass assignment ([Backend Architecture § Coding Standards](07-backend-architecture.md#8-coding-standards))
- [ ] Dependency vulnerability scan clean (or exceptions documented) on every release ([CI/CD Pipeline § 4](11-cicd-pipeline.md#4-automated-testing-ci-gates))
- [ ] Secrets rotated on a defined schedule (§ 3) and never present in source control or logs ([Monitoring & Logging § Log Aggregation](13-monitoring-logging.md#7-log-aggregation))
- [ ] Rate limiting active on auth and AI endpoints ([API Specification § 7](05-api-specification.md#7-rate-limiting))
- [ ] Database hardening checklist (§ 6) reviewed
- [ ] Backup restore drill performed in the last quarter (§ 7)
- [ ] Penetration test performed in the last 12 months, findings remediated or risk-accepted with sign-off

## 2. Rate Limiting

Defense-in-depth across three layers:
1. **Edge/Nginx** — coarse connection-rate limiting against basic flood/DoS patterns.
2. **Application (`ThrottleRequests`, `RateLimitAi`)** — per-user and per-IP limits as specified in [API Specification § 7](05-api-specification.md#7-rate-limiting), Redis-backed so limits hold across multiple app instances.
3. **AI token budgets** — cost-shaped limiting distinct from request-count limiting, detailed in [AI Coaching Engine § Rate Limiting](09-ai-coaching-engine.md#9-rate-limiting).

## 3. Encryption & Secrets Management

| Data | At rest | In transit |
|---|---|---|
| Database | Managed MySQL 8 encryption-at-rest (provider-native, e.g., AWS RDS storage encryption) | TLS between app and DB |
| Object storage (progress photos, exports) | Server-side encryption (SSE-S3/KMS-equivalent) | Pre-signed HTTPS URLs only, short-lived |
| Refresh tokens | Stored as SHA-256 hash, never plaintext (BR-4) | TLS |
| Passwords | bcrypt/argon2id (NFR-7) | TLS |
| Secrets (API keys, DB creds, JWT signing keys) | Managed secret store (AWS Secrets Manager / equivalent), not `.env` files in production | Injected at container start ([Deployment Guide § Environment Variables](12-deployment-guide.md#7-environment-variables)) |

**Secrets management rules:** no secret is ever committed, logged, or returned in an API response; each environment (dev/staging/production) has fully independent secrets; the `ANTHROPIC_API_KEY` used in production is distinct from the developer's personal Claude Pro subscription referenced in [PRD § Risks & Assumptions](01-prd.md#10-risks--assumptions) — production billing is metered API usage, not the dev subscription. Rotation schedule: JWT signing keys and third-party API keys rotated at minimum annually or immediately on suspected compromise, with a documented rotation runbook that supports zero-downtime key rollover (dual-key acceptance window for JWT verification during rotation).

## 4. Input Validation

All external input validated at the boundary (Form Requests, per [Backend Architecture § 2](07-backend-architecture.md#2-layering--responsibilities)) — type, range, and format checked before reaching services; free-text fields (workout notes, AI chat messages) are length-capped and never interpolated into SQL (Eloquent parameter binding only) or into AI system prompts (§ [AI Coaching Engine § Safety Guardrails](09-ai-coaching-engine.md#7-safety-guardrails) — user text is always a `user`-role message, never prompt-concatenated). File uploads (progress photos) validated for MIME type and size server-side, not just by client-declared extension, and stored outside the web root with randomized storage paths.

## 5. API Protection

- Authentication required on every route except `/auth/*` and `/health`; enforced globally with an explicit allow-list rather than an opt-in per-route guard, so a forgotten annotation fails closed, not open.
- CORS restricted to known origins (the mobile app doesn't use CORS, but any future web client/admin panel is explicitly allow-listed, never `*`).
- Mass-assignment protection via Eloquent `$fillable` allow-lists on every model, never `$guarded = []`.
- Consistent error envelope (§ [API Specification § 4](05-api-specification.md#4-error-response-format)) avoids leaking stack traces or internal paths in production (`APP_DEBUG=false` enforced by deploy-time config check).

## 6. Database Hardening

- Application DB user has least-privilege grants (no `DROP`/`ALTER` in production application credentials — migrations run under a separate, more-privileged, pipeline-only credential per [Deployment Guide § Database Migrations on Deploy](12-deployment-guide.md#8-database-migrations-on-deploy)).
- No direct public internet exposure of the MySQL port; database reachable only from the app/worker network (VPC-private).
- Query logging of full statement text disabled in production (would leak PII into logs); slow-query log captures duration/fingerprint, not full parameter values.
- All PII-bearing columns reviewed against the data classification implied by [Database Design § 3.1](04-database-design.md#31-identity--auth) (name, email, date_of_birth) for the export/deletion flows in § 8.

## 7. Backup Verification

Automated backups per [Database Design § Backup & Restore Strategy](04-database-design.md#7-backup--restore-strategy); verification closes the loop that a backup is actually restorable:

- **Nightly automated check:** restore the latest snapshot into an ephemeral instance, run a row-count/checksum comparison against a known-good baseline query set, alert on mismatch (ties to [Monitoring & Logging § Alerting](13-monitoring-logging.md#8-alerting)).
- **Quarterly manual drill:** a human restores a snapshot into staging and validates the application boots and reads correctly against it — catching failure modes an automated checksum wouldn't (e.g., a schema/application version mismatch).

## 8. Disaster Recovery

| Scenario | Recovery approach | Target |
|---|---|---|
| Single app instance failure | Load balancer routes around it; auto-scaling group replaces it | Seconds, no user impact |
| Database primary failure | Managed MySQL failover to standby/replica | RTO < 5 min (managed service SLA-dependent) |
| Region-level outage | Cross-region snapshot copy (§ [Database Design § 7](04-database-design.md#7-backup--restore-strategy)) restored into a standby region | RTO measured in hours; documented runbook, tested at least annually — not a hot cross-region standby at MVP scale/cost |
| Data corruption from a bad deploy | Point-in-time recovery via binlog replay to just before the incident | RPO ≤ 5 min |
| Compromised credentials | Immediate rotation runbook (§ 3), revoke all active sessions (`auth_refresh_tokens` mass-revoke), force re-login | Minutes to initiate, full rotation within the hour |

RTO/RPO targets above are documented commitments, not aspirations — they're re-validated against actual managed-service SLAs before being published externally (e.g., in a customer-facing trust page, if one is built).

## 9. Compliance Considerations

- **GDPR/CCPA-aligned data rights:** export (NFR-8) and deletion (FR-108, BR-6) are in-app self-service, not support-ticket-only — this is a hardening/compliance requirement, not just a UX nicety.
- **Health-adjacent data sensitivity:** body measurements, nutrition, and AI coaching conversations are treated as sensitive personal data even where not strictly regulated as "health data" in every jurisdiction — access-logged, encrypted at rest, and excluded from any future analytics/ML training use without explicit opt-in.
- **Children's privacy:** MVP targets adults (18+, [PRD § Target Audience](01-prd.md#3-target-audience)); age-gating at registration and no design accommodation for under-13 users (avoiding COPPA scope entirely rather than attempting partial compliance).
- **App store requirements:** privacy manifest/data-use disclosures (Apple App Privacy, Google Data Safety) kept in sync with the actual data flows documented in [Database Design](04-database-design.md) and this document — reviewed every release, not just at initial submission.
- **AI provider data handling:** Anthropic's API data-usage terms for the account tier in use are reviewed and referenced here as the basis for what user data is permissible to send as AI context — the [AI Coaching Engine § Context Management](09-ai-coaching-engine.md#3-context-management) scoping (persona-limited, summarized, no raw dump) is itself a data-minimization control, not just a cost control.
