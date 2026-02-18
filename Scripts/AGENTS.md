# Scripts — Agent Instructions

<!-- Updated: 2026-02-18 -->

## Contents

- **`ironui-cli`** — Cached wrapper around `swift run ironui-cli`. Compiles the CLI
  binary once and caches it, validating against a checksum of the source files.
  Use this instead of `swift run ironui-cli` for faster execution (~30-60s savings).
- **`pre-commit`** — Git hook that formats Swift code on commit.
  Install with: `ln -sf ../../Scripts/pre-commit .git/hooks/pre-commit`.
