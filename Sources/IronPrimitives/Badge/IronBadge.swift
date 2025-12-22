import IronCore
import SwiftUI

// MARK: - IronBadge

/// A small status indicator or count display.
///
/// `IronBadge` provides consistent badge styling for notifications, status
/// indicators, and count displays. Badges can display text, numbers, or
/// appear as simple dots.
///
/// ## Basic Usage
///
/// ```swift
/// // Count badge
/// IronBadge(count: 5)
///
/// // Text badge
/// IronBadge("New")
///
/// // Dot indicator
/// IronBadge()
/// ```
///
/// ## Styles
///
/// ```swift
/// IronBadge(count: 3, style: .filled)    // Solid background
/// IronBadge(count: 3, style: .soft)      // Tinted background
/// IronBadge(count: 3, style: .outlined)  // Border only
/// ```
///
/// ## Colors
///
/// ```swift
/// IronBadge(count: 5, color: .primary)
/// IronBadge("Error", color: .error)
/// IronBadge(color: .success)  // Green dot
/// ```
///
/// ## As Overlay
///
/// ```swift
/// Image(systemName: "bell")
///   .overlay(alignment: .topTrailing) {
///     IronBadge(count: 3)
///       .offset(x: 6, y: -6)
///   }
/// ```
public struct IronBadge: View {

  // MARK: Lifecycle

  /// Creates a dot badge (no content).
  ///
  /// - Parameters:
  ///   - style: The visual style of the badge.
  ///   - color: The semantic color of the badge.
  ///   - size: The size of the badge.
  public init(
    style: IronBadgeStyle = .filled,
    color: IronBadgeColor = .primary,
    size: IronBadgeSize = .medium,
  ) {
    content = .dot
    self.style = style
    self.color = color
    self.size = size
    maxCount = nil
  }

  /// Creates a badge with a text label.
  ///
  /// - Parameters:
  ///   - label: The text to display.
  ///   - style: The visual style of the badge.
  ///   - color: The semantic color of the badge.
  ///   - size: The size of the badge.
  public init(
    _ label: LocalizedStringKey,
    style: IronBadgeStyle = .filled,
    color: IronBadgeColor = .primary,
    size: IronBadgeSize = .medium,
  ) {
    content = .text(label)
    self.style = style
    self.color = color
    self.size = size
    maxCount = nil
  }

  /// Creates a badge with a text label from a string.
  ///
  /// - Parameters:
  ///   - label: The string to display.
  ///   - style: The visual style of the badge.
  ///   - color: The semantic color of the badge.
  ///   - size: The size of the badge.
  public init(
    _ label: some StringProtocol,
    style: IronBadgeStyle = .filled,
    color: IronBadgeColor = .primary,
    size: IronBadgeSize = .medium,
  ) {
    content = .string(String(label))
    self.style = style
    self.color = color
    self.size = size
    maxCount = nil
  }

  /// Creates a badge displaying a count.
  ///
  /// - Parameters:
  ///   - count: The number to display.
  ///   - maxCount: Maximum count before showing "+". Defaults to 99.
  ///   - style: The visual style of the badge.
  ///   - color: The semantic color of the badge.
  ///   - size: The size of the badge.
  public init(
    count: Int,
    maxCount: Int = 99,
    style: IronBadgeStyle = .filled,
    color: IronBadgeColor = .primary,
    size: IronBadgeSize = .medium,
  ) {
    content = .count(count)
    self.style = style
    self.color = color
    self.size = size
    self.maxCount = maxCount
  }

  // MARK: Public

  public var body: some View {
    contentView
      .font(font)
      .foregroundStyle(foregroundColor)
      .padding(.horizontal, horizontalPadding)
      .padding(.vertical, verticalPadding)
      .frame(minWidth: minSize, minHeight: minSize)
      .background {
        Capsule()
          .fill(backgroundColor)
      }
      .overlay {
        if style == .outlined {
          Capsule()
            .strokeBorder(badgeColor, lineWidth: borderWidth)
        }
      }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  /// Scaled metrics for Dynamic Type support.
  @ScaledMetric(relativeTo: .caption2)
  private var smallMinSize: CGFloat = 16
  @ScaledMetric(relativeTo: .caption)
  private var mediumMinSize: CGFloat = 20
  @ScaledMetric(relativeTo: .footnote)
  private var largeMinSize: CGFloat = 24

  @ScaledMetric(relativeTo: .caption2)
  private var smallDotSize: CGFloat = 6
  @ScaledMetric(relativeTo: .caption)
  private var mediumDotSize: CGFloat = 8
  @ScaledMetric(relativeTo: .footnote)
  private var largeDotSize: CGFloat = 10

  private let content: BadgeContent
  private let style: IronBadgeStyle
  private let color: IronBadgeColor
  private let size: IronBadgeSize
  private let maxCount: Int?

  @ViewBuilder
  private var contentView: some View {
    switch content {
    case .dot:
      // Empty view - the background circle is the badge
      Color.clear
        .frame(width: dotSize, height: dotSize)

    case .text(let key):
      Text(key)

    case .string(let string):
      Text(string)

    case .count(let count):
      if let maxCount, count > maxCount {
        Text("\(maxCount)+")
      } else {
        Text("\(count)")
      }
    }
  }

  private var font: Font {
    switch size {
    case .small: theme.typography.labelSmall
    case .medium: theme.typography.labelSmall
    case .large: theme.typography.labelMedium
    }
  }

  private var horizontalPadding: CGFloat {
    switch content {
    case .dot:
      0
    case .text, .string, .count:
      switch size {
      case .small: theme.spacing.xs
      case .medium: theme.spacing.sm
      case .large: theme.spacing.md
      }
    }
  }

  private var verticalPadding: CGFloat {
    switch content {
    case .dot:
      0
    case .text, .string, .count:
      switch size {
      case .small: 2
      case .medium: theme.spacing.xs
      case .large: theme.spacing.sm
      }
    }
  }

  private var minSize: CGFloat {
    switch size {
    case .small: smallMinSize
    case .medium: mediumMinSize
    case .large: largeMinSize
    }
  }

  private var dotSize: CGFloat {
    switch size {
    case .small: smallDotSize
    case .medium: mediumDotSize
    case .large: largeDotSize
    }
  }

  private var borderWidth: CGFloat {
    switch size {
    case .small: 1
    case .medium: 1.5
    case .large: 2
    }
  }

  private var badgeColor: Color {
    switch color {
    case .primary: theme.colors.primary
    case .secondary: theme.colors.secondary
    case .success: theme.colors.success
    case .warning: theme.colors.warning
    case .error: theme.colors.error
    case .info: theme.colors.info
    case .custom(let customColor): customColor
    }
  }

  private var foregroundColor: Color {
    switch style {
    case .filled:
      switch color {
      case .primary: theme.colors.onPrimary
      case .secondary: theme.colors.onSecondary
      default: .white
      }

    case .soft, .outlined:
      badgeColor
    }
  }

  private var backgroundColor: Color {
    switch style {
    case .filled:
      badgeColor
    case .soft:
      badgeColor.opacity(0.15)
    case .outlined:
      Color.clear
    }
  }
}

// MARK: - BadgeContent

private enum BadgeContent {
  case dot
  case text(LocalizedStringKey)
  case string(String)
  case count(Int)
}

// MARK: - IronBadgeStyle

/// Visual styles for `IronBadge`.
public enum IronBadgeStyle: Sendable, CaseIterable {
  /// Solid background with contrasting text.
  case filled
  /// Tinted/soft background with matching text.
  case soft
  /// Border only with no background fill.
  case outlined
}

// MARK: - IronBadgeColor

/// Semantic colors for `IronBadge`.
public enum IronBadgeColor: Sendable {
  /// Primary brand color.
  case primary
  /// Secondary brand color.
  case secondary
  /// Success/positive indicator.
  case success
  /// Warning indicator.
  case warning
  /// Error/destructive indicator.
  case error
  /// Informational indicator.
  case info
  /// Custom color.
  case custom(Color)
}

// MARK: - IronBadgeSize

/// Size options for `IronBadge`.
public enum IronBadgeSize: Sendable, CaseIterable {
  /// Small badge for compact layouts.
  case small
  /// Medium badge, the default size.
  case medium
  /// Large badge for prominent displays.
  case large
}

// MARK: - Convenience Extensions

extension IronBadge {
  /// Creates a badge that hides when count is zero.
  ///
  /// - Parameters:
  ///   - count: The number to display.
  ///   - hidesWhenZero: Whether to hide when count is zero.
  ///   - maxCount: Maximum count before showing "+".
  ///   - style: The visual style of the badge.
  ///   - color: The semantic color of the badge.
  ///   - size: The size of the badge.
  /// - Returns: An optional badge view.
  @ViewBuilder
  public static func count(
    _ count: Int,
    hidesWhenZero: Bool = true,
    maxCount: Int = 99,
    style: IronBadgeStyle = .filled,
    color: IronBadgeColor = .primary,
    size: IronBadgeSize = .medium,
  ) -> some View {
    if hidesWhenZero, count == 0 {
      EmptyView()
    } else {
      IronBadge(count: count, maxCount: maxCount, style: style, color: color, size: size)
    }
  }
}

// MARK: - CountBadgeOverlay

/// Internal wrapper for count badge overlay with scaled offsets.
private struct CountBadgeOverlay: View {

  // MARK: Internal

  let count: Int
  let maxCount: Int
  let hidesWhenZero: Bool
  let style: IronBadgeStyle
  let color: IronBadgeColor

  var body: some View {
    IronBadge.count(
      count,
      hidesWhenZero: hidesWhenZero,
      maxCount: maxCount,
      style: style,
      color: color,
      size: .small,
    )
    .fixedSize()
    .offset(x: horizontalOffset, y: -baseOffset)
  }

  // MARK: Private

  /// Base offset for single-digit badges, scales with Dynamic Type.
  @ScaledMetric(relativeTo: .caption2)
  private var baseOffset: CGFloat = 6

  /// Extra offset per additional digit character.
  @ScaledMetric(relativeTo: .caption2)
  private var digitOffset: CGFloat = 4

  /// Calculates horizontal offset based on digit count.
  private var horizontalOffset: CGFloat {
    let displayCount = min(count, maxCount)
    let digitCount = displayCount == 0 ? 1 : String(displayCount).count
    let hasPlus = count > maxCount

    // Base offset + additional offset for each extra digit beyond the first
    let extraDigits = max(0, digitCount - 1) + (hasPlus ? 1 : 0)
    return baseOffset + (CGFloat(extraDigits) * digitOffset)
  }
}

// MARK: - DotBadgeOverlay

/// Internal wrapper for dot badge overlay with scaled offsets.
private struct DotBadgeOverlay: View {
  let color: IronBadgeColor

  var body: some View {
    IronBadge(color: color, size: .small)
      .fixedSize()
      .offset(x: offset, y: -offset)
  }

  /// Offset for dot badges, scales with Dynamic Type.
  @ScaledMetric(relativeTo: .caption2)
  private var offset: CGFloat = 3

}

// MARK: - View Extension for Badge Overlay

extension View {
  /// Adds a badge overlay to the view.
  ///
  /// The badge is positioned at the top-trailing corner, offset outside
  /// the view bounds so it doesn't obscure the content. The offset scales
  /// automatically based on the badge content size and Dynamic Type settings.
  ///
  /// ```swift
  /// Image(systemName: "bell")
  ///   .ironBadge(count: 5)
  /// ```
  ///
  /// - Parameters:
  ///   - count: The count to display.
  ///   - hidesWhenZero: Whether to hide when count is zero.
  ///   - maxCount: Maximum count before showing "+". Defaults to 99.
  ///   - style: The visual style of the badge.
  ///   - color: The semantic color of the badge.
  /// - Returns: The view with a badge overlay.
  public func ironBadge(
    count: Int,
    hidesWhenZero: Bool = true,
    maxCount: Int = 99,
    style: IronBadgeStyle = .filled,
    color: IronBadgeColor = .error,
  ) -> some View {
    overlay(alignment: .topTrailing) {
      CountBadgeOverlay(
        count: count,
        maxCount: maxCount,
        hidesWhenZero: hidesWhenZero,
        style: style,
        color: color,
      )
    }
  }

  /// Adds a dot badge overlay to the view.
  ///
  /// The badge is positioned at the top-trailing corner, offset outside
  /// the view bounds so it doesn't obscure the content. The offset scales
  /// automatically with Dynamic Type settings.
  ///
  /// ```swift
  /// Image(systemName: "bell")
  ///   .ironBadge(isVisible: hasNotifications)
  /// ```
  ///
  /// - Parameters:
  ///   - isVisible: Whether the badge is visible.
  ///   - color: The semantic color of the badge.
  /// - Returns: The view with a dot badge overlay.
  public func ironBadge(
    isVisible: Bool,
    color: IronBadgeColor = .error,
  ) -> some View {
    overlay(alignment: .topTrailing) {
      if isVisible {
        DotBadgeOverlay(color: color)
      }
    }
  }
}

// MARK: - Previews

#Preview("IronBadge - Counts") {
  HStack(spacing: 24) {
    IronBadge(count: 1)
    IronBadge(count: 9)
    IronBadge(count: 42)
    IronBadge(count: 100)
    IronBadge(count: 999, maxCount: 99)
  }
  .padding()
}

#Preview("IronBadge - Text") {
  HStack(spacing: 16) {
    IronBadge("New")
    IronBadge("Beta", color: .info)
    IronBadge("Pro", color: .warning)
    IronBadge("Sale", color: .error)
  }
  .padding()
}

#Preview("IronBadge - Dots") {
  HStack(spacing: 24) {
    IronBadge(size: .small)
    IronBadge(size: .medium)
    IronBadge(size: .large)
  }
  .padding()
}

#Preview("IronBadge - Styles") {
  VStack(spacing: 16) {
    HStack(spacing: 16) {
      IronBadge(count: 5, style: .filled)
      IronBadge(count: 5, style: .soft)
      IronBadge(count: 5, style: .outlined)
    }
    HStack(spacing: 16) {
      IronBadge("New", style: .filled)
      IronBadge("New", style: .soft)
      IronBadge("New", style: .outlined)
    }
  }
  .padding()
}

#Preview("IronBadge - Colors") {
  VStack(spacing: 12) {
    HStack(spacing: 12) {
      IronBadge(count: 3, color: .primary)
      IronBadge(count: 3, color: .secondary)
      IronBadge(count: 3, color: .success)
      IronBadge(count: 3, color: .warning)
      IronBadge(count: 3, color: .error)
      IronBadge(count: 3, color: .info)
    }
    HStack(spacing: 12) {
      IronBadge(count: 3, style: .soft, color: .primary)
      IronBadge(count: 3, style: .soft, color: .secondary)
      IronBadge(count: 3, style: .soft, color: .success)
      IronBadge(count: 3, style: .soft, color: .warning)
      IronBadge(count: 3, style: .soft, color: .error)
      IronBadge(count: 3, style: .soft, color: .info)
    }
  }
  .padding()
}

#Preview("IronBadge - Sizes") {
  HStack(spacing: 24) {
    VStack(spacing: 8) {
      IronBadge(count: 5, size: .small)
      Text("Small").font(.caption)
    }
    VStack(spacing: 8) {
      IronBadge(count: 5, size: .medium)
      Text("Medium").font(.caption)
    }
    VStack(spacing: 8) {
      IronBadge(count: 5, size: .large)
      Text("Large").font(.caption)
    }
  }
  .padding()
}

#Preview("IronBadge - Overlay") {
  HStack(spacing: 32) {
    // Count badge
    Image(systemName: "bell.fill")
      .font(.title)
      .ironBadge(count: 3)

    // Dot badge
    Image(systemName: "envelope.fill")
      .font(.title)
      .ironBadge(isVisible: true)

    // No badge when zero
    Image(systemName: "message.fill")
      .font(.title)
      .ironBadge(count: 0)

    // Custom color
    Image(systemName: "cart.fill")
      .font(.title)
      .ironBadge(count: 12, color: .success)
  }
  .padding()
}

#Preview("IronBadge - Status Indicators") {
  VStack(alignment: .leading, spacing: 12) {
    HStack(spacing: 8) {
      IronBadge(color: .success, size: .small)
      Text("Online")
    }
    HStack(spacing: 8) {
      IronBadge(color: .warning, size: .small)
      Text("Away")
    }
    HStack(spacing: 8) {
      IronBadge(color: .error, size: .small)
      Text("Offline")
    }
  }
  .padding()
}
