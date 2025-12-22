# IronUI Visual Identity

IronUI's visual identity is inspired by groundbreaking design work from apps like [Family](https://benji.org/family-values) and [Honkish](https://benji.org/honkish). Our goal is to create components that are not just functional, but delightful to use.

## Core Design Principles

### 1. Fluidity Over Statics

The UI should feel like a constantly evolving space, not a series of static screens.

**Guidelines:**

- Prefer seamless transitions between states over abrupt changes
- Elements should morph, expand, and contract rather than simply appear/disappear
- Motion creates visible links between screens, helping users understand navigation
- Use `matchedGeometryEffect` for element persistence across views
- Use `.contentTransition(.interpolate)` for text/label morphing

**Examples:**

```swift
// Good: Morphing button label
Button(action: action) {
    Text(isLoading ? "Loading..." : "Submit")
        .contentTransition(.interpolate)
}

// Good: Expanding card
CardView()
    .matchedGeometryEffect(id: cardID, in: namespace)
```

### 2. Progressive Revelation

Show complexity only when needed. Respect the user's time and cognitive load.

**Guidelines:**

- Start with simple, focused interfaces
- Reveal advanced options through expanding trays or progressive disclosure
- Use dynamic containers that grow to accommodate content
- Avoid overwhelming users with all options at once

**Examples:**

- Settings panels that expand to show advanced options
- Form fields that reveal validation details on focus
- Menus that show frequently used items first

### 3. Delight Through Details

Strategic micro-interactions create emotional connection without becoming distracting.

**Guidelines:**

- Apply the **Delight-Impact Curve**: Less-used features get more delightful moments
- Frequently-used actions should be efficient with subtle satisfaction
- Easter eggs reward exploration
- Haptic feedback (where available) reinforces actions

**Examples:**

- Satisfying animation when completing a task
- Subtle bounce on successful form submission
- Playful animations in empty states
- Confetti for achievements (sparingly!)

### 4. Semantic Motion & Color

Visual elements should communicate meaning, not just decoration.

**Guidelines:**

- Colors reinforce meaning:
  - Red/destructive colors for dangerous actions
  - Green for success
  - Yellow/orange for warnings
- Transitions communicate relationships between elements
- Physics-based animations feel natural and predictable
- Use spring animations with appropriate response/damping

**Animation Tokens:**

| Token | Use Case | Configuration |
|-------|----------|---------------|
| `snappy` | Quick feedback, buttons | `.spring(response: 0.3, dampingFraction: 0.7)` |
| `smooth` | Standard transitions | `.spring(response: 0.4, dampingFraction: 0.8)` |
| `bouncy` | Playful, celebratory | `.spring(response: 0.5, dampingFraction: 0.6)` |
| `gentle` | Slow reveals, backgrounds | `.spring(response: 0.6, dampingFraction: 0.9)` |

### 5. Dimensional Awareness

Create a sense of space and depth in the interface.

**Guidelines:**

- Use contextual overlays rather than full-screen displacement
- Maintain spatial relationships during navigation
- Create depth through subtle shadows and layering
- Color-tinted shadows add richness (e.g., primary button casts primary-tinted shadow)

**Shadow System:**

```swift
// Multi-layer shadows for natural depth
.shadow(color: .black.opacity(0.04), radius: 1, y: 1)
.shadow(color: .black.opacity(0.08), radius: 4, y: 2)
.shadow(color: .black.opacity(0.04), radius: 8, y: 4)

// Color-tinted shadows
.shadow(color: theme.colors.primary.opacity(0.3), radius: 8, y: 4)
```

## Motion Patterns

| Pattern | Use Case | Implementation |
|---------|----------|----------------|
| **Morph** | Button labels, icons changing | `.contentTransition(.interpolate)` |
| **Expand/Contract** | Trays, accordions, cards | `matchedGeometryEffect` |
| **Slide & Fade** | List items appearing | Combined `.offset` + `.opacity` |
| **Spring Response** | Button press, toggle | `.spring(response:dampingFraction:)` |
| **Ripple** | Touch feedback | Custom ripple effect modifier |
| **Shimmer** | Loading states | Animated gradient mask |

## Default Theme Characteristics

### Color Palette

- **Bold primaries**: Confident, not muted
- **Rich semantics**: Distinct success/warning/error colors
- **Surface depth**: Subtle gradients for elevated surfaces
- **High contrast**: WCAG AA compliant

### Typography

- Clean, modern type scale
- Dynamic Type support throughout
- Semantic weights: regular, medium, semibold, bold

### Spacing

- 8pt grid system
- Generous whitespace
- Minimum 44pt touch targets

### Corners

- Consistent radius scale: sm (4pt), md (8pt), lg (12pt), xl (16pt), full (9999pt)
- Larger radii for larger elements

### Shadows

- Multi-layer for natural appearance
- Color-tinted for interactive elements
- Respect `accessibilityReduceTransparency`

## Accessibility Considerations

All visual identity choices must respect accessibility:

1. **Reduce Motion**: Provide alternatives when `accessibilityReduceMotion` is enabled
2. **Contrast**: All color combinations meet WCAG AA (4.5:1 minimum)
3. **Focus Indicators**: Clear, visible focus states
4. **Dynamic Type**: All text scales appropriately

```swift
@Environment(\.accessibilityReduceMotion) private var reduceMotion

var animation: Animation {
    reduceMotion ? .none : theme.animation.bouncy
}
```

## Inspiration & References

- [Family Values - Design Philosophy](https://benji.org/family-values)
- [Honkish - Design Breakdown](https://benji.org/honkish)
- [Apple Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
- [Material Design Motion](https://m3.material.io/styles/motion)
