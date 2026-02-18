# Sources — Agent Instructions

<!-- Updated: 2026-02-18 -->

> Coding conventions and shared guidance for all IronUI source modules.
> Module-specific context lives in each module's own `AGENTS.md`.

## Theming & Visual Identity

- Use token-based theming (`IronTheme` and token protocols).
- Default theme should embody the visual identity principles in `adrs/0003-visual-identity.md`
  and `adrs/VISUAL_IDENTITY.md`.
- Prefer semantic tokens; avoid hard-coded colors, spacing, or fonts in components.

## Accessibility (Non-Negotiable)

- Minimum touch targets: 44×44 points.
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

## Documentation

- All public APIs must have DocC docs.
- Update module DocC when public APIs change.
- Prefer tutorials/articles for onboarding and complex components.

## Logging

- Never use `print`, `debugPrint`, or `dump` in production code.
- Use `IronLogger` from `IronCore` with appropriate log levels.

## Module Dependency Order

```
IronCore (foundation — no IronUI dependencies)
  └─► IronPrimitives (basic controls)
        └─► IronComponents (composed controls)
        └─► IronForms (form-specific components)
        └─► IronLayouts (layout containers)
        └─► IronNavigation (navigation patterns)
        └─► IronDataDisplay (data visualization)
              └─► IronUI (umbrella re-export)
```

Never import a higher-layer module from a lower-layer module.
