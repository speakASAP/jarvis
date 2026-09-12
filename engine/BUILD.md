# Building the vendored engine

There is no Rust toolchain on the alfares host. Build in a container.

```bash
cd engine
docker run --rm -v "$PWD":/w -w /w \
  -e PATH=/usr/local/cargo/bin:/usr/local/bin:/usr/bin:/bin \
  -e CARGO_HOME=/w/.cargo-home \
  rust:1-slim sh -c '
    apt-get update -qq
    apt-get install -y -qq pkg-config libssl-dev build-essential clang libclang-dev
    cargo build'
```

Two things are required and neither is obvious:

- **`PATH` must be set explicitly.** `rust:1-slim` keeps cargo in
  `/usr/local/cargo/bin`, which is not on the default `PATH` for a
  non-login shell. Without it, `cargo` reports `not found` and looks
  like a missing toolchain. Verified: cargo 1.98.1, rustc 1.98.1.
- **`clang` and `libclang-dev` are required.** `libsqlite3-sys` runs
  bindgen in its build script and panics with
  `Unable to find libclang` otherwise. This dependency disappears once
  the store port to PostgreSQL is finished.

`CARGO_HOME=/w/.cargo-home` keeps the ~440-crate registry inside the
repo directory so it survives between container runs; it is gitignored.

## Cargo.toml

`Cargo.toml.upstream` is the unmodified upstream manifest, kept for
diffing against future upstream releases. `Cargo.toml` is ours: same
contents with the package renamed to `jarvis-engine`.
