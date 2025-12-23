import CoreTransferable
import IronCore
import IronPrimitives
import SwiftUI

// MARK: - UUID + @retroactive Transferable

extension UUID: @retroactive Transferable {
  public static var transferRepresentation: some TransferRepresentation {
    ProxyRepresentation(exporting: \.uuidString) { UUID(uuidString: $0) ?? UUID() }
  }
}

// MARK: - IronKanban

/// A project management board with draggable cards between columns.
///
/// `IronKanban` displays items organized into columns, with drag-and-drop
/// support for moving items between columns.
///
/// ## Basic Usage
///
/// ```swift
/// enum TaskStatus: String, CaseIterable {
///   case todo, inProgress, done
/// }
///
/// struct Task: Identifiable {
///   let id: UUID
///   var title: String
///   var status: TaskStatus
/// }
///
/// IronKanban(
///   columns: TaskStatus.allCases,
///   items: $tasks,
///   columnKeyPath: \.status
/// ) { task in
///   TaskCard(task: task)
/// } header: { status, count in
///   IronText("\(status.rawValue) (\(count))", style: .titleSmall)
/// }
/// ```
///
/// ## With Custom Empty State
///
/// ```swift
/// IronKanban(
///   columns: TaskStatus.allCases,
///   items: $tasks,
///   columnKeyPath: \.status
/// ) { task in
///   TaskCard(task: task)
/// } header: { status, count in
///   IronText(status.rawValue, style: .titleSmall)
/// } emptyState: { status in
///   IronText("No tasks", style: .bodyMedium, color: .secondary)
/// }
/// ```
public struct IronKanban<
  Item: Identifiable,
  Column: Hashable,
  CardContent: View,
  HeaderContent: View,
  EmptyContent: View,
>: View where Item.ID: Transferable {

  // MARK: Lifecycle

  /// Creates a Kanban board with custom empty state.
  ///
  /// - Parameters:
  ///   - columns: The columns to display.
  ///   - items: Binding to the array of items.
  ///   - columnKeyPath: KeyPath to the column property on each item.
  ///   - spacing: Spacing configuration for the board.
  ///   - card: A view builder that creates content for each item card.
  ///   - header: A view builder that creates content for each column header.
  ///   - emptyState: A view builder that creates content for empty columns.
  public init(
    columns: [Column],
    items: Binding<[Item]>,
    columnKeyPath: WritableKeyPath<Item, Column>,
    spacing: IronKanbanSpacing = .standard,
    @ViewBuilder card: @escaping (Item) -> CardContent,
    @ViewBuilder header: @escaping (Column, Int) -> HeaderContent,
    @ViewBuilder emptyState: @escaping (Column) -> EmptyContent,
  ) {
    self.columns = columns
    _items = items
    self.columnKeyPath = columnKeyPath
    self.spacing = spacing
    cardBuilder = card
    headerBuilder = header
    emptyStateBuilder = emptyState
  }

  // MARK: Public

  public var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(alignment: .top, spacing: spacing.columnSpacing) {
        ForEach(columns, id: \.self) { column in
          KanbanColumn(
            column: column,
            items: itemsForColumn(column),
            allItems: $items,
            columnKeyPath: columnKeyPath,
            spacing: spacing,
            cardBuilder: cardBuilder,
            headerBuilder: headerBuilder,
            emptyStateBuilder: emptyStateBuilder,
          )
        }
      }
      .padding(.horizontal, theme.spacing.md)
    }
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Kanban board with \(columns.count) columns")
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  @Binding private var items: [Item]

  private let columns: [Column]
  private let columnKeyPath: WritableKeyPath<Item, Column>
  private let spacing: IronKanbanSpacing
  private let cardBuilder: (Item) -> CardContent
  private let headerBuilder: (Column, Int) -> HeaderContent
  private let emptyStateBuilder: (Column) -> EmptyContent

  private func itemsForColumn(_ column: Column) -> [Item] {
    items.filter { $0[keyPath: columnKeyPath] == column }
  }
}

// MARK: - Convenience Initializer

extension IronKanban where EmptyContent == IronKanbanDefaultEmptyState, Item.ID: Transferable {
  /// Creates a Kanban board with default empty state.
  ///
  /// - Parameters:
  ///   - columns: The columns to display.
  ///   - items: Binding to the array of items.
  ///   - columnKeyPath: KeyPath to the column property on each item.
  ///   - spacing: Spacing configuration for the board.
  ///   - card: A view builder that creates content for each item card.
  ///   - header: A view builder that creates content for each column header.
  public init(
    columns: [Column],
    items: Binding<[Item]>,
    columnKeyPath: WritableKeyPath<Item, Column>,
    spacing: IronKanbanSpacing = .standard,
    @ViewBuilder card: @escaping (Item) -> CardContent,
    @ViewBuilder header: @escaping (Column, Int) -> HeaderContent,
  ) {
    self.init(
      columns: columns,
      items: items,
      columnKeyPath: columnKeyPath,
      spacing: spacing,
      card: card,
      header: header,
      emptyState: { _ in IronKanbanDefaultEmptyState() },
    )
  }
}

// MARK: - KanbanColumn

/// Internal view for a single Kanban column.
private struct KanbanColumn<
  Item: Identifiable,
  Column: Hashable,
  CardContent: View,
  HeaderContent: View,
  EmptyContent: View,
>: View where Item.ID: Transferable {

  // MARK: Internal

  let column: Column
  let items: [Item]
  @Binding var allItems: [Item]
  let columnKeyPath: WritableKeyPath<Item, Column>
  let spacing: IronKanbanSpacing
  let cardBuilder: (Item) -> CardContent
  let headerBuilder: (Column, Int) -> HeaderContent
  let emptyStateBuilder: (Column) -> EmptyContent

  var body: some View {
    VStack(alignment: .leading, spacing: theme.spacing.sm) {
      // Header
      headerBuilder(column, items.count)
        .frame(maxWidth: .infinity, alignment: .leading)

      // Cards or empty state
      ScrollView(.vertical, showsIndicators: false) {
        LazyVStack(spacing: spacing.cardSpacing) {
          if items.isEmpty {
            emptyStateBuilder(column)
              .frame(maxWidth: .infinity)
              .frame(minHeight: 100)
          } else {
            ForEach(items) { item in
              cardBuilder(item)
                .draggable(item.id) {
                  // Drag preview
                  cardBuilder(item)
                    .frame(width: columnWidth)
                    .opacity(0.8)
                }
            }
          }
        }
        .padding(.vertical, theme.spacing.xs)
      }
      .frame(maxHeight: .infinity)
      .dropDestination(for: Item.ID.self) { droppedIDs, _ in
        handleDrop(droppedIDs)
      } isTargeted: { isTargeted in
        withAnimation(theme.animation.snappy) {
          isDropTargeted = isTargeted
        }
      }
    }
    .padding(theme.spacing.sm)
    .frame(width: columnWidth)
    .background(
      RoundedRectangle(cornerRadius: theme.radii.md)
        .fill(isDropTargeted ? theme.colors.primary.opacity(0.1) : theme.colors.surface)
    )
    .overlay(
      RoundedRectangle(cornerRadius: theme.radii.md)
        .strokeBorder(
          isDropTargeted ? theme.colors.primary : Color.clear,
          style: StrokeStyle(lineWidth: 2, dash: isDropTargeted ? [5, 5] : []),
        )
    )
    .accessibilityElement(children: .contain)
    .accessibilityLabel("Column with \(items.count) items")
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  @State private var isDropTargeted = false

  @ScaledMetric(relativeTo: .body)
  private var columnWidth: CGFloat = 280

  private func handleDrop(_ droppedIDs: [Item.ID]) -> Bool {
    for id in droppedIDs {
      if let index = allItems.firstIndex(where: { $0.id == id }) {
        allItems[index][keyPath: columnKeyPath] = column
      }
    }
    return true
  }
}

// MARK: - IronKanbanDefaultEmptyState

/// Default empty state view for Kanban columns.
public struct IronKanbanDefaultEmptyState: View {

  // MARK: Public

  public var body: some View {
    VStack(spacing: theme.spacing.sm) {
      IronIcon(systemName: "tray", size: .large, color: .secondary)
      IronText("Drop items here", style: .bodyMedium, color: .secondary)
    }
    .frame(maxWidth: .infinity)
    .padding(theme.spacing.lg)
    .background(
      RoundedRectangle(cornerRadius: theme.radii.sm)
        .strokeBorder(theme.colors.border, style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
    )
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme
}

// MARK: - IronKanbanCard

/// A pre-styled card for Kanban boards.
///
/// Use this as a convenience wrapper for card content.
///
/// ```swift
/// IronKanbanCard(priority: .high) {
///   VStack(alignment: .leading) {
///     IronText(task.title, style: .bodyLarge)
///     IronText(task.dueDate, style: .caption, color: .secondary)
///   }
/// }
/// ```
public struct IronKanbanCard<Content: View>: View {

  // MARK: Lifecycle

  /// Creates a Kanban card.
  ///
  /// - Parameters:
  ///   - priority: Optional priority indicator.
  ///   - content: The card content.
  public init(
    priority: IronKanbanPriority = .none,
    @ViewBuilder content: () -> Content,
  ) {
    self.priority = priority
    self.content = content()
  }

  // MARK: Public

  public var body: some View {
    HStack(alignment: .top, spacing: theme.spacing.sm) {
      if priority != .none {
        priorityIndicator
      }

      content
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(theme.spacing.md)
    .background(theme.colors.surfaceElevated)
    .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
    .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  private let priority: IronKanbanPriority
  private let content: Content

  private var priorityIndicator: some View {
    Circle()
      .fill(priorityColor)
      .frame(width: 8, height: 8)
      .padding(.top, 6)
  }

  private var priorityColor: Color {
    switch priority {
    case .none: Color.clear
    case .low: theme.colors.info
    case .medium: theme.colors.warning
    case .high: theme.colors.error
    case .urgent: theme.colors.error
    }
  }
}

// MARK: - IronKanbanSpacing

/// Spacing options for Kanban boards.
public enum IronKanbanSpacing: Sendable, CaseIterable {
  /// Compact spacing (8pt between columns, 4pt between cards).
  case compact
  /// Standard spacing (16pt between columns, 8pt between cards).
  case standard
  /// Spacious spacing (24pt between columns, 12pt between cards).
  case spacious

  // MARK: Internal

  var columnSpacing: CGFloat {
    switch self {
    case .compact: 8
    case .standard: 16
    case .spacious: 24
    }
  }

  var cardSpacing: CGFloat {
    switch self {
    case .compact: 4
    case .standard: 8
    case .spacious: 12
    }
  }
}

// MARK: - IronKanbanPriority

/// Priority indicators for Kanban cards.
public enum IronKanbanPriority: Sendable, CaseIterable {
  /// No priority indicator.
  case none
  /// Low priority (blue).
  case low
  /// Medium priority (yellow/orange).
  case medium
  /// High priority (red).
  case high
  /// Urgent priority (red, pulsing).
  case urgent
}

// MARK: - PreviewStatus

private enum PreviewStatus: String, CaseIterable, Hashable {
  case todo = "To Do"
  case inProgress = "In Progress"
  case done = "Done"
}

// MARK: - PreviewTask

private struct PreviewTask: Identifiable {
  let id = UUID()
  var title: String
  var status: PreviewStatus
  var priority: IronKanbanPriority
}

// MARK: - Previews

#Preview("IronKanban - Basic") {
  @Previewable @State var tasks = [
    PreviewTask(title: "Design homepage", status: .todo, priority: .high),
    PreviewTask(title: "Setup CI/CD", status: .todo, priority: .medium),
    PreviewTask(title: "Write tests", status: .inProgress, priority: .low),
    PreviewTask(title: "Code review", status: .inProgress, priority: .none),
    PreviewTask(title: "Deploy v1.0", status: .done, priority: .none),
  ]

  IronKanban(
    columns: PreviewStatus.allCases,
    items: $tasks,
    columnKeyPath: \.status,
  ) { task in
    IronKanbanCard(priority: task.priority) {
      IronText(task.title, style: .bodyMedium, color: .primary)
    }
  } header: { status, count in
    HStack {
      IronText(status.rawValue, style: .titleSmall, color: .primary)
      Spacer()
      IronBadge(count: count, color: .secondary, size: .small)
    }
  }
}

#Preview("IronKanban - Empty Columns") {
  @Previewable @State var tasks: [PreviewTask] = [
    PreviewTask(title: "Only task", status: .inProgress, priority: .medium)
  ]

  IronKanban(
    columns: PreviewStatus.allCases,
    items: $tasks,
    columnKeyPath: \.status,
  ) { task in
    IronKanbanCard(priority: task.priority) {
      IronText(task.title, style: .bodyMedium, color: .primary)
    }
  } header: { status, count in
    IronText("\(status.rawValue) (\(count))", style: .titleSmall, color: .primary)
  }
}

#Preview("IronKanban - Compact Spacing") {
  @Previewable @State var tasks = [
    PreviewTask(title: "Task 1", status: .todo, priority: .none),
    PreviewTask(title: "Task 2", status: .todo, priority: .none),
    PreviewTask(title: "Task 3", status: .inProgress, priority: .none),
  ]

  IronKanban(
    columns: PreviewStatus.allCases,
    items: $tasks,
    columnKeyPath: \.status,
    spacing: .compact,
  ) { task in
    IronKanbanCard {
      IronText(task.title, style: .bodySmall, color: .primary)
    }
  } header: { status, _ in
    IronText(status.rawValue, style: .labelLarge, color: .primary)
  }
}

#Preview("IronKanbanCard - Priorities") {
  VStack(spacing: 12) {
    IronKanbanCard(priority: .urgent) {
      IronText("Urgent task", style: .bodyMedium, color: .primary)
    }
    IronKanbanCard(priority: .high) {
      IronText("High priority", style: .bodyMedium, color: .primary)
    }
    IronKanbanCard(priority: .medium) {
      IronText("Medium priority", style: .bodyMedium, color: .primary)
    }
    IronKanbanCard(priority: .low) {
      IronText("Low priority", style: .bodyMedium, color: .primary)
    }
    IronKanbanCard(priority: .none) {
      IronText("No priority", style: .bodyMedium, color: .primary)
    }
  }
  .padding()
  .frame(width: 300)
}
