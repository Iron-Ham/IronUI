# IronUI

A modern SwiftUI component library for iOS 26+ and macOS 26+, designed for the Liquid Glass aesthetic.

[![Swift 6](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![iOS 26+](https://img.shields.io/badge/iOS-26+-blue.svg)](https://developer.apple.com/ios/)
[![macOS 26+](https://img.shields.io/badge/macOS-26+-blue.svg)](https://developer.apple.com/macos/)
[![MIT License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

## Features

- **60+ Production-Ready Components** - Buttons, forms, data display, navigation, and more
- **Liquid Glass Aesthetic** - Designed for iOS 26 and macOS 26's visual language
- **Complete Theming System** - 6 token categories with automatic light/dark mode adaptation
- **Full Accessibility** - VoiceOver, Dynamic Type, and reduced motion support
- **Swift 6 Ready** - Strict concurrency compliance throughout

## Installation

### Swift Package Manager

Add IronUI to your project using Xcode:

1. Go to **File > Add Package Dependencies...**
2. Enter the repository URL:
   ```
   https://github.com/Iron-Ham/IronUI
   ```
3. Select the version and click **Add Package**

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Iron-Ham/IronUI", from: "1.0.0")
]
```

## Quick Start

```swift
import IronUI
import SwiftUI

struct ContentView: View {
    @State private var name = ""
    @State private var isEnabled = true

    var body: some View {
        IronContainer {
            VStack(spacing: 24) {
                IronText("Welcome", style: .headlineLarge, color: .primary)

                IronTextField("Enter your name", text: $name)

                IronToggle("Enable notifications", isOn: $isEnabled)

                IronButton("Get Started", variant: .filled) {
                    // Handle action
                }
            }
        }
    }
}
```

## Components

### Primitives
Basic building blocks for constructing interfaces.

| Component | Description |
|-----------|-------------|
| `IronButton` | Themed button with variants, sizes, and icons |
| `IronText` | Typography component with semantic styles |
| `IronIcon` | SF Symbol wrapper with theming |
| `IronTextField` | Styled text input |
| `IronSecureField` | Password input with visibility toggle |
| `IronCheckbox` | Checkbox with label |
| `IronToggle` | Switch control |
| `IronRadio` | Radio button for single selection |
| `IronProgress` | Linear and circular progress indicators |
| `IronSpinner` | Loading spinner |
| `IronAlert` | Contextual alert messages |
| `IronBadge` | Count and status badges |
| `IronCard` | Container with elevation styles |
| `IronDivider` | Visual separator |

### Components
Composed elements for common UI patterns.

| Component | Description |
|-----------|-------------|
| `IronAvatar` | User profile image with status badges |
| `IronChip` | Tags, filters, and selections |
| `IronSegmentedControl` | Tabbed selection control |
| `IronMenu` | Dropdown menu with sections |
| `IronSkeleton` | Loading placeholders |

### Layouts
Responsive layout components.

| Component | Description |
|-----------|-------------|
| `IronContainer` | Responsive width container |
| `IronFlow` | Flexbox-style wrapping layout |
| `IronResponsiveStack` | Threshold-based H/V stack |
| `IronAdaptiveStack` | Content-aware H/V stack |
| `IronSizeClassStack` | Size class responsive stack |

### Forms
Form building with validation.

| Component | Description |
|-----------|-------------|
| `IronForm` | Scrollable form container |
| `IronFormSection` | Grouped form fields |
| `IronFormField` | Field with label, hint, and error |
| `IronDatePicker` | Themed date selection |
| `IronValidator` | Composable validation rules |

### Data Display
Components for visualizing structured data.

| Component | Description |
|-----------|-------------|
| `IronTimeline` | Vertical event timeline |
| `IronKanban` | Kanban board with drag support |
| `IronDatabase` | Notion-style database tables |

## Theming

IronUI provides a complete theming system with six token categories:

```swift
@Environment(\.ironTheme) private var theme

// Colors
theme.colors.primary
theme.colors.surface
theme.colors.textPrimary

// Typography
theme.typography.headlineLarge
theme.typography.bodyMedium

// Spacing (8pt grid)
theme.spacing.sm   // 8pt
theme.spacing.md   // 12pt
theme.spacing.lg   // 16pt

// Corner radii
theme.radii.md     // 8pt
theme.radii.lg     // 12pt

// Shadows
theme.shadows.md   // Card elevation

// Animations
theme.animation.bouncy
theme.animation.snappy
```

## Documentation

Full documentation is available at [iron-ham.github.io/IronUI](https://iron-ham.github.io/IronUI/documentation/ironui/)

### Module Documentation

| Module | Description |
|--------|-------------|
| [IronUI](https://iron-ham.github.io/IronUI/documentation/ironui/) | Umbrella module (re-exports all) |
| [IronCore](https://iron-ham.github.io/IronUI/documentation/ironcore/) | Theming, tokens, accessibility |
| [IronPrimitives](https://iron-ham.github.io/IronUI/documentation/ironprimitives/) | Basic components |
| [IronComponents](https://iron-ham.github.io/IronUI/documentation/ironcomponents/) | Composed components |
| [IronLayouts](https://iron-ham.github.io/IronUI/documentation/ironlayouts/) | Layout helpers |
| [IronForms](https://iron-ham.github.io/IronUI/documentation/ironforms/) | Form components |
| [IronDataDisplay](https://iron-ham.github.io/IronUI/documentation/irondatadisplay/) | Data visualization |
| [IronNavigation](https://iron-ham.github.io/IronUI/documentation/ironnavigation/) | Navigation & presentation |

## Developer CLI

IronUI includes a developer CLI (`ironui`) for common development tasks. All commands use native Swift—no shell scripts required.

```bash
swift run ironui-cli <command> [options]
```

### Commands

| Command | Description |
|---------|-------------|
| `build` | Build the package (`--config release` for release builds) |
| `clean` | Remove build artifacts (`--all` to include Package.resolved) |
| `docs` | Generate DocC documentation (`--preview` for live preview server) |
| `export-snapshots` | Export snapshots to DocC Resources (`--dry-run` to preview) |
| `format` | Format Swift sources with Airbnb style (`--dry-run` to check only) |
| `snapshots` | Run snapshot tests on macOS + iOS (`--record`, `--platform`, `--simulator`) |
| `test` | Run tests (`--filter`, `--test-target`, `--parallel`, `--verbose`) |

### Examples

```bash
# Build for release
swift run ironui-cli build --config release

# Format and check without modifying
swift run ironui-cli format --dry-run

# Run specific tests in parallel
swift run ironui-cli test --filter Button --parallel

# Record new snapshot baselines (macOS + iOS)
swift run ironui-cli snapshots --record

# Run iOS snapshots only on a specific simulator
swift run ironui-cli snapshots --platform ios --simulator "iPhone 16 Pro Max"

# Preview documentation locally
swift run ironui-cli docs --preview

# Clean everything and rebuild
swift run ironui-cli clean --all && swift run ironui-cli build
```

## Requirements

- iOS 26.0+
- macOS 26.0+
- Swift 6.0+
- Xcode 16.0+

## License

IronUI is available under the MIT license. See the [LICENSE](LICENSE) file for more info.

## Contributing

Contributions are welcome! Please read our [Contributing Guide](CONTRIBUTING.md) before submitting a pull request.
