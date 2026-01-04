import Foundation

// MARK: - IronDatabaseSortState

/// Represents the current sort state of an `IronDatabaseTable`.
///
/// Sort state tracks which column is being sorted and in what direction.
/// The table uses view-layer sorting to maintain original row order in
/// the underlying `IronDatabase` while displaying rows in sorted order.
///
/// ## Usage
///
/// ```swift
/// @State private var sortState: IronDatabaseSortState?
///
/// IronDatabaseTable(
///   database: $database,
///   sortState: $sortState
/// )
///
/// // Programmatically set sort
/// sortState = IronDatabaseSortState(
///   columnID: nameColumn.id,
///   direction: .ascending
/// )
/// ```
public struct IronDatabaseSortState: Sendable, Equatable, Hashable {

  // MARK: Lifecycle

  /// Creates a new sort state.
  ///
  /// - Parameters:
  ///   - columnID: The ID of the column to sort by.
  ///   - direction: The sort direction (ascending or descending).
  public init(columnID: UUID, direction: SortDirection) {
    self.columnID = columnID
    self.direction = direction
  }

  // MARK: Public

  /// The ID of the column being sorted.
  public var columnID: UUID

  /// The current sort direction.
  public var direction: SortDirection

  /// Toggles the sort direction.
  public mutating func toggleDirection() {
    direction.toggle()
  }

  /// Creates a new sort state with the opposite direction.
  public func toggled() -> IronDatabaseSortState {
    IronDatabaseSortState(columnID: columnID, direction: direction.toggled)
  }
}

// MARK: IronDatabaseSortState.SortDirection

extension IronDatabaseSortState {

  /// The direction of sorting.
  public enum SortDirection: String, Sendable, CaseIterable, Equatable, Hashable {

    /// Ascending order (A-Z, 0-9, earliest-latest).
    case ascending

    /// Descending order (Z-A, 9-0, latest-earliest).
    case descending

    // MARK: Public

    /// The SF Symbol name for this sort direction.
    public var iconName: String {
      switch self {
      case .ascending:
        "chevron.up"
      case .descending:
        "chevron.down"
      }
    }

    /// The accessibility label for this sort direction.
    public var accessibilityLabel: String {
      switch self {
      case .ascending:
        "Sorted ascending"
      case .descending:
        "Sorted descending"
      }
    }

    /// The opposite direction.
    public var toggled: SortDirection {
      switch self {
      case .ascending:
        .descending
      case .descending:
        .ascending
      }
    }

    /// Toggles between ascending and descending.
    public mutating func toggle() {
      self = toggled
    }
  }
}

// MARK: - Cell Value Comparison

extension IronDatabaseSortState {

  // MARK: Public

  /// Compares two cell values for sorting.
  ///
  /// - Parameters:
  ///   - lhs: The first cell value.
  ///   - rhs: The second cell value.
  ///   - direction: The sort direction.
  /// - Returns: `true` if `lhs` should come before `rhs`.
  public static func compare(
    _ lhs: IronCellValue,
    _ rhs: IronCellValue,
    direction: SortDirection,
  ) -> Bool {
    let ascending = compareAscending(lhs, rhs)
    return direction == .ascending ? ascending : !ascending
  }

  // MARK: Private

  /// Compares two cell values in ascending order.
  ///
  /// Empty values sort to the end.
  private static func compareAscending(_ lhs: IronCellValue, _ rhs: IronCellValue) -> Bool {
    // Empty values always sort to the end
    if lhs.isEmpty, !rhs.isEmpty { return false }
    if !lhs.isEmpty, rhs.isEmpty { return true }
    if lhs.isEmpty, rhs.isEmpty { return false }

    switch (lhs, rhs) {
    case (.text(let a), .text(let b)):
      return a.localizedStandardCompare(b) == .orderedAscending

    case (.number(let a), .number(let b)):
      return a < b

    case (.date(let a), .date(let b)):
      return a < b

    case (.checkbox(let a), .checkbox(let b)):
      // Unchecked before checked
      return !a && b

    case (.email(let a), .email(let b)):
      return a.localizedStandardCompare(b) == .orderedAscending

    case (.phone(let a), .phone(let b)):
      return a.localizedStandardCompare(b) == .orderedAscending

    case (.url(let a), .url(let b)):
      return (a?.absoluteString ?? "").localizedStandardCompare(b?.absoluteString ?? "") == .orderedAscending

    case (.person(let a), .person(let b)):
      return (a?.name ?? "").localizedStandardCompare(b?.name ?? "") == .orderedAscending

    case (.select(let a), .select(let b)):
      // UUIDs sorted by string representation (stable but arbitrary)
      return (a?.uuidString ?? "").localizedStandardCompare(b?.uuidString ?? "") == .orderedAscending

    case (.multiSelect(let a), .multiSelect(let b)):
      // Sort by count, then by first element
      if a.count != b.count {
        return a.count < b.count
      } else {
        let sortedA = a.sorted { $0.uuidString < $1.uuidString }
        let sortedB = b.sorted { $0.uuidString < $1.uuidString }
        return (sortedA.first?.uuidString ?? "") < (sortedB.first?.uuidString ?? "")
      }

    default:
      // Different types: compare by text representation
      return lhs.textValue.localizedStandardCompare(rhs.textValue) == .orderedAscending
    }
  }
}
