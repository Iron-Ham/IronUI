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
/// ## With Status Indicator
///
/// ```swift
/// IronAvatar(name: "John Doe", status: .online)
/// IronAvatar(name: "John Doe", status: .away)
/// IronAvatar(name: "John Doe", status: .busy)
/// IronAvatar(name: "John Doe", status: .offline)
/// ```
public struct IronAvatar: View {

  // MARK: Lifecycle

  /// Creates an avatar with an image.
  ///
  /// - Parameters:
  ///   - image: The image to display.
  ///   - size: The size of the avatar.
  ///   - status: Optional status indicator.
  public init(
    image: Image,
    size: IronAvatarSize = .medium,
    status: IronAvatarStatus? = nil,
  ) {
    imageSource = .image(image)
    self.size = size
    self.status = status
    name = nil
  }

  /// Creates an avatar with a remote URL.
  ///
  /// - Parameters:
  ///   - url: The URL of the image to load.
  ///   - name: Fallback name for initials if image fails to load.
  ///   - size: The size of the avatar.
  ///   - status: Optional status indicator.
  public init(
    url: URL,
    name: String? = nil,
    size: IronAvatarSize = .medium,
    status: IronAvatarStatus? = nil,
  ) {
    imageSource = .url(url)
    self.size = size
    self.status = status
    self.name = name
  }

  /// Creates an avatar with initials from a name.
  ///
  /// - Parameters:
  ///   - name: The name to extract initials from.
  ///   - size: The size of the avatar.
  ///   - status: Optional status indicator.
  public init(
    name: String,
    size: IronAvatarSize = .medium,
    status: IronAvatarStatus? = nil,
  ) {
    imageSource = nil
    self.size = size
    self.status = status
    self.name = name
  }

  // MARK: Public

  public var body: some View {
    ZStack(alignment: .bottomTrailing) {
      avatarContent
        .frame(width: avatarSize, height: avatarSize)
        .clipShape(Circle())

      if let status {
        statusIndicator(status)
      }
    }
    .accessibilityElement(children: .ignore)
    .accessibilityLabel(accessibilityLabel)
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
  private let status: IronAvatarStatus?
  private let name: String?

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

  private var statusSize: CGFloat {
    switch size {
    case .small: 8
    case .medium: 10
    case .large: 14
    case .xlarge: 18
    }
  }

  private var statusBorderWidth: CGFloat {
    switch size {
    case .small: 1.5
    case .medium: 2
    case .large: 2.5
    case .xlarge: 3
    }
  }

  private var accessibilityLabel: String {
    var label = name ?? "Avatar"
    if let status {
      label += ", \(status.rawValue)"
    }
    return label
  }

  private func statusIndicator(_ status: IronAvatarStatus) -> some View {
    Circle()
      .fill(statusColor(for: status))
      .frame(width: statusSize, height: statusSize)
      .overlay {
        Circle()
          .strokeBorder(theme.colors.background, lineWidth: statusBorderWidth)
      }
  }

  private func statusColor(for status: IronAvatarStatus) -> Color {
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

#Preview("IronAvatar - Status") {
  HStack(spacing: 16) {
    IronAvatar(name: "Online", size: .large, status: .online)
    IronAvatar(name: "Away", size: .large, status: .away)
    IronAvatar(name: "Busy", size: .large, status: .busy)
    IronAvatar(name: "Offline", size: .large, status: .offline)
  }
  .padding()
}

#Preview("IronAvatar - With Image") {
  HStack(spacing: 16) {
    IronAvatar(image: Image(systemName: "person.fill"), size: .medium)
    IronAvatar(image: Image(systemName: "person.circle.fill"), size: .large)
  }
  .padding()
}

#Preview("IronAvatar - Avatar Group") {
  struct Demo: View {
    let names = ["Alice", "Bob", "Charlie", "Diana", "Eve"]

    var body: some View {
      HStack(spacing: -12) {
        ForEach(names, id: \.self) { name in
          IronAvatar(name: name, size: .medium)
            .overlay {
              Circle()
                .strokeBorder(Color.white, lineWidth: 2)
            }
        }
      }
      .padding()
    }
  }

  return Demo()
}

#Preview("IronAvatar - Profile Card") {
  VStack(spacing: 12) {
    IronAvatar(name: "Sarah Johnson", size: .xlarge, status: .online)

    IronText("Sarah Johnson", style: .titleMedium, color: .primary)
    IronText("Product Designer", style: .bodyMedium, color: .secondary)
  }
  .padding()
}
