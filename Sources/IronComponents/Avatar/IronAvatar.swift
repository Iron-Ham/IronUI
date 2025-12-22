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
/// // With AsyncImage
/// IronAvatar(url: URL(string: "https://example.com/avatar.jpg")!)
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
  ///   - innerBorder: Optional inner border style.
  ///   - badge: A view builder for the badge.
  public init(
    url: URL,
    name: String? = nil,
    size: IronAvatarSize = .medium,
    innerBorder: IronAvatarInnerBorder = .none,
    @ViewBuilder badge: () -> Badge,
  ) {
    imageSource = .url(url)
    self.size = size
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
  ///   - innerBorder: Optional inner border style.
  ///   - badge: A view builder for the badge.
  public init(
    name: String,
    size: IronAvatarSize = .medium,
    innerBorder: IronAvatarInnerBorder = .none,
    @ViewBuilder badge: () -> Badge,
  ) {
    imageSource = nil
    self.size = size
    self.innerBorder = innerBorder
    self.badge = badge()
    self.name = name
    badgeAccessibilityLabel = nil
  }

  // MARK: Public

  public var body: some View {
    let inset = badgeInset
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
        .alignmentGuide(.trailing) { d in d[HorizontalAlignment.center] + inset }
        .alignmentGuide(.bottom) { d in d[VerticalAlignment.center] + inset }
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
      AvatarWithBadgeCutout(
        avatarSize: avatarSize,
        badgeSize: badgeSize,
        cutoutPadding: badgeCutoutPadding,
      )
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
      if hasBadge {
        AvatarWithBadgeCutout(
          avatarSize: avatarSize,
          badgeSize: badgeSize,
          cutoutPadding: badgeCutoutPadding,
        )
        .strokeBorder(color, lineWidth: width)
      } else {
        Circle()
          .strokeBorder(color, lineWidth: width)
      }

    case .gradient(let color, let opacity, let width):
      if hasBadge {
        AvatarWithBadgeCutout(
          avatarSize: avatarSize,
          badgeSize: badgeSize,
          cutoutPadding: badgeCutoutPadding,
        )
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
    guard let name, !name.isEmpty else { return theme.colors.primary }

    // Generate consistent color based on name hash
    let hash = abs(name.hashValue)
    let colors: [Color] = [
      theme.colors.primary,
      theme.colors.secondary,
      theme.colors.success,
      theme.colors.warning,
      theme.colors.info,
    ]
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

  private var badgeSize: CGFloat {
    switch size {
    case .small: 12
    case .medium: 14
    case .large: 18
    case .xlarge: 24
    }
  }

  /// How far the badge center is inset from the avatar edge
  private var badgeInset: CGFloat {
    badgeSize * 0.15
  }

  /// Extra padding around the badge for the cutout
  private var badgeCutoutPadding: CGFloat {
    switch size {
    case .small: 2
    case .medium: 2.5
    case .large: 3
    case .xlarge: 4
    }
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
  ///   - innerBorder: Optional inner border style.
  public init(
    url: URL,
    name: String? = nil,
    size: IronAvatarSize = .medium,
    innerBorder: IronAvatarInnerBorder = .none,
  ) {
    imageSource = .url(url)
    self.size = size
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
  ///   - innerBorder: Optional inner border style.
  public init(
    name: String,
    size: IronAvatarSize = .medium,
    innerBorder: IronAvatarInnerBorder = .none,
  ) {
    imageSource = nil
    self.size = size
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
  ///   - innerBorder: Optional inner border style.
  ///   - status: The status to display.
  public init(
    url: URL,
    name: String? = nil,
    size: IronAvatarSize = .medium,
    innerBorder: IronAvatarInnerBorder = .none,
    status: IronAvatarStatus,
  ) {
    imageSource = .url(url)
    self.size = size
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
  ///   - innerBorder: Optional inner border style.
  ///   - status: The status to display.
  public init(
    name: String,
    size: IronAvatarSize = .medium,
    innerBorder: IronAvatarInnerBorder = .none,
    status: IronAvatarStatus,
  ) {
    imageSource = nil
    self.size = size
    self.innerBorder = innerBorder
    badge = IronAvatarStatusBadge(status: status)
    self.name = name
    badgeAccessibilityLabel = status.rawValue
  }
}

// MARK: - AvatarWithBadgeCutout

/// A circle shape with a smooth bezier-curved cutout for a badge at the bottom-trailing corner.
///
/// Unlike a simple circle intersection (which creates sharp points), this shape uses
/// bezier curves that are tangent to the main circle, creating a smooth, organic notch.
struct AvatarWithBadgeCutout: Shape {
  let avatarSize: CGFloat
  let badgeSize: CGFloat
  let cutoutPadding: CGFloat

  func path(in rect: CGRect) -> Path {
    let center = CGPoint(x: rect.midX, y: rect.midY)
    let radius = min(rect.width, rect.height) / 2

    // Badge position: bottom-trailing, slightly inset
    let badgeInset = badgeSize * 0.15
    let badgeCenterX = rect.maxX - badgeSize / 2 - badgeInset
    let badgeCenterY = rect.maxY - badgeSize / 2 - badgeInset
    let badgeCenter = CGPoint(x: badgeCenterX, y: badgeCenterY)
    let cutoutRadius = (badgeSize / 2) + cutoutPadding

    // Calculate distance from avatar center to badge center
    let dx = badgeCenter.x - center.x
    let dy = badgeCenter.y - center.y
    let distanceBetweenCenters = sqrt(dx * dx + dy * dy)

    // Angle from avatar center to badge center
    let angleToCenter = atan2(dy, dx)

    // Calculate the angular span we need to cut out
    // Using law of cosines: find angle at avatar center where the cutout circle intersects
    // c² = a² + b² - 2ab·cos(C)
    // Solving for C: cos(C) = (a² + b² - c²) / (2ab)
    // where a = radius, b = distanceBetweenCenters, c = cutoutRadius
    let cosHalfAngle = (radius * radius + distanceBetweenCenters * distanceBetweenCenters - cutoutRadius * cutoutRadius)
      / (2 * radius * distanceBetweenCenters)
    let halfAngle = acos(min(1, max(-1, cosHalfAngle)))

    // The angles on the main circle where we transition to the cutout
    let startCutoutAngle = angleToCenter - halfAngle
    let endCutoutAngle = angleToCenter + halfAngle

    // Points on the main circle where the cutout begins and ends
    let startPoint = CGPoint(
      x: center.x + radius * cos(startCutoutAngle),
      y: center.y + radius * sin(startCutoutAngle),
    )
    let endPoint = CGPoint(
      x: center.x + radius * cos(endCutoutAngle),
      y: center.y + radius * sin(endCutoutAngle),
    )

    // Calculate tangent directions at start and end points (perpendicular to radius)
    // For a circle, tangent at angle θ points in direction θ + π/2
    let startTangent = CGPoint(
      x: -sin(startCutoutAngle),
      y: cos(startCutoutAngle),
    )
    let endTangent = CGPoint(
      x: -sin(endCutoutAngle),
      y: cos(endCutoutAngle),
    )

    // Calculate the deepest point of the notch (closest to badge center)
    // Position it so there's proper clearance for the badge
    let notchPoint = CGPoint(
      x: center.x + (distanceBetweenCenters - cutoutRadius + cutoutPadding) * cos(angleToCenter),
      y: center.y + (distanceBetweenCenters - cutoutRadius + cutoutPadding) * sin(angleToCenter),
    )

    // Control point distance - determines how smooth/sharp the curve is
    let controlDistance = cutoutRadius * 1.1

    // Control points for the bezier curves
    // Start control: follows tangent direction from start point (into the cutout)
    let startControl = CGPoint(
      x: startPoint.x + startTangent.x * controlDistance,
      y: startPoint.y + startTangent.y * controlDistance,
    )

    // End control: follows tangent direction from end point (back from cutout)
    let endControl = CGPoint(
      x: endPoint.x - endTangent.x * controlDistance,
      y: endPoint.y - endTangent.y * controlDistance,
    )

    var path = Path()

    // Start from the end of the cutout and draw the main arc around
    path.addArc(
      center: center,
      radius: radius,
      startAngle: .radians(endCutoutAngle),
      endAngle: .radians(startCutoutAngle + 2 * .pi),
      clockwise: false,
    )

    // Now draw the smooth cutout curve using a cubic bezier
    // This creates a smooth "bay" that flows naturally from the circle
    path.addQuadCurve(
      to: notchPoint,
      control: startControl,
    )
    path.addQuadCurve(
      to: endPoint,
      control: endControl,
    )

    path.closeSubpath()

    return path
  }
}

// MARK: InsettableShape

extension AvatarWithBadgeCutout: InsettableShape {
  func inset(by amount: CGFloat) -> some InsettableShape {
    InsetAvatarWithBadgeCutout(
      avatarSize: avatarSize,
      badgeSize: badgeSize,
      cutoutPadding: cutoutPadding,
      insetAmount: amount,
    )
  }
}

// MARK: - InsetAvatarWithBadgeCutout

/// An inset version of `AvatarWithBadgeCutout` for stroke borders.
///
/// Uses the same smooth bezier-curve approach as `AvatarWithBadgeCutout`.
struct InsetAvatarWithBadgeCutout: InsettableShape {
  let avatarSize: CGFloat
  let badgeSize: CGFloat
  let cutoutPadding: CGFloat
  let insetAmount: CGFloat

  func path(in rect: CGRect) -> Path {
    let insetRect = rect.insetBy(dx: insetAmount, dy: insetAmount)
    let center = CGPoint(x: insetRect.midX, y: insetRect.midY)
    let radius = min(insetRect.width, insetRect.height) / 2

    // Badge position: bottom-trailing, slightly inset (same as non-inset version)
    let badgeInset = badgeSize * 0.15
    let badgeCenterX = rect.maxX - badgeSize / 2 - badgeInset
    let badgeCenterY = rect.maxY - badgeSize / 2 - badgeInset
    let badgeCenter = CGPoint(x: badgeCenterX, y: badgeCenterY)
    let cutoutRadius = (badgeSize / 2) + cutoutPadding - insetAmount

    // Calculate distance from avatar center to badge center
    let dx = badgeCenter.x - center.x
    let dy = badgeCenter.y - center.y
    let distanceBetweenCenters = sqrt(dx * dx + dy * dy)

    // Angle from avatar center to badge center
    let angleToCenter = atan2(dy, dx)

    var path = Path()

    // Check if cutout would be valid
    guard
      cutoutRadius > 0,
      distanceBetweenCenters < radius + cutoutRadius,
      distanceBetweenCenters > abs(radius - cutoutRadius)
    else {
      // No valid cutout, just draw a circle
      path.addArc(
        center: center,
        radius: radius,
        startAngle: .degrees(0),
        endAngle: .degrees(360),
        clockwise: false,
      )
      return path
    }

    // Calculate the angular span we need to cut out using law of cosines
    let cosHalfAngle = (radius * radius + distanceBetweenCenters * distanceBetweenCenters - cutoutRadius * cutoutRadius)
      / (2 * radius * distanceBetweenCenters)
    let halfAngle = acos(min(1, max(-1, cosHalfAngle)))

    // The angles on the main circle where we transition to the cutout
    let startCutoutAngle = angleToCenter - halfAngle
    let endCutoutAngle = angleToCenter + halfAngle

    // Points on the main circle where the cutout begins and ends
    let startPoint = CGPoint(
      x: center.x + radius * cos(startCutoutAngle),
      y: center.y + radius * sin(startCutoutAngle),
    )
    let endPoint = CGPoint(
      x: center.x + radius * cos(endCutoutAngle),
      y: center.y + radius * sin(endCutoutAngle),
    )

    // Calculate tangent directions at start and end points
    let startTangent = CGPoint(
      x: -sin(startCutoutAngle),
      y: cos(startCutoutAngle),
    )
    let endTangent = CGPoint(
      x: -sin(endCutoutAngle),
      y: cos(endCutoutAngle),
    )

    // Calculate the deepest point of the notch
    let notchPoint = CGPoint(
      x: center.x + (distanceBetweenCenters - cutoutRadius + (cutoutPadding - insetAmount)) * cos(angleToCenter),
      y: center.y + (distanceBetweenCenters - cutoutRadius + (cutoutPadding - insetAmount)) * sin(angleToCenter),
    )

    // Control point distance
    let controlDistance = cutoutRadius * 1.1

    // Control points for the bezier curves
    let startControl = CGPoint(
      x: startPoint.x + startTangent.x * controlDistance,
      y: startPoint.y + startTangent.y * controlDistance,
    )
    let endControl = CGPoint(
      x: endPoint.x - endTangent.x * controlDistance,
      y: endPoint.y - endTangent.y * controlDistance,
    )

    // Draw the main arc
    path.addArc(
      center: center,
      radius: radius,
      startAngle: .radians(endCutoutAngle),
      endAngle: .radians(startCutoutAngle + 2 * .pi),
      clockwise: false,
    )

    // Draw the smooth cutout curve using quadratic bezier curves
    path.addQuadCurve(
      to: notchPoint,
      control: startControl,
    )
    path.addQuadCurve(
      to: endPoint,
      control: endControl,
    )

    path.closeSubpath()

    return path
  }

  func inset(by amount: CGFloat) -> some InsettableShape {
    InsetAvatarWithBadgeCutout(
      avatarSize: avatarSize,
      badgeSize: badgeSize,
      cutoutPadding: cutoutPadding,
      insetAmount: insetAmount + amount,
    )
  }
}

// MARK: - IronAvatarStatusBadge

/// A status indicator badge for avatars.
public struct IronAvatarStatusBadge: View {

  // MARK: Lifecycle

  public init(status: IronAvatarStatus) {
    self.status = status
  }

  // MARK: Public

  public var body: some View {
    Circle()
      .fill(statusColor)
      .overlay {
        Circle()
          .strokeBorder(theme.colors.background, lineWidth: 2)
      }
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
    IronAvatar(name: "Verified", size: .large) {
      Image(systemName: "checkmark.seal.fill")
        .resizable()
        .foregroundStyle(.blue)
    }

    IronAvatar(name: "Pro User", size: .large) {
      Image(systemName: "star.fill")
        .resizable()
        .foregroundStyle(.yellow)
    }

    IronAvatar(name: "New", size: .large) {
      Circle()
        .fill(.red)
        .overlay {
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
        Image(systemName: "checkmark.seal.fill")
          .resizable()
          .foregroundStyle(.blue)
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
