# Vendored engine

Source: [JanYork/llm-wiki-cli](https://github.com/JanYork/llm-wiki-cli) (LWC),
Apache-2.0.

- Upstream commit: `c8538367cc55e81288360606ea8c49fbd0d84e55`
- Upstream version: `0.18.5`
- Vendored: 2026-09-12

## What was removed and why

| Removed | LOC | Reason |
| --- | --- | --- |
| `src/learning/`, `learning_runtime.rs`, `learning_schema.rs` | 11,341 | Tutor/book/practice suite; out of approved scope |
| `src/store/plan.rs`, `src/store/todo.rs` | 1,338 | INV-002: RunLayer is the sole task authority |
| `src/office.rs`, `src/trans*.rs` | ~3,200 | Document conversion and translation; not in scope |

81,172 LOC upstream, 66,241 after removal.

## Fork status

The store is being ported from SQLite to PostgreSQL (owner decision
2026-09-12). **Upstream upgrades are therefore manual merges, not `git pull`.**

Measured coupling at the time of the decision: 32 of 97 files reference
rusqlite, with 5 `fts5` virtual tables, 102 `PRAGMA`, 17 `json_extract`,
7 `WITHOUT ROWID` and the rusqlite `session` extension (no PostgreSQL
analogue). See `docs/21_execution_plans/EP-TASK-001-bootstrap-service.md`
step 5 for the sequencing.
