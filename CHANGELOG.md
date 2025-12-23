# Changelog

All notable changes to IronUI will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

## [1.0.0] - 2024-XX-XX

### Added

#### Core
- Complete theming system with 6 token categories (colors, typography, spacing, radii, shadows, animations)
- `IronTheme` protocol and `IronDefaultTheme` implementation
- SwiftUI Environment integration via `@Environment(\.ironTheme)`
- Accessibility support with `.accessibleAnimation()` modifier
- `IronLogger` for structured logging

#### Primitives
- `IronButton` - Themed button with variants (filled, outlined, ghost, elevated), sizes, and icon support
- `IronText` - Typography component with 16 semantic styles
- `IronIcon` - SF Symbol wrapper with theming support
- `IronTextField` - Styled text input with placeholder and validation states
- `IronSecureField` - Password input with visibility toggle
- `IronCheckbox` - Checkbox with label support
- `IronToggle` - Switch control with label
- `IronRadio` - Radio button for single selection groups
- `IronProgress` - Linear and circular progress indicators
- `IronSpinner` - Loading spinner with size variants
- `IronAlert` - Contextual alert messages (info, success, warning, error)
- `IronBadge` - Count badges, text badges, and dot indicators
- `IronCard` - Container with elevation styles (elevated, filled, outlined)
- `IronDivider` - Visual separator with label support

#### Components
- `IronAvatar` - User profile images with initials fallback and status badges
- `IronChip` - Tags, filters, and selections with dismiss and select actions
- `IronSegmentedControl` - Tabbed selection with spring animations
- `IronMenu` - Dropdown menu with sections and keyboard shortcuts
- `IronSkeleton` - Loading placeholders with shimmer animation

#### Layouts
- `IronContainer` - Responsive width container with padding options
- `IronFlow` - Flexbox-style wrapping layout
- `IronResponsiveStack` - Threshold-based horizontal/vertical stack
- `IronAdaptiveStack` - Content-aware layout switching
- `IronSizeClassStack` - Size class responsive stack

#### Forms
- `IronForm` - Scrollable form container
- `IronFormSection` - Grouped form fields with headers and footers
- `IronFormField` - Field wrapper with label, hint, and error display
- `IronFormRow` - Horizontal field layout
- `IronDatePicker` - Themed date selection
- `IronTimePicker` - Themed time selection
- `IronValidator` - Composable validation rules

#### Data Display
- `IronTimeline` - Vertical event timeline with multiple layouts
- `IronKanban` - Kanban board with drag-and-drop support
- `IronDatabase` - Notion-style database tables with multiple column types

#### Navigation
- `IronTray` - Bottom sheet presentation

### Requirements
- iOS 26.0+
- macOS 26.0+
- Swift 6.0+
- Xcode 16.0+

[Unreleased]: https://github.com/Iron-Ham/IronUI/compare/v1.0.0...HEAD
[1.0.0]: https://github.com/Iron-Ham/IronUI/releases/tag/v1.0.0
