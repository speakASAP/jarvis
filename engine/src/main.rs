// Removed from upstream: learning suite (tutor/book/practice), office and
// translation are out of approved scope; plan/todo are excluded by INV-002.
// See engine/VENDORING.md.
mod agent;
mod archive;
mod artifacts;
mod changeset;
mod cli;
mod codegraph;
mod config;
mod contracts;
mod error;
mod external_graph;
pub mod graph;
mod import;
mod learning_schema;
mod mcp;
mod scope;
mod secret_scan;
pub mod segment;
mod source_diff;
mod store;
mod sync;
mod sync_git;
pub mod tokenize;
mod update;
mod view;
mod work;

fn main() {
    cli::main();
}
