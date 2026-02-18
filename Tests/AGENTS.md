# Tests — Agent Instructions

<!-- Updated: 2026-02-18 -->

> Testing conventions for IronUI.

## Frameworks

- **Unit tests:** Swift Testing (`import Testing`, not XCTestCase).
- **Snapshot tests:** PointFree `swift-snapshot-testing`.

## Running Tests

| Command | Purpose |
|---------|---------|
| `swift run ironui-cli test` | Run unit tests (both platforms) |
| `swift run ironui-cli test --platform macos` | macOS only |
| `swift run ironui-cli snapshots` | Run snapshot tests (both platforms) |
| `swift run ironui-cli snapshots --record` | Update snapshot baselines |

## Structure

- Unit tests mirror the source module structure: `IronCoreTests/`, `IronPrimitivesTests/`, etc.
- Snapshot tests are centralized in `IronUISnapshotTests/` with subdirectories per module.
- `__Snapshots__/` directories contain recorded baselines — commit these.
- `SnapshotTestUtilities.swift` has shared helpers for snapshot configuration.

## Conventions

- Add accessibility audits for interactive components.
- For snapshot/visual changes, always re-record for **both iOS and macOS**.
- Visually inspect snapshot diffs before committing.
- Integration tests go in `IronUIIntegrationTests/`.
