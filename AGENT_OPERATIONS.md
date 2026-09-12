# Agent Operations: jarvis

This repository follows the company Cross-Agent Automation Standard:

```text
/home/ssf/.ai-agent-standards/CROSS_AGENT_AUTOMATION_STANDARD.md
```

## Roles

- Readiness scanner: classifies work and blockers without implementing.
- Worker agent: implements one bounded task or workstream.
- Worker monitor: tracks handoffs and shared-file conflicts.
- Integration validator: validates completed work and separates regressions
  from recorded validation debt.

## Before work

Confirm:

- an active task and upstream traceability exist;
- an execution plan defines scope, allowed files and forbidden files;
- integration and project-invariant impacts are explicit;
- sensitive-data and contract/schema impacts are classified;
- validation commands and evidence paths are named;
- parallel ownership, dependencies, integration owner and merge order are clear.

## Parallel work

Do not assign multiple agents to the same file, schema, migration, public
contract, deployment file or status artifact without one documented integration
owner and conflict-resolution order.

Each workstream records its objective, owner role, allowed and forbidden files,
dependencies, blockers, validation evidence and handoff output.

## Validation debt

Record known out-of-scope failures in
`docs/orchestrator/VALIDATION_DEBT.md`. Validation debt never excuses a failure
that affects the active task, changed files or acceptance criteria.

## Handoff

Update `TASKS.md` and `STATE.json` before ending an incomplete work session.
Record deferred deployment explicitly.

## Project-specific operations

### Gates

```bash
python3 ../intent-preservation-system/scripts/validate_adoption_profile.py --root . --phase planning
python3 ../intent-preservation-system/scripts/pre_coding_gate.py --root .
```

### Verify the invariant boundary

Enumerate routes from the running application, not by static scan:

- no plan/todo/task route is reachable (INV-002)
- every route except `GET /health` returns 401 without a token (INV-006)

### Deployment

Deployment is owner-gated and serialized. Sub-agents stop before deploying.
Verify a rollout by comparing pod age to commit time, not by matching log lines.
Check `ExternalSecret` is `Ready=True` before concluding a deploy failed; a
sealed Vault breaks every ExternalSecret with a message that never mentions Vault.

### Data safety

Raw sources are immutable and backed up with the database. Before any operation
that could remove wiki history, confirm with the owner - the wiki is a
compounding artifact and re-ingest does not reproduce prior synthesis.
