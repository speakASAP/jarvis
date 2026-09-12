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

const SCHEMA_VERSION_KEY: &str = "format_version";

fn read_schema_version(conn: &Connection) -> Result<i32> {
    let raw: Option<String> = conn
        .query_row(
            "SELECT value FROM meta WHERE key = ?1",
            params![SCHEMA_VERSION_KEY],
            |row| row.get(0),
        )
        .optional()?;
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

fn write_schema_version(conn: &Connection, version: i32) -> Result<()> {
    conn.execute(
        "INSERT INTO meta(key, value) VALUES (?1, ?2)
         ON CONFLICT (key) DO UPDATE SET value = EXCLUDED.value",
        params![SCHEMA_VERSION_KEY, version.to_string()],
    )?;
    Ok(())
}
