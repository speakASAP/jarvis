-- Temporal memory, ported from the vendored engine's
-- create_temporal_memory_schema (src/store/temporal_memory.rs).
--
-- Run AS THE OWNING ROLE (jarvis_app), like 0001 and 0002.
--
-- Port notes specific to this file:
--   * memory_fts (the third fts5 virtual table) becomes a generated tsvector,
--     matching the approach in 0002: event_type and context weighted above
--     content, and rows cascade from memory_events the way
--     contentless_delete=1 behaved.
--   * memory_events_request_id is a partial UNIQUE index; PostgreSQL supports
--     those directly, so it ports unchanged.
--   * memory_state is a single-row counter table (CHECK(id = 1)) and keeps that
--     shape; its seed row is inserted here as upstream does.

BEGIN;

CREATE TABLE memory_events (
    id            text PRIMARY KEY CHECK (btrim(id) <> ''),
    request_id    text CHECK (request_id IS NULL OR btrim(request_id) <> ''),
    fingerprint   text NOT NULL CHECK (length(fingerprint) = 64),
    event_type    text NOT NULL CHECK (btrim(event_type) <> ''),
    context       text NOT NULL CHECK (btrim(context) <> ''),
    occurred_at   timestamptz NOT NULL,
    recorded_at   timestamptz NOT NULL DEFAULT now(),
    valid_from    timestamptz,
    valid_until   timestamptz,
    pinned        boolean NOT NULL DEFAULT false,
    logical_bytes bigint NOT NULL CHECK (logical_bytes >= 0)
);
CREATE UNIQUE INDEX memory_events_request_id
    ON memory_events (request_id) WHERE request_id IS NOT NULL;
CREATE INDEX memory_events_context
    ON memory_events (event_type, context, occurred_at DESC, id);
CREATE INDEX memory_events_retention
    ON memory_events (occurred_at, id);

CREATE TABLE memory_fragments (
    event_id text NOT NULL REFERENCES memory_events(id) ON DELETE CASCADE,
    kind     text NOT NULL CHECK (kind IN
        ('observed', 'decision', 'constraint', 'learned', 'unresolved', 'outcome')),
    ordinal  integer NOT NULL CHECK (ordinal >= 0),
    value    text NOT NULL CHECK (btrim(value) <> ''),
    PRIMARY KEY (event_id, kind, ordinal)
);
CREATE INDEX memory_fragments_kind ON memory_fragments (kind, event_id);

CREATE TABLE memory_changes (
    event_id     text NOT NULL REFERENCES memory_events(id) ON DELETE CASCADE,
    ordinal      integer NOT NULL CHECK (ordinal >= 0),
    subject      text NOT NULL CHECK (btrim(subject) <> ''),
    before_value text,
    after_value  text,
    reason       text,
    PRIMARY KEY (event_id, ordinal)
);

CREATE TABLE memory_evidence (
    event_id  text NOT NULL REFERENCES memory_events(id) ON DELETE CASCADE,
    ordinal   integer NOT NULL CHECK (ordinal >= 0),
    reference text NOT NULL CHECK (btrim(reference) <> ''),
    excerpt   text,
    PRIMARY KEY (event_id, ordinal)
);

CREATE TABLE memory_relations (
    event_id        text NOT NULL REFERENCES memory_events(id) ON DELETE CASCADE,
    ordinal         integer NOT NULL CHECK (ordinal >= 0),
    relation_type   text NOT NULL CHECK (relation_type IN
        ('supersedes', 'contradicts', 'resolves', 'supports', 'related')),
    target_event_id text NOT NULL REFERENCES memory_events(id) ON DELETE CASCADE,
    basis           text,
    PRIMARY KEY (event_id, ordinal)
);
CREATE INDEX memory_relations_target
    ON memory_relations (target_event_id, relation_type, event_id);

CREATE TABLE memory_feedback (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    event_id   text NOT NULL REFERENCES memory_events(id) ON DELETE CASCADE,
    signal     text NOT NULL CHECK (signal IN ('useful', 'not-useful')),
    reason     text NOT NULL CHECK (btrim(reason) <> ''),
    created_at timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX memory_feedback_event ON memory_feedback (event_id, created_at, id);

CREATE TABLE memory_hint_state (
    candidate_key    text PRIMARY KEY CHECK (btrim(candidate_key) <> ''),
    hint_type        text NOT NULL CHECK (btrim(hint_type) <> ''),
    last_emitted_at  timestamptz NOT NULL,
    next_eligible_at timestamptz NOT NULL
);

CREATE TABLE memory_state (
    id                  integer PRIMARY KEY CHECK (id = 1),
    record_attempts     bigint NOT NULL DEFAULT 0 CHECK (record_attempts >= 0),
    inserted_events     bigint NOT NULL DEFAULT 0 CHECK (inserted_events >= 0),
    idempotent_replays  bigint NOT NULL DEFAULT 0 CHECK (idempotent_replays >= 0),
    feedback_useful     bigint NOT NULL DEFAULT 0 CHECK (feedback_useful >= 0),
    feedback_not_useful bigint NOT NULL DEFAULT 0 CHECK (feedback_not_useful >= 0),
    age_evictions       bigint NOT NULL DEFAULT 0 CHECK (age_evictions >= 0),
    capacity_evictions  bigint NOT NULL DEFAULT 0 CHECK (capacity_evictions >= 0),
    event_count         bigint NOT NULL DEFAULT 0 CHECK (event_count >= 0),
    logical_bytes       bigint NOT NULL DEFAULT 0 CHECK (logical_bytes >= 0)
);
INSERT INTO memory_state(id) VALUES (1);

-- Replaces: CREATE VIRTUAL TABLE memory_fts USING fts5(...)
CREATE TABLE memory_documents (
    event_id   text PRIMARY KEY REFERENCES memory_events(id) ON DELETE CASCADE,
    event_type text NOT NULL DEFAULT '',
    context    text NOT NULL DEFAULT '',
    content    text NOT NULL DEFAULT '',
    search_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', coalesce(event_type, '')), 'A') ||
        setweight(to_tsvector('simple', coalesce(context,    '')), 'B') ||
        setweight(to_tsvector('simple', coalesce(content,    '')), 'D')
    ) STORED
);
CREATE INDEX memory_documents_vector ON memory_documents USING gin (search_vector);

COMMIT;
