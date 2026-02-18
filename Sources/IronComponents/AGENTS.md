# IronComponents — Agent Instructions

<!-- Updated: 2026-02-18 -->

> Composed components built from IronPrimitives.

## What Lives Here

Avatar, Chip, Menu, SegmentedControl, Skeleton.

## Key Conventions

- Components compose primitives — prefer `IronText`, `IronButton`, etc. over raw SwiftUI.
- Depends on `IronCore` and `IronPrimitives`.
- Each component gets its own subdirectory.
- Snapshot tests live in `Tests/IronUISnapshotTests/Components/`.
