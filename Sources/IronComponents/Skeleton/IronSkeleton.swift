import IronCore
import SwiftUI

// MARK: - IronSkeleton

/// A themed skeleton loading placeholder with shimmer animation.
///
/// `IronSkeleton` provides animated placeholder shapes that indicate
/// content is loading, following the library's motion principles.
///
/// ## Basic Usage
///
/// ```swift
/// // Text placeholder
/// IronSkeleton(shape: .text)
///
/// // Circular placeholder (avatar)
/// IronSkeleton(shape: .circle(size: 40))
///
/// // Rectangular placeholder (image)
/// IronSkeleton(shape: .rectangle(width: 200, height: 150))
/// ```
///
/// ## Rounded Shapes
///
/// ```swift
/// IronSkeleton(shape: .rounded(width: 100, height: 20, radius: 4))
/// IronSkeleton(shape: .capsule(width: 80, height: 32))
/// ```
///
/// ## Multiple Lines
///
/// ```swift
/// VStack(alignment: .leading, spacing: 8) {
///   IronSkeleton(shape: .text)
///   IronSkeleton(shape: .text(widthRatio: 0.8))
///   IronSkeleton(shape: .text(widthRatio: 0.6))
/// }
/// ```
public struct IronSkeleton: View {

  // MARK: Lifecycle

  /// Creates a skeleton with the specified shape.
  ///
  /// - Parameters:
  ///   - shape: The shape of the skeleton.
  ///   - animated: Whether to show the shimmer animation.
  public init(
    shape: IronSkeletonShape,
    animated: Bool = true,
  ) {
    self.shape = shape
    self.animated = animated
  }

  // MARK: Public

  public var body: some View {
    skeletonContent
      .accessibilityElement(children: .ignore)
      .accessibilityLabel("Loading")
      .accessibilityAddTraits(animated ? .updatesFrequently : [])
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  @State private var shimmerOffset: CGFloat = -1

  private let shape: IronSkeletonShape
  private let animated: Bool

  @ViewBuilder
  private var skeletonContent: some View {
    switch shape {
    case .text(let widthRatio):
      skeletonView(
        shape: RoundedRectangle(cornerRadius: 4),
        width: widthRatio < 1.0 ? nil : nil,
        height: 16,
      )

    case .circle(let size):
      skeletonView(
        shape: Circle(),
        width: size,
        height: size,
      )

    case .rectangle(let width, let height):
      skeletonView(
        shape: Rectangle(),
        width: width,
        height: height,
      )

    case .rounded(let width, let height, let radius):
      skeletonView(
        shape: RoundedRectangle(cornerRadius: radius),
        width: width,
        height: height,
      )

    case .capsule(let width, let height):
      skeletonView(
        shape: Capsule(),
        width: width,
        height: height,
      )
    }
  }

  private var shimmerOverlay: some View {
    GeometryReader { geometry in
      let width = geometry.size.width
      let gradientWidth = width * 0.6

      LinearGradient(
        colors: [
          .clear,
          theme.colors.background.opacity(0.4),
          theme.colors.background.opacity(0.6),
          theme.colors.background.opacity(0.4),
          .clear,
        ],
        startPoint: .leading,
        endPoint: .trailing,
      )
      .frame(width: gradientWidth)
      .offset(x: shimmerOffset * (width + gradientWidth) - gradientWidth)
      .onAppear {
        withAnimation(
          .linear(duration: 1.5)
            .repeatForever(autoreverses: false)
        ) {
          shimmerOffset = 1
        }
      }
    }
  }

  private func skeletonView(
    shape: some Shape,
    width: CGFloat?,
    height: CGFloat?,
  ) -> some View {
    shape
      .fill(theme.colors.border.opacity(0.5))
      .frame(width: width, height: height)
      .overlay {
        if animated {
          shimmerOverlay
            .clipShape(shape)
        }
      }
  }

}

// MARK: - IronSkeletonShape

/// Shape options for `IronSkeleton`.
public enum IronSkeletonShape: Sendable {
  /// A text line placeholder.
  /// - Parameter widthRatio: The width as a ratio of container width (0-1).
  case text(widthRatio: CGFloat = 1.0)

  /// A circular placeholder (e.g., for avatars).
  /// - Parameter size: The diameter of the circle.
  case circle(size: CGFloat)

  /// A rectangular placeholder (e.g., for images).
  /// - Parameters:
  ///   - width: The width of the rectangle.
  ///   - height: The height of the rectangle.
  case rectangle(width: CGFloat, height: CGFloat)

  /// A rounded rectangle placeholder.
  /// - Parameters:
  ///   - width: The width of the rectangle.
  ///   - height: The height of the rectangle.
  ///   - radius: The corner radius.
  case rounded(width: CGFloat, height: CGFloat, radius: CGFloat)

  /// A capsule placeholder (e.g., for chips, badges).
  /// - Parameters:
  ///   - width: The width of the capsule.
  ///   - height: The height of the capsule.
  case capsule(width: CGFloat, height: CGFloat)
}

// MARK: - IronSkeletonText

/// A convenience view for text skeleton placeholders with proper layout.
public struct IronSkeletonText: View {

  // MARK: Lifecycle

  /// Creates text skeleton lines.
  ///
  /// - Parameters:
  ///   - lines: Number of text lines.
  ///   - lastLineRatio: Width ratio for the last line (0-1).
  ///   - spacing: Spacing between lines.
  public init(
    lines: Int = 3,
    lastLineRatio: CGFloat = 0.7,
    spacing: CGFloat = 8,
  ) {
    self.lines = lines
    self.lastLineRatio = lastLineRatio
    self.spacing = spacing
  }

  // MARK: Public

  public var body: some View {
    VStack(alignment: .leading, spacing: spacing) {
      ForEach(0..<lines, id: \.self) { index in
        GeometryReader { geometry in
          let isLast = index == lines - 1
          let width = isLast ? geometry.size.width * lastLineRatio : geometry.size.width

          IronSkeleton(shape: .rounded(width: width, height: 16, radius: 4))
        }
        .frame(height: 16)
      }
    }
  }

  // MARK: Private

  private let lines: Int
  private let lastLineRatio: CGFloat
  private let spacing: CGFloat
}

// MARK: - IronSkeletonCard

/// A pre-built skeleton for card layouts.
public struct IronSkeletonCard: View {

  // MARK: Lifecycle

  /// Creates a skeleton card.
  ///
  /// - Parameter showImage: Whether to show an image placeholder.
  public init(showImage: Bool = true) {
    self.showImage = showImage
  }

  // MARK: Public

  public var body: some View {
    VStack(alignment: .leading, spacing: theme.spacing.md) {
      if showImage {
        IronSkeleton(shape: .rectangle(width: .infinity, height: 150))
          .frame(maxWidth: .infinity)
          .frame(height: 150)
      }

      HStack(spacing: theme.spacing.md) {
        IronSkeleton(shape: .circle(size: 40))

        VStack(alignment: .leading, spacing: theme.spacing.xs) {
          IronSkeleton(shape: .rounded(width: 120, height: 16, radius: 4))
          IronSkeleton(shape: .rounded(width: 80, height: 12, radius: 3))
        }
      }

      IronSkeletonText(lines: 2)
    }
    .padding(theme.spacing.md)
    .background(theme.colors.surfaceElevated)
    .clipShape(RoundedRectangle(cornerRadius: theme.radii.lg))
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  private let showImage: Bool
}

// MARK: - IronSkeletonList

/// A pre-built skeleton for list item layouts.
public struct IronSkeletonList: View {

  // MARK: Lifecycle

  /// Creates a skeleton list.
  ///
  /// - Parameter count: Number of list items to show.
  public init(count: Int = 5) {
    self.count = count
  }

  // MARK: Public

  public var body: some View {
    VStack(spacing: theme.spacing.md) {
      ForEach(0..<count, id: \.self) { _ in
        IronSkeletonListItem()
      }
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  private let count: Int
}

// MARK: - IronSkeletonListItem

/// A pre-built skeleton for a single list item.
public struct IronSkeletonListItem: View {

  // MARK: Public

  public var body: some View {
    HStack(spacing: theme.spacing.md) {
      IronSkeleton(shape: .circle(size: 48))

      VStack(alignment: .leading, spacing: theme.spacing.xs) {
        IronSkeleton(shape: .rounded(width: 140, height: 16, radius: 4))
        IronSkeleton(shape: .rounded(width: 100, height: 12, radius: 3))
      }

      Spacer()

      IronSkeleton(shape: .rounded(width: 60, height: 24, radius: 4))
    }
    .padding(.vertical, theme.spacing.sm)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
}

// MARK: - Previews

#Preview("IronSkeleton - Shapes") {
  VStack(spacing: 24) {
    IronSkeleton(shape: .text())
      .frame(width: 200)

    IronSkeleton(shape: .circle(size: 48))

    IronSkeleton(shape: .rectangle(width: 150, height: 100))

    IronSkeleton(shape: .rounded(width: 120, height: 40, radius: 8))

    IronSkeleton(shape: .capsule(width: 100, height: 32))
  }
  .padding()
}

#Preview("IronSkeleton - Text Lines") {
  IronSkeletonText(lines: 4)
    .padding()
}

#Preview("IronSkeleton - Card") {
  IronSkeletonCard()
    .padding()
}

#Preview("IronSkeleton - List") {
  IronSkeletonList(count: 5)
    .padding()
}

#Preview("IronSkeleton - Profile Loading") {
  VStack(spacing: 16) {
    IronSkeleton(shape: .circle(size: 80))

    IronSkeleton(shape: .rounded(width: 150, height: 24, radius: 4))
    IronSkeleton(shape: .rounded(width: 100, height: 16, radius: 4))

    IronSkeletonText(lines: 3, lastLineRatio: 0.5)
      .frame(width: 250)
  }
  .padding()
}

#Preview("IronSkeleton - Static (No Animation)") {
  VStack(spacing: 16) {
    IronSkeleton(shape: .rounded(width: 200, height: 20, radius: 4), animated: false)
    IronSkeleton(shape: .circle(size: 48), animated: false)
  }
  .padding()
}
