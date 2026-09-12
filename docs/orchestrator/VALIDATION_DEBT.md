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
| VD-002 | 2026-09-12 | `seed-jarvis-roles.js --apply`; `provision-service-token.js --apply` | RESOLVED 2026-09-12: owner granted the permission. Application `jarvis`, 5 roles and 4 S2S principals created; 7 Vault keys written and matched against `k8s/external-secret.yaml` | Auth identity provisioning | ssf | None; all required infrastructure is provisioned | Closed | This ledger; `--check-db-only` output showed hasRequiredRole=true for all four pairs |

## Update format

When debt exists, add a table with: ID, date, command, sanitized failure,
scope, owner, current-task impact, unblock condition and evidence path.
