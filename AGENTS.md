# IronUI — Agent Instructions

> **This is a living document.** Agents are encouraged to update and extend these
> instructions as they learn about the codebase. See
> [Self-Improvement Protocol](#self-improvement-protocol).

## Self-Improvement Protocol

This repo uses a **distributed AGENTS.md system**. Instructions are decomposed
across directories so agents receive context scoped to their working directory.

### How It Works

- Each directory may contain an `AGENTS.md` with context specific to that area.
- `CLAUDE.md` is always a **symlink** to `AGENTS.md` — never a standalone file.
- Agents inherit instructions from all ancestor `AGENTS.md` files automatically.

### When to Create or Update

Agents **should** create or update an `AGENTS.md` when they:

- Discover a non-obvious pattern, convention, or gotcha in a directory.
- Learn something from a bug fix that future agents should know.
- Identify dependencies or constraints between files that aren't obvious.
- Find that existing instructions are outdated or incomplete.
- Complete significant work in a directory that lacks an `AGENTS.md`.

### Pre-Commit Knowledge Capture

**Before committing, agents must pause and reflect:**

1. Did I uncover any non-obvious behavior, gotcha, or pattern during this work?
2. Did I learn something about a module's internals that isn't documented?
3. Did I fix a bug whose root cause would be useful for future agents to know?
4. Did I discover a relationship between files/modules that isn't captured?

If the answer to any of these is **yes**, update the relevant `AGENTS.md` (or create
one) as part of the same commit. Treat knowledge capture as part of the deliverable,
not an afterthought.

### Rules for Writing AGENTS.md

- Keep instructions **scoped** to the directory — don't repeat ancestor content.
- Be **concise** — bullet points over prose.
- Include **concrete examples** where they clarify.
- Date new entries: `<!-- Updated: YYYY-MM-DD -->`.
- Always create the symlink alongside: `ln -s AGENTS.md CLAUDE.md`.
- Never contradict ancestor instructions without explicit justification.
- Prefer **learnings and gotchas** over restating obvious things.

---

## Product Goals

- Build a modern, sleek, playful SwiftUI design system inspired by Family/Honkish.
- Prioritize accessibility, customization, and extensibility.
- Target **iOS 26+** and **macOS 26+** only; use the latest APIs without back-compat shims.

## Commit Practices

- Never use co-authored commits.
- Never add "Generated with Claude Code" or similar AI attribution footers.
- Work in branches; never commit directly to `main`.
- Prefer stacked PRs; open draft PRs when possible.
- Use conventional commit messages (feat:, fix:, docs:, etc.).

## Architecture & Modules

- Follow the ADR-defined module hierarchy in `adrs/`.
- Keep dependency direction one-way: **Core → Primitives → Components → higher layers**.
- Document significant architectural changes with a new ADR in `adrs/`.
- See `Sources/AGENTS.md` for coding conventions and module-specific context.

## Project Management: Tuist

This project uses [Tuist](https://tuist.dev) for project generation. Tuist enables:
- Warnings-as-errors enforcement (not possible with SPM alone)
- Unified testing across platforms
- Better Xcode project management

### Getting Started with Tuist

```bash
# Install dependencies and generate Xcode project
tuist install
tuist generate

# Install git hooks (formats code on commit)
ln -sf ../../Scripts/pre-commit .git/hooks/pre-commit

# Open the generated workspace
open IronUI.xcworkspace
```

### Tuist Commands

| Command | Purpose |
|---------|---------|
| `tuist install` | Fetch and resolve dependencies |
| `tuist generate` | Generate Xcode workspace and projects |
| `tuist build IronUI --platform macos` | Build for macOS |
| `tuist build IronUI --platform ios` | Build for iOS |
| `tuist test --platform macos` | Run all tests on macOS |
| `tuist test --platform ios` | Run all tests on iOS |
| `tuist clean` | Clean Tuist cache |

## Developer CLI

For faster execution, use the cached wrapper script:
```bash
./Scripts/ironui-cli <command>
```

The wrapper caches the compiled CLI binary and validates it against a checksum of the
source files. This avoids recompilation on every invocation (~30-60s savings).

Alternatively, `swift run ironui-cli <command>` works but recompiles the CLI each time.

| Command | Purpose |
|---------|---------|
| `build` | Build the package (`--platform macos/ios`, `--spm` for SPM mode) |
| `clean` | Remove build artifacts and Tuist cache (`--all` for full clean) |
| `docs` | Generate documentation (`--preview` for live server) |
| `export-snapshots` | Export snapshots to DocC Resources |
| `format` | Format Swift sources (`--dry-run` to check only) |
| `snapshots` | Run snapshot tests (`--platform`, `--record`, `--spm`) |
| `test` | Run unit tests (`--platform macos/ios`, `--spm` for SPM mode) |

## Planning & Issues

- Record plans in `Plans/` (not `Plan.md`).
- Record problems/concerns as markdown files in `Issues/`.
