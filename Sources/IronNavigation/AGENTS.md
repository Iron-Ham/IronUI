# IronNavigation — Agent Instructions

<!-- Updated: 2026-02-18 -->

> Navigation patterns: trays, sheets, and navigation flows.

## What Lives Here

Tray.

## Key Conventions

- Depends on `IronCore`.
- Snapshot tests live in `Tests/IronUISnapshotTests/Navigation/`.

## Learnings

<!-- Updated: 2026-02-18 -->
- Column resize gestures on iOS can conflict with the system navigation back swipe.
  See commit `ed6d4d83` for the fix pattern (prevent gesture interference).
