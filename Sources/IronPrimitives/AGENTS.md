# IronPrimitives — Agent Instructions

<!-- Updated: 2026-02-18 -->

> Basic UI controls that wrap or replace SwiftUI built-ins.
> Higher-layer modules should use these instead of raw SwiftUI views.

## What Lives Here

Alert, Badge, Button, Card, Checkbox, ContextLine, Divider, Icon, Progress,
Radio, SecureField, Spinner, Text, TextField, Toggle.

## Key Conventions

- Each primitive lives in its own subdirectory (e.g., `Button/`).
- Primitives depend only on `IronCore` — never on Components, Forms, etc.
- All primitives must consume theme tokens, not hard-coded values.
- Every interactive primitive needs accessibility labels, hints, and traits.
- Snapshot tests for primitives live in `Tests/IronUISnapshotTests/Primitives/`.
