# EP-TASK-001-bootstrap-service: Bootstrap jarvis

```yaml
id: EP-TASK-001-bootstrap-service
status: approved
source_task: ../11_tasks/TASK-001-bootstrap-service.md
goal_impact:
  - ../22_goal_impact/GOAL-IMPACT-TASK-001.md
validation:
  - ../12_validation/VAL-TASK-001-bootstrap-service.md
owner: "ssf"
created: 2026-09-12
last_updated: 2026-09-12
completeness_level: complete
parallelization_strategy: parallel_goals
required_gates:
  - adoption
  - pre-coding
```

## Upstream traceability

- Business intent: `../../BUSINESS.md`
- Vision: `../01_vision/VISION.md`
- System responsibilities: `../../SYSTEM.md`
- Task: `../11_tasks/TASK-001-bootstrap-service.md`
- Goal impact: `../22_goal_impact/GOAL-IMPACT-TASK-001.md`
- Contract: `../06_architecture/INTEGRATION_CONTRACT.md`
- Upstream engine: JanYork/llm-wiki-cli (Apache-2.0), pinned version

## Scope

Vendor the LWC engine, wrap it in an authenticated HTTP service exposing
ingest/query/lint/wiki-read, move durable state to PostgreSQL and MinIO, wire the
required integrations, and ship to `statex-apps` at `jarvis.alfares.cz`.

## Non-goals

No plan/todo surface. No changes to RunLayer, ai-microservice, auth-microservice
or the frontend. No public anonymous access. No LWC learning suite exposure. No
replacement of docs-RAG Git ingestion.

## Project invariants

INV-001..INV-007 from `../17_governance/PROJECT_INVARIANTS.md`. INV-002 and
INV-006 are enforced by the routing layer and asserted by enumeration against the
running app, not by static scan. INV-004 is enforced by transactional wiki writes
and asserted by fault injection.

## Sensitive-data handling

Vault key names only in Git and docs; values never printed. Fixtures are
synthetic. Logs carry operation metadata, never source content or tokens.
Evidence files contain no secret values.

## Contract validation plan

- API: schema tests per route; citation resolution asserted on query responses.
- Persistence: migration applied with `migrate deploy` after an offline diff; never `migrate dev`.
- Auth: token-valid, token-invalid and no-token cases per route.
- AI: success, timeout and outage cases; outage asserts a byte-identical wiki.
- Storage: upload/retrieve round trip; credential scope limited to `jarvis-raw`.

## Replay and determinism plan

Ingest is idempotent by source checksum. Retries of a failed ingest cannot commit
a partial page. Assertions are structural (page exists, citations resolve, counts
change) because LLM output is not bit-deterministic.

## Files to inspect

- `../06_architecture/INTEGRATION_CONTRACT.md`, `../17_governance/PROJECT_INVARIANTS.md`
- `/home/ssf/Documents/Github/shared/docs/CREATE_SERVICE.md`, `DEPLOY_STANDARD.md`, `ECOSYSTEM_MAP.md`
- `/home/ssf/Documents/Github/auth-microservice/docs/SERVICE_IDENTITY_CONSUMER_STANDARD.md`
- Vendored LWC: `src/store/*.rs`, `src/view/mod.rs`, `src/agent/tool_protocol.rs`

## Files to create

- `src/` HTTP wrapper: routing, guards, handlers, persistence adapters, integration clients
- `migrations/` initial schema
- `tests/` unit, contract, failure-mode, route-enumeration
- `Dockerfile`, `.dockerignore`
- `docs/12_validation/VAL-TASK-001-bootstrap-service.md` evidence

## Files to modify

- `k8s/*.yaml` (scaffolded), `deploy.config.sh`, `.env.example`, `README.md`, `SYSTEM.md`, `TASKS.md`, `STATE.json`
- Ecosystem: `shared/ECOSYSTEM_MAP.md`, `shared/config/ecosystem-repositories.json`

## Files that must not be modified

- `docs/00_constitution/CONSTITUTION.md`
- `docs/01_vision/VISION.md`
- `docs/17_governance/PROJECT_INVARIANTS.md` (without a fresh invariant review)
- Any file in another repository (RunLayer, ai-microservice, auth-microservice, frontend)

## Implementation steps

1. Vendor LWC at a pinned version; record upstream commit and Apache-2.0 notice.
2. Define the PostgreSQL schema and generate the initial migration offline.
3. Build the HTTP layer with an explicit route table; omit plan/todo entirely.
4. Apply the auth guard per route, allowing only `/health` unauthenticated.
5. Replace local-only persistence with PostgreSQL and MinIO adapters.
6. Route all model calls through ai-microservice; hold no provider key.
7. Add logging, notifications and `/health` with Kubernetes probes.
8. Write tests including fault injection and route enumeration.
9. Provision Auth identity/roles, Vault keys, MinIO bucket, PostgreSQL role.
10. Render manifests, verify ExternalSecret readiness, deploy via the serialized runner.
11. Record validation evidence and register catalog, ecosystem map and docs-RAG.

## Parallel execution

| Workstream | Status | Owner role | Allowed files | Dependencies | Validation | Merge order |
| --- | --- | --- | --- | --- | --- | --- |
| Documentation and contracts | complete | Intent owner | `docs/**`, `ips-adoption.json` | Approved vision | Adoption gate passes | first |
| Application implementation | ready-now | Implementation owner | `src/**`, `tests/**`, `migrations/**`, `Dockerfile` | Approved contracts | `cargo test`, contract tests | second |
| Infrastructure provisioning | dependency-gated | Integration owner | Vault, MinIO, PostgreSQL, Auth registration | Owner authorization | ExternalSecret `Ready=True`, scoped access verified | second (parallel) |
| Deployment and integration | final integration | Integration owner | `k8s/**`, `deploy.config.sh`, ecosystem catalog | Validated application and infrastructure | Health, pod-age check, route enumeration | last |

## Blockers

None blocking documentation or implementation. Infrastructure provisioning needs
owner authorization for: Auth application registration, Vault path
`secret/prod/jarvis`, MinIO bucket, PostgreSQL role. Deployment is owner-gated
per the standard; sub-agents stop before deployment.

## Test plan

- Unit: citation extraction, checksum idempotency, route table shape.
- Contract: each route against auth-valid/invalid/absent; persistence round trips.
- Integration: ingest to query end to end on synthetic fixtures.
- Failure-mode: AI outage (wiki byte-identical), PostgreSQL down (readiness fails),
  MinIO down (ingest rejected), logging down (request path unaffected).
- Invariant: route enumeration proves no plan/todo route and no anonymous read.

## Validation plan

| Acceptance criterion | Command / evidence |
| --- | --- |
| Gates pass | `validate_adoption_profile.py --phase planning`; `pre_coding_gate.py` |
| Ingest creates page, re-ingest no-op | Fixture ingest run; page and citation counts |
| Query cites resolvable pages | Query fixture; citation resolution count |
| Lint reports contradiction | Seeded-contradiction lint run |
| No plan/todo route, 401 without token | Route enumeration against the running app |
| Deployment healthy, state durable | ExternalSecret `Ready=True`, `/health`, pod age vs commit time, pod-deletion retention |

## Gate commands

Run from the adopting repository:

```bash
python3 ../intent-preservation-system/scripts/validate_adoption_profile.py --root . --phase planning
python3 ../intent-preservation-system/scripts/pre_coding_gate.py --root .
```

The central deployment-readiness gate is intended for repositories adopting
the complete IPS tree. Lightweight service adoption uses the adoption gate,
project tests, integration evidence and the shared deployment preflight.

## Documentation updates

`README.md`, `SYSTEM.md`, `TASKS.md`, `STATE.json`, the validation report, and the
ecosystem catalog, map and port registry.

## Rollback plan

- Code: revert the commit; auto-deploy ships the previous image.
- Migration: forward-only; the initial migration is additive, so rollback is dropping the unused database.
- Manifests: `kubectl rollout undo` for the deployment.
- Integration: jarvis has no consumers at bootstrap, so removal breaks nothing; catalog and map entries are reverted with the commit.
- Data: raw sources are immutable in MinIO and survive a rollback; the wiki is regenerable by re-ingest.

## Handoff

Implementation owner delivers passing tests plus route-enumeration output.
Integration owner performs provisioning and deployment and completes the
validation report. Deployment is not performed by a sub-agent.

## Completion checklist

- [x] Protected intent approved
- [ ] Adoption profile valid
- [x] Integration decisions complete
- [ ] Implementation and tests complete
- [ ] Required integrations exercised
- [ ] Deployment dry run passes
- [ ] Validation report complete
