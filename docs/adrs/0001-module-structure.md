# ADR-0001: Module Structure

## Status

Accepted

## Context

IronUI aims to be a comprehensive, modular SwiftUI component library. We need to decide how to structure the package to allow:

1. Consumers to import only what they need
2. Clear separation of concerns
3. Manageable dependency graph
4. Independent versioning potential

## Decision

Structure IronUI as a multi-module Swift Package with the following hierarchy:

```
IronUI (Umbrella)
    |
    +-- IronCore (Foundation - No internal dependencies)
    |       |-- Design Tokens
    |       |-- Theme Protocols
    |       |-- Accessibility Utilities
    |       |-- Platform Abstractions
    |
    +-- IronPrimitives (Atomic - Depends on IronCore)
    |       |-- Button, Text, Icon
    |       |-- TextField, Toggle, Checkbox, Radio
    |
    +-- IronLayouts (Layout - Depends on IronCore)
    |       |-- Container, Grid, Stack variants
    |
    +-- IronComponents (Molecules - Depends on IronCore, IronPrimitives, IronLayouts)
    |       |-- Card, Alert, Badge, Avatar
    |
    +-- IronNavigation (Depends on IronCore, IronPrimitives, IronComponents)
    |       |-- Custom transitions, presentation styles
    |
    +-- IronForms (Depends on IronCore, IronPrimitives, IronComponents)
    |       |-- Form, FormField, DatePicker
    |
    +-- IronDataDisplay (Depends on IronCore, IronPrimitives, IronComponents)
    |       |-- Table, DataGrid, Timeline
    |
    +-- IronKitBridge (Depends on IronCore)
            |-- UIKit/AppKit representables
```

## Consequences

### Positive

- Consumers can import only `IronPrimitives` without pulling in navigation or forms
- Clear dependency direction (no cycles)
- Easier to test modules in isolation
- Can add new modules without affecting existing ones
- Build times improved for consumers using subsets

### Negative

- More complex package manifest
- Need to manage cross-module APIs carefully
- Public API surface is larger (each module exposes its own API)

### Neutral

- Follows Atomic Design principles (atoms -> molecules -> organisms)
- Similar to how MaterialUI and other component libraries structure themselves

## Alternatives Considered

### Single Module

All components in one `IronUI` module. Simpler but forces consumers to import everything.

### Per-Component Modules

Each component as its own module (e.g., `IronButton`, `IronCard`). Too granular, would create import complexity.

## References

- [Atomic Design by Brad Frost](https://bradfrost.com/blog/post/atomic-web-design/)
- [Swift Package Manager Documentation](https://www.swift.org/documentation/package-manager/)
