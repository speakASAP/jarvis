# TASK-001-bootstrap-service: Bootstrap jarvis

```yaml
id: TASK-001-bootstrap-service
status: approved
owner: "ssf"
created: 2026-09-12
last_updated: 2026-09-12
completeness_level: complete
upstream:
  - ../../BUSINESS.md
  - ../../SYSTEM.md
  - ../01_vision/VISION.md
goal_impact:
  - ../22_goal_impact/GOAL-IMPACT-TASK-001.md
execution_plan:
  - ../21_execution_plans/EP-TASK-001-bootstrap-service.md
project_invariant_impact: preserves
sensitive_data_classification: none
contract_schema_impact: creates
replay_determinism_impact: affected
parallel_workstream_context: final-integration
required_gates:
  - adoption
  - pre-coding
```

## Objective

Deliver jarvis as a deployable, ecosystem-integrated runtime service at
`jarvis.alfares.cz` (port 4870, namespace `statex-apps`) that wraps the LWC
engine behind an authenticated HTTP API exposing ingest, query, lint and wiki
read, with durable state in PostgreSQL and MinIO, and no task/plan surface.


## Upstream links

- `../01_vision/VISION.md` - one-sentence vision, key outcomes, non-goals
- `../../BUSINESS.md` - product intent
- `../../SYSTEM.md` - service responsibilities
- `../06_architecture/INTEGRATION_CONTRACT.md` - capability decisions
- `../17_governance/PROJECT_INVARIANTS.md` - INV-001..INV-007


## Goal impact

Establishes the ecosystem's compounding knowledge layer. See
`../22_goal_impact/GOAL-IMPACT-TASK-001.md`.


## Project invariant impact

Preserves INV-001 through INV-007. INV-002 (no task surface) and INV-006 (no
anonymous read) are the two this task most directly establishes: the wrapper
exposes a deliberately reduced subset of the LWC CLI and guards every route
except `/health`.


## Sensitive-data classification

Raw sources are owner-curated and may contain internal ecosystem detail. No
payment, credential or personal-data class is in scope. Vault key names are
recorded; values never appear in Git, docs, logs or transcripts. Test fixtures
use synthetic sources only.


## Contract and schema impact

Creates:
- HTTP API: `POST /ingest`, `POST /query`, `POST /lint`, `GET /wiki/*`, `GET /health`
- PostgreSQL schema: raw source metadata, wiki page, citation edge, operation log
- MinIO bucket `jarvis-raw`
- Auth application identity `jarvis` with `user`, `editor`, `admin` roles
- Vault path `secret/prod/jarvis` declared through `k8s/external-secret.yaml`

Deliberately not created: any plan, todo, task or approval endpoint (INV-002).


## Replay and determinism impact

Ingest is idempotent by raw-source checksum: re-ingesting an identical source is
a no-op. Wiki writes are all-or-nothing, so a retried failed ingest cannot leave
a partial page (INV-004). LLM synthesis is not bit-deterministic; validation
asserts structural properties (page exists, citations resolve), never exact text.


## Scope

- Vendor the LWC engine and pin its version.
- HTTP wrapper exposing ingest/query/lint/wiki-read only.
- Persistence adapters for PostgreSQL and MinIO replacing local-only state.
- Integrations: auth, ai, logging, notifications, monitoring, docs-rag, backups.
- Kubernetes manifests, ExternalSecret wiring, ingress for `jarvis.alfares.cz`.
- Bootstrap validation evidence.


## Non-goals

- No plan/todo/task surface (INV-002); RunLayer remains sole task authority.
- No RunLayer, ai-microservice, auth-microservice or frontend code changes; jarvis
  publishes a contract they may consume later.
- No public anonymous access.
- No replacement of docs-RAG direct Git ingestion.
- No LWC learning suite (tutor, book, practice) exposure.


## Acceptance criteria

- [ ] Planning and pre-coding gates pass; every capability is `required` or `not-applicable` with a reason.
- [ ] `POST /ingest` of a fixture source creates a wiki page whose citations resolve; re-ingest is a no-op.
- [ ] `POST /query` returns an answer citing existing pages; `POST /lint` reports a seeded contradiction.
- [ ] Route enumeration against the running app shows no plan/todo route and 401 without a token (INV-002, INV-006).
- [ ] ExternalSecret is `Ready=True`, pod starts with intended key names, `GET /health` passes, pod deletion loses no wiki state (INV-005).


## Required context

- `../../BUSINESS.md`
- `../../SYSTEM.md`
- `../06_architecture/INTEGRATION_CONTRACT.md`
- `../17_governance/PROJECT_INVARIANTS.md`
- `../21_execution_plans/EP-TASK-001-bootstrap-service.md`
- `/home/ssf/Documents/Github/shared/docs/CREATE_SERVICE.md`
- `/home/ssf/Documents/Github/intent-preservation-system/docs/24_onboarding/PROJECT_ADOPTION_STANDARD.md`

## Validation task

Validation report:
`../12_validation/VAL-TASK-001-bootstrap-service.md`.

## Required gates

| Gate | Command or evidence | Blocks on |
| --- | --- | --- |
| Adoption | `python3 ../intent-preservation-system/scripts/validate_adoption_profile.py --root . --phase planning` | Missing/incomplete project documents or integration decisions |
| Pre-coding | `python3 ../intent-preservation-system/scripts/pre_coding_gate.py --root .` | Traceability, invariants, scope or sensitive-data violations |
| Application | `cargo test && cargo clippy -- -D warnings` | Implementation regression |
| Integration | Contract tests for auth, postgres, minio, ai; route/auth enumeration against the running app | Broken required integration |

## Parallel workstream context

- Ready-now: vendoring LWC, HTTP wrapper, persistence adapters, manifests.
- Dependency-gated: Auth identity and roles; Vault keys; MinIO bucket; PostgreSQL role.
- Blocked: none.
- Final-integration: consumption by RunLayer, ai-microservice and the frontend,
  which are separate tasks against the published contract.
