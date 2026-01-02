import IronCore
import IronPrimitives
import SwiftUI

// MARK: - IronDatabaseTable

/// A Notion-style table view for displaying and editing database content.
///
/// `IronDatabaseTable` provides a grid-based view of an `IronDatabase` with
/// support for inline editing, row selection, and column management.
///
/// ## Basic Usage
///
/// ```swift
/// @State private var database = IronDatabase(name: "Tasks")
///
/// IronDatabaseTable(database: $database)
/// ```
///
/// ## With Selection
///
/// ```swift
/// @State private var selection: Set<IronRow.ID> = []
///
/// IronDatabaseTable(
///   database: $database,
///   selection: $selection
/// )
/// ```
///
/// ## With Add Callbacks
///
/// ```swift
/// IronDatabaseTable(
///   database: $database,
///   onAddRow: { database.addRow() },
///   onAddColumn: { showColumnSheet = true }
/// )
/// ```
public struct IronDatabaseTable: View {

  // MARK: Lifecycle

  /// Creates a database table view.
  ///
  /// - Parameters:
  ///   - database: Binding to the database.
  ///   - selection: Binding to selected row IDs.
  ///   - onAddRow: Callback when the add row button is tapped.
  ///   - onAddColumn: Callback when the add column button is tapped.
  public init(
    database: Binding<IronDatabase>,
    selection: Binding<Set<IronRow.ID>> = .constant([]),
    onAddRow: (() -> Void)? = nil,
    onAddColumn: (() -> Void)? = nil,
  ) {
    _database = database
    _selection = selection
    self.onAddRow = onAddRow
    self.onAddColumn = onAddColumn
  }

  // MARK: Public

  public var body: some View {
    ScrollView(.horizontal, showsIndicators: true) {
      VStack(alignment: .leading, spacing: 0) {
        // Header row - stays fixed at top
        headerRow

        IronDivider()

        // Data rows - vertical scroll only
        ScrollView(.vertical, showsIndicators: true) {
          VStack(alignment: .leading, spacing: 0) {
            ForEach(database.rows) { row in
              dataRow(for: row)
              IronDivider()
            }

            // Add row button
            if onAddRow != nil {
              addRowButton
            }
          }
        }
      }
      .frame(minWidth: totalWidth)
    }
    .background(theme.colors.surface)
    .clipShape(RoundedRectangle(cornerRadius: theme.radii.md))
    .overlay(
      RoundedRectangle(cornerRadius: theme.radii.md)
        .strokeBorder(theme.colors.border, lineWidth: 1)
    )
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  @Binding private var database: IronDatabase
  @Binding private var selection: Set<IronRow.ID>

  @State private var editingCell: CellID?
  @State private var hoveredRow: IronRow.ID?

  @ScaledMetric(relativeTo: .body)
  private var defaultColumnWidth: CGFloat = 150
  @ScaledMetric(relativeTo: .body)
  private var rowHeight: CGFloat = 40
  @ScaledMetric(relativeTo: .body)
  private var selectionColumnWidth: CGFloat = 40

  private let onAddRow: (() -> Void)?
  private let onAddColumn: (() -> Void)?

  private var totalWidth: CGFloat {
    let columnsWidth = database.columns.reduce(0) { $0 + ($1.width ?? defaultColumnWidth) }
    let addColumnWidth: CGFloat = onAddColumn != nil ? 44 : 0
    return selectionColumnWidth + columnsWidth + addColumnWidth + theme.spacing.md * 2
  }

  private var headerRow: some View {
    HStack(spacing: 0) {
      // Selection column header
      Rectangle()
        .fill(Color.clear)
        .frame(width: selectionColumnWidth)

      // Column headers
      ForEach(database.columns) { column in
        columnHeader(for: column)
      }

      // Add column button
      if onAddColumn != nil {
        addColumnButton
      }
    }
    .frame(height: rowHeight)
    .background(theme.colors.surfaceElevated)
  }

  private var addColumnButton: some View {
    Button {
      onAddColumn?()
    } label: {
      IronIcon(systemName: "plus", size: .small, color: .secondary)
    }
    .buttonStyle(.plain)
    .frame(width: 44, height: rowHeight)
    .contentShape(Rectangle())
    .accessibilityLabel("Add column")
  }

  private var addRowButton: some View {
    Button {
      onAddRow?()
    } label: {
      HStack(spacing: theme.spacing.sm) {
        IronIcon(systemName: "plus", size: .small, color: .secondary)
        IronText("New", style: .bodyMedium, color: .secondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, theme.spacing.md)
      .frame(height: rowHeight)
    }
    .buttonStyle(.plain)
    .accessibilityLabel("Add row")
  }

  private func columnHeader(for column: IronColumn) -> some View {
    HStack(spacing: theme.spacing.xs) {
      IronIcon(systemName: column.type.iconName, size: .small, color: .secondary)
      IronText(column.name, style: .labelMedium, color: .secondary)
      Spacer()
    }
    .padding(.horizontal, theme.spacing.sm)
    .frame(width: column.width ?? defaultColumnWidth, height: rowHeight)
    .contentShape(Rectangle())
    .contextMenu {
      columnContextMenu(for: column)
    }
  }

  @ViewBuilder
  private func columnContextMenu(for column: IronColumn) -> some View {
    Button {
      // Edit column name - could show a popover
    } label: {
      Label("Rename", systemImage: "pencil")
    }

    Menu("Change Type") {
      ForEach(IronColumnType.allCases, id: \.self) { type in
        Button {
          if let index = database.columns.firstIndex(where: { $0.id == column.id }) {
            database.columns[index].type = type
          }
        } label: {
          Label(type.displayName, systemImage: type.iconName)
        }
      }
    }

    Divider()

    Button(role: .destructive) {
      database.removeColumn(column.id)
    } label: {
      Label("Delete Column", systemImage: "trash")
    }
  }

  private func dataRow(for row: IronRow) -> some View {
    HStack(spacing: 0) {
      // Selection checkbox
      selectionCell(for: row)

      // Data cells
      ForEach(database.columns) { column in
        dataCell(for: row, column: column)
      }

      // Spacer for add column
      if onAddColumn != nil {
        Spacer()
          .frame(width: 44)
      }
    }
    .frame(height: rowHeight)
    .background(rowBackground(for: row))
    .onHover { isHovered in
      hoveredRow = isHovered ? row.id : nil
    }
    .contextMenu {
      rowContextMenu(for: row)
    }
  }

  private func selectionCell(for row: IronRow) -> some View {
    Button {
      if selection.contains(row.id) {
        selection.remove(row.id)
      } else {
        selection.insert(row.id)
      }
    } label: {
      IronIcon(
        systemName: selection.contains(row.id) ? "checkmark.square.fill" : "square",
        size: .small,
        color: selection.contains(row.id) ? .primary : .secondary,
      )
    }
    .buttonStyle(.plain)
    .frame(width: selectionColumnWidth, height: rowHeight)
    .opacity(selection.contains(row.id) || hoveredRow == row.id ? 1 : 0)
    .animation(.easeInOut(duration: 0.15), value: hoveredRow)
    .accessibilityLabel(selection.contains(row.id) ? "Selected" : "Not selected")
  }

  private func dataCell(for row: IronRow, column: IronColumn) -> some View {
    let cellID = CellID(rowID: row.id, columnID: column.id)
    let isEditing = editingCell == cellID

    return IronDatabaseCell(
      column: column,
      value: cellValueBinding(row: row.id, column: column.id),
      isEditing: isEditing,
    )
    .padding(.horizontal, theme.spacing.sm)
    .frame(width: column.width ?? defaultColumnWidth, height: rowHeight, alignment: .leading)
    .contentShape(Rectangle())
    .onTapGesture {
      // Only allow editing for editable column types
      if column.type != .checkbox {
        editingCell = cellID
      }
    }
    .onSubmit {
      editingCell = nil
    }
  }

  private func cellValueBinding(row rowID: IronRow.ID, column columnID: IronColumn.ID) -> Binding<IronCellValue> {
    Binding(
      get: { database.value(for: rowID, column: columnID) },
      set: { database.setValue($0, for: rowID, column: columnID) },
    )
  }

  private func rowBackground(for row: IronRow) -> some View {
    Group {
      if selection.contains(row.id) {
        theme.colors.primary.opacity(0.1)
      } else if hoveredRow == row.id {
        theme.colors.surface.opacity(0.5)
      } else {
        Color.clear
      }
    }
  }

  @ViewBuilder
  private func rowContextMenu(for row: IronRow) -> some View {
    Button {
      database.addRow()
    } label: {
      Label("Insert Row Below", systemImage: "plus")
    }

    Divider()

    Button(role: .destructive) {
      selection.remove(row.id)
      database.removeRow(row.id)
    } label: {
      Label("Delete Row", systemImage: "trash")
    }
  }

}

// MARK: - CellID

private struct CellID: Equatable, Hashable {
  let rowID: IronRow.ID
  let columnID: IronColumn.ID
}

// MARK: - Previews

#Preview("IronDatabaseTable - Basic") {
  @Previewable @State var database = createPreviewDatabase()

  IronDatabaseTable(
    database: $database,
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
      database: $database,
      selection: $selection,
      onAddRow: { database.addRow() },
    )
  }
  .padding()
}

#Preview("IronDatabaseTable - Empty") {
  @Previewable @State var database = IronDatabase(name: "Empty Database")

  IronDatabaseTable(
    database: $database,
    onAddRow: { database.addRow() },
    onAddColumn: { database.addColumn(name: "Column", type: .text) },
  )
  .padding()
}

// MARK: - Preview Helpers

private func createPreviewDatabase() -> IronDatabase {
  var database = IronDatabase(name: "Tasks")

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
  database.setValue(.date(Calendar.current.date(byAdding: .day, value: -2, to: Date())!), for: row3.id, column: dueDateColumn.id)
  database.setValue(.number(1), for: row3.id, column: priorityColumn.id)
  database.setValue(.checkbox(true), for: row3.id, column: doneColumn.id)

  return database
}
