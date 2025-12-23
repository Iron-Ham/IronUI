# Getting Started

Add IronUI to your project and build your first interface.

## Overview

IronUI is a SwiftUI component library designed for iOS 26+ and macOS 26+. It provides a complete design system with themed components, accessibility support, and the Liquid Glass aesthetic.

## Installation

Add IronUI to your project using Swift Package Manager.

### Xcode

1. Open your project in Xcode
2. Go to **File > Add Package Dependencies...**
3. Enter the repository URL:
   ```
   https://github.com/Iron-Ham/IronUI
   ```
4. Select the version and click **Add Package**

### Package.swift

Add IronUI as a dependency in your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/Iron-Ham/IronUI", from: "1.0.0")
]
```

Then add it to your target:

```swift
.target(
    name: "YourApp",
    dependencies: ["IronUI"]
)
```

## Platform Requirements

IronUI requires:
- **iOS 26.0+**
- **macOS 26.0+**
- **Swift 6.0+**

These requirements enable the Liquid Glass aesthetic and latest SwiftUI features.

## Your First View

Import IronUI and start building:

```swift
import IronUI
import SwiftUI

struct ContentView: View {
    @State private var name = ""
    @State private var isEnabled = true

    var body: some View {
        IronContainer {
            VStack(spacing: 24) {
                IronText("Welcome to IronUI", style: .headlineLarge, color: .primary)

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

## Module Structure

IronUI is organized into focused modules:

| Module | Description |
|--------|-------------|
| `IronCore` | Theming, tokens, and platform abstractions |
| `IronPrimitives` | Basic components (Button, Text, TextField) |
| `IronComponents` | Composed components (Avatar, Chip, Menu) |
| `IronLayouts` | Layout helpers (Container, Flow, Stack) |
| `IronForms` | Form components with validation |
| `IronDataDisplay` | Data visualization (Timeline, Kanban, Database) |
| `IronUI` | Umbrella module (imports all above) |

For most projects, simply import `IronUI` to access everything.

## Next Steps

- <doc:Theming> - Customize colors, typography, and spacing
- <doc:Accessibility> - Build inclusive interfaces
- Explore individual components in the API reference
