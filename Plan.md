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

### Phase 1: IronNavigation - Dynamic Tray
**Priority: HIGH** - This is the showcase component

```
Sources/IronNavigation/
├── Tray/
│   ├── IronTray.swift              # Core tray container
│   ├── IronTrayConfiguration.swift # Height detents, theming
│   ├── IronTrayStack.swift         # Multi-tray coordination
│   └── IronTrayModifier.swift      # .ironTray() view modifier
└── Transitions/
    └── IronDirectionalTransition.swift
```

**IronTray Features:**
- [ ] Detent system (fractional heights, intrinsic sizing)
- [ ] Drag gesture with velocity-based dismissal
- [ ] Stacked trays with height differentiation
- [ ] Adaptive theming per tray
- [ ] Navigation header (title + dismiss/back icon)
- [ ] Background dimming with tap-to-dismiss
- [ ] Keyboard avoidance
- [ ] Accessibility: reduce motion support

### Phase 2: IronCore - Animation Utilities
**Priority: HIGH** - Needed for tray polish and text morphing

```
Sources/IronCore/Animation/
├── IronTextMorph.swift        # Shared letter animation helper
├── IronMatchedGeometry.swift  # matchedGeometryEffect helpers
└── IronTransition.swift       # Custom AnyTransition extensions
```

**Animation Features:**
- [ ] `.ironMorphingText()` modifier for label transitions
- [ ] `IronNamespace` environment for shared geometry
- [ ] Directional slide transitions
- [ ] Spring presets beyond current tokens

### Phase 3: IronLayouts - Container Components
**Priority: MEDIUM** - Useful but not blocking

```
Sources/IronLayouts/
├── IronContainer.swift    # Adaptive padding/max-width
├── IronVStack.swift       # VStack with spacing tokens
├── IronHStack.swift       # HStack with spacing tokens
└── IronGrid.swift         # Responsive grid
```

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

Start **Phase 1: IronTray** in IronNavigation module.
