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

## StringProtocol Overload Parity

<!-- Updated: 2026-02-18 -->

Every public initializer that takes `LocalizedStringKey` for a title **must** have a
corresponding `some StringProtocol` overload. This is the standard SwiftUI pattern
(see `SwiftUI.Text`). Without it, callers passing `String` variables get a compile
error because Swift won't implicitly convert `String` → `LocalizedStringKey`.

- When adding a new `LocalizedStringKey` init, always add the `StringProtocol` twin.
- The `StringProtocol` overload converts via `LocalizedStringKey(String(title))`.
- Use accessibility strings via `String(localized:)`, not bare string literals.
