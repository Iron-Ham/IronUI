# ADR-0006: Component API Design

## Status

Accepted

## Context

As IronUI grows, consistent API design across components becomes critical for:

1. Developer experience and discoverability
2. Reducing cognitive load when learning new components
3. Maintaining a cohesive library feel
4. Preventing breaking changes from inconsistent patterns

## Decision

Establish the following API design conventions for all IronUI components:

### 1. Naming Conventions

**Boolean properties** use `is` prefix:
```swift
isDisabled, isSelected, isChecked, isOn, isRequired, isFullWidth
```

**Action callbacks** use `on` prefix:
```swift
onTap, onDismiss, onChange, onSubmit
```

**Content builders** use descriptive names:
```swift
label, content, header, footer, leading, trailing
```

### 2. Controlled Components

All interactive components use `Binding<T>` (controlled pattern):

```swift
// Correct: Controlled via Binding
IronToggle(isOn: $isEnabled)
IronTextField(text: $email)

// Not supported: Uncontrolled with initial value
IronToggle(initialValue: true)  // ❌
```

**Rationale:** Controlled components provide predictable state, easier testing, and align with SwiftUI conventions.

### 3. Configuration vs Composition

**Use configuration (parameters)** for:
- Variants and sizes (closed set of options)
- Boolean flags
- Simple string content

**Use composition (`@ViewBuilder`)** for:
- Complex or custom content
- When consumers need full control over child views

**Provide both when practical:**
```swift
// Configuration (convenience)
IronButton("Submit", variant: .filled) { }

// Composition (flexibility)
IronButton(variant: .filled) {
    // action
} label: {
    HStack {
        Image(systemName: "paperplane")
        Text("Submit")
    }
}
```

### 4. Closed Enums for Variants

Variant and size types are **closed enums**, not protocols:

```swift
public enum IronButtonVariant: Sendable, CaseIterable {
    case filled, outlined, ghost, elevated
}

public enum IronButtonSize: Sendable, CaseIterable {
    case small, medium, large
}
```

**Rationale:**
- Ensures exhaustive switch statements
- Prevents untested custom variants
- New variants are added via library updates or feature requests
- Keeps the design system cohesive

### 5. Optional Callbacks

Use optional closures with `nil` default, not empty closures:

```swift
// Correct
public init(onDismiss: (() -> Void)? = nil)

// Avoid
public init(onDismiss: @escaping () -> Void = {})
```

**Rationale:** Allows components to conditionally render UI (e.g., dismiss button) based on callback presence.

### 6. Initializer Parameter Order

Follow this order for consistency:

1. Content/title (first, often unlabeled)
2. Binding (if applicable)
3. Variant/style
4. Size
5. Color
6. Boolean modifiers (isDisabled, isRequired, etc.)
7. Callbacks (onTap, onDismiss)
8. ViewBuilder content/label (trailing)

```swift
public init(
    _ title: LocalizedStringKey,           // 1. Content
    variant: IronButtonVariant = .filled,  // 3. Variant
    size: IronButtonSize = .medium,        // 4. Size
    isFullWidth: Bool = false,             // 6. Boolean
    action: @escaping () -> Void           // 7. Callback
)
```

### 7. Localization

All user-facing strings accept `LocalizedStringKey`:

```swift
public init(_ title: LocalizedStringKey)
public init(_ title: String)  // Convenience, converts internally
```

## Consequences

### Positive

- Predictable, learnable API across all components
- Easier code review (deviations from conventions are obvious)
- Better autocomplete experience
- Reduced documentation burden (patterns are consistent)

### Negative

- Some flexibility sacrificed (no custom variants)
- Requires discipline to maintain consistency
- Existing components may need updates to conform

## References

- [Swift API Design Guidelines](https://www.swift.org/documentation/api-design-guidelines/)
- [SwiftUI Component Patterns](https://developer.apple.com/documentation/swiftui)
