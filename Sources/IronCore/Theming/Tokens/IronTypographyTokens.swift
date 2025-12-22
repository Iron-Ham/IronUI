import SwiftUI

// MARK: - IronTypographyTokens

/// Defines the typography scale for an IronUI theme.
///
/// Typography tokens follow a semantic naming convention based on
/// Material Design's type scale, providing clear hierarchy:
/// - **Display**: Large, expressive headlines
/// - **Headline**: Section headers
/// - **Title**: Card and dialog titles
/// - **Body**: Main content text
/// - **Label**: Buttons, tabs, and small UI elements
/// - **Caption**: Supporting text and metadata
///
/// All fonts support Dynamic Type by default.
///
/// ## Example
///
/// ```swift
/// Text("Welcome")
///   .font(theme.typography.displayLarge)
/// ```
public protocol IronTypographyTokens: Sendable {

  /// Largest display text for hero moments.
  var displayLarge: Font { get }

  /// Medium display text for prominent headlines.
  var displayMedium: Font { get }

  /// Small display text for secondary headlines.
  var displaySmall: Font { get }

  /// Large headline for section titles.
  var headlineLarge: Font { get }

  /// Medium headline for subsections.
  var headlineMedium: Font { get }

  /// Small headline for card headers.
  var headlineSmall: Font { get }

  /// Large title for dialogs and prominent cards.
  var titleLarge: Font { get }

  /// Medium title for list items and cards.
  var titleMedium: Font { get }

  /// Small title for compact UI elements.
  var titleSmall: Font { get }

  /// Large body text for comfortable reading.
  var bodyLarge: Font { get }

  /// Medium body text for standard content.
  var bodyMedium: Font { get }

  /// Small body text for dense content.
  var bodySmall: Font { get }

  /// Large label for prominent buttons and tabs.
  var labelLarge: Font { get }

  /// Medium label for standard buttons.
  var labelMedium: Font { get }

  /// Small label for compact UI.
  var labelSmall: Font { get }

  /// Caption text for metadata and timestamps.
  var caption: Font { get }
}

// MARK: - IronDefaultTypographyTokens

/// Default typography tokens using the system font with Dynamic Type support.
public struct IronDefaultTypographyTokens: IronTypographyTokens {

  // MARK: Lifecycle

  public init() { }

  // MARK: Public

  public var displayLarge: Font {
    .system(size: 57, weight: .regular, design: .default)
  }

  public var displayMedium: Font {
    .system(size: 45, weight: .regular, design: .default)
  }

  public var displaySmall: Font {
    .system(size: 36, weight: .regular, design: .default)
  }

  public var headlineLarge: Font {
    .system(size: 32, weight: .semibold, design: .default)
  }

  public var headlineMedium: Font {
    .system(size: 28, weight: .semibold, design: .default)
  }

  public var headlineSmall: Font {
    .system(size: 24, weight: .semibold, design: .default)
  }

  public var titleLarge: Font {
    .system(size: 22, weight: .medium, design: .default)
  }

  public var titleMedium: Font {
    .system(size: 16, weight: .medium, design: .default)
  }

  public var titleSmall: Font {
    .system(size: 14, weight: .medium, design: .default)
  }

  public var bodyLarge: Font {
    .system(size: 16, weight: .regular, design: .default)
  }

  public var bodyMedium: Font {
    .system(size: 14, weight: .regular, design: .default)
  }

  public var bodySmall: Font {
    .system(size: 12, weight: .regular, design: .default)
  }

  public var labelLarge: Font {
    .system(size: 14, weight: .medium, design: .default)
  }

  public var labelMedium: Font {
    .system(size: 12, weight: .medium, design: .default)
  }

  public var labelSmall: Font {
    .system(size: 11, weight: .medium, design: .default)
  }

  public var caption: Font {
    .system(size: 12, weight: .regular, design: .default)
  }
}
