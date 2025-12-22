import IronCore
import SwiftUI

// MARK: - IronText

/// A themed text component with semantic styling.
///
/// `IronText` provides consistent typography across your app by using
/// the theme's typography tokens. It supports all semantic text styles
/// from display headings to captions.
///
/// ## Basic Usage
///
/// ```swift
/// IronText("Hello, World!")
/// IronText("Welcome", style: .headlineLarge)
/// ```
///
/// ## Text Styles
///
/// ```swift
/// IronText("Display", style: .displayLarge)
/// IronText("Headline", style: .headlineMedium)
/// IronText("Title", style: .titleSmall)
/// IronText("Body", style: .bodyLarge)
/// IronText("Label", style: .labelMedium)
/// IronText("Caption", style: .caption)
/// ```
///
/// ## Custom Colors
///
/// ```swift
/// IronText("Primary", color: .primary)
/// IronText("Secondary", color: .secondary)
/// IronText("Error", color: .error)
/// ```
public struct IronText: View {

  // MARK: Lifecycle

  /// Creates themed text with the specified style.
  ///
  /// - Parameters:
  ///   - content: The text content to display.
  ///   - style: The typography style to apply.
  ///   - color: The semantic color to use.
  public init(
    _ content: LocalizedStringKey,
    style: IronTextStyle = .bodyMedium,
    color: IronTextColor = .primary,
  ) {
    self.content = .localized(content)
    self.style = style
    self.color = color
  }

  /// Creates themed text from a string.
  ///
  /// - Parameters:
  ///   - content: The string content to display.
  ///   - style: The typography style to apply.
  ///   - color: The semantic color to use.
  public init(
    _ content: some StringProtocol,
    style: IronTextStyle = .bodyMedium,
    color: IronTextColor = .primary,
  ) {
    self.content = .string(String(content))
    self.style = style
    self.color = color
  }

  // MARK: Public

  public var body: some View {
    textView
      .font(font)
      .foregroundStyle(foregroundColor)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  private let content: TextContent
  private let style: IronTextStyle
  private let color: IronTextColor

  private var textView: Text {
    switch content {
    case .localized(let key):
      Text(key)
    case .string(let string):
      Text(string)
    }
  }

  private var font: Font {
    switch style {
    case .displayLarge: theme.typography.displayLarge
    case .displayMedium: theme.typography.displayMedium
    case .displaySmall: theme.typography.displaySmall
    case .headlineLarge: theme.typography.headlineLarge
    case .headlineMedium: theme.typography.headlineMedium
    case .headlineSmall: theme.typography.headlineSmall
    case .titleLarge: theme.typography.titleLarge
    case .titleMedium: theme.typography.titleMedium
    case .titleSmall: theme.typography.titleSmall
    case .bodyLarge: theme.typography.bodyLarge
    case .bodyMedium: theme.typography.bodyMedium
    case .bodySmall: theme.typography.bodySmall
    case .labelLarge: theme.typography.labelLarge
    case .labelMedium: theme.typography.labelMedium
    case .labelSmall: theme.typography.labelSmall
    case .caption: theme.typography.caption
    }
  }

  private var foregroundColor: Color {
    switch color {
    case .primary: theme.colors.textPrimary
    case .secondary: theme.colors.textSecondary
    case .disabled: theme.colors.textDisabled
    case .placeholder: theme.colors.textPlaceholder
    case .onPrimary: theme.colors.onPrimary
    case .onSecondary: theme.colors.onSecondary
    case .onSurface: theme.colors.onSurface
    case .success: theme.colors.success
    case .warning: theme.colors.warning
    case .error: theme.colors.error
    case .info: theme.colors.info
    case .custom(let customColor): customColor
    }
  }
}

// MARK: - TextContent

private enum TextContent {
  case localized(LocalizedStringKey)
  case string(String)
}

// MARK: - IronTextStyle

/// Typography styles for `IronText`.
///
/// These styles map directly to the theme's typography tokens,
/// providing consistent sizing across the app.
public enum IronTextStyle: Sendable, CaseIterable {
  /// Extra large display text for hero sections.
  case displayLarge
  /// Large display text.
  case displayMedium
  /// Smaller display text.
  case displaySmall

  /// Large headline for major sections.
  case headlineLarge
  /// Medium headline.
  case headlineMedium
  /// Small headline.
  case headlineSmall

  /// Large title for cards and dialogs.
  case titleLarge
  /// Medium title.
  case titleMedium
  /// Small title.
  case titleSmall

  /// Large body text for primary content.
  case bodyLarge
  /// Default body text.
  case bodyMedium
  /// Small body text.
  case bodySmall

  /// Large label for buttons and form fields.
  case labelLarge
  /// Medium label.
  case labelMedium
  /// Small label.
  case labelSmall

  /// Caption text for metadata and hints.
  case caption
}

// MARK: - IronTextColor

/// Semantic colors for `IronText`.
///
/// Use semantic colors to ensure text remains readable across
/// light and dark modes.
public enum IronTextColor: Sendable {
  /// Primary text color for main content.
  case primary
  /// Secondary text color for supporting content.
  case secondary
  /// Disabled text color.
  case disabled
  /// Placeholder text color.
  case placeholder
  /// Text on primary-colored backgrounds.
  case onPrimary
  /// Text on secondary-colored backgrounds.
  case onSecondary
  /// Text on surface backgrounds.
  case onSurface
  /// Success/positive text.
  case success
  /// Warning text.
  case warning
  /// Error/destructive text.
  case error
  /// Informational text.
  case info
  /// Custom color override.
  case custom(Color)
}

// MARK: - Previews

#Preview("IronText - Styles") {
  ScrollView {
    VStack(alignment: .leading, spacing: 8) {
      Group {
        IronText("Display Large", style: .displayLarge)
        IronText("Display Medium", style: .displayMedium)
        IronText("Display Small", style: .displaySmall)
      }

      Divider()

      Group {
        IronText("Headline Large", style: .headlineLarge)
        IronText("Headline Medium", style: .headlineMedium)
        IronText("Headline Small", style: .headlineSmall)
      }

      Divider()

      Group {
        IronText("Title Large", style: .titleLarge)
        IronText("Title Medium", style: .titleMedium)
        IronText("Title Small", style: .titleSmall)
      }

      Divider()

      Group {
        IronText("Body Large", style: .bodyLarge)
        IronText("Body Medium", style: .bodyMedium)
        IronText("Body Small", style: .bodySmall)
      }

      Divider()

      Group {
        IronText("Label Large", style: .labelLarge)
        IronText("Label Medium", style: .labelMedium)
        IronText("Label Small", style: .labelSmall)
      }

      Divider()

      IronText("Caption", style: .caption)
    }
    .padding()
  }
}

#Preview("IronText - Colors") {
  VStack(alignment: .leading, spacing: 12) {
    IronText("Primary Text", color: .primary)
    IronText("Secondary Text", color: .secondary)
    IronText("Disabled Text", color: .disabled)
    IronText("Success Text", color: .success)
    IronText("Warning Text", color: .warning)
    IronText("Error Text", color: .error)
    IronText("Info Text", color: .info)
    IronText("Custom Color", color: .custom(.purple))
  }
  .padding()
}
