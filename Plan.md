# IronUI Development Plan

## Goal

Build the components needed to recreate the [Family Values](https://benji.org/family-values) showcase, culminating in the dynamic bottom sheet (tray) system.

---

## Current State

### Completed Modules

**IronCore** - Foundation layer
- IronLogger (OSLog integration)
- IronTheme + AnyIronTheme
- Tokens: Animation, Color, Radius, Shadow, Spacing, Typography

**IronPrimitives** - Atomic components
- IronButton, IronText, IronIcon, IronDivider
- IronTextField, IronSecureField, IronToggle, IronCheckbox, IronRadio
- IronCard, IronBadge, IronProgress, IronSpinner, IronAlert, IronContextLine

**IronComponents** - Composed components
- IronAvatar (with badge cutout)
- IronChip, IronMenu, IronSegmentedControl, IronSkeleton

### Placeholder Modules (structure only)
- IronLayouts, IronNavigation, IronForms, IronDataDisplay, IronKitBridge, IronUI

---

## Family Values Components

From the [Family Values](https://benji.org/family-values) showcase:

### 1. Dynamic Tray System (Primary Goal)
- Variable heights signaling progression
- Context preservation (overlay, not full-screen)
- Single focus per tray
- Contextual/adaptive theming
- Navigation controls (dismiss/back via title icon)
- Drag-to-dismiss with velocity detection

### 2. Text Morphing Animations
- Button labels: "Continue" → "Confirm" (shared letter animation)
- Dynamic number formatting (comma repositioning)
- Partial text updates (only changed portions animate)

### 3. Transition Patterns
- Directional tab switching (motion matches direction)
- Shared element transitions (components glide between screens)
- Chevron/icon rotation during navigation

### 4. Micro-interactions
- Ripple effects
- Confetti celebrations
- Shimmer for background updates
- Drag-and-drop reordering

---

## Implementation Phases

### Phase 1: IronNavigation - Dynamic Tray ✅
**Priority: HIGH** - This is the showcase component

```
Sources/IronNavigation/
├── Tray/
│   ├── IronTray.swift          # Content-sized tray container
│   └── IronTrayModifier.swift  # .ironTray() view modifier
```

**Completed (Family Values redesign):**
- [x] Content-driven sizing (not fixed detents)
- [x] Drag gesture with velocity-based dismissal
- [x] IronTrayStack for sequential navigation
- [x] IronTrayNavigator with push/pop/popToRoot
- [x] IronTrayHeader (title + dismiss/back icon)
- [x] Background dimming with tap-to-dismiss
- [x] Accessibility: reduce motion support
- [x] Height animations signal progression

### Phase 2: IronCore - Animation Utilities ✅
**Priority: HIGH** - Needed for tray polish and text morphing

```
Sources/IronCore/Animation/
├── IronTextTransition.swift      # Text morphing utilities
├── IronMatchedGeometry.swift     # Matched geometry helpers
└── IronDirectionalTransition.swift # Directional transitions
```

**Completed:**
- [x] IronMorphingText - Animated text transitions
- [x] IronCountingText - Animated number counting
- [x] `.ironMorphingText()` modifier
- [x] `ironNamespace` environment for shared geometry
- [x] `.ironMatchedGeometry()` modifier
- [x] IronHeroTransition container
- [x] IronDirection enum with directional transitions
- [x] `.ironSlide()` and `.ironPush()` transitions
- [x] IronDirectionalContainer for tab-like navigation

### Phase 3: IronLayouts - Layout Components ✅
**Priority: MEDIUM** - Useful but not blocking

```
Sources/IronLayouts/
├── Container/
│   └── IronContainer.swift    # Adaptive max-width + padding
├── Flow/
│   └── IronFlowLayout.swift   # Flexbox-style wrap layout
└── Responsive/
    └── IronResponsiveStack.swift  # Adaptive HStack/VStack
```

**Completed:**
- [x] IronFlow - Flexbox-style wrapping for tags, chips, labels
- [x] IronAdaptiveStack - ViewThatFits-based layout switching
- [x] IronResponsiveStack - Threshold-based layout switching
- [x] IronSizeClassStack - Size class-based layout switching
- [x] IronContainer - Max-width constraints for content

### Phase 4: Micro-interactions
**Priority: LOW** - Polish layer

- [ ] `.ironRipple()` modifier
- [ ] `IronConfetti` view
- [ ] Enhanced drag-and-drop helpers

### Phase 5: IronForms - Form Container
**Priority: LOW** - After navigation is solid

- [ ] `IronForm` - Form container with sections
- [ ] `IronFormField` - Label + input + error wrapper
- [ ] `IronDatePicker` - Themed date picker

---

## Tooling

- [x] `ironui-cli` - Developer CLI (on `feat/ironui-cli` branch)
  - [x] `build`, `test`, `format`, `docs` commands
  - [ ] Merge to main

---

## Next Action

Phases 1-3 complete. Next options:
- **Phase 4: Micro-interactions** - `.ironRipple()`, `IronConfetti`
- **Phase 5: IronForms** - Form container, validation
