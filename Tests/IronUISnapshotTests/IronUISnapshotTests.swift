import SnapshotTesting
import SwiftUI
import Testing
@testable import IronUI

#if canImport(AppKit)
import AppKit
#endif

// MARK: - IronTimelineSnapshotTests

@Suite("IronTimeline Snapshots")
struct IronTimelineSnapshotTests {

  // MARK: Internal

  @Test("Timeline - Leading Layout")
  @MainActor
  func timelineLeadingLayout() {
    let view = IronTimeline(
      entries: testEvents,
      layout: .leading,
      connectorStyle: .solid,
    ) { event in
      IronTimelineEntry(
        title: LocalizedStringKey(event.title),
        subtitle: event.subtitle.map { LocalizedStringKey($0) },
        timestamp: event.date,
        node: event.node,
      )
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 350)
  }

  @Test("Timeline - Alternating Layout")
  @MainActor
  func timelineAlternatingLayout() {
    let view = IronTimeline(
      entries: testEvents,
      layout: .alternating,
      connectorStyle: .solid,
    ) { event in
      IronTimelineEntry(
        title: LocalizedStringKey(event.title),
        subtitle: event.subtitle.map { LocalizedStringKey($0) },
        timestamp: event.date,
        node: event.node,
      )
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 450)
  }

  @Test("Timeline - Trailing Layout")
  @MainActor
  func timelineTrailingLayout() {
    let view = IronTimeline(
      entries: testEvents,
      layout: .trailing,
      connectorStyle: .solid,
    ) { event in
      IronTimelineEntry(
        title: LocalizedStringKey(event.title),
        subtitle: event.subtitle.map { LocalizedStringKey($0) },
        timestamp: event.date,
        node: event.node,
      )
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 350)
  }

  @Test("Timeline - Dashed Connector")
  @MainActor
  func timelineDashedConnector() {
    let view = IronTimeline(
      entries: Array(testEvents.prefix(3)),
      layout: .leading,
      connectorStyle: .dashed,
    ) { event in
      IronTimelineEntry(
        title: LocalizedStringKey(event.title),
        node: event.node,
      )
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 350)
  }

  @Test("Timeline - Node Styles")
  @MainActor
  func timelineNodeStyles() {
    let nodesEvents = [
      TestEvent(title: "Default", subtitle: nil, date: Date(), node: .default),
      TestEvent(title: "Primary Dot", subtitle: nil, date: Date(), node: .dot(color: .primary)),
      TestEvent(
        title: "Success Icon",
        subtitle: nil,
        date: Date(),
        node: .icon(systemName: "checkmark.circle.fill", color: .success),
      ),
      TestEvent(title: "Error Icon", subtitle: nil, date: Date(), node: .icon(systemName: "xmark.circle.fill", color: .error)),
    ]

    let view = IronTimeline(
      entries: nodesEvents,
      layout: .leading,
      connectorStyle: .solid,
    ) { event in
      IronTimelineEntry(
        title: LocalizedStringKey(event.title),
        node: event.node,
      )
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 350)
  }

  // MARK: Private

  private struct TestEvent: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String?
    let date: Date
    let node: IronTimelineNode
  }

  private var testEvents: [TestEvent] {
    [
      TestEvent(
        title: "Project Started",
        subtitle: "Initial commit",
        date: Date(),
        node: .icon(systemName: "flag.fill", color: .success),
      ),
      TestEvent(
        title: "First Release",
        subtitle: "Version 1.0",
        date: Date().addingTimeInterval(-86400),
        node: .dot(color: .primary),
      ),
      TestEvent(
        title: "Bug Fix",
        subtitle: nil,
        date: Date().addingTimeInterval(-172_800),
        node: .dot(color: .warning),
      ),
      TestEvent(
        title: "Major Update",
        subtitle: "Version 2.0 with new features",
        date: Date().addingTimeInterval(-259_200),
        node: .icon(systemName: "star.fill", color: .info),
      ),
    ]
  }

}

// MARK: - IronKanbanSnapshotTests

@Suite("IronKanban Snapshots")
struct IronKanbanSnapshotTests {

  // MARK: Internal

  @Test("Kanban - Basic Layout")
  @MainActor
  func kanbanBasic() {
    let tasks = testTasks

    let view = IronKanban(
      columns: TaskStatus.allCases,
      items: .constant(tasks),
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
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 700)
  }

  @Test("Kanban - Compact Spacing")
  @MainActor
  func kanbanCompactSpacing() {
    let tasks = testTasks

    let view = IronKanban(
      columns: TaskStatus.allCases,
      items: .constant(tasks),
      columnKeyPath: \.status,
      spacing: .compact,
    ) { task in
      IronKanbanCard(priority: task.priority) {
        IronText(task.title, style: .bodySmall, color: .primary)
      }
    } header: { status, _ in
      IronText(status.rawValue, style: .labelMedium, color: .primary)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 600)
  }

  @Test("Kanban - Empty Columns")
  @MainActor
  func kanbanEmptyColumns() {
    let tasks = [Task(title: "Only task", status: .inProgress, priority: .medium)]

    let view = IronKanban(
      columns: TaskStatus.allCases,
      items: .constant(tasks),
      columnKeyPath: \.status,
    ) { task in
      IronKanbanCard(priority: task.priority) {
        IronText(task.title, style: .bodyMedium, color: .primary)
      }
    } header: { status, count in
      IronText("\(status.rawValue) (\(count))", style: .titleSmall, color: .primary)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 700)
  }

  @Test("Kanban Card - Priorities")
  @MainActor
  func kanbanCardPriorities() {
    let view = VStack(spacing: 12) {
      IronKanbanCard(priority: .urgent) {
        IronText("Urgent priority", style: .bodyMedium, color: .primary)
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

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 280)
  }

  // MARK: Private

  private enum TaskStatus: String, CaseIterable, Hashable {
    case todo = "To Do"
    case inProgress = "In Progress"
    case done = "Done"
  }

  private struct Task: Identifiable {
    let id = UUID()
    var title: String
    var status: TaskStatus
    var priority: IronKanbanPriority
  }

  private var testTasks: [Task] {
    [
      Task(title: "Design homepage", status: .todo, priority: .high),
      Task(title: "Setup CI/CD", status: .todo, priority: .medium),
      Task(title: "Write tests", status: .inProgress, priority: .low),
      Task(title: "Code review", status: .inProgress, priority: .none),
      Task(title: "Deploy v1.0", status: .done, priority: .none),
    ]
  }

}

// MARK: - IronDatabaseSnapshotTests

@Suite("IronDatabase Snapshots")
struct IronDatabaseSnapshotTests {

  // MARK: Internal

  @Test("Database Table - Basic")
  @MainActor
  func databaseTableBasic() {
    let database = createTestDatabase()

    let view = IronDatabaseTable(
      database: .constant(database),
      onAddRow: { },
      onAddColumn: { },
    )
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 700)
  }

  @Test("Database Table - Empty")
  @MainActor
  func databaseTableEmpty() {
    let database = IronDatabase(name: "Empty Database")

    let view = IronDatabaseTable(
      database: .constant(database),
      onAddRow: { },
      onAddColumn: { },
    )
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 350)
  }

  @Test("Database Cells - Display")
  @MainActor
  func databaseCellsDisplay() {
    let options = [
      IronSelectOption(name: "Option A", color: .primary),
      IronSelectOption(name: "Option B", color: .success),
      IronSelectOption(name: "Option C", color: .warning),
    ]

    let textColumn = IronColumn(name: "Text", type: .text)
    let numberColumn = IronColumn(name: "Number", type: .number)
    let dateColumn = IronColumn(name: "Date", type: .date)
    let checkboxColumn = IronColumn(name: "Checkbox", type: .checkbox)
    let selectColumn = IronColumn(name: "Select", type: .select, options: options)
    let multiSelectColumn = IronColumn(name: "Multi", type: .multiSelect, options: options)

    let view = VStack(alignment: .leading, spacing: 16) {
      cellRow(label: "Text") {
        IronDatabaseCell(column: textColumn, value: .constant(.text("Hello World")))
      }
      cellRow(label: "Number") {
        IronDatabaseCell(column: numberColumn, value: .constant(.number(42.5)))
      }
      cellRow(label: "Date") {
        IronDatabaseCell(column: dateColumn, value: .constant(.date(Date())))
      }
      cellRow(label: "Checkbox") {
        IronDatabaseCell(column: checkboxColumn, value: .constant(.checkbox(true)))
      }
      cellRow(label: "Select") {
        IronDatabaseCell(column: selectColumn, value: .constant(.select(options[1].id)))
      }
      cellRow(label: "Multi") {
        IronDatabaseCell(column: multiSelectColumn, value: .constant(.multiSelect(Set([options[0].id, options[2].id]))))
      }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 350)
  }

  @Test("Database Cells - Links")
  @MainActor
  func databaseCellsLinks() {
    let urlColumn = IronColumn(name: "URL", type: .url)
    let emailColumn = IronColumn(name: "Email", type: .email)
    let phoneColumn = IronColumn(name: "Phone", type: .phone)
    let personColumn = IronColumn(name: "Person", type: .person)

    let view = VStack(alignment: .leading, spacing: 16) {
      cellRow(label: "URL") {
        IronDatabaseCell(column: urlColumn, value: .constant(.url(URL(string: "https://apple.com"))))
      }
      cellRow(label: "Email") {
        IronDatabaseCell(column: emailColumn, value: .constant(.email("hello@example.com")))
      }
      cellRow(label: "Phone") {
        IronDatabaseCell(column: phoneColumn, value: .constant(.phone("+1 (555) 123-4567")))
      }
      cellRow(label: "Person") {
        IronDatabaseCell(column: personColumn, value: .constant(.person(IronPerson(name: "John Doe"))))
      }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 320)
  }

  // MARK: Private

  private func createTestDatabase() -> IronDatabase {
    var database = IronDatabase(name: "Tasks")

    let titleColumn = database.addColumn(name: "Title", type: .text)
    let statusColumn = database.addColumn(name: "Status", type: .select, options: [
      IronSelectOption(name: "To Do", color: .secondary),
      IronSelectOption(name: "In Progress", color: .warning),
      IronSelectOption(name: "Done", color: .success),
    ])
    let dueDateColumn = database.addColumn(name: "Due Date", type: .date)
    let priorityColumn = database.addColumn(name: "Priority", type: .number)
    let doneColumn = database.addColumn(name: "Complete", type: .checkbox)

    let row1 = database.addRow()
    database.setValue(.text("Design homepage"), for: row1.id, column: titleColumn.id)
    database.setValue(.select(statusColumn.options[1].id), for: row1.id, column: statusColumn.id)
    database.setValue(.date(Date()), for: row1.id, column: dueDateColumn.id)
    database.setValue(.number(1), for: row1.id, column: priorityColumn.id)
    database.setValue(.checkbox(false), for: row1.id, column: doneColumn.id)

    let row2 = database.addRow()
    database.setValue(.text("Write documentation"), for: row2.id, column: titleColumn.id)
    database.setValue(.select(statusColumn.options[0].id), for: row2.id, column: statusColumn.id)
    database.setValue(.number(2), for: row2.id, column: priorityColumn.id)
    database.setValue(.checkbox(false), for: row2.id, column: doneColumn.id)

    let row3 = database.addRow()
    database.setValue(.text("Fix login bug"), for: row3.id, column: titleColumn.id)
    database.setValue(.select(statusColumn.options[2].id), for: row3.id, column: statusColumn.id)
    database.setValue(
      .date(Calendar.current.date(byAdding: .day, value: -2, to: Date())!),
      for: row3.id,
      column: dueDateColumn.id,
    )
    database.setValue(.number(1), for: row3.id, column: priorityColumn.id)
    database.setValue(.checkbox(true), for: row3.id, column: doneColumn.id)

    return database
  }

  private func cellRow(
    label: String,
    @ViewBuilder content: () -> some View,
  ) -> some View {
    HStack {
      Text(label)
        .frame(width: 80, alignment: .trailing)
        .foregroundStyle(.secondary)
      content()
      Spacer()
    }
  }
}
