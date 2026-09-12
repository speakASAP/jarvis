# Project Constitution: jarvis

> Protected document. Human approval is required. AI agents may draft only from
> approved source material and must not modify the approved baseline directly.

```yaml
id: CONSTITUTION-jarvis
status: approved
owner: "ssf"
created: 2026-09-12
last_updated: 2026-09-12
completeness_level: complete
upstream: []
downstream:
  - ../01_vision/VISION.md
  - ../17_governance/PROJECT_INVARIANTS.md
```

## Purpose

jarvis holds a compounding artifact: a wiki derived from owner-curated sources
that accumulates synthesis over time and cannot be cheaply re-derived. This
constitution protects two things ordinary testing does not: the integrity of that
artifact, and the boundary that keeps jarvis a knowledge service rather than a
second task authority competing with RunLayer.

## Constitutional principles

### Intent preservation

Every implementation artifact must trace to approved project intent.

### Human-controlled change

Human approval is required to: change the vision or these principles; expose a
new public route or widen the API surface; add or remove a required integration;
change the authorization model; delete raw sources or wiki history; and deploy to
production. Agents may draft and implement within an approved task, but must stop
before deployment.

### Scope boundaries

jarvis owns knowledge: raw source custody, wiki pages, citations and the
operation log. jarvis never owns tasks, plans, goals or approval gates - RunLayer
is the sole task authority. jarvis does not author raw sources, does not replace
docs-RAG Git ingestion of repository documentation, and does not expose the LWC
learning suite.

### Data and security

Raw sources are immutable once ingested. Secrets exist only in Vault at
`secret/prod/jarvis` and reach pods through ExternalSecret; no plaintext
Kubernetes Secret, and no secret value in Git, documentation, logs, or terminal
output - key names only. jarvis holds no third-party model provider key; model
access is only through ai-microservice. Every route except `/health` requires a
validated identity. Failures are raised loudly and never silently swallowed.

### Validation

No task is complete without evidence against its acceptance criteria and
upstream goal.

## Amendment process

1. Create an amendment proposal under `docs/17_governance/amendments/`.
2. Explain the change, reason, affected artifacts and compatibility impact.
3. Obtain human approval.
4. Update dependent artifacts and rerun relevant validation.

## Approval

Status: approved
Approved by: ssf
Approval evidence: owner-confirmation: session-2026-09-12-ssf-approved-jarvis-k8s-wiki-only-scope
