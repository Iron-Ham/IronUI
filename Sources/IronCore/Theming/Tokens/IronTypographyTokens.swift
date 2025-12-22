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

/// Default typography tokens using system text styles with full Dynamic Type support.
///
/// These tokens map to SwiftUI's built-in text styles, ensuring proper scaling
/// when users adjust their Dynamic Type settings in Accessibility preferences.
///
/// ## Dynamic Type Behavior
///
/// All fonts automatically scale based on the user's preferred content size.
/// This ensures your app remains accessible to users with vision impairments.
///
/// ## Text Style Mapping
///
/// | Token | Base Style | Typical Use |
/// |-------|------------|-------------|
/// | displayLarge | largeTitle | Hero headlines |
/// | displayMedium | largeTitle (lighter) | Secondary heroes |
/// | displaySmall | title | Prominent headings |
/// | headlineLarge | title | Section headers |
/// | headlineMedium | title2 | Subsections |
/// | headlineSmall | title3 | Card headers |
/// | titleLarge | headline | Dialog titles |
/// | titleMedium | subheadline | List item titles |
/// | titleSmall | footnote (medium) | Compact titles |
/// | bodyLarge | body | Primary content |
/// | bodyMedium | callout | Standard content |
/// | bodySmall | footnote | Dense content |
/// | labelLarge | subheadline | Prominent buttons |
/// | labelMedium | footnote (medium) | Standard buttons |
/// | labelSmall | caption | Compact labels |
/// | caption | caption2 | Metadata |
public struct IronDefaultTypographyTokens: IronTypographyTokens {

  // MARK: Lifecycle

  public init() { }

  // MARK: Public

  public var displayLarge: Font {
    .largeTitle.weight(.bold)
  }

  public var displayMedium: Font {
    .largeTitle.weight(.semibold)
  }

  public var displaySmall: Font {
    .title.weight(.semibold)
  }

  public var headlineLarge: Font {
    .title.weight(.bold)
  }

  public var headlineMedium: Font {
    .title2.weight(.semibold)
  }

  public var headlineSmall: Font {
    .title3.weight(.semibold)
  }

  public var titleLarge: Font {
    .headline
  }

  public var titleMedium: Font {
    .subheadline.weight(.medium)
  }

  public var titleSmall: Font {
    .footnote.weight(.medium)
  }

  public var bodyLarge: Font {
    .body
  }

  public var bodyMedium: Font {
    .callout
  }

  public var bodySmall: Font {
    .footnote
  }

  public var labelLarge: Font {
    .subheadline.weight(.medium)
  }

  public var labelMedium: Font {
    .footnote.weight(.medium)
  }

  public var labelSmall: Font {
    .caption.weight(.medium)
  }

  public var caption: Font {
    .caption2
  }
}
