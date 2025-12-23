# ``IronUI``

A modern SwiftUI component library for iOS 26+ and macOS 26+, designed for the Liquid Glass aesthetic.

## Overview

IronUI provides a comprehensive suite of 60+ production-ready SwiftUI components with:

- **Liquid Glass Aesthetic** - Designed for iOS 26 and macOS 26's visual language
- **Complete Theming System** - 6 token categories with automatic light/dark mode adaptation
- **Full Accessibility** - VoiceOver, Dynamic Type, and reduced motion support
- **Swift 6 Ready** - Strict concurrency compliance throughout

### Design Philosophy

IronUI follows five core principles:

1. **Fluidity Over Statics** - Seamless transitions and morphing elements
2. **Progressive Revelation** - Show complexity only when needed
3. **Delight Through Details** - Strategic micro-interactions
4. **Semantic Motion & Color** - Visuals that communicate meaning
5. **Soft, Confident UI** - Avoid hard edges; embrace flowing contours

## Topics

### Essentials

- <doc:GettingStarted>
- <doc:Theming>
- <doc:Accessibility>

### Modules

Import individual modules for smaller bundle sizes, or use `IronUI` for everything.

| Module | Description |
|--------|-------------|
| `IronCore` | Theming, tokens, accessibility |
| `IronPrimitives` | Basic components (Button, Text, TextField) |
| `IronComponents` | Composed components (Avatar, Chip, Menu) |
| `IronLayouts` | Layout helpers (Container, Flow, Stack) |
| `IronForms` | Form components (Form, FormField, DatePicker) |
| `IronDataDisplay` | Data visualization (Timeline, Kanban, Database) |
| `IronNavigation` | Navigation & presentation (Tray) |

### Primitives

Basic building blocks for constructing interfaces: `IronButton`, `IronText`, `IronIcon`, `IronTextField`, `IronSecureField`, `IronCheckbox`, `IronToggle`, `IronRadio`, `IronProgress`, `IronSpinner`, `IronAlert`, `IronBadge`, `IronCard`, `IronDivider`.

### Components

Composed elements for common UI patterns: `IronAvatar`, `IronChip`, `IronSegmentedControl`, `IronMenu`, `IronSkeleton`.

### Layouts

Responsive layout components: `IronContainer`, `IronFlow`, `IronResponsiveStack`, `IronAdaptiveStack`, `IronSizeClassStack`.

### Forms

Form building components with validation: `IronForm`, `IronFormSection`, `IronFormField`, `IronFormRow`, `IronDatePicker`, `IronTimePicker`, `IronValidator`.

### Data Display

Components for visualizing structured data: `IronTimeline`, `IronKanban`, `IronDatabase`.

### Navigation

Navigation and presentation components: `IronTray`.
