# Tasks: jarvis

This file is the concise human-readable work queue. Detailed task contracts
live under `docs/11_tasks/`; execution plans and validation reports remain
linked from those task documents.

## Active

- [ ] `TASK-001-bootstrap-service` - complete documentation-first onboarding,
  integration decisions, implementation and validation.

## Ready next

- None until `TASK-001-bootstrap-service` is validated.

## Blocked

- Infrastructure provisioning needs owner authorization: Auth application
  registration, Vault path `secret/prod/jarvis`, MinIO bucket `jarvis-raw`,
  PostgreSQL role. Deployment itself is owner-gated.

## Completed

- No task has completed validation yet. `TASK-001-bootstrap-service`
  documentation and integration decisions are approved; implementation and
  deployment remain open.

## Handoff

Current machine-readable state: [`STATE.json`](STATE.json).
Detailed bootstrap task:
[`docs/11_tasks/TASK-001-bootstrap-service.md`](docs/11_tasks/TASK-001-bootstrap-service.md).

## Context for the next session

- Engine: vendored [LWC](https://github.com/JanYork/llm-wiki-cli) (Apache-2.0),
  **not yet vendored into `src/`**.
- Boundary: wiki only. RunLayer is the sole task authority (INV-002); the LWC
  plan/todo surface is deliberately not exposed.
- Auto-deploy: jarvis is deny-listed in `shared/scripts/deploy-queue/registry.sh`
  until `TASK-001-bootstrap-service` is validated. Remove that entry then.
- Next: vendor LWC, build the HTTP wrapper, add PostgreSQL and MinIO adapters,
  wire integrations, then an owner-gated deploy.

### Provisioning pending owner authorization

- Auth application identity plus `app:jarvis:{user,editor,admin}` roles
- Vault `secret/prod/jarvis` — 9 keys declared in `k8s/external-secret.yaml`, none written yet
- PostgreSQL database `jarvis` and least-privilege role `jarvis_app`
- MinIO private bucket `jarvis-raw`
