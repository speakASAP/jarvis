# jarvis

jarvis is the Alfares ecosystem's knowledge layer. It turns owner-curated raw
sources into a maintained, interlinked wiki - the Karpathy LLM Wiki pattern -
and serves citation-backed synthesis over an authenticated HTTP API to the owner
and to other services. Unlike retrieval that re-derives an answer from raw
documents on every question, jarvis compiles knowledge once and keeps it current,
so the wiki compounds with every source added. It owns knowledge only: RunLayer
remains the sole authority for tasks, plans and approval gates.

## Status

- Lifecycle: onboarding
- Production status: not deployed
- Owner: ssf
- Domain: `jarvis.alfares.cz`
- Port: 4870
- Namespace: `statex-apps`
- Engine: vendored [LWC](https://github.com/JanYork/llm-wiki-cli) (Apache-2.0)

## Documentation authority

- Business intent: [`BUSINESS.md`](BUSINESS.md)
- System contract: [`SYSTEM.md`](SYSTEM.md)
- Agent instructions: [`AGENTS.md`](AGENTS.md)
- Current work: [`TASKS.md`](TASKS.md)
- Machine-readable state: [`STATE.json`](STATE.json)
- IPS adoption: [`ips-adoption.json`](ips-adoption.json)
- Integration decisions:
  [`docs/06_architecture/INTEGRATION_CONTRACT.md`](docs/06_architecture/INTEGRATION_CONTRACT.md)

Git is authoritative. docs-RAG is a derived discovery index.

## Capabilities

- **Ingest** - store a raw source immutably, derive a summary page, update related pages and the index
- **Query** - answer a question from the wiki with resolvable citations
- **Lint** - report contradictions, stale claims, orphan pages and missing cross-references
- **Wiki read** - fetch pages and their citations

Not provided: tasks, plans, todos or approval gates (see RunLayer).

## Interfaces

| Method | Path | Role | Purpose |
| --- | --- | --- | --- |
| POST | `/ingest` | `app:jarvis:editor` | Add a raw source and update the wiki |
| POST | `/query` | `app:jarvis:user` | Ask a question; returns answer plus citations |
| POST | `/lint` | `app:jarvis:editor` | Run wiki health checks |
| GET | `/wiki/*` | `app:jarvis:user` | Read wiki pages |
| GET | `/health` | none | Liveness and readiness |

No events are published or consumed. Service-to-service callers authenticate per
`SERVICE_IDENTITY_CONSUMER_STANDARD.md`.

## Development

```bash
cargo build
cargo test
cargo clippy -- -D warnings
cargo run
```

Implementation is pending; `TASK-001-bootstrap-service` is the active task.

## Configuration

Names and safe examples live in [`.env.example`](.env.example). Secret values
exist only in Vault at `secret/prod/jarvis` and reach pods through
[`k8s/external-secret.yaml`](k8s/external-secret.yaml). Never commit a value, and
never create a plaintext Kubernetes Secret.

## Deployment

Deployment uses `deploy.config.sh` and the shared runner:

```bash
../shared/scripts/deploy.sh jarvis --dry-run
```

Before concluding a deploy result:

- confirm the `ExternalSecret` is `Ready=True` (a sealed Vault fails deploys with
  a message that never mentions Vault);
- verify the rollout by comparing pod age to commit time, not by matching log lines;
- enumerate routes against the running pod to confirm no plan/todo route is
  reachable and that every route except `/health` rejects an unauthenticated call.

## Health and observability

`GET /health` is unauthenticated and backs the Kubernetes liveness and readiness
probes; readiness fails when PostgreSQL is unreachable so an unhealthy pod leaves
rotation. Structured logs go to `logging-microservice` as service `jarvis`;
delivery is fire-and-forget and never throws into the request path. Lint findings
are delivered to the owner through `notifications-microservice`.
