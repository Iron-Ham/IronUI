# Theming

Customize IronUI's appearance with design tokens and themes.

## Overview

IronUI's theming system provides six categories of design tokens that control every aspect of your app's visual appearance. Tokens automatically adapt between light and dark modes.

## Token Categories

### Color Tokens

25 semantic colors organized by purpose:

```swift
theme.colors.primary          // Brand primary color
theme.colors.secondary        // Supporting color
theme.colors.background       // Page background
theme.colors.surface          // Card/component background
theme.colors.surfaceElevated  // Elevated surfaces
theme.colors.border           // Borders and dividers
theme.colors.textPrimary      // Primary text
theme.colors.textSecondary    // Secondary text
theme.colors.success          // Success states
theme.colors.warning          // Warning states
theme.colors.error            // Error states
theme.colors.info             // Informational states
```

### Typography Tokens

15 font styles following a consistent scale:

```swift
theme.typography.displayLarge   // Hero text (57pt)
theme.typography.displayMedium  // Large display (45pt)
theme.typography.headlineLarge  // Section headers (32pt)
theme.typography.titleLarge     // Card titles (22pt)
theme.typography.bodyLarge      // Primary content (17pt)
theme.typography.bodyMedium     // Default body (15pt)
theme.typography.labelMedium    // Buttons/labels (14pt)
theme.typography.caption        // Metadata (12pt)
```

### Spacing Tokens

10 spacing values following an 8pt grid:

```swift
theme.spacing.none   // 0pt
theme.spacing.xxs    // 2pt
theme.spacing.xs     // 4pt
theme.spacing.sm     // 8pt
theme.spacing.md     // 12pt
theme.spacing.lg     // 16pt
theme.spacing.xl     // 24pt
theme.spacing.xxl    // 32pt
theme.spacing.xxxl   // 48pt
theme.spacing.huge   // 64pt
```

### Radius Tokens

7 corner radius values:

```swift
theme.radii.none  // 0pt (sharp corners)
theme.radii.xs    // 2pt
theme.radii.sm    // 4pt
theme.radii.md    // 8pt
theme.radii.lg    // 12pt
theme.radii.xl    // 16pt
theme.radii.full  // Fully rounded (capsule)
```

### Shadow Tokens

5 elevation levels with multi-layer shadows:

```swift
theme.shadows.none       // No shadow
theme.shadows.sm         // Subtle elevation
theme.shadows.md         // Card elevation
theme.shadows.lg         // Modal elevation
theme.shadows.xl         // Floating element
```

### Animation Tokens

5 durations and 6 spring-based presets:

```swift
// Durations
theme.animation.instant   // 0.1s
theme.animation.fast      // 0.2s
theme.animation.normal    // 0.3s
theme.animation.slow      // 0.5s
theme.animation.verySlow  // 1.0s

// Spring animations
theme.animation.snappy    // Quick, responsive
theme.animation.bouncy    // Playful bounce
theme.animation.smooth    // Gentle transition
```

## Accessing the Theme

Use the environment to access theme tokens in any view:

```swift
struct MyView: View {
    @Environment(\.ironTheme) private var theme

    var body: some View {
        Text("Hello")
            .font(theme.typography.headlineMedium)
            .foregroundStyle(theme.colors.textPrimary)
            .padding(theme.spacing.lg)
            .background(theme.colors.surface)
            .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
    }
}
```

## Creating a Custom Theme

Implement the `IronTheme` protocol to create a custom theme:

```swift
struct MyCustomTheme: IronTheme {
    let colors = MyColorTokens()
    let typography = MyTypographyTokens()
    let spacing = IronDefaultSpacingTokens()
    let radii = IronDefaultRadiusTokens()
    let shadows = IronDefaultShadowTokens()
    let animation = IronDefaultAnimationTokens()
}

struct MyColorTokens: ColorTokens {
    var primary: Color { .blue }
    var secondary: Color { .purple }
    // ... implement all required colors
}
```

Apply your custom theme:

```swift
ContentView()
    .environment(\.ironTheme, MyCustomTheme())
```

## Best Practices

1. **Use semantic tokens** - Prefer `theme.colors.primary` over hardcoded colors
2. **Respect the scale** - Use spacing tokens instead of arbitrary values
3. **Test both modes** - Verify your UI in light and dark mode
4. **Maintain contrast** - Ensure text remains readable on all backgrounds
