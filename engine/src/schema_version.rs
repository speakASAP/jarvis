// PostgreSQL replacement for SQLite's `PRAGMA user_version`.
//
// Upstream stored the schema version in the database header and reached it with
// pragma_query_value / pragma_update (36 reads and 18 writes across the store).
// PostgreSQL has no header slot, so the version lives in the `meta` table that
// migrations/0001_init.sql already creates, under the key 'format_version'.
//
// These two helpers are the only places that knowledge lives; every call site
// goes through them rather than issuing its own SQL, so the storage location can
// change again without touching the ladder in migrations.rs.
//
// A missing row reads as 0, matching a fresh SQLite database, so the
// bootstrap-vs-migrate decision in ensure_schema keeps working unchanged.

use rusqlite::{Connection, params};

use crate::error::{AppError, Result};

const SCHEMA_VERSION_KEY: &str = "format_version";

pub(crate) fn read_schema_version(conn: &Connection) -> Result<i32> {
    // A brand-new database has no `meta` table at all. Upstream read the version
    // from the SQLite header, which always exists, so version 0 meant "not
    // bootstrapped yet". Reading a missing table must mean the same thing here or
    // bootstrap can never run. Only the missing-table case is absorbed; any other
    // database error still propagates.
    let raw: Option<String> = match conn.query_row(
        "SELECT value FROM meta WHERE key = ?1",
        params![SCHEMA_VERSION_KEY],
        |row| row.get(0),
    ) {
        Ok(value) => Some(value),
        Err(rusqlite::Error::QueryReturnedNoRows) => None,
        Err(error) if is_missing_meta_table(&error) => return Ok(0),
        Err(error) => return Err(error.into()),
    };
    match raw {
        None => Ok(0),
        Some(value) => value.trim().parse::<i32>().map_err(|_| {
            // Never guess a version: a corrupt marker must stop the migration
            // ladder rather than silently rerun or skip steps.
            AppError::new(
                "unsupported_store_version",
                format!("schema version marker is not an integer: {value:?}"),
            )
        }),
    }
}

pub(crate) fn write_schema_version(conn: &Connection, version: i32) -> Result<()> {
    conn.execute(
        "INSERT INTO meta(key, value) VALUES (?1, ?2)
         ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value",
        params![SCHEMA_VERSION_KEY, version.to_string()],
    )?;
    Ok(())
}

// The `meta` table is absent only before bootstrap. Match on the message rather
// than a code because rusqlite surfaces this as a generic SQLITE_ERROR, and the
// PostgreSQL driver will report its own undefined_table error here later.
fn is_missing_meta_table(error: &rusqlite::Error) -> bool {
    let text = error.to_string();
    text.contains("no such table: meta") || text.contains("relation \"meta\" does not exist")
}
