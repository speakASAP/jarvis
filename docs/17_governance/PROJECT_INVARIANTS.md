# Project Invariants

```yaml
id: PROJECT-INVARIANTS
status: approved
owner: ssf
created: 2026-09-12
last_updated: 2026-09-12
completeness_level: complete
upstream:
  - ../00_constitution/CONSTITUTION.md
  - ../01_vision/VISION.md
```

## Purpose

jarvis writes derived knowledge from owner-curated sources and serves it to other
services. Two classes of failure are unacceptable and are not caught by ordinary
tests: silent corruption of the accumulated wiki, and jarvis becoming a second
task authority competing with RunLayer. These invariants gate both.

## Applicability

Project-specific invariants apply. jarvis holds a compounding artifact that
cannot be cheaply re-derived, so integrity rules are stricter than for a
stateless service.

## Invariants

| ID | Level | Source | Rule | Forbidden outcome | Validation method | Gate |
|---|---|---|---|---|---|---|
| INV-001 | constitutional | `../00_constitution/CONSTITUTION.md` | Raw sources are immutable; jarvis reads them and never rewrites or deletes them | A raw source is modified or lost by a jarvis operation | Checksum of the raw bucket is unchanged after ingest/query/lint | pre-coding/deployment |
| INV-002 | project | `../01_vision/VISION.md` | jarvis exposes no task, plan, todo or approval surface; RunLayer is the sole task authority | LWC plan/todo endpoints reachable through the public API | Route enumeration from the running app shows no plan/todo path | pre-coding/deployment |
| INV-003 | project | `../01_vision/VISION.md` | Every answer cites the wiki pages and raw sources it derives from | An answer is returned with no resolvable citation | Query fixture asserts every citation resolves | pre-coding/deployment |
| INV-004 | project | `../06_architecture/INTEGRATION_CONTRACT.md` | A failed or partial AI operation leaves the wiki byte-identical; writes are all-or-nothing | A half-written page is committed after an AI or network failure | Fault-injection test compares wiki tree hash before and after a forced failure | pre-coding/deployment |
| INV-005 | project | `../06_architecture/INTEGRATION_CONTRACT.md` | No wiki or raw state lives only on container disk; all durable state is in PostgreSQL or MinIO | Pod replacement loses wiki pages or sources | Delete the pod and verify wiki content is unchanged | deployment |
| INV-006 | constitutional | `SERVICE_IDENTITY_CONSUMER_STANDARD.md` | Every endpoint except `/health` requires a validated identity; no anonymous read | An unauthenticated request returns wiki content | Enumerate routes from the running app and assert 401 without a token | pre-coding/deployment |
| INV-007 | project | `../01_vision/VISION.md` | jarvis holds no third-party model provider key; model access is only through ai-microservice | A provider API key appears in jarvis config, Vault path or environment | Vault key inventory and environment review contain no provider key | pre-coding/deployment |

## Exceptions

None approved.

## Review cadence

Reviewed at every task that changes the public API surface, the persistence
model, or an integration decision in `ips-adoption.json`; and at each deployment
gate.
