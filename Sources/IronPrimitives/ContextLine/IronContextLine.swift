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
/// ## Leading Inset
///
/// By default, `IronContextLine` uses a font-relative inset (~8pt at body size)
/// that aligns well with typical icon widths. Both default and custom inset
/// values scale with Dynamic Type based on `insetRelativeTo`.
///
/// ```swift
/// // Default 8pt, scales with body text style
/// IronContextLine {
///   Text("On branch main")
/// }
///
/// // Custom 16pt, scales with body text style
/// IronContextLine(leadingInset: 16) {
///   Text("Larger inset, still scales")
/// }
///
/// // Custom 16pt, scales with headline text style
/// IronContextLine(leadingInset: 16, insetRelativeTo: .headline) {
///   Text("Scales with headline sizing")
/// }
///
/// // Fixed 16pt (no Dynamic Type scaling)
/// IronContextLine(leadingInset: 16, insetRelativeTo: nil) {
///   Text("Fixed value, no scaling")
/// }
///
/// // No inset (flush alignment)
/// IronContextLine(leadingInset: 0) {
///   Text("Flush left")
/// }
/// ```
///
/// ## Grouped Items
///
/// For multiple related items, use position to create connected branches:
///
/// ```swift
/// VStack(alignment: .leading, spacing: 0) {
///   Text("API Call")
///   IronContextLine(position: .first) { Text("Request sent") }
///   IronContextLine(position: .middle) { Text("Processing...") }
///   IronContextLine(position: .last) { Text("Response received") }
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
  ///   - leadingInset: Base inset value to align with parent icon. Defaults to 8pt.
  ///     This value is scaled by Dynamic Type according to `insetRelativeTo`.
  ///   - insetRelativeTo: The text style to scale the inset relative to.
  ///     Pass `nil` for no scaling (fixed value).
  ///   - content: The child content to display.
  public init(
    position: IronContextLinePosition = .single,
    style: IronContextLineStyle = .standard,
    leadingInset: CGFloat? = nil,
    insetRelativeTo: Font.TextStyle? = .body,
    @ViewBuilder content: () -> Content,
  ) {
    self.position = position
    self.style = style
    self.leadingInset = leadingInset
    self.insetRelativeTo = insetRelativeTo
    self.content = content()
    _isRevealed = .constant(true)
    animateReveal = false
  }

  /// Creates an animatable context line.
  ///
  /// - Parameters:
  ///   - position: The position in a group of context lines.
  ///   - style: The visual style of the connector.
  ///   - leadingInset: Base inset value to align with parent icon. Defaults to 8pt.
  ///     This value is scaled by Dynamic Type according to `insetRelativeTo`.
  ///   - insetRelativeTo: The text style to scale the inset relative to.
  ///     Pass `nil` for no scaling (fixed value).
  ///   - isRevealed: Binding to control visibility with animation.
  ///   - content: The child content to display.
  public init(
    position: IronContextLinePosition = .single,
    style: IronContextLineStyle = .standard,
    leadingInset: CGFloat? = nil,
    insetRelativeTo: Font.TextStyle? = .body,
    isRevealed: Binding<Bool>,
    @ViewBuilder content: () -> Content,
  ) {
    self.position = position
    self.style = style
    self.leadingInset = leadingInset
    self.insetRelativeTo = insetRelativeTo
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
    .padding(.leading, effectiveInset)
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

  /// Base inset value used for scaling calculations.
  private static var baseInsetValue: CGFloat {
    8
  }

  @Binding private var isRevealed: Bool
  @State private var contentHeight: CGFloat = 24

  @Environment(\.ironTheme) private var theme

  /// Scaled metrics for each text style, enabling Dynamic Type scaling.
  /// Base value is 8pt (~half an icon width at standard size).
  @ScaledMetric(relativeTo: .largeTitle)
  private var insetLargeTitle: CGFloat = 8
  @ScaledMetric(relativeTo: .title)
  private var insetTitle: CGFloat = 8
  @ScaledMetric(relativeTo: .title2)
  private var insetTitle2: CGFloat = 8
  @ScaledMetric(relativeTo: .title3)
  private var insetTitle3: CGFloat = 8
  @ScaledMetric(relativeTo: .headline)
  private var insetHeadline: CGFloat = 8
  @ScaledMetric(relativeTo: .subheadline)
  private var insetSubheadline: CGFloat = 8
  @ScaledMetric(relativeTo: .body)
  private var insetBody: CGFloat = 8
  @ScaledMetric(relativeTo: .callout)
  private var insetCallout: CGFloat = 8
  @ScaledMetric(relativeTo: .footnote)
  private var insetFootnote: CGFloat = 8
  @ScaledMetric(relativeTo: .caption)
  private var insetCaption: CGFloat = 8
  @ScaledMetric(relativeTo: .caption2)
  private var insetCaption2: CGFloat = 8

  private let position: IronContextLinePosition
  private let style: IronContextLineStyle
  private let leadingInset: CGFloat?
  private let insetRelativeTo: Font.TextStyle?
  private let content: Content
  private let animateReveal: Bool

  /// Effective inset: applies scaling to user-provided or default value.
  private var effectiveInset: CGFloat {
    // Determine the base value (user-provided or default)
    let baseValue = leadingInset ?? Self.baseInsetValue

    // If no text style specified, use fixed value (no scaling)
    guard let textStyle = insetRelativeTo else {
      return baseValue
    }

    // Apply Dynamic Type scaling to the base value
    return baseValue * scaleFactor(for: textStyle)
  }

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

  /// Returns the scaled inset for a given text style.
  private func scaledInset(for textStyle: Font.TextStyle) -> CGFloat {
    switch textStyle {
    case .largeTitle: return insetLargeTitle
    case .title: return insetTitle
    case .title2: return insetTitle2
    case .title3: return insetTitle3
    case .headline: return insetHeadline
    case .subheadline: return insetSubheadline
    case .body: return insetBody
    case .callout: return insetCallout
    case .footnote: return insetFootnote
    case .caption: return insetCaption
    case .caption2: return insetCaption2
    @unknown default: return insetBody
    }
  }

  /// Scale factor for a text style (how much the base value has been scaled by Dynamic Type).
  private func scaleFactor(for textStyle: Font.TextStyle) -> CGFloat {
    scaledInset(for: textStyle) / Self.baseInsetValue
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
///
/// ## Aligning with Parent Icons
///
/// ```swift
/// HStack(spacing: 8) {
///   Image(systemName: "list.bullet")
///   Text("Results")
/// }
/// IronContextGroup(leadingInset: 10) {
///   Text("Item 1")
///   Text("Item 2")
/// }
/// ```
public struct IronContextGroup<Content: View>: View {

  // MARK: Lifecycle

  /// Creates a context group with multiple items.
  ///
  /// - Parameters:
  ///   - style: The visual style for all lines.
  ///   - leadingInset: Base inset value to align with parent icon. Defaults to 8pt.
  ///     This value is scaled by Dynamic Type according to `insetRelativeTo`.
  ///   - insetRelativeTo: The text style to scale the inset relative to.
  ///     Pass `nil` for no scaling (fixed value).
  ///   - content: The child views to wrap in context lines.
  public init(
    style: IronContextLineStyle = .standard,
    leadingInset: CGFloat? = nil,
    insetRelativeTo: Font.TextStyle? = .body,
    @ViewBuilder content: () -> Content,
  ) {
    self.style = style
    self.leadingInset = leadingInset
    self.insetRelativeTo = insetRelativeTo
    self.content = content()
  }

  // MARK: Public

  public var body: some View {
    _VariadicView.Tree(
      IronContextGroupLayout(
        style: style,
        leadingInset: leadingInset,
        insetRelativeTo: insetRelativeTo,
      )
    ) {
      content
    }
  }

  // MARK: Private

  private let style: IronContextLineStyle
  private let leadingInset: CGFloat?
  private let insetRelativeTo: Font.TextStyle?
  private let content: Content
}

// MARK: - IronContextGroupLayout

private struct IronContextGroupLayout: _VariadicView_UnaryViewRoot {
  let style: IronContextLineStyle
  let leadingInset: CGFloat?
  let insetRelativeTo: Font.TextStyle?

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

        IronContextLine(
          position: position,
          style: style,
          leadingInset: leadingInset,
          insetRelativeTo: insetRelativeTo,
        ) {
          child
        }
      }
    }
  }
}

// MARK: - Previews

#Preview("IronContextLine - Single") {
  VStack(alignment: .leading, spacing: 0) {
    HStack(spacing: 8) {
      Image(systemName: "terminal")
      Text("Bash(git status)")
        .fontWeight(.medium)
    }
    .padding(.bottom, 4)

    // Default leadingInset is font-relative (~8pt at body size)
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

#Preview("IronContextLine - Inset Options") {
  VStack(alignment: .leading, spacing: 16) {
    VStack(alignment: .leading, spacing: 0) {
      Text("Default 8pt (scales with .body)")
        .font(.caption)
        .foregroundStyle(.secondary)
      IronContextLine {
        Text("Scales with Dynamic Type")
      }
    }

    VStack(alignment: .leading, spacing: 0) {
      Text("Custom 16pt (scales with .body)")
        .font(.caption)
        .foregroundStyle(.secondary)
      IronContextLine(leadingInset: 16) {
        Text("Larger inset, still scales")
      }
    }

    VStack(alignment: .leading, spacing: 0) {
      Text("Custom 16pt (scales with .headline)")
        .font(.caption)
        .foregroundStyle(.secondary)
      IronContextLine(leadingInset: 16, insetRelativeTo: .headline) {
        Text("Scales with headline sizing")
      }
    }

    VStack(alignment: .leading, spacing: 0) {
      Text("Fixed 16pt (insetRelativeTo: nil)")
        .font(.caption)
        .foregroundStyle(.secondary)
      IronContextLine(leadingInset: 16, insetRelativeTo: nil) {
        Text("No Dynamic Type scaling")
      }
    }

    VStack(alignment: .leading, spacing: 0) {
      Text("No inset (leadingInset: 0)")
        .font(.caption)
        .foregroundStyle(.secondary)
      IronContextLine(leadingInset: 0) {
        Text("Flush to leading edge")
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
  @Previewable @State var isRevealed = false

  return VStack(alignment: .leading, spacing: 8) {
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
