import IronCore
import IronPrimitives
import SwiftUI

// MARK: - IronTimeline

/// A vertical event timeline for displaying chronological entries.
///
/// `IronTimeline` displays a series of entries connected by a vertical line,
/// with customizable node indicators and layout options.
///
/// ## Basic Usage
///
/// ```swift
/// IronTimeline(entries: events) { event in
///   IronTimelineEntry(
///     title: event.title,
///     subtitle: event.description,
///     timestamp: event.date
///   )
/// }
/// ```
///
/// ## Custom Node Indicators
///
/// ```swift
/// IronTimeline(entries: events) { event in
///   IronTimelineEntry(
///     title: event.title,
///     node: .icon(systemName: "checkmark.circle.fill", color: .success)
///   )
/// }
/// ```
///
/// ## Alternating Layout
///
/// ```swift
/// IronTimeline(entries: events, layout: .alternating) { event in
///   IronTimelineEntry(title: event.title)
/// }
/// ```
public struct IronTimeline<Entry: Identifiable, Content: View>: View {

  // MARK: Lifecycle

  /// Creates a timeline with the specified entries.
  ///
  /// - Parameters:
  ///   - entries: The array of entries to display.
  ///   - layout: The layout style for entries. Defaults to `.leading`.
  ///   - connectorStyle: The style of the connecting line. Defaults to `.solid`.
  ///   - content: A view builder that creates content for each entry.
  public init(
    entries: [Entry],
    layout: IronTimelineLayout = .leading,
    connectorStyle: IronTimelineConnectorStyle = .solid,
    @ViewBuilder content: @escaping (Entry) -> Content,
  ) {
    self.entries = entries
    self.layout = layout
    self.connectorStyle = connectorStyle
    self.content = content
  }

  // MARK: Public

  public var body: some View {
    VStack(alignment: layoutAlignment, spacing: 0) {
      ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
        TimelineRow(
          entry: entry,
          index: index,
          isLast: index == entries.count - 1,
          layout: layout,
          connectorStyle: connectorStyle,
          content: content,
        )
      }
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Timeline with \(entries.count) entries")
  }

  // MARK: Private

  private let entries: [Entry]
  private let layout: IronTimelineLayout
  private let connectorStyle: IronTimelineConnectorStyle
  private let content: (Entry) -> Content

  private var layoutAlignment: HorizontalAlignment {
    switch layout {
    case .leading: .leading
    case .alternating: .center
    case .trailing: .trailing
    }
  }
}

// MARK: - TimelineRow

/// Internal view for a single timeline row with connector.
private struct TimelineRow<Entry: Identifiable, Content: View>: View {

  // MARK: Internal

  let entry: Entry
  let index: Int
  let isLast: Bool
  let layout: IronTimelineLayout
  let connectorStyle: IronTimelineConnectorStyle
  let content: (Entry) -> Content

  var body: some View {
    HStack(alignment: .top, spacing: theme.spacing.md) {
      switch layout {
      case .leading:
        connectorColumn
        content(entry)
          .frame(maxWidth: .infinity, alignment: .leading)

      case .trailing:
        content(entry)
          .frame(maxWidth: .infinity, alignment: .trailing)
        connectorColumn

      case .alternating:
        if index.isMultiple(of: 2) {
          content(entry)
            .frame(maxWidth: .infinity, alignment: .trailing)
          connectorColumn
          Color.clear
            .frame(maxWidth: .infinity)
        } else {
          Color.clear
            .frame(maxWidth: .infinity)
          connectorColumn
          content(entry)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
      }
    }
    .accessibilityElement(children: .combine)
    .accessibilityLabel("Entry \(index + 1) of \(index + 1)")
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  @ScaledMetric(relativeTo: .body)
  private var connectorWidth: CGFloat = 2
  @ScaledMetric(relativeTo: .body)
  private var nodeSize: CGFloat = 12

  private var connectorColumn: some View {
    VStack(spacing: 0) {
      // Connector line spans the full height, node is rendered by IronTimelineEntry
      if index > 0 || !isLast {
        connectorLine
          .frame(maxHeight: .infinity)
      }
    }
    .frame(width: connectorWidth)
    .padding(.top, theme.spacing.sm + (nodeSize / 2)) // Align with center of entry's node
  }

  @ViewBuilder
  private var connectorLine: some View {
    switch connectorStyle {
    case .solid:
      Rectangle()
        .fill(theme.colors.border)
        .frame(width: connectorWidth)

    case .dashed:
      DashedLine()
        .stroke(theme.colors.border, style: StrokeStyle(lineWidth: connectorWidth, dash: [4, 4]))
        .frame(width: connectorWidth)

    case .dotted:
      DashedLine()
        .stroke(theme.colors.border, style: StrokeStyle(lineWidth: connectorWidth, dash: [2, 4]))
        .frame(width: connectorWidth)

    case .hidden:
      Color.clear
        .frame(width: connectorWidth)
    }
  }
}

// MARK: - DashedLine

/// A simple vertical line shape for dashed/dotted connectors.
private struct DashedLine: Shape {
  func path(in rect: CGRect) -> Path {
    var path = Path()
    path.move(to: CGPoint(x: rect.midX, y: rect.minY))
    path.addLine(to: CGPoint(x: rect.midX, y: rect.maxY))
    return path
  }
}

// MARK: - IronTimelineEntry

/// A single entry in an IronTimeline.
///
/// `IronTimelineEntry` provides a consistent structure for timeline content
/// with customizable node indicators, titles, subtitles, and timestamps.
///
/// ## Basic Usage
///
/// ```swift
/// IronTimelineEntry(
///   title: "Order Placed",
///   subtitle: "Your order has been confirmed",
///   timestamp: orderDate
/// )
/// ```
///
/// ## With Custom Node
///
/// ```swift
/// IronTimelineEntry(
///   title: "Completed",
///   node: .icon(systemName: "checkmark.circle.fill", color: .success)
/// )
/// ```
///
/// ## With Custom Content
///
/// ```swift
/// IronTimelineEntry(node: .dot(color: .primary)) {
///   VStack(alignment: .leading) {
///     IronText("Custom content here", style: .bodyLarge)
///     IronButton("Action", variant: .outlined, size: .small) { }
///   }
/// }
/// ```
public struct IronTimelineEntry<Content: View>: View {

  // MARK: Lifecycle

  /// Creates a timeline entry with title and optional details.
  ///
  /// - Parameters:
  ///   - title: The main title text.
  ///   - subtitle: Optional subtitle text.
  ///   - timestamp: Optional timestamp to display.
  ///   - timestampFormat: The format for displaying the timestamp.
  ///   - node: The node indicator style.
  public init(
    title: LocalizedStringKey,
    subtitle: LocalizedStringKey? = nil,
    timestamp: Date? = nil,
    timestampFormat: IronTimelineTimestampFormat = .relative,
    node: IronTimelineNode = .default,
  )
    where Content == IronTimelineDefaultContent
  {
    self.node = node
    self.timestamp = timestamp
    self.timestampFormat = timestampFormat
    content = {
      IronTimelineDefaultContent(title: title, subtitle: subtitle)
    }
  }

  /// Creates a timeline entry with custom content.
  ///
  /// - Parameters:
  ///   - node: The node indicator style.
  ///   - timestamp: Optional timestamp to display.
  ///   - timestampFormat: The format for displaying the timestamp.
  ///   - content: A view builder for custom content.
  public init(
    node: IronTimelineNode = .default,
    timestamp: Date? = nil,
    timestampFormat: IronTimelineTimestampFormat = .relative,
    @ViewBuilder content: @escaping () -> Content,
  ) {
    self.node = node
    self.timestamp = timestamp
    self.timestampFormat = timestampFormat
    self.content = content
  }

  // MARK: Public

  public var body: some View {
    HStack(alignment: .top, spacing: theme.spacing.md) {
      nodeIndicator
        .accessibilityHidden(true)

      VStack(alignment: .leading, spacing: theme.spacing.xs) {
        if let timestamp {
          IronText(formattedTimestamp(timestamp), style: .caption, color: .secondary)
        }
        content()
      }
    }
    .padding(.vertical, theme.spacing.sm)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  @ScaledMetric(relativeTo: .body)
  private var nodeSize: CGFloat = 12
  @ScaledMetric(relativeTo: .headline)
  private var largeNodeSize: CGFloat = 24

  private let node: IronTimelineNode
  private let timestamp: Date?
  private let timestampFormat: IronTimelineTimestampFormat
  private let content: () -> Content

  @ViewBuilder
  private var nodeIndicator: some View {
    switch node {
    case .default:
      Circle()
        .fill(theme.colors.primary)
        .frame(width: nodeSize, height: nodeSize)

    case .dot(let color):
      Circle()
        .fill(resolveColor(color))
        .frame(width: nodeSize, height: nodeSize)

    case .icon(let systemName, let color):
      IronIcon(systemName: systemName, size: .small, color: iconColor(for: color))
        .frame(width: largeNodeSize, height: largeNodeSize)
        .background(resolveColor(color).opacity(0.15))
        .clipShape(Circle())

    case .custom(let size, let color):
      Circle()
        .fill(resolveColor(color))
        .frame(width: nodeSize(for: size), height: nodeSize(for: size))
    }
  }

  private func resolveColor(_ color: IronTimelineNodeColor) -> Color {
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

  private func iconColor(for color: IronTimelineNodeColor) -> IronIconColor {
    switch color {
    case .primary: .primary
    case .secondary: .secondary
    case .success: .success
    case .warning: .warning
    case .error: .error
    case .info: .info
    case .custom(let customColor): .custom(customColor)
    }
  }

  private func nodeSize(for size: IronTimelineNodeSize) -> CGFloat {
    switch size {
    case .small: 8
    case .medium: 12
    case .large: 16
    }
  }

  private func formattedTimestamp(_ date: Date) -> String {
    switch timestampFormat {
    case .relative:
      date.formatted(.relative(presentation: .named))
    case .time:
      date.formatted(date: .omitted, time: .shortened)
    case .date:
      date.formatted(date: .abbreviated, time: .omitted)
    case .dateTime:
      date.formatted(date: .abbreviated, time: .shortened)
    case .custom(let style):
      date.formatted(style)
    }
  }
}

// MARK: - IronTimelineDefaultContent

/// Default content view for timeline entries with title and subtitle.
public struct IronTimelineDefaultContent: View {

  // MARK: Lifecycle

  public init(title: LocalizedStringKey, subtitle: LocalizedStringKey? = nil) {
    self.title = title
    self.subtitle = subtitle
  }

  // MARK: Public

  public var body: some View {
    VStack(alignment: .leading, spacing: theme.spacing.xxs) {
      IronText(title, style: .bodyLarge, color: .primary)
      if let subtitle {
        IronText(subtitle, style: .bodyMedium, color: .secondary)
      }
    }
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  private let title: LocalizedStringKey
  private let subtitle: LocalizedStringKey?
}

// MARK: - IronTimelineLayout

/// Layout options for `IronTimeline`.
public enum IronTimelineLayout: Sendable, CaseIterable {
  /// Entries aligned to the left with connector on the left edge.
  case leading
  /// Entries alternate between left and right sides.
  case alternating
  /// Entries aligned to the right with connector on the right edge.
  case trailing
}

// MARK: - IronTimelineNode

/// Node indicator styles for timeline entries.
public enum IronTimelineNode: Sendable {
  /// Default circular dot using primary color.
  case `default`
  /// A colored dot.
  case dot(color: IronTimelineNodeColor)
  /// An SF Symbol icon with background.
  case icon(systemName: String, color: IronTimelineNodeColor)
  /// A custom size dot.
  case custom(size: IronTimelineNodeSize, color: IronTimelineNodeColor)
}

// MARK: - IronTimelineNodeColor

/// Semantic colors for timeline nodes.
public enum IronTimelineNodeColor: Sendable {
  /// Primary brand color.
  case primary
  /// Secondary color.
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

// MARK: - IronTimelineNodeSize

/// Size options for timeline nodes.
public enum IronTimelineNodeSize: Sendable, CaseIterable {
  /// Small node (8pt).
  case small
  /// Medium node (12pt, default).
  case medium
  /// Large node (16pt).
  case large
}

// MARK: - IronTimelineConnectorStyle

/// Style options for the connector line between nodes.
public enum IronTimelineConnectorStyle: Sendable, CaseIterable {
  /// Solid continuous line.
  case solid
  /// Dashed line.
  case dashed
  /// Dotted line.
  case dotted
  /// No visible connector.
  case hidden
}

// MARK: - IronTimelineTimestampFormat

/// Format options for timestamps in timeline entries.
public enum IronTimelineTimestampFormat: Sendable {
  /// Relative format (e.g., "2 hours ago").
  case relative
  /// Time only (e.g., "3:45 PM").
  case time
  /// Date only (e.g., "Dec 22").
  case date
  /// Full date and time (e.g., "Dec 22, 3:45 PM").
  case dateTime
  /// Custom format style.
  case custom(Date.FormatStyle)
}

// MARK: - PreviewEvent

private struct PreviewEvent: Identifiable {
  let id = UUID()
  let title: String
  let description: String
  let date: Date
}

// MARK: - PreviewStep

private struct PreviewStep: Identifiable {
  let id = UUID()
  let title: String
  let icon: String
  let color: IronTimelineNodeColor
}

// MARK: - PreviewMilestone

private struct PreviewMilestone: Identifiable {
  let id = UUID()
  let year: String
  let title: String
}

// MARK: - PreviewItem

private struct PreviewItem: Identifiable {
  let id = UUID()
  let title: String
}

// MARK: - Previews

#Preview("IronTimeline - Basic") {
  ScrollView {
    IronTimeline(entries: [
      PreviewEvent(title: "Order Placed", description: "Your order has been confirmed", date: Date()),
      PreviewEvent(title: "Processing", description: "We're preparing your order", date: Date().addingTimeInterval(-3600)),
      PreviewEvent(title: "Shipped", description: "Your order is on its way", date: Date().addingTimeInterval(-7200)),
      PreviewEvent(title: "Delivered", description: "Package delivered successfully", date: Date().addingTimeInterval(-10800)),
    ]) { event in
      IronTimelineEntry(
        title: LocalizedStringKey(event.title),
        subtitle: LocalizedStringKey(event.description),
        timestamp: event.date,
      )
    }
    .padding()
  }
}

#Preview("IronTimeline - Custom Nodes") {
  ScrollView {
    IronTimeline(entries: [
      PreviewStep(title: "Account Created", icon: "person.fill", color: .success),
      PreviewStep(title: "Email Verified", icon: "envelope.fill", color: .success),
      PreviewStep(title: "Profile Setup", icon: "gear", color: .primary),
      PreviewStep(title: "First Purchase", icon: "cart.fill", color: .secondary),
    ]) { step in
      IronTimelineEntry(
        title: LocalizedStringKey(step.title),
        node: .icon(systemName: step.icon, color: step.color),
      )
    }
    .padding()
  }
}

#Preview("IronTimeline - Alternating") {
  ScrollView {
    IronTimeline(
      entries: [
        PreviewMilestone(year: "2020", title: "Company Founded"),
        PreviewMilestone(year: "2021", title: "First Product Launch"),
        PreviewMilestone(year: "2022", title: "Series A Funding"),
        PreviewMilestone(year: "2023", title: "100k Users"),
        PreviewMilestone(year: "2024", title: "Global Expansion"),
      ],
      layout: .alternating,
    ) { milestone in
      IronTimelineEntry(node: .dot(color: .primary)) {
        VStack(alignment: .leading, spacing: 4) {
          IronText(LocalizedStringKey(milestone.year), style: .caption, color: .secondary)
          IronText(LocalizedStringKey(milestone.title), style: .titleSmall, color: .primary)
        }
        .padding()
        .background(.quaternary)
        .clipShape(RoundedRectangle(cornerRadius: 8))
      }
    }
    .padding()
  }
}

#Preview("IronTimeline - Connector Styles") {
  ScrollView {
    VStack(alignment: .leading, spacing: 32) {
      VStack(alignment: .leading) {
        IronText("Solid", style: .labelLarge, color: .secondary)
        IronTimeline(
          entries: [
            PreviewItem(title: "Step 1"),
            PreviewItem(title: "Step 2"),
            PreviewItem(title: "Step 3"),
          ],
          connectorStyle: .solid,
        ) { item in
          IronTimelineEntry(title: LocalizedStringKey(item.title))
        }
      }

      VStack(alignment: .leading) {
        IronText("Dashed", style: .labelLarge, color: .secondary)
        IronTimeline(
          entries: [
            PreviewItem(title: "Step 1"),
            PreviewItem(title: "Step 2"),
            PreviewItem(title: "Step 3"),
          ],
          connectorStyle: .dashed,
        ) { item in
          IronTimelineEntry(title: LocalizedStringKey(item.title))
        }
      }

      VStack(alignment: .leading) {
        IronText("Dotted", style: .labelLarge, color: .secondary)
        IronTimeline(
          entries: [
            PreviewItem(title: "Step 1"),
            PreviewItem(title: "Step 2"),
            PreviewItem(title: "Step 3"),
          ],
          connectorStyle: .dotted,
        ) { item in
          IronTimelineEntry(title: LocalizedStringKey(item.title))
        }
      }
    }
    .padding()
  }
}

#Preview("IronTimeline - Trailing Layout") {
  ScrollView {
    IronTimeline(
      entries: [
        PreviewItem(title: "Morning Standup"),
        PreviewItem(title: "Design Review"),
        PreviewItem(title: "Lunch Break"),
        PreviewItem(title: "Coding Session"),
      ],
      layout: .trailing,
    ) { event in
      IronTimelineEntry(title: LocalizedStringKey(event.title))
    }
    .padding()
  }
}
