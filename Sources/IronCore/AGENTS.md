# IronCore — Agent Instructions

<!-- Updated: 2026-02-18 -->

> Foundation module. Everything else depends on this — changes here ripple everywhere.

## What Lives Here

- **Animation/** — shared animation utilities and motion tokens.
- **Environment/** — SwiftUI environment keys and values for theming/config.
- **Interactions/** — gesture and interaction primitives.
- **Layout/** — foundational layout utilities.
- **Logging/** — `IronLogger` (the only approved logging mechanism).
- **Theming/** — `IronTheme`, token protocols, and default theme definitions.

## Key Constraints

- This module has **zero IronUI dependencies** — it only imports SwiftUI/Foundation.
- Any public API change here affects every downstream module. Be deliberate.
- Theme token protocols defined here are the contract all components build against.
