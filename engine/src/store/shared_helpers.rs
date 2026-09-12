// Helpers that upstream defined inside plan.rs and todo.rs but that
// discussion.rs also depends on. Those two files are removed here (INV-002:
// jarvis exposes no task surface, RunLayer is the sole task authority), so the
// shared pieces are kept separately rather than resurrecting the task code.
//
// Copied verbatim from upstream c8538367:
//   bounded_hook_text      <- src/store/plan.rs:127
//   normalize_agent_context <- src/store/todo.rs:35

fn bounded_hook_text(value: String) -> String {
    const LIMIT: usize = 500;
    if value.chars().count() <= LIMIT {
        value
    } else {
        value.chars().take(LIMIT - 1).chain(['…']).collect()
    }
}

fn normalize_agent_context(value: &str) -> Result<String> {
    let Some(digest) = value.strip_prefix("lwcctx-v1-") else {
        return Err(AppError::new(
            "invalid_agent_context",
            "context must be an lwcctx-v1 token",
        ));
    };
    if digest.len() != 64
        || !digest
            .bytes()
            .all(|byte| byte.is_ascii_digit() || (b'a'..=b'f').contains(&byte))
    {
        return Err(AppError::new(
            "invalid_agent_context",
            "context must be an lwcctx-v1 token",
        ));
    }
    Ok(value.to_owned())
}
