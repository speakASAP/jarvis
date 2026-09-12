# Validation Debt Ledger

## Purpose

Record known validation failures that are not caused by the active task.

## Rules

- Validation debt never excuses a current-task failure.
- Every entry requires an owner, scope and unblock condition.
- Do not include secrets, tokens, raw production data or private evidence.
- Promote an entry to an active blocker when it affects changed files,
  acceptance criteria or required integrations.

## Entries

| ID | Date | Command | Sanitized failure | Scope | Owner | Current-task impact | Unblock condition | Evidence path |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| VD-001 | 2026-09-12 | `rag_search "jarvis LLM Wiki knowledge layer"` | No result returns `repoName: jarvis`; docs-RAG is healthy but has not yet indexed the repository | Onboarding, docs-RAG registration | ssf | None on documentation or gates; the required docs-RAG capability cannot be evidenced until the next ingestion pass | jarvis appears in the catalog (done 2026-09-12) and docs-RAG completes an ingestion run; re-run the query and confirm the owning repository path resolves | This ledger; verified live 2026-09-12 |
| VD-002 | 2026-09-12 | `kubectl cp` / `kubectl exec ... seed-jarvis-roles.js --apply` | Blocked by the harness permission classifier (`[Remote Shell Writes]`) before any write | Auth identity provisioning | ssf | Blocks 6 of 9 Vault keys and every authenticated route; PostgreSQL and MinIO are provisioned | Owner runs `auth-microservice/scripts/seed-jarvis-roles.js` in the auth pod, then `provision-service-token.js` for the four S2S pairs, or grants the permission | This ledger; `auth-microservice/scripts/seed-jarvis-roles.js` (uncommitted) |

## Update format

When debt exists, add a table with: ID, date, command, sanitized failure,
scope, owner, current-task impact, unblock condition and evidence path.
