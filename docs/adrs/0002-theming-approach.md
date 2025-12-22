# ADR-0002: Theming Approach

## Status

Accepted

## Context

IronUI needs a theming system that is:

1. Highly customizable
2. Type-safe
3. Swift 6 concurrency compliant (Sendable)
4. Easy to use with SwiftUI's environment system
5. Supports light/dark mode and beyond

## Decision

Implement a token-based theming system with protocol-based customization:

### Token Hierarchy

```
Global Tokens (Raw Values)
    |
    v
Semantic Tokens (Meaning-based)
    |
    v
Component Tokens (Component-specific)
```

### Core Protocols

```swift
public protocol IronTheme: Sendable {
    associatedtype Colors: IronColorTokens
    associatedtype Typography: IronTypographyTokens
    associatedtype Spacing: IronSpacingTokens
    associatedtype Radii: IronRadiusTokens
    associatedtype Shadows: IronShadowTokens
    associatedtype Animation: IronAnimationTokens

    var colors: Colors { get }
    var typography: Typography { get }
    var spacing: Spacing { get }
    var radii: Radii { get }
    var shadows: Shadows { get }
    var animation: Animation { get }
}
```

### Environment Integration

```swift
extension EnvironmentValues {
    public var ironTheme: any IronTheme { ... }
}
```

### Animation Tokens

Wrap native SwiftUI `Animation` types rather than creating custom animation systems:

```swift
public protocol IronAnimationTokens: Sendable {
    var snappy: Animation { get }  // Wraps .spring(...)
    var smooth: Animation { get }
    var bouncy: Animation { get }
}
```

## Consequences

### Positive

- Full type safety with associated types
- Sendable compliance for Swift 6
- Semantic naming improves code readability
- Easy to create custom themes
- Animation tokens leverage SwiftUI's optimized animation system

### Negative

- Associated types can make generic code more complex
- Learning curve for token-based thinking
- More boilerplate than simple value types

### Neutral

- Similar to design token systems in web (Tailwind, Material)
- Follows SwiftUI's environment pattern

## Alternatives Considered

### Simple Value Types

Use structs with Color/Font properties directly. Less flexible for customization.

### Custom Animation System

Build our own animation engine. Unnecessary when SwiftUI's Animation is excellent.

## References

- [Material Design Tokens](https://m3.material.io/foundations/design-tokens)
- [SwiftUI Environment](https://developer.apple.com/documentation/swiftui/environment)
