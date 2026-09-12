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
