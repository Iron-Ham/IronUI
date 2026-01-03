import Foundation
import SwiftUI

// MARK: - IronDatabaseTableCoordinatorProtocol

/// Protocol for platform-specific table coordinators.
///
/// This protocol defines the shared interface that both macOS and iOS
/// coordinators implement for managing table data and state.
@MainActor
public protocol IronDatabaseTableCoordinatorProtocol: AnyObject {

  /// The table configuration.
  var configuration: IronDatabaseTableConfiguration { get set }

  /// Reloads all table data.
  func reloadData()

  /// Reloads specific rows.
  func reloadRows(_ rowIDs: Set<IronRow.ID>)

  /// Reloads specific columns.
  func reloadColumns(_ columnIDs: Set<IronColumn.ID>)

  /// Updates column widths in the native table.
  func applyColumnWidths()

  /// Scrolls to make a row visible.
  func scrollToRow(_ rowID: IronRow.ID)

  /// Begins editing a cell.
  func beginEditing(row: IronRow.ID, column: IronColumn.ID)

  /// Ends editing the current cell.
  func endEditing()
}

// MARK: - IronDatabaseTableCoordinatorBase

/// Base class providing shared logic for table coordinators.
///
/// Platform-specific coordinators inherit from this class to share
/// common sorting, filtering, and data management logic.
@MainActor
open class IronDatabaseTableCoordinatorBase: NSObject {

  // MARK: Lifecycle

  /// Creates a coordinator with the given configuration.
  public init(configuration: IronDatabaseTableConfiguration) {
    self.configuration = configuration
    super.init()
    recomputeDisplayIndices()
  }

  // MARK: Open

  /// Recomputes the display indices based on current sort and filter state.
  ///
  /// Subclasses should call this when sort or filter state changes.
  open func recomputeDisplayIndices() {
    let database = configuration.database

    // Apply filtering
    var indices: [Int] =
      if configuration.filterState.hasActiveFilters {
        database.rows.indices.filter { index in
          configuration.filterState.evaluate(row: database.rows[index], in: database)
        }
      } else {
        Array(database.rows.indices)
      }

    // Apply sorting
    if
      let sortState = configuration.sortState,
      database.column(sortState.columnID) != nil
    {
      indices.sort { indexA, indexB in
        let valueA = database.rows[indexA].cells[sortState.columnID] ?? .empty
        let valueB = database.rows[indexB].cells[sortState.columnID] ?? .empty
        return IronDatabaseSortState.compare(valueA, valueB, direction: sortState.direction)
      }
    }

    displayRowIndices = indices
  }

  // MARK: Public

  /// The table configuration.
  public var configuration: IronDatabaseTableConfiguration

  /// Indices into the database.rows array, in display order.
  ///
  /// This array accounts for both filtering and sorting,
  /// mapping display positions to actual row indices.
  public private(set) var displayRowIndices = [Int]()

  /// The currently editing cell, if any.
  public var editingCell: CellIdentifier?

  /// The number of rows to display.
  public var displayRowCount: Int {
    displayRowIndices.count
  }

  /// Returns the row at a display index.
  ///
  /// - Parameter displayIndex: The index in the displayed (sorted/filtered) list.
  /// - Returns: The row at that display position.
  public func row(at displayIndex: Int) -> IronRow? {
    guard displayIndex >= 0, displayIndex < displayRowIndices.count else {
      return nil
    }
    let actualIndex = displayRowIndices[displayIndex]
    return configuration.database.rows[safe: actualIndex]
  }

  /// Returns the display index for a row ID.
  ///
  /// - Parameter rowID: The row ID to find.
  /// - Returns: The display index, or nil if not displayed.
  public func displayIndex(for rowID: IronRow.ID) -> Int? {
    displayRowIndices.firstIndex { actualIndex in
      configuration.database.rows[safe: actualIndex]?.id == rowID
    }
  }

  /// Returns the actual row index for a row ID.
  ///
  /// - Parameter rowID: The row ID to find.
  /// - Returns: The index in database.rows, or nil if not found.
  public func actualIndex(for rowID: IronRow.ID) -> Int? {
    configuration.database.rows.firstIndex { $0.id == rowID }
  }

  /// Creates a binding for a cell value.
  ///
  /// - Parameters:
  ///   - rowID: The row ID.
  ///   - columnID: The column ID.
  /// - Returns: A binding to the cell value.
  public func cellValueBinding(row rowID: IronRow.ID, column columnID: IronColumn.ID) -> Binding<IronCellValue> {
    Binding(
      get: { [weak self] in
        self?.configuration.database.value(for: rowID, column: columnID) ?? .empty
      },
      set: { [weak self] newValue in
        self?.configuration.database.setValue(newValue, for: rowID, column: columnID)
      },
    )
  }

  /// Toggles selection for a row.
  ///
  /// - Parameter rowID: The row ID to toggle.
  public func toggleSelection(for rowID: IronRow.ID) {
    if configuration.selection.contains(rowID) {
      configuration.selection.remove(rowID)
    } else {
      if !configuration.allowsMultipleSelection {
        configuration.selection.removeAll()
      }
      configuration.selection.insert(rowID)
    }
  }

  /// Selects all visible rows.
  public func selectAll() {
    let allIDs = displayRowIndices.compactMap { index in
      configuration.database.rows[safe: index]?.id
    }
    configuration.selection = Set(allIDs)
  }

  /// Deselects all rows.
  public func deselectAll() {
    configuration.selection.removeAll()
  }
}

// MARK: - CellIdentifier

/// Identifies a specific cell in the table.
public struct CellIdentifier: Equatable, Hashable, Sendable {

  /// Creates a cell identifier.
  public init(rowID: IronRow.ID, columnID: IronColumn.ID) {
    self.rowID = rowID
    self.columnID = columnID
  }

  /// The row ID.
  public let rowID: IronRow.ID

  /// The column ID.
  public let columnID: IronColumn.ID

}

// MARK: - Array Safe Subscript

extension Array {
  /// Safe subscript that returns nil for out-of-bounds indices.
  subscript(safe index: Int) -> Element? {
    indices.contains(index) ? self[index] : nil
  }
}
