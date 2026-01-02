import IronCore
import IronDataDisplay
import SQLiteData
import SwiftUI

/// Bridge view that displays chores in IronDatabaseTable format
/// with two-way sync to SQLiteData
struct ChoreTableView: View {

  // MARK: Lifecycle

  init(chores: [Chore], members: [HouseholdMember], onEditChore: @escaping (Chore) -> Void) {
    self.chores = chores
    self.members = members
    self.onEditChore = onEditChore

    // Build static column IDs (stable across rebuilds)
    _database = State(initialValue: Self.buildDatabase(from: chores, members: members))
  }

  // MARK: Internal

  let chores: [Chore]
  let members: [HouseholdMember]
  let onEditChore: (Chore) -> Void

  var body: some View {
    IronDatabaseTable(
      database: $database,
      selection: $selection,
      onAddRow: nil,
      onAddColumn: nil,
    )
    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
    .onChange(of: chores) { _, newChores in
      // Rebuild database when chores change externally
      database = Self.buildDatabase(from: newChores, members: members)
    }
    .onChange(of: database) { oldDatabase, newDatabase in
      // Sync changes back to SQLiteData
      syncChangesToDatabase(oldDatabase: oldDatabase, newDatabase: newDatabase)
    }
    .onChange(of: selection) { _, newSelection in
      // When a row is selected, open the edit sheet
      if
        let selectedID = newSelection.first,
        let chore = chores.first(where: { $0.id == selectedID })
      {
        selection.removeAll()
        onEditChore(chore)
      }
    }
  }

  // MARK: Private

  // Stable column IDs
  private static let titleColumnID = UUID(uuidString: "00000001-0000-0000-0000-000000000001")!
  private static let categoryColumnID = UUID(uuidString: "00000001-0000-0000-0000-000000000002")!
  private static let statusColumnID = UUID(uuidString: "00000001-0000-0000-0000-000000000003")!
  private static let dueDateColumnID = UUID(uuidString: "00000001-0000-0000-0000-000000000004")!
  private static let assigneeColumnID = UUID(uuidString: "00000001-0000-0000-0000-000000000005")!
  private static let completedColumnID = UUID(uuidString: "00000001-0000-0000-0000-000000000006")!

  /// Stable option IDs for categories
  private static let categoryOptionIDs: [ChoreCategory: UUID] = [
    .kitchen: UUID(uuidString: "00000002-0000-0000-0000-000000000001")!,
    .bathroom: UUID(uuidString: "00000002-0000-0000-0000-000000000002")!,
    .bedroom: UUID(uuidString: "00000002-0000-0000-0000-000000000003")!,
    .laundry: UUID(uuidString: "00000002-0000-0000-0000-000000000004")!,
    .outdoor: UUID(uuidString: "00000002-0000-0000-0000-000000000005")!,
    .general: UUID(uuidString: "00000002-0000-0000-0000-000000000006")!,
  ]

  /// Stable option IDs for statuses
  private static let statusOptionIDs: [ChoreStatus: UUID] = [
    .todo: UUID(uuidString: "00000003-0000-0000-0000-000000000001")!,
    .inProgress: UUID(uuidString: "00000003-0000-0000-0000-000000000002")!,
    .done: UUID(uuidString: "00000003-0000-0000-0000-000000000003")!,
  ]

  /// Unassigned option ID
  private static let unassignedOptionID = UUID(uuidString: "00000004-0000-0000-0000-000000000001")!

  @State private var database: IronDatabase
  @State private var selection = Set<UUID>()

  @Dependency(\.defaultDatabase) private var sqliteDatabase

  private static func buildDatabase(from chores: [Chore], members: [HouseholdMember]) -> IronDatabase {
    var db = IronDatabase(name: "Chores")

    // Add columns
    db.columns = [
      IronColumn(
        id: titleColumnID,
        name: "Title",
        type: .text,
        width: 200,
      ),
      IronColumn(
        id: categoryColumnID,
        name: "Category",
        type: .select,
        width: 120,
        options: ChoreCategory.allCases.map { category in
          IronSelectOption(
            id: categoryOptionIDs[category]!,
            name: category.displayName,
            color: semanticColor(for: category),
          )
        },
      ),
      IronColumn(
        id: statusColumnID,
        name: "Status",
        type: .select,
        width: 120,
        options: ChoreStatus.allCases.map { status in
          IronSelectOption(
            id: statusOptionIDs[status]!,
            name: status.rawValue,
            color: semanticColor(for: status),
          )
        },
      ),
      IronColumn(
        id: dueDateColumnID,
        name: "Due Date",
        type: .date,
        width: 120,
      ),
      IronColumn(
        id: assigneeColumnID,
        name: "Assignee",
        type: .select,
        width: 140,
        options: [
          IronSelectOption(id: unassignedOptionID, name: "Unassigned", color: .secondary)
        ] + members.map { member in
          IronSelectOption(
            id: member.id,
            name: "\(member.avatarEmoji) \(member.name)",
            color: .primary,
          )
        },
      ),
      IronColumn(
        id: completedColumnID,
        name: "Done",
        type: .checkbox,
        width: 60,
      ),
    ]

    // Add rows
    db.rows = chores.map { chore in
      IronRow(
        id: chore.id,
        cells: [
          titleColumnID: .text(chore.title),
          categoryColumnID: .select(categoryOptionIDs[chore.category]),
          statusColumnID: .select(statusOptionIDs[chore.status]),
          dueDateColumnID: chore.dueDate.map { .date($0) } ?? .empty,
          assigneeColumnID: .select(chore.assigneeId ?? unassignedOptionID),
          completedColumnID: .checkbox(chore.isCompleted),
        ],
      )
    }

    return db
  }

  private static func semanticColor(for category: ChoreCategory) -> IronSemanticColor {
    switch category {
    case .kitchen: .warning
    case .bathroom: .info
    case .bedroom: .accent
    case .laundry: .primary
    case .outdoor: .success
    case .general: .secondary
    }
  }

  private static func semanticColor(for status: ChoreStatus) -> IronSemanticColor {
    switch status {
    case .todo: .secondary
    case .inProgress: .warning
    case .done: .success
    }
  }

  private func syncChangesToDatabase(oldDatabase: IronDatabase, newDatabase: IronDatabase) {
    // Find rows that changed
    for newRow in newDatabase.rows {
      guard let oldRow = oldDatabase.rows.first(where: { $0.id == newRow.id }) else { continue }
      guard oldRow != newRow else { continue }

      // Find corresponding chore
      guard let chore = chores.first(where: { $0.id == newRow.id }) else { continue }

      // Determine what changed and update
      var updatedChore = chore

      // Title
      if
        let newValue = newRow.cells[Self.titleColumnID],
        case .text(let title) = newValue,
        title != chore.title
      {
        updatedChore.title = title
      }

      // Category
      if
        let newValue = newRow.cells[Self.categoryColumnID],
        case .select(let optionID) = newValue,
        let optionID,
        let category = Self.categoryOptionIDs.first(where: { $0.value == optionID })?.key,
        category != chore.category
      {
        updatedChore.category = category
      }

      // Status
      if
        let newValue = newRow.cells[Self.statusColumnID],
        case .select(let optionID) = newValue,
        let optionID,
        let status = Self.statusOptionIDs.first(where: { $0.value == optionID })?.key,
        status != chore.status
      {
        updatedChore.status = status
        // Also update completion state based on status
        if status == .done {
          updatedChore.isCompleted = true
          updatedChore.completedAt = Date()
        } else if chore.status == .done {
          updatedChore.isCompleted = false
          updatedChore.completedAt = nil
        }
      }

      // Due Date
      if let newValue = newRow.cells[Self.dueDateColumnID] {
        switch newValue {
        case .date(let date):
          if chore.dueDate != date {
            updatedChore.dueDate = date
          }

        case .empty:
          if chore.dueDate != nil {
            updatedChore.dueDate = nil
          }

        default:
          break
        }
      }

      // Assignee
      if
        let newValue = newRow.cells[Self.assigneeColumnID],
        case .select(let optionID) = newValue
      {
        let newAssigneeId = (optionID == Self.unassignedOptionID) ? nil : optionID
        if newAssigneeId != chore.assigneeId {
          updatedChore.assigneeId = newAssigneeId
        }
      }

      // Completed
      if
        let newValue = newRow.cells[Self.completedColumnID],
        case .checkbox(let isCompleted) = newValue,
        isCompleted != chore.isCompleted
      {
        updatedChore.isCompleted = isCompleted
        updatedChore.completedAt = isCompleted ? Date() : nil
        // Also update status
        updatedChore.status = isCompleted ? .done : .todo
      }

      // Save if changed
      if updatedChore != chore {
        try? sqliteDatabase.write { db in
          try Chore.upsert { updatedChore }.execute(db)
        }
      }
    }
  }
}

#Preview("ChoreTableView") {
  ChoreTableView(
    chores: SampleData.chores,
    members: SampleData.members,
  ) { chore in
    print("Edit chore: \(chore.title)")
  }
  .ironTheme(IronDefaultTheme())
}
