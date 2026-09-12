-- Full-text search: the PostgreSQL replacement for upstream's two fts5 virtual
-- tables (search_fts, span_fts).
--
-- fts5 stored its own contentless index and was queried with MATCH. PostgreSQL
-- has no equivalent, so each indexed document keeps a generated tsvector and is
-- queried with @@. The field weights preserve upstream's column ordering
-- intent: title and path terms outrank body terms.
--
--   fts5 column  -> weight
--   title_terms     A
--   path_terms      B
--   heading_terms   B  (span_fts only)
--   summary_terms   C  (search_fts only)
--   body_terms      D
--
-- Weights are applied at query time via ts_rank, so a caller can reproduce
-- fts5's ranking without storing per-column vectors.

-- Run this migration AS THE OWNING ROLE (jarvis_app), not as the admin role.
-- Applying it as dbadmin leaves every table owned by dbadmin, and the runtime
-- role then fails at the first query with "permission denied for table pages".
-- Verified on a scratch database 2026-09-12.
--
--   psql "$DATABASE_URL" -v ON_ERROR_STOP=1 -f migrations/0001_init.sql
--
-- DATABASE_URL authenticates as jarvis_app, so ownership lands correctly.

BEGIN;

-- Replaces: CREATE VIRTUAL TABLE search_fts USING fts5(...)
CREATE TABLE search_documents (
    doc_type   text NOT NULL CHECK (doc_type IN ('page', 'source')),
    identifier text NOT NULL,
    title      text NOT NULL DEFAULT '',
    path       text NOT NULL DEFAULT '',
    summary    text NOT NULL DEFAULT '',
    body       text NOT NULL DEFAULT '',
    search_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', coalesce(title,   '')), 'A') ||
        setweight(to_tsvector('simple', coalesce(path,    '')), 'B') ||
        setweight(to_tsvector('simple', coalesce(summary, '')), 'C') ||
        setweight(to_tsvector('simple', coalesce(body,    '')), 'D')
    ) STORED,
    PRIMARY KEY (doc_type, identifier)
);
CREATE INDEX search_documents_vector ON search_documents USING gin (search_vector);

-- Replaces: CREATE VIRTUAL TABLE span_fts USING fts5(...)
-- span_id matches search_spans(span_id); the cascade keeps the index from
-- outliving the span it describes, which contentless_delete=1 did upstream.
CREATE TABLE span_documents (
    span_id             text PRIMARY KEY
        REFERENCES search_spans(span_id) ON DELETE CASCADE,
    span_type           text NOT NULL,
    document_type       text NOT NULL,
    document_identifier text NOT NULL,
    title               text NOT NULL DEFAULT '',
    path                text NOT NULL DEFAULT '',
    heading             text NOT NULL DEFAULT '',
    body                text NOT NULL DEFAULT '',
    search_vector tsvector GENERATED ALWAYS AS (
        setweight(to_tsvector('simple', coalesce(title,   '')), 'A') ||
        setweight(to_tsvector('simple', coalesce(path,    '')), 'B') ||
        setweight(to_tsvector('simple', coalesce(heading, '')), 'B') ||
        setweight(to_tsvector('simple', coalesce(body,    '')), 'D')
    ) STORED
);
CREATE INDEX span_documents_vector ON span_documents USING gin (search_vector);
CREATE INDEX span_documents_document
    ON span_documents (document_type, document_identifier);

COMMIT;
