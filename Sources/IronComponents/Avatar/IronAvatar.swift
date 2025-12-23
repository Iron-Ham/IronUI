import IronCore
import IronPrimitives
import SwiftUI

// MARK: - IronAvatar

/// A themed avatar component for displaying user profile images or initials.
///
/// `IronAvatar` provides a consistent way to display user identity with
/// automatic fallback to initials when no image is available.
///
/// ## Basic Usage
///
/// ```swift
/// // With image
/// IronAvatar(image: Image("profile"))
///
/// // With initials fallback
/// IronAvatar(name: "John Doe")
///
/// // With remote URL
/// IronAvatar(url: URL(string: "https://github.com/iron-ham.png")!)
///
/// // With URL and fallback name
/// IronAvatar(
///   url: URL(string: "https://example.com/avatar.jpg")!,
///   name: "John Doe"
/// )
/// ```
///
/// ## Custom Background Color
///
/// ```swift
/// // Explicit color for initials background
/// IronAvatar(name: "John Doe", backgroundColor: .purple)
///
/// // Custom color palette for automatic selection
/// IronAvatar(name: "John Doe", backgroundColors: [.red, .blue, .green])
/// ```
///
/// ## Sizes
///
/// ```swift
/// IronAvatar(name: "JD", size: .small)
/// IronAvatar(name: "JD", size: .medium)
/// IronAvatar(name: "JD", size: .large)
/// IronAvatar(name: "JD", size: .xlarge)
/// ```
///
/// ## With Status Badge
///
/// ```swift
/// IronAvatar(name: "John Doe", status: .online)
/// IronAvatar(name: "John Doe", status: .away)
/// IronAvatar(name: "John Doe", status: .busy)
/// IronAvatar(name: "John Doe", status: .offline)
/// ```
///
/// ## With Custom Badge
///
/// ```swift
/// IronAvatar(name: "John Doe") {
///   Image(systemName: "checkmark.seal.fill")
///     .foregroundStyle(.blue)
/// }
/// ```
///
/// ## With Inner Border
///
/// ```swift
/// IronAvatar(image: myImage, innerBorder: .gradient(color: .black, opacity: 0.15))
/// ```
public struct IronAvatar<Badge: View>: View {

  // MARK: Lifecycle

  /// Creates an avatar with an image and optional badge.
  ///
  /// - Parameters:
  ///   - image: The image to display.
  ///   - size: The size of the avatar.
  ///   - innerBorder: Optional inner border style.
  ///   - badge: A view builder for the badge.
  public init(
    image: Image,
    size: IronAvatarSize = .medium,
    innerBorder: IronAvatarInnerBorder = .none,
    @ViewBuilder badge: () -> Badge,
  ) {
    imageSource = .image(image)
    self.size = size
    explicitBackgroundColor = nil
    customBackgroundColors = nil
    self.innerBorder = innerBorder
    self.badge = badge()
    name = nil
    badgeAccessibilityLabel = nil
  }

  /// Creates an avatar with a remote URL and optional badge.
  ///
  /// - Parameters:
  ///   - url: The URL of the image to load.
  ///   - name: Fallback name for initials if image fails to load.
  ///   - size: The size of the avatar.
  ///   - backgroundColor: Optional explicit background color for fallback initials.
  ///   - backgroundColors: Optional custom color palette for fallback initials.
  ///   - innerBorder: Optional inner border style.
  ///   - badge: A view builder for the badge.
  public init(
    url: URL,
    name: String? = nil,
    size: IronAvatarSize = .medium,
    backgroundColor: Color? = nil,
    backgroundColors: [Color]? = nil,
    innerBorder: IronAvatarInnerBorder = .none,
    @ViewBuilder badge: () -> Badge,
  ) {
    imageSource = .url(url)
    self.size = size
    explicitBackgroundColor = backgroundColor
    customBackgroundColors = backgroundColors
    self.innerBorder = innerBorder
    self.badge = badge()
    self.name = name
    badgeAccessibilityLabel = nil
  }

  /// Creates an avatar with initials from a name and optional badge.
  ///
  /// - Parameters:
  ///   - name: The name to extract initials from.
  ///   - size: The size of the avatar.
  ///   - backgroundColor: Optional explicit background color for initials. If nil, color is derived from name.
  ///   - backgroundColors: Optional custom color palette for automatic selection. If nil, uses theme colors.
  ///   - innerBorder: Optional inner border style.
  ///   - badge: A view builder for the badge.
  public init(
    name: String,
    size: IronAvatarSize = .medium,
    backgroundColor: Color? = nil,
    backgroundColors: [Color]? = nil,
    innerBorder: IronAvatarInnerBorder = .none,
    @ViewBuilder badge: () -> Badge,
  ) {
    imageSource = nil
    self.size = size
    explicitBackgroundColor = backgroundColor
    customBackgroundColors = backgroundColors
    self.innerBorder = innerBorder
    self.badge = badge()
    self.name = name
    badgeAccessibilityLabel = nil
  }

  // MARK: Public

  public var body: some View {
    let bottomOffset = badgeBottomOffset
    return ZStack(alignment: .bottomTrailing) {
      avatarContent
        .frame(width: avatarSize, height: avatarSize)
        .mask {
          avatarMask
        }
        .overlay {
          innerBorderOverlay
        }

      badge
        .frame(width: badgeSize, height: badgeSize)
        // Position badge centerX at avatar's trailing edge
        .alignmentGuide(.trailing) { d in d[HorizontalAlignment.center] }
        // Position badge bottom slightly below avatar's bottom
        .alignmentGuide(.bottom) { d in d[VerticalAlignment.bottom] - bottomOffset }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilityLabel)
  }

  // MARK: Internal

  /// For internal use: allows setting badge accessibility label for status convenience initializers
  var badgeAccessibilityLabel: String?

  @ViewBuilder
  var avatarMask: some View {
    if hasBadge {
      // Use the PDF mask asset for smooth cutout
      Image("AvatarBadgeMask", bundle: .module)
        .resizable()
    } else {
      Circle()
    }
  }

  // MARK: Private

  private enum ImageSource {
    case image(Image)
    case url(URL)
  }

  @Environment(\.ironTheme) private var theme

  @ScaledMetric(relativeTo: .caption2)
  private var smallSize: CGFloat = 32

  @ScaledMetric(relativeTo: .body)
  private var mediumSize: CGFloat = 40

  @ScaledMetric(relativeTo: .title2)
  private var largeSize: CGFloat = 56

  @ScaledMetric(relativeTo: .largeTitle)
  private var xlargeSize: CGFloat = 80

  private let imageSource: ImageSource?
  private let size: IronAvatarSize
  private let explicitBackgroundColor: Color?
  private let customBackgroundColors: [Color]?
  private let innerBorder: IronAvatarInnerBorder
  private let badge: Badge
  private let name: String?

  private var hasBadge: Bool {
    Badge.self != EmptyView.self
  }

  @ViewBuilder
  private var avatarContent: some View {
    switch imageSource {
    case .image(let image):
      image
        .resizable()
        .scaledToFill()

    case .url(let url):
      AsyncImage(url: url) { phase in
        switch phase {
        case .empty:
          placeholderContent
            .overlay {
              IronSpinner(size: spinnerSize)
            }

        case .success(let image):
          image
            .resizable()
            .scaledToFill()

        case .failure:
          initialsContent

        @unknown default:
          placeholderContent
        }
      }

    case nil:
      initialsContent
    }
  }

  private var placeholderContent: some View {
    Circle()
      .fill(theme.colors.surface)
  }

  private var initialsContent: some View {
    ZStack {
      Circle()
        .fill(backgroundColor)

      IronText(initials, style: initialsStyle, color: .onPrimary)
    }
  }

  @ViewBuilder
  private var innerBorderOverlay: some View {
    switch innerBorder {
    case .none:
      EmptyView()

    case .solid(let color, let width):
      // When using PDF mask with badge, the border width is determined by the asset
      if hasBadge {
        Image("AvatarBadgeBorder", bundle: .module)
          .resizable()
          .foregroundStyle(color)
      } else {
        Circle()
          .strokeBorder(color, lineWidth: width)
      }

    case .gradient(let color, let opacity, let width):
      // When using PDF mask with badge, the border width is determined by the asset
      if hasBadge {
        Image("AvatarBadgeBorder", bundle: .module)
          .resizable()
          .foregroundStyle(color.opacity(opacity))
      } else {
        Circle()
          .strokeBorder(
            RadialGradient(
              colors: [
                color.opacity(0),
                color.opacity(opacity * 0.5),
                color.opacity(opacity),
              ],
              center: .center,
              startRadius: avatarSize * 0.3,
              endRadius: avatarSize * 0.5,
            ),
            lineWidth: width,
          )
      }
    }
  }

  private var initials: String {
    guard let name, !name.isEmpty else { return "?" }

    let components = name.split(separator: " ")
    if components.count >= 2 {
      let first = components[0].prefix(1)
      let last = components[components.count - 1].prefix(1)
      return "\(first)\(last)".uppercased()
    } else {
      return String(name.prefix(2)).uppercased()
    }
  }

  private var backgroundColor: Color {
    // Use explicit color if provided
    if let explicitBackgroundColor {
      return explicitBackgroundColor
    }

    guard let name, !name.isEmpty else { return theme.colors.primary }

    // Use custom palette or default theme colors
    let colors: [Color] = customBackgroundColors ?? [
      theme.colors.primary,
      theme.colors.secondary,
      theme.colors.success,
      theme.colors.warning,
      theme.colors.info,
    ]

    // Use stable hash (djb2 algorithm) instead of Swift's randomized hashValue
    let hash = Self.stableHash(name)
    return colors[hash % colors.count]
  }

  private var avatarSize: CGFloat {
    switch size {
    case .small: smallSize
    case .medium: mediumSize
    case .large: largeSize
    case .xlarge: xlargeSize
    }
  }

  /// Badge size - 50% of avatar, centered within the mask cutout.
  private var badgeSize: CGFloat {
    avatarSize * 0.5
  }

  /// Badge bottom offset - positions badge center correctly within the cutout.
  /// Calculated: container (62.5%) centered with 3pt offset, badge (50%) centered within.
  private var badgeBottomOffset: CGFloat {
    avatarSize * 0.03125
  }

  private var initialsStyle: IronTextStyle {
    switch size {
    case .small: .caption
    case .medium: .labelMedium
    case .large: .titleMedium
    case .xlarge: .titleLarge
    }
  }

  private var spinnerSize: IronSpinnerSize {
    switch size {
    case .small, .medium: .small
    case .large: .medium
    case .xlarge: .large
    }
  }

  private var accessibilityLabel: String {
    var label = name ?? "Avatar"
    if let badgeAccessibilityLabel {
      label += ", \(badgeAccessibilityLabel)"
    }
    return label
  }

  /// Computes a stable hash for a string using the djb2 algorithm.
  /// Unlike Swift's `hashValue`, this produces consistent results across runs.
  private static func stableHash(_ string: String) -> Int {
    var hash: UInt64 = 5381
    for char in string.utf8 {
      hash = ((hash << 5) &+ hash) &+ UInt64(char)
    }
    return Int(hash % UInt64(Int.max))
  }

}

// MARK: - Convenience initializers without badge

extension IronAvatar where Badge == EmptyView {
  /// Creates an avatar with an image.
  ///
  /// - Parameters:
  ///   - image: The image to display.
  ///   - size: The size of the avatar.
  ///   - innerBorder: Optional inner border style.
  public init(
    image: Image,
    size: IronAvatarSize = .medium,
    innerBorder: IronAvatarInnerBorder = .none,
  ) {
    imageSource = .image(image)
    self.size = size
    explicitBackgroundColor = nil
    customBackgroundColors = nil
    self.innerBorder = innerBorder
    badge = EmptyView()
    name = nil
    badgeAccessibilityLabel = nil
  }

  /// Creates an avatar with a remote URL.
  ///
  /// - Parameters:
  ///   - url: The URL of the image to load.
  ///   - name: Fallback name for initials if image fails to load.
  ///   - size: The size of the avatar.
  ///   - backgroundColor: Optional explicit background color for fallback initials.
  ///   - backgroundColors: Optional custom color palette for fallback initials.
  ///   - innerBorder: Optional inner border style.
  public init(
    url: URL,
    name: String? = nil,
    size: IronAvatarSize = .medium,
    backgroundColor: Color? = nil,
    backgroundColors: [Color]? = nil,
    innerBorder: IronAvatarInnerBorder = .none,
  ) {
    imageSource = .url(url)
    self.size = size
    explicitBackgroundColor = backgroundColor
    customBackgroundColors = backgroundColors
    self.innerBorder = innerBorder
    badge = EmptyView()
    self.name = name
    badgeAccessibilityLabel = nil
  }

  /// Creates an avatar with initials from a name.
  ///
  /// - Parameters:
  ///   - name: The name to extract initials from.
  ///   - size: The size of the avatar.
  ///   - backgroundColor: Optional explicit background color. If nil, color is derived from name.
  ///   - backgroundColors: Optional custom color palette for automatic selection. If nil, uses theme colors.
  ///   - innerBorder: Optional inner border style.
  public init(
    name: String,
    size: IronAvatarSize = .medium,
    backgroundColor: Color? = nil,
    backgroundColors: [Color]? = nil,
    innerBorder: IronAvatarInnerBorder = .none,
  ) {
    imageSource = nil
    self.size = size
    explicitBackgroundColor = backgroundColor
    customBackgroundColors = backgroundColors
    self.innerBorder = innerBorder
    badge = EmptyView()
    self.name = name
    badgeAccessibilityLabel = nil
  }
}

// MARK: - Convenience initializers with status

extension IronAvatar where Badge == IronAvatarStatusBadge {
  /// Creates an avatar with an image and status indicator.
  ///
  /// - Parameters:
  ///   - image: The image to display.
  ///   - size: The size of the avatar.
  ///   - innerBorder: Optional inner border style.
  ///   - status: The status to display.
  public init(
    image: Image,
    size: IronAvatarSize = .medium,
    innerBorder: IronAvatarInnerBorder = .none,
    status: IronAvatarStatus,
  ) {
    imageSource = .image(image)
    self.size = size
    explicitBackgroundColor = nil
    customBackgroundColors = nil
    self.innerBorder = innerBorder
    badge = IronAvatarStatusBadge(status: status)
    name = nil
    badgeAccessibilityLabel = status.rawValue
  }

  /// Creates an avatar with a remote URL and status indicator.
  ///
  /// - Parameters:
  ///   - url: The URL of the image to load.
  ///   - name: Fallback name for initials if image fails to load.
  ///   - size: The size of the avatar.
  ///   - backgroundColor: Optional explicit background color for fallback initials.
  ///   - backgroundColors: Optional custom color palette for fallback initials.
  ///   - innerBorder: Optional inner border style.
  ///   - status: The status to display.
  public init(
    url: URL,
    name: String? = nil,
    size: IronAvatarSize = .medium,
    backgroundColor: Color? = nil,
    backgroundColors: [Color]? = nil,
    innerBorder: IronAvatarInnerBorder = .none,
    status: IronAvatarStatus,
  ) {
    imageSource = .url(url)
    self.size = size
    explicitBackgroundColor = backgroundColor
    customBackgroundColors = backgroundColors
    self.innerBorder = innerBorder
    badge = IronAvatarStatusBadge(status: status)
    self.name = name
    badgeAccessibilityLabel = status.rawValue
  }

  /// Creates an avatar with initials from a name and status indicator.
  ///
  /// - Parameters:
  ///   - name: The name to extract initials from.
  ///   - size: The size of the avatar.
  ///   - backgroundColor: Optional explicit background color. If nil, color is derived from name.
  ///   - backgroundColors: Optional custom color palette for automatic selection. If nil, uses theme colors.
  ///   - innerBorder: Optional inner border style.
  ///   - status: The status to display.
  public init(
    name: String,
    size: IronAvatarSize = .medium,
    backgroundColor: Color? = nil,
    backgroundColors: [Color]? = nil,
    innerBorder: IronAvatarInnerBorder = .none,
    status: IronAvatarStatus,
  ) {
    imageSource = nil
    self.size = size
    explicitBackgroundColor = backgroundColor
    customBackgroundColors = backgroundColors
    self.innerBorder = innerBorder
    badge = IronAvatarStatusBadge(status: status)
    self.name = name
    badgeAccessibilityLabel = status.rawValue
  }
}

// MARK: - IronAvatarBadge

/// A circular badge container for avatar badges.
///
/// `IronAvatarBadge` provides a clean circular container with a background
/// color for badge content. Use this to wrap custom badge content.
///
/// ## Basic Usage
///
/// ```swift
/// // Solid color badge (like status indicator)
/// IronAvatarBadge(backgroundColor: .green)
///
/// // Badge with background and content
/// IronAvatarBadge(backgroundColor: .blue) {
///   Image(systemName: "checkmark")
///     .foregroundStyle(.white)
/// }
/// ```
public struct IronAvatarBadge<Content: View>: View {

  // MARK: Lifecycle

  /// Creates a badge with a background color and optional content.
  ///
  /// - Parameters:
  ///   - backgroundColor: The background color of the badge.
  ///   - content: Optional content to display inside the badge.
  public init(
    backgroundColor: Color,
    @ViewBuilder content: () -> Content = { EmptyView() as! Content },
  ) {
    self.backgroundColor = backgroundColor
    self.content = content()
  }

  // MARK: Public

  public var body: some View {
    Circle()
      .fill(backgroundColor)
      .overlay {
        content
          .padding(2)
      }
  }

  // MARK: Private

  private let backgroundColor: Color
  private let content: Content
}

extension IronAvatarBadge where Content == EmptyView {
  /// Creates a solid color badge with no content.
  ///
  /// - Parameter backgroundColor: The background color of the badge.
  public init(backgroundColor: Color) {
    self.backgroundColor = backgroundColor
    content = EmptyView()
  }
}

// MARK: - IronAvatarImageBadge

/// A badge that displays an image within the avatar's badge slot.
///
/// Use this when you want to display a full-bleed image or SF Symbol
/// as a badge without a circular container.
///
/// ```swift
/// IronAvatar(name: "Verified") {
///   IronAvatarImageBadge {
///     Image(systemName: "checkmark.seal.fill")
///       .foregroundStyle(.blue)
///   }
/// }
/// ```
public struct IronAvatarImageBadge<Content: View>: View {

  // MARK: Lifecycle

  /// Creates an image badge with custom content.
  ///
  /// - Parameter content: The content to display as the badge.
  public init(@ViewBuilder content: () -> Content) {
    self.content = content()
  }

  // MARK: Public

  public var body: some View {
    content
      .scaledToFit()
  }

  // MARK: Private

  private let content: Content
}

// MARK: - IronAvatarStatusBadge

/// A status indicator badge for avatars.
///
/// This is a convenience wrapper around `IronAvatarBadge` for common status indicators.
public struct IronAvatarStatusBadge: View {

  // MARK: Lifecycle

  public init(status: IronAvatarStatus) {
    self.status = status
  }

  // MARK: Public

  public var body: some View {
    IronAvatarBadge(backgroundColor: statusColor)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  private let status: IronAvatarStatus

  private var statusColor: Color {
    switch status {
    case .online: theme.colors.success
    case .away: theme.colors.warning
    case .busy: theme.colors.error
    case .offline: theme.colors.textDisabled
    }
  }
}

// MARK: - IronAvatarSize

/// Size options for `IronAvatar`.
public enum IronAvatarSize: Sendable, CaseIterable {
  /// A compact avatar (32pt).
  case small
  /// The default avatar size (40pt).
  case medium
  /// A larger avatar (56pt).
  case large
  /// An extra large avatar for profile pages (80pt).
  case xlarge
}

// MARK: - IronAvatarStatus

/// Status indicator options for `IronAvatar`.
public enum IronAvatarStatus: String, Sendable, CaseIterable {
  /// User is online and available.
  case online
  /// User is away or idle.
  case away
  /// User is busy or in do-not-disturb mode.
  case busy
  /// User is offline.
  case offline
}

// MARK: - IronAvatarInnerBorder

/// Inner border style options for `IronAvatar`.
public enum IronAvatarInnerBorder: Sendable {
  /// No inner border.
  case none
  /// A solid colored inner border.
  case solid(color: Color, width: CGFloat = 1)
  /// A gradient inner border that fades from transparent to the specified color.
  case gradient(color: Color, opacity: Double = 0.15, width: CGFloat = 3)
}

// MARK: - Previews

#Preview("IronAvatar - Initials") {
  HStack(spacing: 16) {
    IronAvatar(name: "John Doe")
    IronAvatar(name: "Alice Smith")
    IronAvatar(name: "Bob")
    IronAvatar(name: "")
  }
  .padding()
}

#Preview("IronAvatar - Custom Colors") {
  VStack(spacing: 16) {
    HStack(spacing: 16) {
      IronAvatar(name: "JD", size: .large, backgroundColor: .purple)
      IronAvatar(name: "AS", size: .large, backgroundColor: .orange)
      IronAvatar(name: "BW", size: .large, backgroundColor: .pink)
    }
    HStack(spacing: 16) {
      // Custom palette - colors will be selected based on name hash
      IronAvatar(name: "Alice", size: .large, backgroundColors: [.red, .blue, .green])
      IronAvatar(name: "Bob", size: .large, backgroundColors: [.red, .blue, .green])
      IronAvatar(name: "Charlie", size: .large, backgroundColors: [.red, .blue, .green])
    }
  }
  .padding()
}

#Preview("IronAvatar - Remote URL") {
  HStack(spacing: 16) {
    // Load from GitHub
    IronAvatar(
      url: URL(string: "https://github.com/iron-ham.png")!,
      name: "Hesham Salman",
      size: .large,
    )

    // With status badge
    IronAvatar(
      url: URL(string: "https://github.com/iron-ham.png")!,
      name: "Hesham Salman",
      size: .large,
      status: .online,
    )

    // Fallback when URL fails (invalid URL)
    IronAvatar(
      url: URL(string: "https://invalid-url-that-will-fail.example")!,
      name: "Fallback User",
      size: .large,
    )
  }
  .padding()
}

#Preview("IronAvatar - Sizes") {
  HStack(spacing: 16) {
    IronAvatar(name: "JD", size: .small)
    IronAvatar(name: "JD", size: .medium)
    IronAvatar(name: "JD", size: .large)
    IronAvatar(name: "JD", size: .xlarge)
  }
  .padding()
}

#Preview("IronAvatar - Status with Cutout") {
  HStack(spacing: 16) {
    IronAvatar(name: "Online", size: .large, status: .online)
    IronAvatar(name: "Away", size: .large, status: .away)
    IronAvatar(name: "Busy", size: .large, status: .busy)
    IronAvatar(name: "Offline", size: .large, status: .offline)
  }
  .padding()
}

#Preview("IronAvatar - Status All Sizes") {
  VStack(spacing: 16) {
    HStack(spacing: 16) {
      IronAvatar(name: "JD", size: .small, status: .online)
      IronAvatar(name: "JD", size: .medium, status: .online)
      IronAvatar(name: "JD", size: .large, status: .online)
      IronAvatar(name: "JD", size: .xlarge, status: .online)
    }
  }
  .padding()
}

#Preview("IronAvatar - Custom Badge") {
  HStack(spacing: 16) {
    // Full-bleed SF Symbol badge
    IronAvatar(name: "Verified", size: .large) {
      IronAvatarImageBadge {
        Image(systemName: "checkmark.seal.fill")
          .resizable()
          .foregroundStyle(.blue)
      }
    }

    // Badge with colored background and icon
    IronAvatar(name: "Pro User", size: .large) {
      IronAvatarBadge(backgroundColor: .yellow) {
        Image(systemName: "star.fill")
          .resizable()
          .foregroundStyle(.white)
      }
    }

    // Badge with notification count
    IronAvatar(name: "New", size: .large) {
      IronAvatarBadge(backgroundColor: .red) {
        Text("3")
          .font(.system(size: 10, weight: .bold))
          .foregroundStyle(.white)
      }
    }
  }
  .padding()
}

#Preview("IronAvatar - Inner Border") {
  VStack(spacing: 24) {
    HStack(spacing: 16) {
      IronAvatar(name: "No Border", size: .large)
      IronAvatar(name: "Solid", size: .large, innerBorder: .solid(color: .black.opacity(0.2)))
      IronAvatar(name: "Gradient", size: .large, innerBorder: .gradient(color: .black, opacity: 0.2))
    }

    HStack(spacing: 16) {
      IronAvatar(name: "With Badge", size: .large, innerBorder: .gradient(color: .black, opacity: 0.15), status: .online)
      IronAvatar(name: "Custom", size: .large, innerBorder: .gradient(color: .black, opacity: 0.15)) {
        IronAvatarImageBadge {
          Image(systemName: "checkmark.seal.fill")
            .resizable()
            .foregroundStyle(.blue)
        }
      }
    }
  }
  .padding()
}

#Preview("IronAvatar - With Image") {
  HStack(spacing: 16) {
    IronAvatar(image: Image(systemName: "person.fill"), size: .medium)
    IronAvatar(image: Image(systemName: "person.circle.fill"), size: .large, status: .online)
  }
  .padding()
}

#Preview("IronAvatar - Avatar Group") {
  struct Demo: View {
    let names = ["Alice", "Bob", "Charlie", "Diana", "Eve"]

    var body: some View {
      HStack(spacing: -12) {
        ForEach(names, id: \.self) { name in
          IronAvatar(name: name, size: .medium, innerBorder: .solid(color: .white, width: 2))
        }
      }
      .padding()
    }
  }

  return Demo()
}

#Preview("IronAvatar - Profile Card") {
  VStack(spacing: 12) {
    IronAvatar(
      name: "Sarah Johnson",
      size: .xlarge,
      innerBorder: .gradient(color: .black, opacity: 0.1),
      status: .online,
    )

    IronText("Sarah Johnson", style: .titleMedium, color: .primary)
    IronText("Product Designer", style: .bodyMedium, color: .secondary)
  }
  .padding()
}

#Preview("IronAvatar - Dark Background") {
  VStack(spacing: 16) {
    HStack(spacing: 16) {
      IronAvatar(name: "Online", size: .xlarge, status: .online)
      IronAvatar(name: "Away", size: .xlarge, status: .away)
    }
    HStack(spacing: 16) {
      IronAvatar(name: "Busy", size: .xlarge, status: .busy)
      IronAvatar(name: "Offline", size: .xlarge, status: .offline)
    }
  }
  .padding(32)
  .background(Color(white: 0.15))
}
