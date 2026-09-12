# Vision: jarvis

> Protected intent baseline. Human approval is required. AI agents may draft
> only from owner-provided or approved source material and must not modify the
> approved baseline directly.

```yaml
id: VISION-jarvis
status: approved
owner: "ssf"
created: 2026-09-12
last_updated: 2026-09-12
completeness_level: complete
upstream:
  - ../00_constitution/CONSTITUTION.md
downstream:
  - ../../BUSINESS.md
  - ../17_governance/PROJECT_INVARIANTS.md
  - ../22_goal_impact/GOAL-IMPACT-TASK-001.md
```

## One-sentence vision

jarvis is the ecosystem's compounding knowledge layer: an LLM-maintained wiki
built from owner-curated raw sources, serving synthesized, citation-backed
answers to humans and to other Alfares services over HTTP.

## Problem statement

Ecosystem knowledge is re-derived from scratch on every question. Retrieval over
raw documents returns chunks, not understanding: contradictions are rediscovered,
cross-references are rebuilt, and the synthesis is discarded as soon as the
answer is delivered. Nothing accumulates. The operator carries in their head what
should be a durable artifact.

## Target users

- The ecosystem owner, who curates raw sources and asks questions.
- RunLayer, which needs grounded knowledge while remaining the sole task authority.
- Other Alfares services requiring citation-backed synthesis over HTTP.

## Core user need

A knowledge store that becomes more useful with every source added, where the
tedious bookkeeping — summarizing, cross-referencing, flagging contradictions,
keeping the index honest — is done by the machine and survives the session.

## Key outcomes

- The owner adds a raw source and the wiki updates itself, including related pages.
- Answers cite the wiki pages and raw sources they came from.
- Contradictions, stale claims and orphan pages are surfaced by lint, not discovered by accident.
- Other services obtain synthesized knowledge through a stable authenticated API.

## Non-goals

- jarvis does not own goals, tasks, plans or approval gates. RunLayer is the sole
  task authority; LWC's Plan and Todo surfaces are deliberately not exposed.
- jarvis is not a general document store and not a replacement for docs-RAG's
  direct Git ingestion of repository documentation.
- jarvis does not hold third-party model provider keys; all model access is
  through ai-microservice.
- jarvis does not author raw sources. Raw input is curated by the owner and immutable.

## Success criteria

- Ingest of a source produces a wiki page and updates every related page, with citations resolving to raw sources.
- Query returns an answer whose citations resolve to existing wiki pages.
- Lint reports contradictions and orphan pages on a seeded fixture.
- An authenticated service call from RunLayer returns synthesized knowledge; an unauthenticated call returns 401.
- The wiki survives pod replacement: no state lives only on container disk.

## Approval

Status: approved
Approved by: ssf
Approval evidence: owner-confirmation: session-2026-09-12-ssf-approved-jarvis-k8s-wiki-only-scope
