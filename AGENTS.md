# IronUI Shared Agent Instructions

These instructions apply to both Claude and Codex when working in this repo.

## Product Goals

- Build a modern, sleek, playful SwiftUI design system inspired by Family/Honkish.
- Prioritize accessibility, customization, and extensibility.
- Target **iOS 26+** and **macOS 26+** only; use the latest APIs without back-compat shims.

## Commit Practices

- Never use co-authored commits.
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

## Testing

- Unit tests: Swift Testing (not XCTestCase).
- Snapshot tests: PointFree `swift-snapshot-testing`.
- Add/maintain accessibility audits for interactive components.
- For snapshot/visual changes, always re-record snapshots for both iOS and macOS
  and visually inspect the results.

## Documentation

- All public APIs must have DocC docs.
- Update module DocC when public APIs change.
- Prefer tutorials/articles for onboarding and complex components.
- Use `Scripts/generate-docs.sh` for site generation.

## Logging

- Never use `print`, `debugPrint`, or `dump` in production code.
- Use `IronLogger` from `IronCore` with appropriate log levels.

## Planning & Issues

- Record plans in `Plans/` (not `Plan.md`).
- Record problems/concerns as markdown files in `Issues/`.
