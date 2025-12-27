# Accessibility

Build inclusive interfaces with IronUI's accessibility features.

## Overview

IronUI is built with accessibility as a core principle. Every component supports VoiceOver, Dynamic Type, and reduced motion preferences out of the box.

## VoiceOver Support

All IronUI components provide meaningful accessibility labels and traits.

### Automatic Labeling

Components automatically generate appropriate labels:

```swift
// Automatically announces "Primary button, Submit"
IronButton("Submit", variant: .filled) { }

// Announces "Toggle, Enable notifications, On"
IronToggle("Enable notifications", isOn: $isEnabled)

// Announces "Avatar for John Doe, Online"
IronAvatar(name: "John Doe", status: .online)
```

### Custom Labels

Override default labels when needed:

```swift
IronButton("", variant: .filled, leadingIcon: "plus") { }
    .accessibilityLabel("Add new item")

IronIcon(systemName: "star.fill", color: .warning)
    .accessibilityLabel("Favorite")
```

### Composite Elements

IronUI combines related elements for efficient VoiceOver navigation:

```swift
// Chip with icon + label + dismiss = single VoiceOver element
IronChip("Swift", icon: "swift") {
    // dismiss action
}
// Announces: "Swift, Removable, Button. Actions available: Remove"
```

## Dynamic Type

IronUI scales appropriately with the user's preferred text size.

### Automatic Scaling

All text and text-related measurements scale with Dynamic Type:

```swift
// Text automatically scales
IronText("Welcome", style: .headlineLarge, color: .primary)

// Icons scale proportionally
IronIcon(systemName: "star", size: .medium, color: .primary)

// Spacing adapts to maintain visual balance
IronButton("Submit", size: .large) { }
```

### ScaledMetric Usage

Components use `@ScaledMetric` for consistent scaling:

```swift
struct MyComponent: View {
    @ScaledMetric(relativeTo: .body) private var iconSize: CGFloat = 20

    var body: some View {
        Image(systemName: "star")
            .frame(width: iconSize, height: iconSize)
    }
}
```

### Testing Dynamic Type

Test your interfaces across the full range of sizes:

- **Extra Small** - Smallest readable size
- **Large** - System default
- **XXX-Large** - Large text preference
- **Accessibility XXX-Large** - Maximum accessibility size

## Reduced Motion

IronUI respects the user's reduced motion preference.

### Automatic Adaptation

Animations automatically simplify when reduced motion is enabled:

```swift
// Uses spring animation normally, instant transition with reduced motion
IronButton("Tap me") { }

// Progress spinner stops animated when reduced motion is on
IronSpinner()
```

### Manual Checking

Check the preference manually for custom animations:

```swift
struct MyView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        content
            .animation(reduceMotion ? nil : .spring(), value: isExpanded)
    }
}
```

### Accessible Animation Modifier

Use the `accessibleAnimation` modifier for automatic handling:

```swift
MyView()
    .accessibleAnimation(.bouncy, value: isExpanded)
```

## Color and Contrast

IronUI's semantic colors maintain WCAG contrast ratios.

### Semantic Colors

Always use semantic color tokens:

```swift
// Good: Semantic colors adapt to context
IronText("Error message", style: .bodyMedium, color: .error)

// Avoid: Hardcoded colors may not have sufficient contrast
Text("Error").foregroundColor(.red)
```

### High Contrast Mode

Components automatically enhance contrast when the user enables "Increase Contrast"
in system accessibility settings (iOS: Settings > Accessibility > Display & Text Size,
macOS: System Settings > Accessibility > Display).

IronUI's default color tokens include high contrast variants for:
- **Text colors**: Pure black/white for maximum readability
- **Borders and dividers**: More prominent for better element separation
- **Backgrounds**: Pure white/black for maximum contrast
- **Semantic colors**: More saturated error, warning, and success colors

```swift
// Colors automatically adapt when accessibilityContrast is .high
IronText("Important message", style: .bodyMedium, color: .primary)

// Custom themes can also support high contrast using the Color initializer
let customColor = Color(
    light: Color(white: 0.4),
    dark: Color(white: 0.6),
    highContrastLight: Color(white: 0.2),
    highContrastDark: Color(white: 0.85)
)
```

## Best Practices

### Do

- Use descriptive labels that convey purpose
- Test with VoiceOver enabled
- Verify layouts at all Dynamic Type sizes
- Respect reduced motion preferences
- Use semantic colors for text

### Don't

- Hide interactive elements from accessibility
- Rely solely on color to convey information
- Use fixed font sizes
- Force animations without checking preferences
- Create contrast ratios below 4.5:1

## Testing Accessibility

### Xcode Accessibility Inspector

1. Open **Xcode > Open Developer Tool > Accessibility Inspector**
2. Select your running simulator
3. Inspect elements and verify labels, traits, and values

### VoiceOver Testing

1. Enable VoiceOver in Settings > Accessibility > VoiceOver
2. Navigate your app using swipe gestures
3. Verify all interactive elements are reachable
4. Check that announcements make sense in context

### Dynamic Type Testing

1. Go to Settings > Accessibility > Display & Text Size
2. Adjust "Larger Text" slider
3. Verify your app remains usable at all sizes
4. Pay attention to text truncation and layout issues
