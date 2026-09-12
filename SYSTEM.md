# System: jarvis

```yaml
id: SYSTEM-jarvis
status: approved
owner: "ssf"
created: 2026-09-12
last_updated: 2026-09-12
completeness_level: complete
upstream:
  - BUSINESS.md
  - docs/01_vision/VISION.md
downstream:
  - docs/06_architecture/INTEGRATION_CONTRACT.md
  - docs/11_tasks/TASK-001-bootstrap-service.md
```

## Purpose

jarvis is the ecosystem's knowledge layer. It wraps the vendored LWC engine in an
authenticated HTTP service at `jarvis.alfares.cz` (port 4870, namespace
`statex-apps`), converting owner-curated raw sources into a maintained,
interlinked wiki and serving citation-backed synthesis to humans and services.


## Responsibilities

- Accept and durably store raw sources, immutably, in MinIO `jarvis-raw`
- Ingest a source into wiki pages and update related pages and the index
- Answer queries with synthesis plus resolvable citations
- Lint the wiki for contradictions, stale claims, orphan pages and missing cross-references
- Maintain wiki state, citation edges and an append-only operation log in PostgreSQL
- Enforce identity on every route except `/health`
- Emit structured logs, expose health for probes, and notify the owner of lint findings


## Non-responsibilities

- Task, plan, goal and approval state - owned by RunLayer (INV-002)
- Repository documentation retrieval - owned by docs-rag-microservice
- Model hosting or provider credentials - owned by ai-microservice (INV-007)
- Identity issuance - owned by auth-microservice
- Authoring or mutating raw sources (INV-001)


## Inputs

- Owner-curated raw sources (text, PDF, images) via authenticated upload
- Queries from the owner and from authorized services
- Lint invocations, scheduled or on demand
- Validated identities from auth-microservice
- Model completions from ai-microservice


## Outputs

- Wiki pages with citations, reachable at `GET /wiki/*`
- Query answers with resolvable citations
- Lint reports of contradictions, stale claims and orphan pages
- Owner notifications for lint findings
- Structured logs to logging-microservice and health for monitoring-microservice


## Dependencies

| Dependency | Kind | Purpose |
| --- | --- | --- |
| `auth-microservice` | required, sync | Identity validation on every guarded route |
| `db-server-postgres` | required, sync | Wiki pages, citations, operation log |
| `minio-microservice` | required, sync | Immutable raw source bytes |
| `ai-microservice` | required, sync | Ingest, query synthesis, lint |
| `logging-microservice` | required, fire-and-forget | Structured logs |
| `notifications-microservice` | required, fire-and-forget | Lint findings to the owner |
| `monitoring-microservice` | required | Health and probes |
| `docs-rag-microservice` | required | Documentation discoverability |
| `backups-microservice` | required | Database and bucket backup |

Full contracts, timeouts and degraded behavior: `docs/06_architecture/INTEGRATION_CONTRACT.md`.


## Upstream traceability

- `BUSINESS.md`
- `docs/01_vision/VISION.md`
- `docs/00_constitution/CONSTITUTION.md`
- `docs/17_governance/PROJECT_INVARIANTS.md`


## Downstream artifacts

- `docs/11_tasks/TASK-001-bootstrap-service.md`
- `docs/21_execution_plans/EP-TASK-001-bootstrap-service.md`
- `docs/06_architecture/INTEGRATION_CONTRACT.md`
- `k8s/` manifests and `deploy.config.sh`


## Validation criteria

- Ingest creates a page and updates related pages; re-ingest of an identical source is a no-op
- Every citation in a query response resolves
- Lint reports a seeded contradiction
- Route enumeration against the running app shows no plan/todo route and 401 without a token
- ExternalSecret `Ready=True`, `/health` passes, and pod deletion loses no wiki state


## Open questions

- Whether lint runs on a schedule or only on demand; on-demand at bootstrap, a CronJob may follow (any CronJob must not reuse the `app:` label of the Service).
- Retention policy for superseded wiki page versions.
- Whether a read-only web view is exposed later; out of bootstrap scope.
