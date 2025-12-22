import IronCore
import SwiftUI

// MARK: - IronContextLine

/// A visual connector line that shows hierarchical or contextual relationships.
///
/// `IronContextLine` creates a curved "branch" indicator commonly seen in
/// tree views, conversation threads, and nested content displays. It visually
/// connects parent content to child/result content.
///
/// ## Basic Usage
///
/// ```swift
/// VStack(alignment: .leading) {
///   Text("Parent Action")
///   IronContextLine {
///     Text("Child Result")
///   }
/// }
/// ```
///
/// ## Grouped Items
///
/// For multiple related items, use position to create connected branches:
///
/// ```swift
/// VStack(alignment: .leading) {
///   Text("API Call")
///   IronContextLine(position: .first) {
///     Text("Request sent")
///   }
///   IronContextLine(position: .middle) {
///     Text("Processing...")
///   }
///   IronContextLine(position: .last) {
///     Text("Response received")
///   }
/// }
/// ```
///
/// ## Animated Reveal
///
/// ```swift
/// IronContextLine(isRevealed: $showResult) {
///   Text("Async result")
/// }
/// ```
public struct IronContextLine<Content: View>: View {

  // MARK: Lifecycle

  /// Creates a context line with child content.
  ///
  /// - Parameters:
  ///   - position: The position in a group of context lines.
  ///   - style: The visual style of the connector.
  ///   - content: The child content to display.
  public init(
    position: IronContextLinePosition = .single,
    style: IronContextLineStyle = .standard,
    @ViewBuilder content: () -> Content,
  ) {
    self.position = position
    self.style = style
    self.content = content()
    _isRevealed = .constant(true)
    animateReveal = false
  }

  /// Creates an animatable context line.
  ///
  /// - Parameters:
  ///   - position: The position in a group of context lines.
  ///   - style: The visual style of the connector.
  ///   - isRevealed: Binding to control visibility with animation.
  ///   - content: The child content to display.
  public init(
    position: IronContextLinePosition = .single,
    style: IronContextLineStyle = .standard,
    isRevealed: Binding<Bool>,
    @ViewBuilder content: () -> Content,
  ) {
    self.position = position
    self.style = style
    self.content = content()
    _isRevealed = isRevealed
    animateReveal = true
  }

  // MARK: Public

  public var body: some View {
    HStack(alignment: .center, spacing: 0) {
      // The connector line
      ContextLineShape(position: position)
        .stroke(lineColor, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
        .frame(width: branchWidth, height: contentHeight)
        .opacity(animateReveal ? (isRevealed ? 1 : 0) : 1)

      // Child content
      content
        .opacity(animateReveal ? (isRevealed ? 1 : 0) : 1)
        .offset(y: animateReveal ? (isRevealed ? 0 : -8) : 0)
    }
    .background(
      GeometryReader { geometry in
        Color.clear.preference(
          key: ContentHeightPreferenceKey.self,
          value: geometry.size.height,
        )
      }
    )
    .onPreferenceChange(ContentHeightPreferenceKey.self) { height in
      contentHeight = max(height, minHeight)
    }
    .animation(animateReveal ? theme.animation.smooth : nil, value: isRevealed)
  }

  // MARK: Private

  @Binding private var isRevealed: Bool
  @State private var contentHeight: CGFloat = 24

  @Environment(\.ironTheme) private var theme

  private let position: IronContextLinePosition
  private let style: IronContextLineStyle
  private let content: Content
  private let animateReveal: Bool

  private var lineColor: Color {
    switch style {
    case .subtle: theme.colors.divider.opacity(0.5)
    case .standard: theme.colors.divider
    case .prominent: theme.colors.border
    case .accent: theme.colors.primary.opacity(0.6)
    case .success: theme.colors.success.opacity(0.6)
    case .error: theme.colors.error.opacity(0.6)
    case .custom(let color): color
    }
  }

  private var lineWidth: CGFloat {
    switch style {
    case .subtle: 1
    case .standard: 1.5
    case .prominent: 2
    default: 1.5
    }
  }

  /// Width of the connector shape (vertical line + horizontal branch)
  private var branchWidth: CGFloat {
    theme.spacing.lg // 24pt gives nice visual connection
  }

  private var minHeight: CGFloat {
    24
  }
}

// MARK: - ContextLineShape

/// Custom shape that draws the curved connector line.
///
/// The shape draws connectors that form a tree structure:
/// ```
/// ├── First item    (.first)
/// │
/// ├── Middle item   (.middle)
/// │
/// └── Last item     (.last)
/// ```
private struct ContextLineShape: Shape {
  let position: IronContextLinePosition

  func path(in rect: CGRect) -> Path {
    var path = Path()

    let lineX = rect.minX
    let curveRadius = min(8, rect.height / 4)
    let branchY = rect.midY

    switch position {
    case .single:
      // Single item: vertical from top to branch point, then curves right
      // │
      // └──
      path.move(to: CGPoint(x: lineX, y: rect.minY))
      path.addLine(to: CGPoint(x: lineX, y: branchY - curveRadius))
      path.addQuadCurve(
        to: CGPoint(x: lineX + curveRadius, y: branchY),
        control: CGPoint(x: lineX, y: branchY),
      )
      path.addLine(to: CGPoint(x: rect.maxX, y: branchY))

    case .first:
      // First in group: vertical line full height + horizontal branch at midY
      // ├── content
      // │
      path.move(to: CGPoint(x: lineX, y: rect.minY))
      path.addLine(to: CGPoint(x: lineX, y: rect.maxY))
      // Horizontal branch
      path.move(to: CGPoint(x: lineX, y: branchY))
      path.addLine(to: CGPoint(x: rect.maxX, y: branchY))

    case .middle:
      // Middle item: vertical line full height + horizontal branch
      // │
      // ├── content
      // │
      path.move(to: CGPoint(x: lineX, y: rect.minY))
      path.addLine(to: CGPoint(x: lineX, y: rect.maxY))
      // Horizontal branch
      path.move(to: CGPoint(x: lineX, y: branchY))
      path.addLine(to: CGPoint(x: rect.maxX, y: branchY))

    case .last:
      // Last item: vertical from top to branch, then curves right
      // │
      // └── content
      path.move(to: CGPoint(x: lineX, y: rect.minY))
      path.addLine(to: CGPoint(x: lineX, y: branchY - curveRadius))
      path.addQuadCurve(
        to: CGPoint(x: lineX + curveRadius, y: branchY),
        control: CGPoint(x: lineX, y: branchY),
      )
      path.addLine(to: CGPoint(x: rect.maxX, y: branchY))

    case .continuation:
      // Just a vertical line (for items that have children below)
      // │
      // │
      path.move(to: CGPoint(x: lineX, y: rect.minY))
      path.addLine(to: CGPoint(x: lineX, y: rect.maxY))
    }

    return path
  }
}

// MARK: - ContentHeightPreferenceKey

private struct ContentHeightPreferenceKey: PreferenceKey {
  static let defaultValue: CGFloat = 24

  static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
    value = max(value, nextValue())
  }
}

// MARK: - IronContextLinePosition

/// Position of a context line within a group of related items.
public enum IronContextLinePosition: Sendable, CaseIterable {
  /// A standalone item with no siblings.
  case single
  /// First item in a group (line continues below).
  case first
  /// Middle item in a group (line continues above and below).
  case middle
  /// Last item in a group (line ends here).
  case last
  /// Continuation line only (no horizontal branch).
  case continuation
}

// MARK: - IronContextLineStyle

/// Visual styles for `IronContextLine`.
public enum IronContextLineStyle: Sendable, Equatable {
  /// A subtle, low-contrast line.
  case subtle
  /// The standard line appearance.
  case standard
  /// A more prominent, thicker line.
  case prominent
  /// Uses the accent/primary color.
  case accent
  /// Uses the success color (for positive results).
  case success
  /// Uses the error color (for failures).
  case error
  /// Custom color.
  case custom(Color)
}

// MARK: CaseIterable

extension IronContextLineStyle: CaseIterable {
  public static var allCases: [IronContextLineStyle] {
    [.subtle, .standard, .prominent, .accent, .success, .error]
  }
}

// MARK: - Convenience Modifiers

extension IronContextLine {
  /// Sets the context line style.
  public func contextLineStyle(_ style: IronContextLineStyle) -> IronContextLine {
    IronContextLine(position: position, style: style) { content }
  }
}

// MARK: - ContextLineContinuation

/// A simple vertical continuation line for manual nesting scenarios.
///
/// Use this when you need to show a continuation line alongside nested content:
///
/// ```swift
/// HStack(alignment: .top, spacing: 0) {
///   ContextLineContinuation()
///   VStack {
///     // nested items
///   }
/// }
/// ```
struct ContextLineContinuation: View {
  var body: some View {
    Rectangle()
      .fill(theme.colors.divider)
      .frame(width: 1.5)
      .frame(width: theme.spacing.lg, alignment: .leading)
  }

  @Environment(\.ironTheme) private var theme

}

// MARK: - IronContextGroup

/// A container that automatically assigns positions to child context lines.
///
/// Use this to simplify creating groups of related context lines:
///
/// ```swift
/// IronContextGroup {
///   Text("First result")
///   Text("Second result")
///   Text("Third result")
/// }
/// ```
public struct IronContextGroup<Content: View>: View {

  // MARK: Lifecycle

  /// Creates a context group with multiple items.
  ///
  /// - Parameters:
  ///   - style: The visual style for all lines.
  ///   - content: The child views to wrap in context lines.
  public init(
    style: IronContextLineStyle = .standard,
    @ViewBuilder content: () -> Content,
  ) {
    self.style = style
    self.content = content()
  }

  // MARK: Public

  public var body: some View {
    _VariadicView.Tree(IronContextGroupLayout(style: style)) {
      content
    }
  }

  // MARK: Private

  private let style: IronContextLineStyle
  private let content: Content
}

// MARK: - IronContextGroupLayout

private struct IronContextGroupLayout: _VariadicView_UnaryViewRoot {
  let style: IronContextLineStyle

  @ViewBuilder
  func body(children: _VariadicView.Children) -> some View {
    let count = children.count

    VStack(alignment: .leading, spacing: 0) {
      ForEach(Array(children.enumerated()), id: \.element.id) { index, child in
        let position: IronContextLinePosition = {
          if count == 1 { return .single }
          if index == 0 { return .first }
          if index == count - 1 { return .last }
          return .middle
        }()

        IronContextLine(position: position, style: style) {
          child
        }
      }
    }
  }
}

// MARK: - Previews

#Preview("IronContextLine - Single") {
  VStack(alignment: .leading, spacing: 8) {
    HStack(spacing: 8) {
      Image(systemName: "terminal")
      Text("Bash(git status)")
        .fontWeight(.medium)
    }
    IronContextLine {
      Text("On branch main, nothing to commit")
        .foregroundStyle(.secondary)
    }
  }
  .padding()
}

#Preview("IronContextLine - Group") {
  VStack(alignment: .leading, spacing: 0) {
    HStack(spacing: 8) {
      Image(systemName: "network")
      Text("API Request")
        .fontWeight(.medium)
    }
    .padding(.bottom, 4)

    // Use spacing: 0 between context lines so they connect!
    IronContextLine(position: .first) {
      HStack(spacing: 4) {
        Image(systemName: "arrow.up.circle")
        Text("Request sent")
      }
      .foregroundStyle(.secondary)
    }
    IronContextLine(position: .middle) {
      HStack(spacing: 4) {
        Image(systemName: "clock")
        Text("Processing...")
      }
      .foregroundStyle(.secondary)
    }
    IronContextLine(position: .last, style: .success) {
      HStack(spacing: 4) {
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(.green)
        Text("200 OK")
      }
    }
  }
  .padding()
}

#Preview("IronContextLine - Styles") {
  VStack(alignment: .leading, spacing: 16) {
    IronContextLine(style: .subtle) {
      Text("Subtle")
    }
    IronContextLine(style: .standard) {
      Text("Standard")
    }
    IronContextLine(style: .prominent) {
      Text("Prominent")
    }
    IronContextLine(style: .accent) {
      Text("Accent")
    }
    IronContextLine(style: .success) {
      Text("Success")
    }
    IronContextLine(style: .error) {
      Text("Error")
    }
  }
  .padding()
}

#Preview("IronContextLine - Nested") {
  VStack(alignment: .leading, spacing: 0) {
    HStack(spacing: 8) {
      Image(systemName: "folder")
      Text("Build Project")
        .fontWeight(.medium)
    }
    .padding(.bottom, 4)

    // First level: Compiling with continuation line
    IronContextLine(position: .continuation) {
      Text("Compiling sources...")
    }

    // Nested items (further indented by being inside another context)
    HStack(alignment: .top, spacing: 0) {
      // Continuation line for the parent level
      ContextLineContinuation()

      VStack(alignment: .leading, spacing: 0) {
        IronContextLine(position: .first) {
          Text("Module A ✓")
            .foregroundStyle(.secondary)
        }
        IronContextLine(position: .last) {
          Text("Module B ✓")
            .foregroundStyle(.secondary)
        }
      }
    }

    // Final result
    IronContextLine(position: .last, style: .success) {
      HStack(spacing: 4) {
        Image(systemName: "checkmark.circle.fill")
          .foregroundStyle(.green)
        Text("Build succeeded")
      }
    }
  }
  .padding()
}

#Preview("IronContextGroup") {
  VStack(alignment: .leading, spacing: 8) {
    HStack(spacing: 8) {
      Image(systemName: "list.bullet")
      Text("Results")
        .fontWeight(.medium)
    }
    IronContextGroup {
      Text("First item")
      Text("Second item")
      Text("Third item")
    }
  }
  .padding()
}

#Preview("IronContextLine - Animated") {
  struct AnimatedDemo: View {
    @State private var isRevealed = false

    var body: some View {
      VStack(alignment: .leading, spacing: 8) {
        Button("Toggle Result") {
          isRevealed.toggle()
        }
        .buttonStyle(.borderedProminent)

        HStack(spacing: 8) {
          Image(systemName: "terminal")
          Text("Long running task")
            .fontWeight(.medium)
        }

        IronContextLine(isRevealed: $isRevealed) {
          HStack(spacing: 4) {
            Image(systemName: "checkmark.circle.fill")
              .foregroundStyle(.green)
            Text("Task completed!")
          }
        }
      }
      .padding()
    }
  }

  return AnimatedDemo()
}
