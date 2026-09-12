# Repository Agent Instructions: jarvis

## Required reading

Read in this order before planning or implementation:

1. `BUSINESS.md`
2. `SYSTEM.md`
3. `README.md`
4. `TASKS.md`
5. `STATE.json`
6. `ips-adoption.json`
7. `docs/00_constitution/CONSTITUTION.md`
8. `docs/01_vision/VISION.md`
9. `docs/06_architecture/INTEGRATION_CONTRACT.md`
10. The active task, goal-impact record, execution plan and validation plan

## Authority

- Git files in this repository are authoritative for project intent and behavior.
- Ecosystem authority is defined in
  `/home/ssf/Documents/Github/shared/docs/DOCUMENTATION_AUTHORITY.md`.
- Cross-agent rules are defined in
  `/home/ssf/.ai-agent-standards/CROSS_AGENT_AUTOMATION_STANDARD.md`.
- docs-RAG is a derived discovery index; verify critical facts against Git.
- While onboarding is incomplete, use the canonical workflow at
  `/home/ssf/Documents/Github/shared/.agents/skills/register-new-app/SKILL.md`
  and do not bypass its planning or ecosystem-registration gates.

## Intent Preservation System

Preserve this chain:

```text
Vision -> Goal Impact -> System -> Feature -> Task -> Execution Plan -> Coding Prompt -> Code -> Validation
```

Do not implement while required intent, scope, integration, invariant or
validation information is missing. Record unavailable facts as `[MISSING: ...]`
or `[UNKNOWN: ...]`; never invent them.

## Safety and operations

- Work in the authoritative server checkout.
- Do not print or commit secrets, tokens or raw production data.
- Use Vault and External Secrets for runtime secrets.
- Follow `AGENT_OPERATIONS.md` for parallel work, validation debt and handoff.
- Use the shared deployment runner and ecosystem deploy lock.
- Do not modify protected constitution, vision or approved business intent
  without a human-approved amendment.

## Project-specific rules

- jarvis never gains a task, plan, todo or approval surface. RunLayer is the sole
  task authority (INV-002). Do not expose the vendored LWC plan/todo commands.
- Raw sources are immutable. No code path rewrites or deletes an ingested source (INV-001).
- Wiki writes are all-or-nothing. A failed AI call must leave the wiki
  byte-identical; never commit a partial page (INV-004).
- Every route except `GET /health` requires a validated identity (INV-006).
  Verify guards by enumerating routes from the running application - static
  coverage scanners report false negatives on guard scope.
- No third-party model provider key in jarvis. All model access is through
  ai-microservice (INV-007).
- Secrets: Vault key names only in Git, docs and terminal output. Never values.
- Answers must carry resolvable citations (INV-003).
- Durable state belongs in PostgreSQL or MinIO, never container disk (INV-005).
- Migrations: generate offline, apply with `migrate deploy`. Never `migrate dev`
  against a live database.
- Stop before deployment; deployment is owner-gated and serialized.

## Required final report

Report files changed, documents created, validation evidence, validation debt,
blockers, deviations and the next concrete action.
