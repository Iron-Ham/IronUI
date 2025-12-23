import IronCore
import SwiftUI

// MARK: - IronContainer

/// A responsive container that constrains content width and applies consistent padding.
///
/// `IronContainer` provides a centered content area with:
/// - Maximum width constraints for readability on large screens
/// - Consistent horizontal padding that adapts to screen size
/// - Vertical padding options for section spacing
///
/// ## Basic Usage
///
/// ```swift
/// IronContainer {
///   VStack(alignment: .leading, spacing: 16) {
///     Text("Welcome")
///       .font(.largeTitle)
///     Text("This content is centered and constrained.")
///   }
/// }
/// ```
///
/// ## Content Widths
///
/// ```swift
/// IronContainer(maxWidth: .narrow) { ... }   // 480pt - forms, dialogs
/// IronContainer(maxWidth: .standard) { ... } // 720pt - articles, content
/// IronContainer(maxWidth: .wide) { ... }     // 1024pt - dashboards
/// IronContainer(maxWidth: .full) { ... }     // No constraint
/// ```
///
/// ## Padding Styles
///
/// ```swift
/// IronContainer(padding: .none) { ... }      // No padding
/// IronContainer(padding: .horizontal) { ... } // Side padding only
/// IronContainer(padding: .all) { ... }       // Full padding (default)
/// ```
public struct IronContainer<Content: View>: View {

  // MARK: Lifecycle

  /// Creates a container with specified constraints.
  ///
  /// - Parameters:
  ///   - maxWidth: The maximum width constraint.
  ///   - padding: The padding style to apply.
  ///   - alignment: The horizontal alignment of content.
  ///   - content: The content to contain.
  public init(
    maxWidth: IronContainerWidth = .standard,
    padding: IronContainerPadding = .all,
    alignment: HorizontalAlignment = .center,
    @ViewBuilder content: () -> Content,
  ) {
    self.maxWidth = maxWidth
    self.padding = padding
    self.alignment = alignment
    self.content = content()
  }

  // MARK: Public

  public var body: some View {
    content
      .frame(maxWidth: maxWidthValue, alignment: Alignment(horizontal: alignment, vertical: .center))
      .padding(.horizontal, horizontalPadding)
      .padding(.vertical, verticalPadding)
      .frame(maxWidth: .infinity, alignment: Alignment(horizontal: alignment, vertical: .center))
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
  @Environment(\.horizontalSizeClass) private var sizeClass

  private let maxWidth: IronContainerWidth
  private let padding: IronContainerPadding
  private let alignment: HorizontalAlignment
  private let content: Content

  private var maxWidthValue: CGFloat? {
    switch maxWidth {
    case .narrow: 480
    case .standard: 720
    case .wide: 1024
    case .full: nil
    case .custom(let value): value
    }
  }

  private var horizontalPadding: CGFloat {
    switch padding {
    case .none:
      theme.spacing.none
    case .horizontal, .all:
      adaptivePadding
    }
  }

  private var verticalPadding: CGFloat {
    switch padding {
    case .none, .horizontal:
      theme.spacing.none
    case .all:
      theme.spacing.lg
    }
  }

  /// Adapts horizontal padding based on size class.
  private var adaptivePadding: CGFloat {
    #if os(iOS)
    switch sizeClass {
    case .compact:
      theme.spacing.md
    case .regular:
      theme.spacing.xl
    default:
      theme.spacing.md
    }
    #else
    theme.spacing.xl
    #endif
  }
}

// MARK: - IronContainerWidth

/// Maximum width constraints for `IronContainer`.
public enum IronContainerWidth: Sendable {
  /// Narrow width (480pt) - ideal for forms, dialogs.
  case narrow
  /// Standard width (720pt) - ideal for articles, content.
  case standard
  /// Wide width (1024pt) - ideal for dashboards.
  case wide
  /// Full width - no maximum constraint.
  case full
  /// Custom maximum width.
  case custom(CGFloat)
}

// MARK: - IronContainerPadding

/// Padding styles for `IronContainer`.
public enum IronContainerPadding: Sendable {
  /// No padding.
  case none
  /// Horizontal padding only.
  case horizontal
  /// Full padding (horizontal and vertical).
  case all
}

// MARK: - Previews

#Preview("IronContainer - Basic") {
  ScrollView {
    VStack(spacing: 24) {
      IronContainer {
        VStack(alignment: .leading, spacing: 12) {
          Text("Welcome to IronUI")
            .font(.largeTitle)
            .fontWeight(.bold)
          Text("This content is centered within a standard-width container with adaptive padding.")
            .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
      .background(Color.blue.opacity(0.1))

      IronContainer {
        Text("Another section of content in its own container.")
          .frame(maxWidth: .infinity, alignment: .leading)
      }
      .background(Color.green.opacity(0.1))
    }
  }
}

#Preview("IronContainer - Widths") {
  ScrollView {
    VStack(spacing: 16) {
      IronContainer(maxWidth: .narrow) {
        Text("Narrow (480pt)")
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.red.opacity(0.2))
      }

      IronContainer(maxWidth: .standard) {
        Text("Standard (720pt)")
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.orange.opacity(0.2))
      }

      IronContainer(maxWidth: .wide) {
        Text("Wide (1024pt)")
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.green.opacity(0.2))
      }

      IronContainer(maxWidth: .full) {
        Text("Full Width")
          .frame(maxWidth: .infinity)
          .padding()
          .background(Color.blue.opacity(0.2))
      }
    }
  }
}

#Preview("IronContainer - Padding Styles") {
  VStack(spacing: 0) {
    IronContainer(padding: .none) {
      Text("No padding")
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.red.opacity(0.2))
    }
    .background(Color.gray.opacity(0.1))

    Divider()

    IronContainer(padding: .horizontal) {
      Text("Horizontal padding only")
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.orange.opacity(0.2))
    }
    .background(Color.gray.opacity(0.1))

    Divider()

    IronContainer(padding: .all) {
      Text("Full padding")
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color.green.opacity(0.2))
    }
    .background(Color.gray.opacity(0.1))
  }
}
