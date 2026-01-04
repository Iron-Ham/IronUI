import SwiftUI

// MARK: - IronDatabaseTableConfiguration

/// Shared configuration for platform-specific `IronDatabaseTable` implementations.
///
/// This configuration object encapsulates all the bindings, callbacks, and
/// display options needed by both macOS and iOS table implementations.
@MainActor
public struct IronDatabaseTableConfiguration {

  // MARK: Lifecycle

  /// Creates a table configuration.
  ///
  /// - Parameters:
  ///   - database: The database to display (observed automatically).
  ///   - selection: Binding to selected row IDs.
  ///   - sortState: Binding to the current sort state.
  ///   - filterState: Binding to the current filter state.
  ///   - onAddRow: Callback when add row is requested.
  ///   - onAddColumn: Callback when add column is requested.
  ///   - onRowAction: Callback for row context menu actions.
  public init(
    database: IronDatabase,
    selection: Binding<Set<IronRow.ID>>,
    sortState: Binding<IronDatabaseSortState?>,
    filterState: Binding<IronDatabaseFilterState>,
    onAddRow: (() -> Void)?,
    onAddColumn: (() -> Void)?,
    onRowAction: ((IronDatabaseRowAction, IronRow.ID) -> Void)?,
  ) {
    self.database = database
    _selection = selection
    _sortState = sortState
    _filterState = filterState
    self.onAddRow = onAddRow
    self.onAddColumn = onAddColumn
    self.onRowAction = onRowAction
  }

  // MARK: Public

  /// Binding to selected row IDs.
  @Binding public var selection: Set<IronRow.ID>

  /// Binding to the current sort state.
  @Binding public var sortState: IronDatabaseSortState?

  /// Binding to the current filter state.
  @Binding public var filterState: IronDatabaseFilterState

  /// The database to display.
  ///
  /// This is an `@Observable` class - changes are tracked automatically.
  public let database: IronDatabase

  /// Callback when add row is requested.
  public let onAddRow: (() -> Void)?

  /// Callback when add column is requested.
  public let onAddColumn: (() -> Void)?

  /// Callback for row actions.
  public let onRowAction: ((IronDatabaseRowAction, IronRow.ID) -> Void)?

  /// Callback for clearing a cell value.
  ///
  /// When provided, cells will show a "Clear" option in their context menu.
  /// The callback receives the row ID and column ID to clear.
  public var onClearCell: ((IronRow.ID, IronColumn.ID) -> Void)?

  /// Whether to show row numbers.
  public var showsRowNumbers = false

  /// Whether columns can be reordered by dragging.
  public var allowsColumnReordering = true

  /// Whether columns can be resized by dragging.
  public var allowsColumnResizing = true

  /// Whether multiple rows can be selected.
  public var allowsMultipleSelection = true

  /// How row selection is triggered.
  ///
  /// - `.checkboxOnly`: Only the checkbox column triggers selection (default).
  /// - `.fullRowTap`: Tapping any cell toggles selection; checkbox column hidden.
  /// - `.both`: Checkbox visible AND row tap also selects.
  public var rowSelectionMode = RowSelectionMode.checkboxOnly

  /// The height of each data row.
  ///
  /// Defaults to 44pt to meet Apple HIG minimum touch target requirements.
  public var rowHeight: CGFloat = 44

  /// The height of the header row.
  public var headerHeight: CGFloat = 44

  /// The minimum width for any column.
  public var minColumnWidth: CGFloat = 80

  /// The width of the selection column.
  public var selectionColumnWidth: CGFloat = 40

  /// The width of the row number column.
  public var rowNumberColumnWidth: CGFloat = 50

  /// Whether to show the selection column.
  ///
  /// This is computed based on `rowSelectionMode`:
  /// - `.checkboxOnly` or `.both`: Shows the checkbox column.
  /// - `.fullRowTap`: Hides the checkbox column.
  public var showsSelectionColumn: Bool {
    rowSelectionMode != .fullRowTap
  }

  /// Whether to show the add row button.
  public var showsAddRowButton: Bool {
    onAddRow != nil
  }

  /// Whether to show the add column button.
  public var showsAddColumnButton: Bool {
    onAddColumn != nil
  }

  /// The filtered rows based on current filter state.
  public var filteredRows: [IronRow] {
    guard filterState.hasActiveFilters else {
      return database.rows
    }
    return database.rows.filter { row in
      filterState.evaluate(row: row, in: database)
    }
  }

  /// The sorted and filtered rows.
  public var displayRows: [IronRow] {
    let rows = filteredRows

    guard let sortState else {
      return rows
    }

    guard database.column(sortState.columnID) != nil else {
      return rows
    }

    return rows.sorted { rowA, rowB in
      let valueA = rowA.cells[sortState.columnID] ?? .empty
      let valueB = rowB.cells[sortState.columnID] ?? .empty
      return IronDatabaseSortState.compare(valueA, valueB, direction: sortState.direction)
    }
  }

  /// The total width of all columns.
  public var totalColumnsWidth: CGFloat {
    database.columns.reduce(0) { total, column in
      total + (column.width ?? column.resolvedWidth)
    }
  }

  /// Toggles sort on a column.
  ///
  /// If the column is already sorted, toggles the direction.
  /// If a different column is sorted, switches to this column ascending.
  /// If no column is sorted, sorts this column ascending.
  public func toggleSort(for columnID: IronColumn.ID) {
    if let currentState = sortState, currentState.columnID == columnID {
      if currentState.direction == .ascending {
        // Toggle to descending - must create new instance to update binding
        sortState = IronDatabaseSortState(columnID: columnID, direction: .descending)
      } else {
        // Already descending, clear sort
        sortState = nil
      }
    } else {
      sortState = IronDatabaseSortState(columnID: columnID, direction: .ascending)
    }
  }

  /// Checks if a column is currently being sorted.
  public func isSorted(columnID: IronColumn.ID) -> Bool {
    sortState?.columnID == columnID
  }

  /// Checks if a column has an active filter.
  public func isFiltered(columnID: IronColumn.ID) -> Bool {
    filterState.filters[columnID] != nil
  }
}

// MARK: - IronDatabaseRowAction

/// Actions that can be performed on a row.
public enum IronDatabaseRowAction: Sendable, Equatable {
  /// Insert a new row below this row.
  case insertBelow

  /// Insert a new row above this row.
  case insertAbove

  /// Duplicate this row.
  case duplicate

  /// Delete this row.
  case delete
}

// MARK: - RowSelectionMode

/// Determines how row selection is triggered in `IronDatabaseTable`.
public enum RowSelectionMode: Sendable, Equatable {
  /// Selection only via the checkbox column.
  ///
  /// This is the default Notion-style behavior where the checkbox
  /// column is visible and tapping cells starts editing instead of selecting.
  case checkboxOnly

  /// Selection via tapping anywhere on the row.
  ///
  /// The checkbox column is hidden and any cell tap toggles selection.
  /// Editing is triggered via double-tap or long-press.
  case fullRowTap

  /// Both checkbox and full-row tap selection are enabled.
  ///
  /// The checkbox column is visible, but tapping any data cell
  /// also toggles the row's selection state.
  case both
}
