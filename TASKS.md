# Tasks: jarvis

This file is the concise human-readable work queue. Detailed task contracts
live under `docs/11_tasks/`; execution plans and validation reports remain
linked from those task documents.

## Active

- [ ] `TASK-001-bootstrap-service` - onboarding, integration decisions and
  infrastructure are complete. Implementation is in progress at step 5 of the
  execution plan.
  - [x] Scope-removal cleanup - the engine compiles. 132 errors -> 0 over 10
        build iterations; all 132 were consequences of the removals, none
        inherited from upstream. INV-002 verified against the built binary:
        plan, todo, tutor, book, practice, office and trans are all rejected.
  - [x] 5a schema port - DONE. 30 tables across four migrations, applied and
        exercised on a scratch database. The earlier "37 tables remaining"
        figure was wrong: of the 54 CREATE TABLE statements in the engine, 9
        were migration-era duplicates of already-ported tables, 9 were plan/todo
        tables excluded by INV-002, and 4 (sync_manifest, sync_objects,
        sync_blobs, files) belong to a separate exported SQLite file and must
        stay SQLite. Only 16 were genuinely new.
  - [ ] 5a-superseded note - PARTIAL. `migrations/0001_init.sql` (15 tables) and
        `0002_search.sql` (fts5 -> tsvector+GIN) are applied and exercised on a
        scratch database. They cover only `store/schema.rs`'s bootstrap.
        The engine issues **54** `CREATE TABLE` statements in total:
        `migrations.rs` 19, `schema.rs` 15, `temporal_memory.rs` 8,
        `sync.rs` 7, `discussion.rs` 3, plus 2 more. Roughly 37 tables
        (temporal memory, discussions, changesets, sync state, graph) are not
        yet ported. Found by cross-checking table names referenced in engine SQL
        against the migration files - do not assume 5a is finished.
  - [ ] 5b core CRUD - port the store's read/write paths off rusqlite.
  - [ ] 5c search - rewrite queries against tsvector; upstream used fts5 MATCH.
  - [ ] 5d versioning - replace the rusqlite `session` extension, which has no
        PostgreSQL analogue, with explicit row versioning.
  - 26 of 85 engine files still reference rusqlite (~25,000 LOC).

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

### Start here

    cd /home/ssf/Documents/Github/jarvis
    grep -rl rusqlite engine/src --include=*.rs | head    # the 26 files to port

Next concrete action: port `engine/src/store/mod.rs` and `types.rs` off
rusqlite (step 5b), then build in the container and commit that increment.

### Build

There is no Rust toolchain on this host. Build and test in a container:

    docker run --rm -v "$PWD":/w -w /w \
      -e PATH=/usr/local/cargo/bin:/usr/local/bin:/usr/bin:/bin \
      rust:1-slim cargo build

The `PATH` override is required: `rust:1-slim` does not put cargo on the
default PATH, so a bare `cargo` reports "not found" and looks like a missing
toolchain. cargo 1.98.1 / rustc 1.98.1.

### Traps hit while porting

- **Removing a `mod x;` line can silently rebind its attribute.** Upstream had
  `#[path = "learning/mod.rs"]` on the line above `mod learning;`. Deleting only
  the `mod` line left the attribute attached to the next item, `mod mcp;`, which
  would have compiled `mcp` from the learning file. Delete the attribute with
  its item, and grep `#[path` afterwards.
- **A syntax error masks every other error.** After removing the office and
  learning blocks the count fell 89 -> 1, which looked like near-success. The
  one error was `unexpected closing delimiter` from a `}` my removal orphaned;
  the parser stopped there, so the remaining errors were simply not reported.
  Treat a sudden collapse to one syntax error as "unknown", not "almost done".
- **The vendored store is one compilation unit** assembled with `include!()`,
  not separate modules, so a deleted file breaks `store/mod.rs` at its include
  line rather than at a use site.
- **`cargo build` twice in one shell command doubles a ~10 minute build** and
  the first run's stale errors are what land in the log. Run it once.

### Decisions that are not visible in the diff

- **PostgreSQL over SQLite-on-a-PVC** was the owner's explicit choice on
  2026-09-12, made with the cost stated: the store is 27k LOC of rusqlite with
  5 `fts5` tables and the `session` extension, so this is a fork and upstream
  upgrades become manual merges. Do not "simplify" it back to SQLite.
- **No plan/todo surface, ever.** RunLayer is the sole task authority (INV-002).
  `engine/src/store/plan.rs` and `todo.rs` were deleted deliberately, not
  missed. Re-adding them would recreate the orchestration drift RunLayer exists
  to prevent.
- **Migrations must run as the owning role.** Applying them as the admin role
  leaves tables owned by `dbadmin`, and `jarvis_app` then fails at the first
  query with `permission denied for table pages`. This was reproduced and fixed
  on a scratch database; both migration files carry the warning.
- **`gen_random_bytes` is not available** (needs pgcrypto). `store_id` and
  `store_revision` derive their 32 random bytes from the built-in
  `gen_random_uuid()` instead, still 64 hex characters like upstream.
- **Verify guards by enumerating routes from the running app**, not by static
  scan, when the HTTP layer lands. Coverage scanners report false negatives on
  guard scope.

### Deploy

`jarvis` is deny-listed in `shared/scripts/deploy-queue/registry.sh`. It has no
Dockerfile and no application yet, so a commit would queue a deploy that the IPS
preflight correctly rejects. Remove that entry only when
`TASK-001-bootstrap-service` is validated.

- Engine: vendored [LWC](https://github.com/JanYork/llm-wiki-cli) (Apache-2.0),
  **not yet vendored into `src/`**.
- Boundary: wiki only. RunLayer is the sole task authority (INV-002); the LWC
  plan/todo surface is deliberately not exposed.
- Auto-deploy: jarvis is deny-listed in `shared/scripts/deploy-queue/registry.sh`
  until `TASK-001-bootstrap-service` is validated. Remove that entry then.
- Next: vendor LWC, build the HTTP wrapper, add PostgreSQL and MinIO adapters,
  wire integrations, then an owner-gated deploy.

### Provisioning — COMPLETE (2026-09-12)

- Auth application `jarvis` (user_facing) with `app:jarvis:{user,editor,admin}`
  and `internal:jarvis:{query,ingest}`
- Four S2S principals, one per (caller -> target) pair, each with exactly one
  least-privilege role: ai `invoke`, logging `ingest`, notifications `send`,
  auth `readonly`
- Vault `secret/prod/jarvis` — 7 keys, matching `k8s/external-secret.yaml` exactly
- PostgreSQL database `jarvis`, role `jarvis_app` (no superuser/createdb, public
  schema revoked)
- MinIO private bucket `jarvis-raw` with a bucket-scoped user; scope verified
  against a foreign bucket

No client id/secret: this Auth identifies an application by its registered name
and domain, not an OAuth client credential.
