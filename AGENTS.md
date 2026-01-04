# IronUI Shared Agent Instructions

These instructions apply to both Claude and Codex when working in this repo.

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
- Keep dependency direction one-way (Core → Primitives → Components → higher layers).
- Document significant architectural changes with a new ADR in `adrs/`.

## Theming & Visual Identity

- Use token-based theming (`IronTheme` and token protocols).
- Default theme should embody the visual identity principles in `adrs/0003-visual-identity.md`
  and `adrs/VISUAL_IDENTITY.md`.
- Prefer semantic tokens; avoid hard-coded colors, spacing, or fonts in components.

## Accessibility (Non-Negotiable)

- Minimum touch targets: 44x44 points.
- Meaningful labels/hints/values for all interactive elements.
- Respect Dynamic Type and `accessibilityReduceMotion`.
- Ensure WCAG AA contrast for default themes.

## Prefer IronUI Primitives

Use IronUI primitives instead of raw SwiftUI controls inside IronUI components:
`IronText`, `IronIcon`, `IronButton`, `IronTextField`, `IronToggle`, etc.
Exceptions: preview-only code for brevity.

## Previews

- Use `@Previewable` for state in previews.
- Name previews descriptively (e.g., `"IronButton - Variants"`).

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

The wrapper caches the compiled CLI binary and validates it against a checksum of the source files. This avoids recompilation on every invocation (~30-60s savings).

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

## Testing

- Unit tests: Swift Testing (not XCTestCase).
- Snapshot tests: PointFree `swift-snapshot-testing`.
- Add/maintain accessibility audits for interactive components.
- Use `swift run ironui-cli test` for running tests.
- Use `swift run ironui-cli snapshots` for snapshot tests (runs both macOS and iOS by default).
- Use `swift run ironui-cli snapshots --record` to update snapshot baselines.
- For snapshot/visual changes, always re-record snapshots for both iOS and macOS
  and visually inspect the results.

## Documentation

- All public APIs must have DocC docs.
- Update module DocC when public APIs change.
- Prefer tutorials/articles for onboarding and complex components.
- Use `swift run ironui-cli docs` for site generation.
- Use `swift run ironui-cli docs --preview` to preview locally.
- Use `swift run ironui-cli export-snapshots` to copy snapshots to DocC Resources.

## Logging

- Never use `print`, `debugPrint`, or `dump` in production code.
- Use `IronLogger` from `IronCore` with appropriate log levels.

## Planning & Issues

- Record plans in `Plans/` (not `Plan.md`).
- Record problems/concerns as markdown files in `Issues/`.
