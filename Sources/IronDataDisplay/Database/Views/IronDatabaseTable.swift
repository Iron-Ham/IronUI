import IronCore
import IronPrimitives
import SwiftUI

// MARK: - IronDatabaseTable

/// A Notion-style table view for displaying and editing database content.
///
/// `IronDatabaseTable` provides a high-performance grid-based view of an `IronDatabase`
/// with support for inline editing, row selection, sorting, filtering, and column management.
///
/// On macOS, this uses `NSTableView` for optimal performance with large datasets.
/// On iOS, this uses `UICollectionView` with compositional layout.
///
/// ## Basic Usage
///
/// ```swift
/// @State private var database = IronDatabase(name: "Tasks")
///
/// IronDatabaseTable(database: database)
/// ```
///
/// ## With Selection
///
/// ```swift
/// @State private var selection: Set<IronRow.ID> = []
///
/// IronDatabaseTable(
///   database: database,
///   selection: $selection
/// )
/// ```
///
/// ## With Sorting and Filtering
///
/// ```swift
/// @State private var sortState: IronDatabaseSortState?
/// @State private var filterState = IronDatabaseFilterState()
///
/// IronDatabaseTable(
///   database: database,
///   sortState: $sortState,
///   filterState: $filterState
/// )
/// ```
///
/// ## With Add Callbacks
///
/// ```swift
/// IronDatabaseTable(
///   database: database,
///   onAddRow: { database.addRow() },
///   onAddColumn: { showColumnSheet = true }
/// )
/// ```
public struct IronDatabaseTable: View {

  // MARK: Lifecycle

  /// Creates a database table view.
  ///
  /// - Parameters:
  ///   - database: The database to display (observed automatically).
  ///   - selection: Binding to selected row IDs.
  ///   - isEditing: Binding to edit mode (enables two-finger swipe selection on iOS).
  ///   - sortState: Binding to the current sort state.
  ///   - filterState: Binding to the current filter state.
  ///   - onAddRow: Callback when the add row button is tapped.
  ///   - onAddColumn: Callback when the add column button is tapped.
  ///   - onRowAction: Callback for row context menu actions.
  public init(
    database: IronDatabase,
    selection: Binding<Set<IronRow.ID>> = .constant([]),
    isEditing: Binding<Bool> = .constant(false),
    sortState: Binding<IronDatabaseSortState?> = .constant(nil),
    filterState: Binding<IronDatabaseFilterState> = .constant(IronDatabaseFilterState()),
    onAddRow: (() -> Void)? = nil,
    onAddColumn: (() -> Void)? = nil,
    onRowAction: ((IronDatabaseRowAction, IronRow.ID) -> Void)? = nil,
  ) {
    self.database = database
    _selection = selection
    _isEditing = isEditing
    _sortState = sortState
    _filterState = filterState
    self.onAddRow = onAddRow
    self.onAddColumn = onAddColumn
    self.onRowAction = onRowAction
  }

  // MARK: Public

  public var body: some View {
    #if os(macOS)
    IronDatabaseTableMacOS(configuration: configuration)
      .background(theme.colors.surface)
      .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
      .overlay(
        RoundedRectangle(cornerRadius: theme.radii.md)
          .strokeBorder(theme.colors.border, lineWidth: 1)
      )
    #else
    IronDatabaseTableIOS(configuration: configuration)
      .background(theme.colors.surface)
      .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
      .overlay(
        RoundedRectangle(cornerRadius: theme.radii.md)
          .strokeBorder(theme.colors.border, lineWidth: 1)
      )
    #endif
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  @Binding private var selection: Set<IronRow.ID>
  @Binding private var isEditing: Bool
  @Binding private var sortState: IronDatabaseSortState?
  @Binding private var filterState: IronDatabaseFilterState

  private let database: IronDatabase

  private let onAddRow: (() -> Void)?
  private let onAddColumn: (() -> Void)?
  private let onRowAction: ((IronDatabaseRowAction, IronRow.ID) -> Void)?

  private var configuration: IronDatabaseTableConfiguration {
    IronDatabaseTableConfiguration(
      database: database,
      selection: $selection,
      isEditing: $isEditing,
      sortState: $sortState,
      filterState: $filterState,
      onAddRow: onAddRow,
      onAddColumn: onAddColumn,
      onRowAction: onRowAction,
    )
  }
}

// MARK: - Previews

#Preview("IronDatabaseTable - Basic") {
  @Previewable @State var database = createPreviewDatabase()

  IronDatabaseTable(
    database: database,
    onAddRow: { database.addRow() },
    onAddColumn: { database.addColumn(name: "New Column", type: .text) },
  )
  .padding()
}

#Preview("IronDatabaseTable - With Selection") {
  @Previewable @State var database = createPreviewDatabase()
  @Previewable @State var selection = Set<IronRow.ID>()

  VStack(alignment: .leading, spacing: 16) {
    IronText("Selected: \(selection.count) rows", style: .bodyMedium, color: .secondary)

    IronDatabaseTable(
      database: database,
      selection: $selection,
      onAddRow: { database.addRow() },
    )
  }
  .padding()
}

#Preview("IronDatabaseTable - With Sorting") {
  @Previewable @State var database = createPreviewDatabase()
  @Previewable @State var sortState: IronDatabaseSortState? = IronDatabaseSortState(
    columnID: UUID(), // Will be set properly in createPreviewDatabase
    direction: .ascending,
  )

  IronDatabaseTable(
    database: database,
    sortState: $sortState,
    onAddRow: { database.addRow() },
  )
  .padding()
}

#Preview("IronDatabaseTable - Large Dataset") {
  @Previewable @State var database = createLargePreviewDatabase(rowCount: 500)

  IronDatabaseTable(
    database: database,
    onAddRow: { database.addRow() },
  )
  .padding()
}

#Preview("IronDatabaseTable - Empty") {
  @Previewable @State var database = IronDatabase(name: "Empty Database")

  IronDatabaseTable(
    database: database,
    onAddRow: { database.addRow() },
    onAddColumn: { database.addColumn(name: "Column", type: .text) },
  )
  .padding()
}

#Preview("IronDatabaseTable - With Filtering") {
  @Previewable @State var database = createLargePreviewDatabase(rowCount: 50)
  @Previewable @State var filterState = IronDatabaseFilterState()
  @Previewable @State var showFilterPopover = false

  VStack(alignment: .leading, spacing: 16) {
    HStack {
      IronText("Rows: \(database.rows.count) total", style: .bodyMedium, color: .secondary)

      Spacer()

      Button {
        // Apply a filter to show only completed tasks
        if filterState.hasActiveFilters {
          filterState.clear()
        } else if let completeColumn = database.columns.first(where: { $0.name == "Complete" }) {
          filterState.filters[completeColumn.id] = .checkbox(.checked)
        }
      } label: {
        Label(
          filterState.hasActiveFilters ? "Clear Filter" : "Show Completed Only",
          systemImage: filterState.hasActiveFilters ? "xmark.circle" : "line.3.horizontal.decrease.circle",
        )
      }
    }

    IronDatabaseTable(
      database: database,
      filterState: $filterState,
      onAddRow: { database.addRow() },
    )
  }
  .padding()
}

#Preview("IronDatabaseTable - All Features") {
  @Previewable @State var database = createLargePreviewDatabase(rowCount: 100)
  @Previewable @State var selection = Set<IronRow.ID>()
  @Previewable @State var sortState: IronDatabaseSortState?
  @Previewable @State var filterState = IronDatabaseFilterState()

  VStack(alignment: .leading, spacing: 16) {
    HStack {
      VStack(alignment: .leading, spacing: 4) {
        IronText("Selected: \(selection.count) rows", style: .caption, color: .secondary)

        if let sortState {
          IronText(
            "Sorted by column: \(sortState.direction == .ascending ? "↑" : "↓")",
            style: .caption,
            color: .secondary,
          )
        }

        if filterState.hasActiveFilters {
          IronText("Filters active: \(filterState.activeFilterCount)", style: .caption, color: .secondary)
        }
      }

      Spacer()

      HStack(spacing: 8) {
        Button("Select All") {
          selection = Set(database.rows.map(\.id))
        }

        Button("Clear Selection") {
          selection.removeAll()
        }

        Button("Clear Filters") {
          filterState.clear()
        }
        .disabled(!filterState.hasActiveFilters)
      }
      .buttonStyle(.bordered)
    }

    IronDatabaseTable(
      database: database,
      selection: $selection,
      sortState: $sortState,
      filterState: $filterState,
      onAddRow: { database.addRow() },
      onAddColumn: { database.addColumn(name: "New Column", type: .text) },
    )
  }
  .padding()
}

#Preview("IronDatabaseTable - Column Width Modes") {
  @Previewable @State var database: IronDatabase = {
    var db = IronDatabase(name: "Width Test")

    // Fixed width column
    var fixedCol = db.addColumn(name: "Fixed (100pt)", type: .text)
    if let idx = db.columns.firstIndex(where: { $0.id == fixedCol.id }) {
      db.columns[idx].widthMode = .fixed(100)
    }

    // Flexible width column
    var flexCol = db.addColumn(name: "Flexible", type: .text)
    if let idx = db.columns.firstIndex(where: { $0.id == flexCol.id }) {
      db.columns[idx].widthMode = .flexible(min: 80, max: 300)
    }

    // Fill column
    var fillCol = db.addColumn(name: "Fill", type: .text)
    if let idx = db.columns.firstIndex(where: { $0.id == fillCol.id }) {
      db.columns[idx].widthMode = .fill(weight: 1.0)
    }

    // Add sample data
    for i in 1 ... 5 {
      let row = db.addRow()
      db.setValue(.text("Row \(i) - Fixed"), for: row.id, column: fixedCol.id)
      db.setValue(.text("Row \(i) - This text might be long"), for: row.id, column: flexCol.id)
      db.setValue(.text("Row \(i) - Fills remaining space"), for: row.id, column: fillCol.id)
    }

    return db
  }()

  IronDatabaseTable(
    database: database,
    onAddRow: { database.addRow() },
  )
  .padding()
}

#Preview("IronDatabaseTable - Resizable Columns (fitHeader)") {
  @Previewable @State var database: IronDatabase = {
    var db = IronDatabase(name: "Resizable Columns")

    // Fit Header mode - width based on header text
    var statusCol = db.addColumn(name: "Status", type: .select, options: [
      IronSelectOption(name: "OK", color: .success),
      IronSelectOption(name: "X", color: .error),
    ])
    if let idx = db.columns.firstIndex(where: { $0.id == statusCol.id }) {
      db.columns[idx].widthMode = .fitHeader
    }

    // Another fitHeader column with longer name
    var descriptionCol = db.addColumn(name: "Description", type: .text)
    if let idx = db.columns.firstIndex(where: { $0.id == descriptionCol.id }) {
      db.columns[idx].widthMode = .fitHeader
    }

    // Flexible column for comparison
    var notesCol = db.addColumn(name: "Notes (Flexible)", type: .text)
    if let idx = db.columns.firstIndex(where: { $0.id == notesCol.id }) {
      db.columns[idx].widthMode = .flexible(min: 100, max: 400)
    }

    // Fixed non-resizable column
    var idCol = db.addColumn(name: "ID", type: .number)
    if let idx = db.columns.firstIndex(where: { $0.id == idCol.id }) {
      db.columns[idx].widthMode = .fixed(50)
      db.columns[idx].isResizable = false
    }

    // Add sample data
    for i in 1 ... 10 {
      let row = db.addRow()
      db.setValue(.select(statusCol.options[i % 2].id), for: row.id, column: statusCol.id)
      db.setValue(.text("Item \(i) description"), for: row.id, column: descriptionCol.id)
      db.setValue(.text("Additional notes for row \(i)"), for: row.id, column: notesCol.id)
      db.setValue(.number(Double(i)), for: row.id, column: idCol.id)
    }

    return db
  }()

  VStack(alignment: .leading, spacing: 12) {
    IronText(
      "Drag column borders in the header to resize. Use VoiceOver actions for accessibility.",
      style: .caption,
      color: .secondary,
    )

    IronDatabaseTable(
      database: database,
      onAddRow: { database.addRow() },
    )
  }
  .padding()
}

#Preview("IronDatabaseTable - Edit Mode") {
  @Previewable @State var database = createLargePreviewDatabase(rowCount: 20)
  @Previewable @State var selection = Set<IronRow.ID>()
  @Previewable @State var isEditing = false

  NavigationStack {
    VStack(alignment: .leading, spacing: 12) {
      IronText(
        "Tap Edit to enable selection mode",
        style: .caption,
        color: .secondary,
      )

      if !selection.isEmpty {
        IronText("Selected: \(selection.count) rows", style: .bodyMedium, color: .primary)
      }

      IronDatabaseTable(
        database: database,
        selection: $selection,
        isEditing: $isEditing,
        onAddRow: { database.addRow() },
      )
    }
    .padding()
    .navigationTitle("Tasks")
    .toolbar {
      ToolbarItem(placement: .primaryAction) {
        Button(isEditing ? "Done" : "Edit") {
          withAnimation {
            isEditing.toggle()
          }
        }
      }

      if isEditing, !selection.isEmpty {
        ToolbarItem(placement: .bottomBar) {
          Button("Delete \(selection.count) items", role: .destructive) {
            for rowID in selection {
              database.removeRow(rowID)
            }
            selection.removeAll()
          }
        }
      }
    }
  }
}

// MARK: - Preview Helpers

@MainActor
private func createPreviewDatabase() -> IronDatabase {
  let database = IronDatabase(name: "Tasks")

  // Add columns
  let titleColumn = database.addColumn(name: "Title", type: .text)
  let statusColumn = database.addColumn(name: "Status", type: .select, options: [
    IronSelectOption(name: "To Do", color: .secondary),
    IronSelectOption(name: "In Progress", color: .warning),
    IronSelectOption(name: "Done", color: .success),
  ])
  let dueDateColumn = database.addColumn(name: "Due Date", type: .date)
  let priorityColumn = database.addColumn(name: "Priority", type: .number)
  let doneColumn = database.addColumn(name: "Complete", type: .checkbox)

  // Add rows
  let row1 = database.addRow()
  database.setValue(.text("Design new homepage"), for: row1.id, column: titleColumn.id)
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

@MainActor
private func createLargePreviewDatabase(rowCount: Int) -> IronDatabase {
  let database = IronDatabase(name: "Large Dataset")

  // Add columns
  let titleColumn = database.addColumn(name: "Title", type: .text)
  let statusColumn = database.addColumn(name: "Status", type: .select, options: [
    IronSelectOption(name: "To Do", color: .secondary),
    IronSelectOption(name: "In Progress", color: .warning),
    IronSelectOption(name: "Done", color: .success),
  ])
  let dueDateColumn = database.addColumn(name: "Due Date", type: .date)
  let priorityColumn = database.addColumn(name: "Priority", type: .number)
  let doneColumn = database.addColumn(name: "Complete", type: .checkbox)

  // Add many rows
  for i in 0..<rowCount {
    let row = database.addRow()
    database.setValue(.text("Task \(i + 1)"), for: row.id, column: titleColumn.id)
    database.setValue(
      .select(statusColumn.options[i % 3].id),
      for: row.id,
      column: statusColumn.id,
    )
    if i % 2 == 0 {
      database.setValue(
        .date(Calendar.current.date(byAdding: .day, value: i % 30, to: Date())!),
        for: row.id,
        column: dueDateColumn.id,
      )
    }
    database.setValue(.number(Double((i % 5) + 1)), for: row.id, column: priorityColumn.id)
    database.setValue(.checkbox(i % 4 == 0), for: row.id, column: doneColumn.id)
  }

  return database
}
