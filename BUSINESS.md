# Business: jarvis

> Protected business baseline. An AI agent may structure an initial draft only
> from owner-provided or approved source material. Human approval is required
> before implementation. After approval, goal changes require a reviewed
> amendment; agents must not silently rewrite business intent.

```yaml
id: BUSINESS-jarvis
status: approved
owner: "ssf"
created: 2026-09-12
last_updated: 2026-09-12
completeness_level: complete
upstream:
  - docs/01_vision/VISION.md
downstream:
  - SYSTEM.md
  - docs/22_goal_impact/GOAL-IMPACT-TASK-001-bootstrap-service.md
```

## Problem

Ecosystem knowledge is re-derived on every question. Retrieval over raw
documents returns chunks, not understanding: contradictions are rediscovered,
cross-references rebuilt, and synthesis discarded once the answer is delivered.
Nothing compounds. The operator carries in their head what should be a durable,
queryable artifact, and no other service can reach it.


## Target users and stakeholders

- The ecosystem owner, who curates raw sources and asks questions
- RunLayer, which needs grounded knowledge while remaining the sole task authority
- ai-microservice and the frontend, as future consumers of synthesized knowledge
- Operators who need to know why a claim in the wiki is believed and from which source


## Value proposition

jarvis turns a pile of sources into a maintained, interlinked wiki that gets more
useful with every addition. The bookkeeping that normally kills a wiki -
summarizing, cross-referencing, flagging contradictions, keeping the index honest
- is done by the machine, survives the session, and is reachable over an
authenticated API by every service in the ecosystem.


## Goals

- Accumulate knowledge rather than re-derive it
- Serve citation-backed answers whose sources can be checked
- Surface contradictions, stale claims and orphan pages before they mislead
- Give other Alfares services a stable contract for synthesized knowledge
- Keep raw sources immutable and the wiki durable across pod replacement


## Non-goals

- Owning tasks, plans, goals or approval gates; RunLayer is the sole task authority
- Replacing docs-RAG direct Git ingestion of repository documentation
- Public or anonymous access
- Holding third-party model provider keys
- Authoring raw sources; input is owner-curated


## Success metrics

- Ingesting a source updates related pages, not just one, demonstrating compounding
- 100% of citations in a query response resolve to an existing page or raw source
- Seeded contradictions are reported by lint rather than found by accident
- An authenticated service call returns synthesized knowledge; unauthenticated returns 401
- Wiki content survives pod deletion unchanged


## Business constraints

- Built on the vendored Apache-2.0 LWC engine; no in-house reimplementation
- Model access only through ai-microservice, keeping provider cost and keys centralized
- Deployment is serialized through the shared deploy runner and owner-approved
- Secrets only via Vault and ExternalSecret; key names in Git, never values


## Approval

Status: approved
Approved by: ssf
Approval evidence: owner-confirmation: session-2026-09-12-ssf-approved-jarvis-k8s-wiki-only-scope
