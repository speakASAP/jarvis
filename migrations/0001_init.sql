-- jarvis wiki store, ported from the vendored LWC SQLite schema
-- (upstream c8538367cc55e81288360606ea8c49fbd0d84e55, src/store/schema.rs).
--
-- Port rules applied throughout:
--   INTEGER PRIMARY KEY AUTOINCREMENT -> GENERATED ALWAYS AS IDENTITY
--   INTEGER 0/1 + CHECK(x IN (0,1))   -> boolean
--   TEXT timestamps                   -> timestamptz
--   TEXT json columns                 -> jsonb
--   TRIM(x) <> ''                     -> btrim(x) <> ''
--   fts5 virtual tables               -> tsvector + GIN (see 0002)
--
-- plan/todo/discussion/agent-tracking tables from upstream are deliberately
-- absent: jarvis exposes no task surface (INV-002) and RunLayer is the sole
-- task authority.

-- Run this migration AS THE OWNING ROLE (jarvis_app), not as the admin role.
-- Applying it as dbadmin leaves every table owned by dbadmin, and the runtime
-- role then fails at the first query with "permission denied for table pages".
-- Verified on a scratch database 2026-09-12.
--
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f migrations/0001_init.sql
--
-- DATABASE_URL authenticates as jarvis_app, so ownership lands correctly.

BEGIN;

CREATE TABLE meta (
    key   text PRIMARY KEY,
    value text NOT NULL
);

CREATE TABLE sources (
    id                     bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    content_hash           text NOT NULL UNIQUE,
    title                  text,
    origin                 text NOT NULL,
    content                text NOT NULL,
    structural_navigation  boolean NOT NULL DEFAULT false,
    created_at             timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE pages (
    slug                   text PRIMARY KEY,
    title                  text NOT NULL,
    kind                   text,
    summary                text,
    body                   text NOT NULL,
    structural_navigation  boolean NOT NULL DEFAULT false,
    created_at             timestamptz NOT NULL,
    updated_at             timestamptz NOT NULL
);

CREATE TABLE page_sources (
    page_slug text   NOT NULL REFERENCES pages(slug) ON DELETE CASCADE,
    source_id bigint NOT NULL REFERENCES sources(id),
    PRIMARY KEY (page_slug, source_id)
);

CREATE TABLE page_provenance (
    page_slug  text NOT NULL REFERENCES pages(slug) ON DELETE CASCADE,
    provenance text NOT NULL
        CHECK (provenance IN ('user-provided', 'agent-observed', 'hypothesis')),
    PRIMARY KEY (page_slug, provenance)
);

CREATE TABLE tags (
    name               text PRIMARY KEY,
    autoload           boolean NOT NULL DEFAULT false,
    autoload_priority  integer NOT NULL DEFAULT 0,
    autoload_limit     integer NOT NULL DEFAULT 10
        CHECK (autoload_limit BETWEEN 1 AND 100),
    autoload_max_chars integer NOT NULL DEFAULT 50000
        CHECK (autoload_max_chars BETWEEN 1 AND 100000),
    reason             text NOT NULL,
    updated_at         timestamptz NOT NULL
);

CREATE TABLE page_tags (
    tag_name   text NOT NULL REFERENCES tags(name)  ON DELETE CASCADE,
    page_slug  text NOT NULL REFERENCES pages(slug) ON DELETE CASCADE,
    priority   integer NOT NULL DEFAULT 0,
    reason     text NOT NULL,
    created_at timestamptz NOT NULL,
    updated_at timestamptz NOT NULL,
    PRIMARY KEY (tag_name, page_slug)
);
CREATE INDEX page_tags_lookup ON page_tags (tag_name, priority DESC, page_slug ASC);
CREATE INDEX page_tags_page   ON page_tags (page_slug, tag_name);

CREATE TABLE links (
    from_slug text NOT NULL REFERENCES pages(slug) ON DELETE CASCADE,
    to_slug   text NOT NULL,
    PRIMARY KEY (from_slug, to_slug)
);

CREATE TABLE semantic_relations (
    id              text PRIMARY KEY,
    relation_type   text NOT NULL,
    from_identifier text NOT NULL,
    to_identifier   text NOT NULL,
    confidence      double precision,
    provenance      text NOT NULL,
    reason          text,
    source_ids      jsonb NOT NULL DEFAULT '[]'::jsonb,
    created_at      timestamptz NOT NULL DEFAULT now(),
    updated_at      timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE operations (
    id         bigint GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    action     text NOT NULL,
    target     text NOT NULL,
    detail     jsonb NOT NULL,
    created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE ingest_jobs (
    source_id               bigint PRIMARY KEY REFERENCES sources(id) ON DELETE CASCADE,
    status                  text NOT NULL CHECK (status IN
        ('pending', 'analyzing', 'generating', 'completed', 'failed')),
    attempts                integer NOT NULL DEFAULT 0 CHECK (attempts >= 0),
    analysis                text,
    last_error              text,
    no_derived_pages_reason text,
    updated_at              timestamptz NOT NULL
);
CREATE INDEX ingest_jobs_status_source ON ingest_jobs (status, source_id);

CREATE TABLE source_path_revisions (
    tracked_path text   NOT NULL CHECK (btrim(tracked_path) <> ''),
    revision     integer NOT NULL CHECK (revision >= 1),
    source_id    bigint NOT NULL REFERENCES sources(id) ON DELETE RESTRICT,
    observed_at  timestamptz NOT NULL,
    PRIMARY KEY (tracked_path, revision)
);
CREATE INDEX source_path_revisions_source
    ON source_path_revisions (source_id, tracked_path, revision);

CREATE TABLE retrieval_weights (
    target_type       text NOT NULL CHECK (target_type IN ('page', 'source')),
    target_identifier text NOT NULL CHECK (btrim(target_identifier) <> ''),
    provenance        text NOT NULL
        CHECK (provenance IN ('user-provided', 'agent-observed')),
    weight            integer NOT NULL CHECK (weight IN (-2, -1, 1, 2)),
    reason            text NOT NULL CHECK (btrim(reason) <> ''),
    updated_at        timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (target_type, target_identifier, provenance)
);

CREATE TABLE retrieval_feedback (
    query_fingerprint text NOT NULL CHECK (length(query_fingerprint) = 64),
    target_type       text NOT NULL CHECK (target_type IN ('page', 'source')),
    target_identifier text NOT NULL CHECK (btrim(target_identifier) <> ''),
    provenance        text NOT NULL
        CHECK (provenance IN ('user-provided', 'agent-observed')),
    signal            integer NOT NULL CHECK (signal IN (-1, 1)),
    reason            text NOT NULL CHECK (btrim(reason) <> ''),
    updated_at        timestamptz NOT NULL DEFAULT now(),
    PRIMARY KEY (query_fingerprint, target_type, target_identifier, provenance)
);
CREATE INDEX retrieval_feedback_target
    ON retrieval_feedback (target_type, target_identifier, query_fingerprint);

CREATE TABLE search_spans (
    span_id             text PRIMARY KEY,
    span_type           text NOT NULL CHECK (span_type IN ('passage', 'sentence')),
    document_type       text NOT NULL CHECK (document_type IN ('page', 'source')),
    document_identifier text NOT NULL,
    parent_identifier   text NOT NULL,
    ordinal             integer NOT NULL,
    byte_start          integer NOT NULL,
    byte_end            integer NOT NULL,
    content_fingerprint text NOT NULL,
    segmenter_version   integer NOT NULL,
    active              boolean NOT NULL DEFAULT true
);
CREATE INDEX search_spans_document
    ON search_spans (document_type, document_identifier, active);

-- Upstream seeds these with LOWER(HEX(RANDOMBLOB(32))). gen_random_bytes would
-- need pgcrypto, so derive 32 random bytes from gen_random_uuid(), which is
-- built in since PG 13: two UUIDs are 32 bytes of randomness.
INSERT INTO meta(key, value) VALUES
    ('format_version', '1'),
    ('store_id',       replace(gen_random_uuid()::text, '-', '')
                    || replace(gen_random_uuid()::text, '-', '')),
    ('store_revision', replace(gen_random_uuid()::text, '-', '')
                    || replace(gen_random_uuid()::text, '-', ''));

COMMIT;
