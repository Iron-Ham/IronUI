import IronCore
import SwiftUI

// MARK: - IronResponsiveStack

/// A stack that switches between horizontal and vertical layout based on available space.
///
/// `IronResponsiveStack` automatically adapts its layout direction based on
/// whether children can fit horizontally. This is useful for responsive designs
/// where you want items side-by-side on wide screens but stacked on narrow screens.
///
/// ## Basic Usage
///
/// ```swift
/// IronResponsiveStack {
///   Text("Label")
///   TextField("Value", text: $value)
/// }
/// ```
///
/// ## With Threshold
///
/// Specify a minimum width for horizontal layout:
///
/// ```swift
/// IronResponsiveStack(threshold: 400) {
///   ProfileImage()
///   ProfileDetails()
/// }
/// ```
///
/// ## Custom Spacing and Alignment
///
/// ```swift
/// IronResponsiveStack(
///   horizontalSpacing: 16,
///   verticalSpacing: 12,
///   horizontalAlignment: .top,
///   verticalAlignment: .leading
/// ) {
///   // Content...
/// }
/// ```
public struct IronResponsiveStack<Content: View>: View {

  // MARK: Lifecycle

  /// Creates a responsive stack with specified layout parameters.
  ///
  /// - Parameters:
  ///   - threshold: Minimum width to use horizontal layout. If nil, calculates based on content.
  ///   - horizontalSpacing: Spacing when horizontal.
  ///   - verticalSpacing: Spacing when vertical.
  ///   - horizontalAlignment: Vertical alignment when horizontal.
  ///   - verticalAlignment: Horizontal alignment when vertical.
  ///   - content: The content views.
  public init(
    threshold: CGFloat? = nil,
    horizontalSpacing: CGFloat = 8,
    verticalSpacing: CGFloat = 8,
    horizontalAlignment: VerticalAlignment = .center,
    verticalAlignment: HorizontalAlignment = .leading,
    @ViewBuilder content: () -> Content,
  ) {
    self.threshold = threshold
    self.horizontalSpacing = horizontalSpacing
    self.verticalSpacing = verticalSpacing
    self.horizontalAlignment = horizontalAlignment
    self.verticalAlignment = verticalAlignment
    self.content = content()
  }

  // MARK: Public

  public var body: some View {
    GeometryReader { geometry in
      let isHorizontal = shouldBeHorizontal(width: geometry.size.width)

      Group {
        if isHorizontal {
          HStack(alignment: horizontalAlignment, spacing: horizontalSpacing) {
            content
          }
        } else {
          VStack(alignment: verticalAlignment, spacing: verticalSpacing) {
            content
          }
        }
      }
      .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment(isHorizontal: isHorizontal))
    }
  }

  // MARK: Private

  private let threshold: CGFloat?
  private let horizontalSpacing: CGFloat
  private let verticalSpacing: CGFloat
  private let horizontalAlignment: VerticalAlignment
  private let verticalAlignment: HorizontalAlignment
  private let content: Content

  private func shouldBeHorizontal(width: CGFloat) -> Bool {
    if let threshold {
      return width >= threshold
    }
    // Default: horizontal on wider screens
    return width >= 500
  }

  private func alignment(isHorizontal: Bool) -> Alignment {
    if isHorizontal {
      switch verticalAlignment {
      case .leading: .leading
      case .trailing: .trailing
      case .center: .center
      default: .leading
      }
    } else {
      switch horizontalAlignment {
      case .top: .top
      case .bottom: .bottom
      case .center: .center
      default: .top
      }
    }
  }
}

// MARK: - IronAdaptiveStack

/// A stack that uses ViewThatFits to choose between horizontal and vertical layout.
///
/// Unlike `IronResponsiveStack` which uses a threshold, `IronAdaptiveStack`
/// measures actual content to determine if horizontal layout fits.
///
/// ## Usage
///
/// ```swift
/// IronAdaptiveStack {
///   Button("Cancel") { }
///   Button("Save") { }
///   Button("Delete") { }
/// }
/// ```
///
/// On wide screens, buttons appear side-by-side.
/// On narrow screens, buttons stack vertically.
public struct IronAdaptiveStack<Content: View>: View {

  // MARK: Lifecycle

  /// Creates an adaptive stack.
  ///
  /// - Parameters:
  ///   - horizontalSpacing: Spacing when horizontal.
  ///   - verticalSpacing: Spacing when vertical.
  ///   - horizontalAlignment: Vertical alignment when horizontal.
  ///   - verticalAlignment: Horizontal alignment when vertical.
  ///   - content: The content views.
  public init(
    horizontalSpacing: CGFloat = 8,
    verticalSpacing: CGFloat = 8,
    horizontalAlignment: VerticalAlignment = .center,
    verticalAlignment: HorizontalAlignment = .center,
    @ViewBuilder content: () -> Content,
  ) {
    self.horizontalSpacing = horizontalSpacing
    self.verticalSpacing = verticalSpacing
    self.horizontalAlignment = horizontalAlignment
    self.verticalAlignment = verticalAlignment
    self.content = content()
  }

  // MARK: Public

  public var body: some View {
    ViewThatFits(in: .horizontal) {
      HStack(alignment: horizontalAlignment, spacing: horizontalSpacing) {
        content
      }
      VStack(alignment: verticalAlignment, spacing: verticalSpacing) {
        content
      }
    }
  }

  // MARK: Private

  private let horizontalSpacing: CGFloat
  private let verticalSpacing: CGFloat
  private let horizontalAlignment: VerticalAlignment
  private let verticalAlignment: HorizontalAlignment
  private let content: Content
}

// MARK: - IronSizeClassStack

/// A stack that switches layout based on horizontal size class.
///
/// Uses system size class (compact vs regular) to determine layout.
/// Ideal for iPad split view and iPhone rotation handling.
///
/// ## Usage
///
/// ```swift
/// IronSizeClassStack {
///   Sidebar()
///   DetailView()
/// }
/// ```
public struct IronSizeClassStack<Content: View>: View {

  // MARK: Lifecycle

  /// Creates a size class responsive stack.
  ///
  /// - Parameters:
  ///   - compactLayout: Layout to use in compact width. Defaults to vertical.
  ///   - regularLayout: Layout to use in regular width. Defaults to horizontal.
  ///   - horizontalSpacing: Spacing when horizontal.
  ///   - verticalSpacing: Spacing when vertical.
  ///   - content: The content views.
  public init(
    compactLayout: LayoutDirection = .vertical,
    regularLayout: LayoutDirection = .horizontal,
    horizontalSpacing: CGFloat = 16,
    verticalSpacing: CGFloat = 16,
    @ViewBuilder content: () -> Content,
  ) {
    self.compactLayout = compactLayout
    self.regularLayout = regularLayout
    self.horizontalSpacing = horizontalSpacing
    self.verticalSpacing = verticalSpacing
    self.content = content()
  }

  // MARK: Public

  /// Layout direction options.
  public enum LayoutDirection: Sendable {
    case horizontal
    case vertical
  }

  public var body: some View {
    Group {
      #if os(iOS)
      if sizeClass == .compact {
        layoutView(for: compactLayout)
      } else {
        layoutView(for: regularLayout)
      }
      #else
      layoutView(for: regularLayout)
      #endif
    }
  }

  // MARK: Private

  #if os(iOS)
  @Environment(\.horizontalSizeClass) private var sizeClass
  #endif

  private let compactLayout: LayoutDirection
  private let regularLayout: LayoutDirection
  private let horizontalSpacing: CGFloat
  private let verticalSpacing: CGFloat
  private let content: Content

  @ViewBuilder
  private func layoutView(for direction: LayoutDirection) -> some View {
    switch direction {
    case .horizontal:
      HStack(spacing: horizontalSpacing) {
        content
      }

    case .vertical:
      VStack(spacing: verticalSpacing) {
        content
      }
    }
  }
}

// MARK: - Previews

#Preview("IronResponsiveStack") {
  VStack(spacing: 32) {
    Text("Resize window to see layout change")
      .font(.headline)

    IronResponsiveStack(threshold: 300) {
      Text("Item 1")
        .padding()
        .background(Color.blue.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 8))

      Text("Item 2")
        .padding()
        .background(Color.green.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 8))

      Text("Item 3")
        .padding()
        .background(Color.orange.opacity(0.2))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
    .frame(height: 150)
    .background(Color.gray.opacity(0.1))
  }
  .padding()
}

#Preview("IronAdaptiveStack - Buttons") {
  VStack(spacing: 24) {
    Text("Buttons adapt to available space")
      .font(.headline)

    IronAdaptiveStack(horizontalSpacing: 12, verticalSpacing: 8) {
      Button("Cancel") { }
        .buttonStyle(.bordered)
      Button("Save") { }
        .buttonStyle(.borderedProminent)
      Button("Delete") { }
        .buttonStyle(.bordered)
        .tint(.red)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 12))
  }
  .padding()
}

#Preview("IronAdaptiveStack - Form Fields") {
  VStack(spacing: 16) {
    IronAdaptiveStack(horizontalSpacing: 16, verticalSpacing: 8) {
      Text("Username")
        .frame(width: 100, alignment: .trailing)
      TextField("Enter username", text: .constant(""))
        .textFieldStyle(.roundedBorder)
    }

    IronAdaptiveStack(horizontalSpacing: 16, verticalSpacing: 8) {
      Text("Email")
        .frame(width: 100, alignment: .trailing)
      TextField("Enter email", text: .constant(""))
        .textFieldStyle(.roundedBorder)
    }

    IronAdaptiveStack(horizontalSpacing: 16, verticalSpacing: 8) {
      Text("Password")
        .frame(width: 100, alignment: .trailing)
      SecureField("Enter password", text: .constant(""))
        .textFieldStyle(.roundedBorder)
    }
  }
  .padding()
}

#Preview("IronSizeClassStack") {
  IronSizeClassStack {
    VStack {
      Text("Sidebar")
        .font(.headline)
      Text("Navigation items here")
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.blue.opacity(0.1))

    VStack {
      Text("Detail View")
        .font(.headline)
      Text("Main content here")
        .foregroundStyle(.secondary)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.green.opacity(0.1))
  }
}
