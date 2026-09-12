# ADR-001: SQLite is retained for transport, snapshot and replay artifacts

```yaml
id: ADR-001
status: accepted
owner: ssf
created: 2026-09-12
upstream:
  - ../21_execution_plans/EP-TASK-001-bootstrap-service.md
  - ../17_governance/PROJECT_INVARIANTS.md
```

## Context

The owner chose to port the vendored LWC store from SQLite to PostgreSQL
(2026-09-12), accepting that this forks the engine. The execution plan listed
`ATTACH` (28 sites) and the `backup` API (27 mentions) as subsystems needing an
explicit replacement rather than a translation.

Measuring them changed the picture:

**`ATTACH` — 14 real call sites, all transient files.** Every alias is
`sync_draft`, `sync_normalized`, `sync_live_snapshot`, `sync_merge_N`,
`baseline`, `candidate`, `replay_blob`, `replay_live` or `live_base`. Each
attaches a **filesystem path** to a sync or changeset-replay file, in
`prepare_sync_transfer`, `select_sync_transfer`, `merge_sync_blobs_into`,
`read_sync_publication_receipt`, `validate_changeset_sync_replay_item` or
`export_sync_state_with_continuity`. None attaches the live store to another
live store.

**`backup` — 5 real `Backup::new` call sites,** not 27; the rest were the word
appearing in comments and identifiers. All five copy a connection to a local
file: shadow-migration (`migrate_schema_shadow`), checkpoints
(`create_checkpoint`), a graph-ingest candidate guarded by `TemporaryDatabase`,
and a sync snapshot (`create_sync_live_snapshot`).

These sit in the same subsystem as `sync_manifest`, `sync_objects`, `sync_blobs`
and `files`, which are created with `Connection::open` against a separate
exported file and are a portable interchange format other LWC installations
read.

## Decision

The live wiki store is PostgreSQL. SQLite is retained, deliberately, for:

1. **Sync transport** — the exported `.db` artifact and its `ATTACH`-based merge
   and replay validation.
2. **Checkpoints and snapshots** — point-in-time file copies used by changesets,
   sync publication and graph ingest.
3. **Shadow migration** — the pending-store copy used to rehearse a schema
   migration before adopting it.

`ATTACH` and `Backup::new` are therefore **not ported**. They keep operating on
SQLite files, which is what they already do.

## Consequences

- The wiki's durable state — pages, sources, citations, temporal memory,
  discussions, changeset records — lives in PostgreSQL and satisfies INV-005.
- Transport and snapshot artifacts remain single-file SQLite, which keeps the
  sync format compatible and avoids reimplementing file-copy semantics over a
  networked database.
- `create_checkpoint` is reached from changeset, sync-publication and
  graph-ingest paths. Its PostgreSQL equivalent, when those paths run against
  the live store, is a logical export rather than a page-level copy. **This is
  the one open item**: the checkpoint source connection will be PostgreSQL once
  the store port completes, and `Backup::new` cannot take a PostgreSQL
  connection. The affected paths must either operate on an exported snapshot or
  be disabled until reimplemented. Recorded as a follow-up, not as done.
- The document-graph ingest path is gated by `GraphSetting` and resolves to
  `disabled` by default, so its checkpoint use is not on the default path.

## Alternatives rejected

- **Porting `ATTACH` to PostgreSQL schemas or `postgres_fdw`.** Would change the
  sync file format and gain nothing: the attached files are transient.
- **Reimplementing `Backup::new` as `pg_dump`.** Wrong granularity for a
  same-process page copy, and would add a shell dependency to the ingest path.
