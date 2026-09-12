# GOAL-IMPACT-TASK-001: Bootstrap jarvis

```yaml
id: GOAL-IMPACT-TASK-001
artifact_type: task
artifact_id: TASK-001-bootstrap-service
artifact_path: ../11_tasks/TASK-001-bootstrap-service.md
primary_goal: "Establish a compounding ecosystem knowledge layer (VISION-jarvis, One-sentence vision)"
secondary_goals:
  - "Keep RunLayer the sole task authority while giving it grounded knowledge (VISION-jarvis, Non-goals)"
  - "Centralize model access through ai-microservice (INV-007)"
impact_level: high
status: approved
```

## Goal

`../01_vision/VISION.md`, "One-sentence vision" and "Key outcomes": the ecosystem
needs a knowledge layer that accumulates instead of re-deriving, serving
citation-backed synthesis to humans and services.

## Contribution

The bootstrap task is what makes the goal reachable at all: it converts LWC from
a single-operator local CLI into an authenticated ecosystem service with durable
state. Without it, knowledge stays on one machine, unreachable by RunLayer or any
other consumer, and is lost with the container.

It also fixes the authority boundary at the outset. Exposing a reduced API
surface that omits plan/todo (INV-002) prevents the second task store that would
otherwise compete with RunLayer and cause the orchestration drift RunLayer exists
to prevent.

## Success metric

Measurable, not file creation:

- Ingesting N sources produces N source pages plus a non-zero number of updated
  related pages, demonstrating compounding rather than isolated storage.
- 100% of citations in a query response resolve to an existing wiki page or raw source.
- A seeded contradiction is reported by lint.
- An authenticated RunLayer-identity call returns synthesized knowledge; the same
  call without a token returns 401.
- After pod deletion, wiki page count and content hashes are unchanged.

## Invariant compatibility

| Invariant | Preservation |
| --- | --- |
| INV-001 raw immutability | Wrapper exposes no raw mutation route; bucket checksum asserted unchanged |
| INV-002 no task surface | Plan/todo omitted from routing; asserted by route enumeration |
| INV-003 citations | Query response schema requires citations; fixture asserts resolution |
| INV-004 atomic writes | Wiki writes committed in one transaction; fault-injection test |
| INV-005 no container-only state | PostgreSQL and MinIO adapters; pod-deletion test |
| INV-006 no anonymous read | Guard applied per route; enumerated against the running app |
| INV-007 no provider key | Vault inventory and env reviewed; AI only via ai-microservice |

## Upstream and downstream links

- Upstream: `../../BUSINESS.md`, `../01_vision/VISION.md` ("Key outcomes", "Non-goals")
- Task: `../11_tasks/TASK-001-bootstrap-service.md`
- Plan: `../21_execution_plans/EP-TASK-001-bootstrap-service.md`
- Validation: `../12_validation/VAL-TASK-001-bootstrap-service.md`

## Validation method

Evidence recorded in the bootstrap validation report: gate output, ingest/query/
lint fixture runs with citation resolution counts, route and auth enumeration
performed against the running application rather than by static scan, pod
deletion state-retention check, and ExternalSecret readiness.
