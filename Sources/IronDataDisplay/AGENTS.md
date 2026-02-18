# IronDataDisplay — Agent Instructions

<!-- Updated: 2026-02-18 -->

> Components for displaying structured data: tables, kanban boards, timelines.

## What Lives Here

Database, Kanban, Timeline.

## Key Conventions

- Depends on `IronCore` and `IronPrimitives`.
- **ListKit** (`Iron-Ham/Lists`) is an **iOS-only** dependency — it provides `CollectionViewDiffableDataSource` and `DiffableDataSourceSnapshot` with async, serialized applies. It is conditionally linked via `condition: .when(platforms: [.iOS])` in both `Package.swift` and `Project.swift`. All ListKit usage must be inside `#if os(iOS)` guards.
- These components tend to be complex — pay extra attention to performance.
- Snapshot tests live in `Tests/IronUISnapshotTests/DataDisplay/`.
