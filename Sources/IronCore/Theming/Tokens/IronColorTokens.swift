import SwiftUI

// MARK: - IronColorTokens

/// Defines the color palette for an IronUI theme.
///
/// Color tokens are organized into semantic categories:
/// - **Brand colors**: Primary, secondary, and accent colors
/// - **Semantic colors**: Success, warning, error, and info
/// - **Surface colors**: Background and surface variations
/// - **Content colors**: Text and icon colors on various surfaces
/// - **Border colors**: Dividers, borders, and focus indicators
///
/// ## Creating a Custom Color Palette
///
/// ```swift
/// struct MyColorTokens: IronColorTokens {
///   var primary: Color { .blue }
///   var secondary: Color { .purple }
///   // ... implement all required properties
/// }
/// ```
public protocol IronColorTokens: Sendable {

  /// The primary brand color used for key UI elements.
  var primary: Color { get }

  /// A variant of the primary color for hover/pressed states.
  var primaryVariant: Color { get }

  /// The secondary brand color for supporting elements.
  var secondary: Color { get }

  /// A variant of the secondary color for hover/pressed states.
  var secondaryVariant: Color { get }

  /// An accent color for highlights and calls to action.
  var accent: Color { get }

  /// Color indicating success or positive outcomes.
  var success: Color { get }

  /// Color indicating warnings or caution.
  var warning: Color { get }

  /// Color indicating errors or destructive actions.
  var error: Color { get }

  /// Color for informational elements.
  var info: Color { get }

  /// The main background color of the app.
  var background: Color { get }

  /// The color for card and container surfaces.
  var surface: Color { get }

  /// An elevated surface color with more prominence.
  var surfaceElevated: Color { get }

  /// Content color to use on primary-colored backgrounds.
  var onPrimary: Color { get }

  /// Content color to use on secondary-colored backgrounds.
  var onSecondary: Color { get }

  /// Content color to use on the main background.
  var onBackground: Color { get }

  /// Content color to use on surface-colored backgrounds.
  var onSurface: Color { get }

  /// Content color to use on error-colored backgrounds.
  var onError: Color { get }

  /// Primary text color for main content.
  var textPrimary: Color { get }

  /// Secondary text color for supporting content.
  var textSecondary: Color { get }

  /// Text color for disabled elements.
  var textDisabled: Color { get }

  /// Text color for placeholder text in inputs.
  var textPlaceholder: Color { get }

  /// Default border color for containers and inputs.
  var border: Color { get }

  /// Border color for focused elements.
  var borderFocused: Color { get }

  /// Color for dividers and separators.
  var divider: Color { get }
}

// MARK: - IronDefaultColorTokens

/// Default color tokens providing a modern, accessible color palette.
public struct IronDefaultColorTokens: IronColorTokens {

  // MARK: Lifecycle

  public init() { }

  // MARK: Public

  public var primary: Color {
    Color(red: 0.2, green: 0.4, blue: 0.9) // Confident blue
  }

  public var primaryVariant: Color {
    Color(red: 0.15, green: 0.35, blue: 0.8)
  }

  public var secondary: Color {
    Color(red: 0.55, green: 0.35, blue: 0.85) // Rich purple
  }

  public var secondaryVariant: Color {
    Color(red: 0.45, green: 0.25, blue: 0.75)
  }

  public var accent: Color {
    Color(red: 0.95, green: 0.45, blue: 0.25) // Warm orange
  }

  public var success: Color {
    Color(red: 0.2, green: 0.7, blue: 0.4)
  }

  public var warning: Color {
    Color(red: 0.95, green: 0.7, blue: 0.2)
  }

  public var error: Color {
    Color(red: 0.9, green: 0.25, blue: 0.3)
  }

  public var info: Color {
    Color(red: 0.2, green: 0.6, blue: 0.85)
  }

  public var background: Color {
    Color(light: Color(white: 0.98), dark: Color(white: 0.08))
  }

  public var surface: Color {
    Color(light: .white, dark: Color(white: 0.12))
  }

  public var surfaceElevated: Color {
    Color(light: .white, dark: Color(white: 0.16))
  }

  public var onPrimary: Color {
    .white
  }

  public var onSecondary: Color {
    .white
  }

  public var onBackground: Color {
    Color(light: Color(white: 0.1), dark: Color(white: 0.95))
  }

  public var onSurface: Color {
    Color(light: Color(white: 0.1), dark: Color(white: 0.95))
  }

  public var onError: Color {
    .white
  }

  public var textPrimary: Color {
    Color(light: Color(white: 0.1), dark: Color(white: 0.95))
  }

  public var textSecondary: Color {
    Color(light: Color(white: 0.4), dark: Color(white: 0.6))
  }

  public var textDisabled: Color {
    Color(light: Color(white: 0.6), dark: Color(white: 0.4))
  }

  public var textPlaceholder: Color {
    Color(light: Color(white: 0.5), dark: Color(white: 0.5))
  }

  public var border: Color {
    Color(light: Color(white: 0.85), dark: Color(white: 0.25))
  }

  public var borderFocused: Color {
    primary
  }

  public var divider: Color {
    Color(light: Color(white: 0.9), dark: Color(white: 0.2))
  }
}

// MARK: - Color Extension for Light/Dark Mode

extension Color {
  /// Creates a color that automatically adapts to light and dark mode.
  init(light: Color, dark: Color) {
    #if canImport(UIKit)
    self.init(uiColor: UIColor { traits in
      traits.userInterfaceStyle == .dark
        ? UIColor(dark)
        : UIColor(light)
    })
    #elseif canImport(AppKit)
    /// Use the adaptive NSColor approach
    let nsColor = NSColor(name: nil) { appearance in
      appearance.bestMatch(from: [.darkAqua, .aqua]) == .darkAqua
        ? NSColor(dark)
        : NSColor(light)
    }
    if #available(macOS 12.0, *) {
      self.init(nsColor: nsColor)
    } else {
      // Fallback for macOS 11: use cgColor
      self.init(nsColor.cgColor)
    }
    #else
    self = light
    #endif
  }
}
