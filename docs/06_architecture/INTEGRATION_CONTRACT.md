# Integration Contract

## Purpose

jarvis is the ecosystem's knowledge layer. It converts owner-curated raw sources
into a maintained, interlinked wiki and serves citation-backed synthesis over
HTTP to humans and to other Alfares services. It consumes model capacity,
identity, storage and observability from the ecosystem; it publishes knowledge.

It deliberately does not participate in task orchestration. RunLayer is the sole
task authority and is a consumer of jarvis, not a peer task store (INV-002).

## Capability decisions

The machine-readable decisions live in `ips-adoption.json`. This document adds
the human-readable architecture and contract links.

| Capability | Component | Decision | Contract/API/event | Configuration | Failure mode | Validation evidence |
| --- | --- | --- | --- | --- | --- | --- |
| Auth | `auth-microservice` | required | RS256 service identity + user roles per SERVICE_IDENTITY_CONSUMER_STANDARD.md | AUTH_SERVICE_URL, JARVIS_CLIENT_ID, JARVIS_CLIENT_SECRET via ESO | Requests rejected with 401 when token invalid or Auth unreachable; no anonymous fallback | Unauthenticated request to /query returns 401; valid service token returns 200 |
| PostgreSQL | `db-server-postgres` | required | Dedicated database jarvis with least-privilege role jarvis_app | DATABASE_URL via ESO from secret/prod/jarvis | Service fails readiness when database unreachable; never starts with an empty fallback store | Readiness probe fails on bad DSN; migrations apply with migrate deploy |
| Redis | `db-server-redis` | not-applicable | not-applicable | not-applicable | not-applicable | not-applicable |
| Logging | `logging-microservice` | required | HTTP POST to logging-microservice with service=jarvis | LOGGING_SERVICE_URL from configmap | Log delivery is fire-and-forget and must never throw into the request path; failures degrade to stderr | Ingest and query operations appear in logging-microservice for service jarvis |
| Notifications | `notifications-microservice` | required | HTTP POST to notifications-microservice, PLAIN parse mode | NOTIFICATIONS_SERVICE_URL from configmap | Notification failure is logged and never blocks or fails the lint run | A seeded lint contradiction produces one owner notification |
| AI | `ai-microservice` | required | HTTP to ai-microservice completion endpoint | AI_SERVICE_URL from configmap; no provider API key held by jarvis | Ingest/query return 503 and change no wiki state when AI is unavailable; partial pages are never committed | Ingest of a fixture source produces a wiki page; AI outage leaves wiki byte-identical |
| Payments | `payments-microservice` | not-applicable | not-applicable | not-applicable | not-applicable | not-applicable |
| Catalog | `catalog-microservice` | not-applicable | not-applicable | not-applicable | not-applicable | not-applicable |
| Orders | `orders-microservice` | not-applicable | not-applicable | not-applicable | not-applicable | not-applicable |
| Warehouse | `warehouse-microservice` | not-applicable | not-applicable | not-applicable | not-applicable | not-applicable |
| Invoices | `invoices-microservice` | not-applicable | not-applicable | not-applicable | not-applicable | not-applicable |
| Object storage | `minio-microservice` | required | Private MinIO bucket jarvis-raw with bucket-scoped credentials | MINIO_ENDPOINT, MINIO_ACCESS_KEY, MINIO_SECRET_KEY, MINIO_BUCKET via ESO | Ingest fails loudly when the bucket is unreachable; no silent local-disk fallback | Upload then retrieve a fixture source; credentials reach no other bucket |
| Events | `RabbitMQ` | not-applicable | not-applicable | not-applicable | not-applicable | not-applicable |
| Documentation retrieval | `docs-rag-microservice` | required | Direct Git repository ingestion | shared/config/ecosystem-repositories.json | Git remains authoritative when retrieval is unavailable or unconfident | Distinctive project phrase resolves to the owning repository path |
| Monitoring | `monitoring-microservice` | required | GET /health plus Kubernetes probes | Deployment probes and service metadata | Readiness prevents unhealthy rollout | Health and readiness checks pass |
| Backups | `backups-microservice` | required | Scheduled backup of jarvis database and jarvis-raw bucket | Registered with backups-microservice schedule | A missed backup window raises an alert rather than passing silently | Restore rehearsal reproduces wiki pages and raw sources |

## Data ownership

| Entity | Owner | Store | Notes |
| --- | --- | --- | --- |
| Raw source blob | jarvis | MinIO `jarvis-raw` | Immutable after upload (INV-001) |
| Raw source metadata | jarvis | PostgreSQL `jarvis` | Checksum, origin, ingest timestamp |
| Wiki page | jarvis | PostgreSQL `jarvis` | Derived; regenerable only by re-ingest |
| Citation edge | jarvis | PostgreSQL `jarvis` | Page to source and page to page |
| Ingest/lint log | jarvis | PostgreSQL `jarvis` | Append-only operation record |
| Task, plan, goal | RunLayer | RunLayer store | jarvis never persists these (INV-002) |
| Repository documentation | docs-rag-microservice | Git | jarvis does not duplicate it |

## Authentication and authorization

- Every route except `GET /health` requires a validated identity (INV-006).
- Service-to-service calls use paired RS256 service identity plus roles, per the
  sole canonical `SERVICE_IDENTITY_CONSUMER_STANDARD.md`.
- User-facing access is via the hosted Auth flow at `auth.alfares.cz`; jarvis
  registers as a `user_facing` application with role `app:jarvis:user`.
- Roles: `app:jarvis:user` reads wiki and queries; `app:jarvis:editor` ingests and
  lints; `app:jarvis:admin` manages sources and deletions.
- jarvis holds no third-party model provider key (INV-007).

## Synchronous dependencies

| Dependency | Purpose | Timeout | On failure |
| --- | --- | --- | --- |
| `auth-microservice` | Token validation | 5s | 401; never fall through to anonymous |
| `db-server-postgres` | Durable wiki state | 5s | Readiness fails; no in-memory fallback |
| `minio-microservice` | Raw source bytes | 10s | Ingest fails loudly; no local-disk fallback |
| `ai-microservice` | Ingest, query synthesis, lint | 120s | 503; wiki left byte-identical (INV-004) |

## Asynchronous dependencies

None. `event-bus` is `not-applicable`: RunLayer calls jarvis synchronously and no
async fan-out is in approved scope. Logging and notification deliveries are
fire-and-forget side effects, never request-path dependencies.

## Degraded operation

| Unavailable | Behavior |
| --- | --- |
| ai-microservice | Reads and `GET /wiki/*` continue from stored pages; ingest/query/lint return 503 and write nothing |
| PostgreSQL | Readiness fails and the pod leaves rotation; no writes attempted |
| MinIO | Existing wiki reads continue; new ingest is rejected |
| auth-microservice | All authenticated routes return 401; no anonymous degradation (INV-006) |
| logging-microservice | Request path unaffected; logs degrade to stderr and never throw |
| notifications-microservice | Lint completes and records findings; delivery failure is logged only |

## Validation

- Capability decisions: `python3 ../intent-preservation-system/scripts/validate_adoption_profile.py --root . --phase planning`
- Invariants: `docs/17_governance/PROJECT_INVARIANTS.md`
- Bootstrap evidence: `docs/12_validation/VAL-TASK-001-bootstrap-service.md`
- Route/auth enumeration is performed against the running application, not by
  static scan, because coverage scanners report false negatives on guard scope.
