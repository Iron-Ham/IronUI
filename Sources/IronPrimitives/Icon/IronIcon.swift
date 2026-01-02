import IronCore
import SwiftUI

// MARK: - IronIcon

/// A themed icon component with semantic sizing and coloring.
///
/// `IronIcon` provides consistent iconography across your app by using
/// SF Symbols with theme-aware sizing and colors. Icons automatically
/// scale with Dynamic Type to remain proportional to text.
///
/// ## Basic Usage
///
/// ```swift
/// IronIcon(systemName: "star.fill")
/// IronIcon(systemName: "heart", size: .large)
/// ```
///
/// ## Sizes
///
/// ```swift
/// IronIcon(systemName: "star", size: .xSmall)
/// IronIcon(systemName: "star", size: .small)
/// IronIcon(systemName: "star", size: .medium)
/// IronIcon(systemName: "star", size: .large)
/// IronIcon(systemName: "star", size: .xLarge)
/// ```
///
/// ## Colors
///
/// ```swift
/// IronIcon(systemName: "checkmark.circle", color: .success)
/// IronIcon(systemName: "exclamationmark.triangle", color: .warning)
/// IronIcon(systemName: "xmark.circle", color: .error)
/// ```
public struct IronIcon: View {

  // MARK: Lifecycle

  /// Creates a themed icon from an SF Symbol name.
  ///
  /// - Parameters:
  ///   - systemName: The name of the SF Symbol.
  ///   - size: The semantic size of the icon.
  ///   - color: The semantic color of the icon.
  public init(
    systemName: String,
    size: IronIconSize = .medium,
    color: IronIconColor = .primary,
  ) {
    source = .system(systemName)
    self.size = size
    self.color = color
  }

  /// Creates a themed icon from a custom image name.
  ///
  /// Custom images are rendered as templates (single-color) and will
  /// scale with Dynamic Type. For best results, provide vector-based
  /// (PDF) or high-resolution images.
  ///
  /// - Parameters:
  ///   - name: The name of the image asset.
  ///   - bundle: The bundle containing the image asset.
  ///   - size: The semantic size of the icon.
  ///   - color: The semantic color of the icon.
  public init(
    _ name: String,
    bundle: Bundle? = nil,
    size: IronIconSize = .medium,
    color: IronIconColor = .primary,
  ) {
    source = .asset(name, bundle: bundle)
    self.size = size
    self.color = color
  }

  // MARK: Public

  public var body: some View {
    if color == .inherit {
      iconView
        .accessibilityHidden(true)
    } else {
      iconView
        .foregroundStyle(foregroundColor)
        .accessibilityHidden(true)
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  /// Scaled metrics for custom images, each tied to a specific text style.
  /// This ensures custom images scale identically to SF Symbols at each size.
  @ScaledMetric(relativeTo: .caption2)
  private var xSmallSize: CGFloat = 12
  @ScaledMetric(relativeTo: .footnote)
  private var smallSize: CGFloat = 16
  @ScaledMetric(relativeTo: .callout)
  private var mediumSize: CGFloat = 20
  @ScaledMetric(relativeTo: .body)
  private var largeSize: CGFloat = 24
  @ScaledMetric(relativeTo: .headline)
  private var xLargeSize: CGFloat = 32

  private let source: IconSource
  private let size: IronIconSize
  private let color: IronIconColor

  @ViewBuilder
  private var iconView: some View {
    switch source {
    case .system(let name):
      // SF Symbols scale naturally with font/imageScale
      Image(systemName: name)
        .font(iconFont)
        .imageScale(imageScale)

    case .asset(let name, let bundle):
      // Custom images use @ScaledMetric tied to matching text styles
      Image(name, bundle: bundle)
        .renderingMode(.template)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(width: customImageSize, height: customImageSize)
    }
  }

  /// Uses text styles for Dynamic Type scaling (SF Symbols).
  private var iconFont: Font {
    switch size {
    case .xSmall: theme.typography.caption
    case .small: theme.typography.bodySmall
    case .medium: theme.typography.bodyMedium
    case .large: theme.typography.bodyLarge
    case .xLarge: theme.typography.titleLarge
    }
  }

  private var imageScale: Image.Scale {
    switch size {
    case .xSmall: .small
    case .small: .small
    case .medium: .medium
    case .large: .large
    case .xLarge: .large
    }
  }

  /// Size for custom images, scales with Dynamic Type via text-style-relative @ScaledMetric.
  private var customImageSize: CGFloat {
    switch size {
    case .xSmall: xSmallSize
    case .small: smallSize
    case .medium: mediumSize
    case .large: largeSize
    case .xLarge: xLargeSize
    }
  }

  private var foregroundColor: Color {
    switch color {
    case .inherit: .clear // Never reached - handled separately in body
    case .primary: theme.colors.textPrimary
    case .secondary: theme.colors.textSecondary
    case .disabled: theme.colors.textDisabled
    case .onPrimary: theme.colors.onPrimary
    case .onSecondary: theme.colors.onSecondary
    case .onSurface: theme.colors.onSurface
    case .success: theme.colors.success
    case .warning: theme.colors.warning
    case .error: theme.colors.error
    case .info: theme.colors.info
    case .accent: theme.colors.accent
    case .custom(let customColor): customColor
    }
  }
}

// MARK: - IconSource

private enum IconSource {
  case system(String)
  case asset(String, bundle: Bundle?)
}

// MARK: - IronIconSize

/// Size options for `IronIcon`.
///
/// Sizes follow a consistent scale that works well with text and
/// other UI elements. All sizes support Dynamic Type and will scale
/// based on the user's accessibility preferences.
public enum IronIconSize: Sendable, CaseIterable {
  /// Extra small icon, scales with caption text.
  case xSmall
  /// Small icon, scales with body small text.
  case small
  /// Medium icon, scales with body medium text. Default size.
  case medium
  /// Large icon, scales with body large text.
  case large
  /// Extra large icon, scales with title large text.
  case xLarge
}

// MARK: - IronIconColor

/// Semantic colors for `IronIcon`.
///
/// Use semantic colors to ensure icons remain visible and
/// meaningful across light and dark modes.
public enum IronIconColor: Sendable, Equatable {
  /// Inherit color from parent view's foreground style.
  case inherit
  /// Primary icon color for main content.
  case primary
  /// Secondary icon color for supporting content.
  case secondary
  /// Disabled icon color.
  case disabled
  /// Icon on primary-colored backgrounds.
  case onPrimary
  /// Icon on secondary-colored backgrounds.
  case onSecondary
  /// Icon on surface backgrounds.
  case onSurface
  /// Success/positive icon.
  case success
  /// Warning icon.
  case warning
  /// Error/destructive icon.
  case error
  /// Informational icon.
  case info
  /// Accent color icon.
  case accent
  /// Custom color override.
  case custom(Color)
}

// MARK: - Previews

#Preview("IronIcon - Sizes") {
  HStack(spacing: 16) {
    ForEach(IronIconSize.allCases, id: \.self) { size in
      IronIcon(systemName: "star.fill", size: size)
    }
  }
  .padding()
}

#Preview("IronIcon - Colors") {
  VStack(alignment: .leading, spacing: 12) {
    HStack(spacing: 12) {
      IronIcon(systemName: "circle.fill", color: .primary)
      Text("Primary")
    }
    HStack(spacing: 12) {
      IronIcon(systemName: "circle.fill", color: .secondary)
      Text("Secondary")
    }
    HStack(spacing: 12) {
      IronIcon(systemName: "checkmark.circle.fill", color: .success)
      Text("Success")
    }
    HStack(spacing: 12) {
      IronIcon(systemName: "exclamationmark.triangle.fill", color: .warning)
      Text("Warning")
    }
    HStack(spacing: 12) {
      IronIcon(systemName: "xmark.circle.fill", color: .error)
      Text("Error")
    }
    HStack(spacing: 12) {
      IronIcon(systemName: "info.circle.fill", color: .info)
      Text("Info")
    }
    HStack(spacing: 12) {
      IronIcon(systemName: "star.fill", color: .accent)
      Text("Accent")
    }
  }
  .padding()
}

#Preview("IronIcon - Common Icons") {
  LazyVGrid(columns: [GridItem(.adaptive(minimum: 60))], spacing: 16) {
    ForEach(
      [
        "house.fill",
        "gear",
        "person.fill",
        "magnifyingglass",
        "bell.fill",
        "envelope.fill",
        "heart.fill",
        "star.fill",
        "trash.fill",
        "pencil",
        "plus",
        "xmark",
        "checkmark",
        "chevron.right",
        "arrow.left",
        "arrow.right",
      ],
      id: \.self,
    ) { name in
      VStack(spacing: 4) {
        IronIcon(systemName: name, size: .large)
        Text(name)
          .font(.caption2)
          .lineLimit(1)
      }
    }
  }
  .padding()
}
