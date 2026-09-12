-- Discussion and changeset state, ported from the vendored engine's
-- create_discussion_schema (src/store/discussion.rs) and
-- create_changeset_state (src/store/migrations.rs).
--
-- Run AS THE OWNING ROLE (jarvis_app), like the earlier migrations.
--
-- Scope note: the sync_manifest / sync_objects / sync_blobs / files tables are
-- deliberately NOT here. They are created with Connection::open(path) against a
-- separate exported SQLite file and are a portable interchange artifact, not
-- live store state. They stay SQLite; porting them to PostgreSQL would change a
-- file format other LWC installations read.
--
-- WITHOUT ROWID has no PostgreSQL equivalent and needs none: it is a SQLite
-- storage-layout hint, not a semantic constraint.

BEGIN;

CREATE TABLE discussions (
    id       text PRIMARY KEY,
    context  text NOT NULL,
    revision integer NOT NULL,
    body     text NOT NULL
);

CREATE TABLE discussion_revisions (
    discussion_id text NOT NULL REFERENCES discussions(id),
    revision      integer NOT NULL,
    request_id    text NOT NULL,
    input         text NOT NULL,
    -- Upstream stores '{}' here and rewrites any non-'{}' body on migration:
    -- legacy prototype snapshots duplicated every preceding answer, and the
    -- inputs already retain the history. jsonb keeps that default explicit.
    body          jsonb NOT NULL DEFAULT '{}'::jsonb,
    created_at    timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (discussion_id, revision),
    UNIQUE (discussion_id, request_id)
);

CREATE TABLE discussion_bindings (
    context       text PRIMARY KEY,
    discussion_id text NOT NULL REFERENCES discussions(id)
);

CREATE TABLE changesets (
    id                    text PRIMARY KEY CHECK (length(id) = 64),
    name                  text NOT NULL CHECK (btrim(name) <> ''),
    status                text NOT NULL
        CHECK (status IN ('draft', 'committed', 'rolled_back')),
    base_revision         text NOT NULL CHECK (length(base_revision) = 64),
    base_operation_id     bigint NOT NULL CHECK (base_operation_id >= 0),
    begin_operation_id    bigint NOT NULL CHECK (begin_operation_id > base_operation_id),
    pre_commit_checkpoint text,
    post_revision         text CHECK (post_revision IS NULL OR length(post_revision) = 64),
    created_at            timestamptz NOT NULL,
    committed_at          timestamptz,
    rolled_back_at        timestamptz
);
CREATE INDEX changesets_name_created ON changesets (name, created_at);

COMMIT;
