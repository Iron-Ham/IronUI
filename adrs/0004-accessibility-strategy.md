# ADR-0004: Accessibility Strategy

## Status

Accepted

## Context

IronUI must be accessible to all users, including those using assistive technologies. We need to ensure:

1. WCAG 2.1 AA compliance at minimum
2. VoiceOver and other screen reader support
3. Dynamic Type support
4. Sufficient color contrast
5. Keyboard navigation (macOS)
6. Reduce Motion respect

## Decision

Implement accessibility as a first-class concern with the following strategies:

### 1. Component-Level Requirements

Every interactive component must:

```swift
// Minimum touch target: 44x44 points
.frame(minWidth: 44, minHeight: 44)

// Proper accessibility traits
.accessibilityAddTraits(.isButton)
.accessibilityRemoveTraits(isDisabled ? .isEnabled : [])

// Meaningful labels
.accessibilityLabel(accessibilityLabel ?? computedLabel)
.accessibilityHint(accessibilityHint)
```

### 2. Dynamic Type Support

All text must scale with Dynamic Type:

```swift
// Use semantic font styles
.font(.body)  // Not .system(size: 16)

// Or theme typography that respects Dynamic Type
Text("Hello")
    .font(theme.typography.bodyLarge)
```

### 3. Color Contrast

- All color token combinations must meet WCAG AA (4.5:1 for text)
- Provide contrast-checking utilities in IronCore
- Default theme validated for contrast compliance

### 4. Motion Accessibility

Respect `accessibilityReduceMotion`:

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

var animation: Animation {
    reduceMotion ? .none : theme.animation.bouncy
}
```

### 5. Focus Management

- Clear focus indicators on all interactive elements
- Logical focus order
- Focus trapping for modals/dialogs

### 6. Testing Requirements

- Accessibility audit in CI using Xcode's accessibility inspector
- Document accessibility features for each component

## Consequences

### Positive

- Inclusive design from the start
- Legal compliance for enterprise users
- Better experience for all users (larger touch targets, clear focus)
- Forces thoughtful component design

### Negative

- Additional development time per component
- Testing complexity increases
- Some visual designs may need adjustment for contrast

### Neutral

- Following established patterns (Apple HIG, WCAG)
- Similar requirements to other mature UI libraries

## Alternatives Considered

### Accessibility as Opt-in

Make accessibility features optional. Rejected because it leads to inaccessible defaults.

### Separate Accessible Components

Create "IronButtonAccessible" variants. Rejected because it fragments the API and makes accessibility an afterthought.

## References

- [WCAG 2.1 Guidelines](https://www.w3.org/WAI/WCAG21/quickref/)
- [Apple Accessibility Documentation](https://developer.apple.com/accessibility/)
- [CVS Health iOS Accessibility Techniques](https://github.com/cvs-health/ios-swiftui-accessibility-techniques)
