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
///
/// This palette automatically adapts to high contrast mode when the user enables
/// "Increase Contrast" in system accessibility settings. In high contrast mode:
/// - Borders become more prominent
/// - Text colors have increased contrast
/// - Dividers are more visible
/// - Semantic colors are more saturated
public struct IronDefaultColorTokens: IronColorTokens {

  // MARK: Lifecycle

  public init() { }

  // MARK: Public

  public var primary: Color {
    // High contrast: deeper blue for better visibility
    Color(
      light: Color(red: 0.2, green: 0.4, blue: 0.9),
      dark: Color(red: 0.2, green: 0.4, blue: 0.9),
      highContrastLight: Color(red: 0.1, green: 0.3, blue: 0.8),
      highContrastDark: Color(red: 0.3, green: 0.5, blue: 1.0)
    )
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
    // High contrast: more saturated green
    Color(
      light: Color(red: 0.2, green: 0.7, blue: 0.4),
      dark: Color(red: 0.2, green: 0.7, blue: 0.4),
      highContrastLight: Color(red: 0.1, green: 0.6, blue: 0.3),
      highContrastDark: Color(red: 0.3, green: 0.8, blue: 0.5)
    )
  }

  public var warning: Color {
    // High contrast: deeper orange-yellow
    Color(
      light: Color(red: 0.95, green: 0.7, blue: 0.2),
      dark: Color(red: 0.95, green: 0.7, blue: 0.2),
      highContrastLight: Color(red: 0.85, green: 0.55, blue: 0.0),
      highContrastDark: Color(red: 1.0, green: 0.75, blue: 0.3)
    )
  }

  public var error: Color {
    // High contrast: more saturated red
    Color(
      light: Color(red: 0.9, green: 0.25, blue: 0.3),
      dark: Color(red: 0.9, green: 0.25, blue: 0.3),
      highContrastLight: Color(red: 0.8, green: 0.1, blue: 0.15),
      highContrastDark: Color(red: 1.0, green: 0.35, blue: 0.4)
    )
  }

  public var info: Color {
    Color(red: 0.2, green: 0.6, blue: 0.85)
  }

  public var background: Color {
    // High contrast: pure white/black for maximum contrast
    Color(
      light: Color(white: 0.98),
      dark: Color(white: 0.08),
      highContrastLight: .white,
      highContrastDark: .black
    )
  }

  public var surface: Color {
    // High contrast: pure white/near-black
    Color(
      light: .white,
      dark: Color(white: 0.12),
      highContrastLight: .white,
      highContrastDark: Color(white: 0.05)
    )
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
    // High contrast: pure black/white
    Color(
      light: Color(white: 0.1),
      dark: Color(white: 0.95),
      highContrastLight: .black,
      highContrastDark: .white
    )
  }

  public var onSurface: Color {
    // High contrast: pure black/white
    Color(
      light: Color(white: 0.1),
      dark: Color(white: 0.95),
      highContrastLight: .black,
      highContrastDark: .white
    )
  }

  public var onError: Color {
    .white
  }

  public var textPrimary: Color {
    // High contrast: pure black/white for maximum readability
    Color(
      light: Color(white: 0.1),
      dark: Color(white: 0.95),
      highContrastLight: .black,
      highContrastDark: .white
    )
  }

  public var textSecondary: Color {
    // High contrast: darker/lighter for better readability
    Color(
      light: Color(white: 0.4),
      dark: Color(white: 0.6),
      highContrastLight: Color(white: 0.25),
      highContrastDark: Color(white: 0.8)
    )
  }

  public var textDisabled: Color {
    // High contrast: more visible disabled text
    Color(
      light: Color(white: 0.6),
      dark: Color(white: 0.4),
      highContrastLight: Color(white: 0.45),
      highContrastDark: Color(white: 0.55)
    )
  }

  public var textPlaceholder: Color {
    // High contrast: more visible placeholder text
    Color(
      light: Color(white: 0.5),
      dark: Color(white: 0.5),
      highContrastLight: Color(white: 0.35),
      highContrastDark: Color(white: 0.65)
    )
  }

  public var border: Color {
    // High contrast: much more prominent borders
    Color(
      light: Color(white: 0.85),
      dark: Color(white: 0.25),
      highContrastLight: Color(white: 0.5),
      highContrastDark: Color(white: 0.6)
    )
  }

  public var borderFocused: Color {
    primary
  }

  public var divider: Color {
    // High contrast: more visible dividers
    Color(
      light: Color(white: 0.9),
      dark: Color(white: 0.2),
      highContrastLight: Color(white: 0.6),
      highContrastDark: Color(white: 0.5)
    )
  }
}

// MARK: - Color Extension for Light/Dark Mode and High Contrast

extension Color {
  /// Creates a color that automatically adapts to light and dark mode.
  init(light: Color, dark: Color) {
    self.init(
      light: light,
      dark: dark,
      highContrastLight: nil,
      highContrastDark: nil
    )
  }

  /// Creates a color that automatically adapts to light/dark mode and high contrast settings.
  ///
  /// When the user enables "Increase Contrast" in system accessibility settings,
  /// the high contrast variants will be used instead of the standard colors.
  ///
  /// - Parameters:
  ///   - light: The color to use in light mode with standard contrast.
  ///   - dark: The color to use in dark mode with standard contrast.
  ///   - highContrastLight: The color to use in light mode with increased contrast.
  ///     If `nil`, the standard light color is used.
  ///   - highContrastDark: The color to use in dark mode with increased contrast.
  ///     If `nil`, the standard dark color is used.
  init(light: Color, dark: Color, highContrastLight: Color?, highContrastDark: Color?) {
    #if canImport(UIKit)
    self.init(uiColor: UIColor { traits in
      let isDark = traits.userInterfaceStyle == .dark
      let isHighContrast = traits.accessibilityContrast == .high

      if isDark {
        return isHighContrast && highContrastDark != nil
          ? UIColor(highContrastDark!)
          : UIColor(dark)
      } else {
        return isHighContrast && highContrastLight != nil
          ? UIColor(highContrastLight!)
          : UIColor(light)
      }
    })
    #elseif canImport(AppKit)
    let nsColor = NSColor(name: nil) { appearance in
      // Check all four appearance variants for proper automatic updates
      let allAppearances: [NSAppearance.Name] = [
        .aqua,
        .darkAqua,
        .accessibilityHighContrastAqua,
        .accessibilityHighContrastDarkAqua,
      ]

      let match = appearance.bestMatch(from: allAppearances)
      let isDark = match == .darkAqua || match == .accessibilityHighContrastDarkAqua
      let isHighContrast = match == .accessibilityHighContrastAqua
        || match == .accessibilityHighContrastDarkAqua

      if isDark {
        return isHighContrast && highContrastDark != nil
          ? NSColor(highContrastDark!)
          : NSColor(dark)
      } else {
        return isHighContrast && highContrastLight != nil
          ? NSColor(highContrastLight!)
          : NSColor(light)
      }
    }
    self.init(nsColor: nsColor)
    #else
    self = light
    #endif
  }
}
