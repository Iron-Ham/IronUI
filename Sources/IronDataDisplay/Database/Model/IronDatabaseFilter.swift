import Foundation

// MARK: - IronDatabaseFilter

/// A filter applied to a database column.
///
/// Filters are type-specific, allowing for appropriate filtering operations
/// based on the column's data type. Each filter can evaluate whether a
/// cell value passes its criteria.
///
/// ## Usage
///
/// ```swift
/// // Text filter
/// let filter = IronDatabaseFilter.text(.contains("hello"))
///
/// // Number filter
/// let filter = IronDatabaseFilter.number(.between(min: 10, max: 100))
///
/// // Date filter
/// let filter = IronDatabaseFilter.date(.isThisWeek)
///
/// // Evaluate against a value
/// let passes = filter.evaluate(.text("hello world")) // true
/// ```
public enum IronDatabaseFilter: Sendable, Equatable, Hashable {

  /// Filter for text columns.
  case text(TextFilter)

  /// Filter for number columns.
  case number(NumberFilter)

  /// Filter for date columns.
  case date(DateFilter)

  /// Filter for checkbox columns.
  case checkbox(CheckboxFilter)

  /// Filter for select and multiSelect columns.
  case select(SelectFilter)

  // MARK: Public

  /// A human-readable description of this filter.
  public var description: String {
    switch self {
    case .text(let filter):
      filter.description
    case .number(let filter):
      filter.description
    case .date(let filter):
      filter.description
    case .checkbox(let filter):
      filter.description
    case .select(let filter):
      filter.description
    }
  }

  /// Evaluates whether a cell value passes this filter.
  ///
  /// - Parameter value: The cell value to evaluate.
  /// - Returns: `true` if the value passes the filter.
  public func evaluate(_ value: IronCellValue) -> Bool {
    switch self {
    case .text(let filter):
      filter.evaluate(value)
    case .number(let filter):
      filter.evaluate(value)
    case .date(let filter):
      filter.evaluate(value)
    case .checkbox(let filter):
      filter.evaluate(value)
    case .select(let filter):
      filter.evaluate(value)
    }
  }

}

// MARK: IronDatabaseFilter.TextFilter

extension IronDatabaseFilter {

  /// Filter operations for text-based columns.
  public enum TextFilter: Sendable, Equatable, Hashable {

    /// Text contains the given string (case-insensitive).
    case contains(String)

    /// Text equals the given string exactly (case-insensitive).
    case equals(String)

    /// Text starts with the given string (case-insensitive).
    case startsWith(String)

    /// Text ends with the given string (case-insensitive).
    case endsWith(String)

    /// Text is empty or nil.
    case isEmpty

    /// Text is not empty.
    case isNotEmpty

    // MARK: Public

    /// A human-readable description.
    public var description: String {
      switch self {
      case .contains(let query):
        "contains \"\(query)\""
      case .equals(let query):
        "equals \"\(query)\""
      case .startsWith(let query):
        "starts with \"\(query)\""
      case .endsWith(let query):
        "ends with \"\(query)\""
      case .isEmpty:
        "is empty"
      case .isNotEmpty:
        "is not empty"
      }
    }

    /// Evaluates the filter against a cell value.
    public func evaluate(_ value: IronCellValue) -> Bool {
      let text: String =
        switch value {
        case .text(let s):
          s
        case .email(let s):
          s
        case .phone(let s):
          s
        case .url(let url):
          url?.absoluteString ?? ""
        case .person(let person):
          person?.name ?? ""
        default:
          value.textValue
        }

      switch self {
      case .contains(let query):
        return text.localizedCaseInsensitiveContains(query)
      case .equals(let query):
        return text.localizedCaseInsensitiveCompare(query) == .orderedSame
      case .startsWith(let query):
        return text.lowercased().hasPrefix(query.lowercased())
      case .endsWith(let query):
        return text.lowercased().hasSuffix(query.lowercased())
      case .isEmpty:
        return text.isEmpty
      case .isNotEmpty:
        return !text.isEmpty
      }
    }

  }
}

// MARK: IronDatabaseFilter.NumberFilter

extension IronDatabaseFilter {

  /// Filter operations for numeric columns.
  public enum NumberFilter: Sendable, Equatable, Hashable {

    /// Number equals the given value.
    case equals(Double)

    /// Number is greater than the given value.
    case greaterThan(Double)

    /// Number is less than the given value.
    case lessThan(Double)

    /// Number is greater than or equal to the given value.
    case greaterThanOrEqual(Double)

    /// Number is less than or equal to the given value.
    case lessThanOrEqual(Double)

    /// Number is between min and max (inclusive).
    case between(min: Double, max: Double)

    /// Number is empty/nil.
    case isEmpty

    /// Number is not empty.
    case isNotEmpty

    // MARK: Public

    /// A human-readable description.
    public var description: String {
      switch self {
      case .equals(let value):
        "= \(value.formatted())"
      case .greaterThan(let value):
        "> \(value.formatted())"
      case .lessThan(let value):
        "< \(value.formatted())"
      case .greaterThanOrEqual(let value):
        ">= \(value.formatted())"
      case .lessThanOrEqual(let value):
        "<= \(value.formatted())"
      case .between(let min, let max):
        "\(min.formatted()) - \(max.formatted())"
      case .isEmpty:
        "is empty"
      case .isNotEmpty:
        "is not empty"
      }
    }

    /// Evaluates the filter against a cell value.
    public func evaluate(_ value: IronCellValue) -> Bool {
      guard case .number(let number) = value else {
        // For isEmpty/isNotEmpty, check if value is empty
        switch self {
        case .isEmpty:
          return value.isEmpty
        case .isNotEmpty:
          return !value.isEmpty
        default:
          return false
        }
      }

      switch self {
      case .equals(let target):
        return abs(number - target) < .ulpOfOne
      case .greaterThan(let target):
        return number > target
      case .lessThan(let target):
        return number < target
      case .greaterThanOrEqual(let target):
        return number >= target
      case .lessThanOrEqual(let target):
        return number <= target
      case .between(let min, let max):
        return number >= min && number <= max
      case .isEmpty:
        return false // Already handled above
      case .isNotEmpty:
        return true // Already handled above
      }
    }

  }
}

// MARK: IronDatabaseFilter.DateFilter

extension IronDatabaseFilter {

  /// Filter operations for date columns.
  public enum DateFilter: Sendable, Equatable, Hashable {

    /// Date equals the given date (same day).
    case equals(Date)

    /// Date is before the given date.
    case before(Date)

    /// Date is after the given date.
    case after(Date)

    /// Date is between start and end (inclusive).
    case between(start: Date, end: Date)

    /// Date is today.
    case isToday

    /// Date is within the current week.
    case isThisWeek

    /// Date is within the current month.
    case isThisMonth

    /// Date is within the past N days.
    case pastDays(Int)

    /// Date is within the next N days.
    case nextDays(Int)

    /// Date is empty/nil.
    case isEmpty

    /// Date is not empty.
    case isNotEmpty

    // MARK: Public

    /// A human-readable description.
    public var description: String {
      switch self {
      case .equals(let date):
        "is \(date.formatted(date: .abbreviated, time: .omitted))"
      case .before(let date):
        "before \(date.formatted(date: .abbreviated, time: .omitted))"
      case .after(let date):
        "after \(date.formatted(date: .abbreviated, time: .omitted))"
      case .between(let start, let end):
        "\(start.formatted(date: .abbreviated, time: .omitted)) - \(end.formatted(date: .abbreviated, time: .omitted))"
      case .isToday:
        "is today"
      case .isThisWeek:
        "is this week"
      case .isThisMonth:
        "is this month"
      case .pastDays(let days):
        "past \(days) days"
      case .nextDays(let days):
        "next \(days) days"
      case .isEmpty:
        "is empty"
      case .isNotEmpty:
        "is not empty"
      }
    }

    /// Evaluates the filter against a cell value.
    public func evaluate(_ value: IronCellValue) -> Bool {
      guard case .date(let date) = value else {
        switch self {
        case .isEmpty:
          return value.isEmpty
        case .isNotEmpty:
          return !value.isEmpty
        default:
          return false
        }
      }

      let calendar = Calendar.current

      switch self {
      case .equals(let target):
        return calendar.isDate(date, inSameDayAs: target)

      case .before(let target):
        return date < calendar.startOfDay(for: target)

      case .after(let target):
        return date >= calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: target) ?? target)

      case .between(let start, let end):
        let startOfStart = calendar.startOfDay(for: start)
        let endOfEnd = calendar.startOfDay(for: calendar.date(byAdding: .day, value: 1, to: end) ?? end)
        return date >= startOfStart && date < endOfEnd

      case .isToday:
        return calendar.isDateInToday(date)

      case .isThisWeek:
        return calendar.isDate(date, equalTo: Date(), toGranularity: .weekOfYear)

      case .isThisMonth:
        return calendar.isDate(date, equalTo: Date(), toGranularity: .month)

      case .pastDays(let days):
        guard let pastDate = calendar.date(byAdding: .day, value: -days, to: Date()) else {
          return false
        }
        return date >= calendar.startOfDay(for: pastDate) && date <= Date()

      case .nextDays(let days):
        guard let futureDate = calendar.date(byAdding: .day, value: days, to: Date()) else {
          return false
        }
        return date >= Date() && date <= calendar.startOfDay(
          for: calendar.date(byAdding: .day, value: 1, to: futureDate) ?? futureDate
        )

      case .isEmpty:
        return false

      case .isNotEmpty:
        return true
      }
    }

  }
}

// MARK: IronDatabaseFilter.CheckboxFilter

extension IronDatabaseFilter {

  /// Filter operations for checkbox columns.
  public enum CheckboxFilter: Sendable, Equatable, Hashable {

    /// Checkbox is checked (true).
    case checked

    /// Checkbox is unchecked (false).
    case unchecked

    // MARK: Public

    /// A human-readable description.
    public var description: String {
      switch self {
      case .checked:
        "is checked"
      case .unchecked:
        "is unchecked"
      }
    }

    /// Evaluates the filter against a cell value.
    public func evaluate(_ value: IronCellValue) -> Bool {
      guard case .checkbox(let isChecked) = value else {
        return false
      }

      switch self {
      case .checked:
        return isChecked
      case .unchecked:
        return !isChecked
      }
    }

  }
}

// MARK: IronDatabaseFilter.SelectFilter

extension IronDatabaseFilter {

  /// Filter operations for select and multiSelect columns.
  public enum SelectFilter: Sendable, Equatable, Hashable {

    /// Value includes any of the given option IDs.
    case includes(Set<UUID>)

    /// Value excludes all of the given option IDs.
    case excludes(Set<UUID>)

    /// No option is selected.
    case isEmpty

    /// At least one option is selected.
    case isNotEmpty

    // MARK: Public

    /// A human-readable description.
    public var description: String {
      switch self {
      case .includes(let ids):
        "includes \(ids.count) option(s)"
      case .excludes(let ids):
        "excludes \(ids.count) option(s)"
      case .isEmpty:
        "is empty"
      case .isNotEmpty:
        "is not empty"
      }
    }

    /// Evaluates the filter against a cell value.
    public func evaluate(_ value: IronCellValue) -> Bool {
      let selectedIDs: Set<UUID> =
        switch value {
        case .select(let id):
          id.map { Set([$0]) } ?? []
        case .multiSelect(let ids):
          ids
        default:
          []
        }

      switch self {
      case .includes(let targetIDs):
        return !selectedIDs.isDisjoint(with: targetIDs)
      case .excludes(let targetIDs):
        return selectedIDs.isDisjoint(with: targetIDs)
      case .isEmpty:
        return selectedIDs.isEmpty
      case .isNotEmpty:
        return !selectedIDs.isEmpty
      }
    }

  }
}

// MARK: - IronDatabaseFilterState

/// Container for all active filters on a database.
///
/// Filter state manages multiple column filters and determines
/// how they combine (AND or OR logic).
///
/// ## Usage
///
/// ```swift
/// @State private var filterState = IronDatabaseFilterState()
///
/// // Add a filter
/// filterState.filters[nameColumnID] = .text(.contains("John"))
/// filterState.filters[ageColumnID] = .number(.greaterThan(18))
///
/// // Clear all filters
/// filterState.clear()
/// ```
public struct IronDatabaseFilterState: Sendable, Equatable, Hashable {

  // MARK: Lifecycle

  /// Creates an empty filter state.
  public init() {
    filters = [:]
    mode = .and
  }

  /// Creates a filter state with initial filters.
  ///
  /// - Parameters:
  ///   - filters: Initial filters by column ID.
  ///   - mode: The filter combination mode.
  public init(filters: [UUID: IronDatabaseFilter], mode: FilterMode = .and) {
    self.filters = filters
    self.mode = mode
  }

  // MARK: Public

  /// Active filters by column ID.
  public var filters: [UUID: IronDatabaseFilter]

  /// How filters are combined.
  public var mode: FilterMode

  /// Whether any filters are active.
  public var hasActiveFilters: Bool {
    !filters.isEmpty
  }

  /// The number of active filters.
  public var activeFilterCount: Int {
    filters.count
  }

  /// Evaluates whether a row passes all filters.
  ///
  /// - Parameters:
  ///   - row: The row to evaluate.
  ///   - database: The database containing the row.
  /// - Returns: `true` if the row passes all filters.
  public func evaluate(row: IronRow, in _: IronDatabase) -> Bool {
    guard !filters.isEmpty else { return true }

    let results = filters.map { columnID, filter in
      let value = row.cells[columnID] ?? .empty
      return filter.evaluate(value)
    }

    switch mode {
    case .and:
      return results.allSatisfy { $0 }
    case .or:
      return results.contains { $0 }
    }
  }

  /// Clears all filters.
  public mutating func clear() {
    filters.removeAll()
  }

  /// Removes the filter for a specific column.
  ///
  /// - Parameter columnID: The column ID.
  public mutating func removeFilter(for columnID: UUID) {
    filters.removeValue(forKey: columnID)
  }
}

// MARK: IronDatabaseFilterState.FilterMode

extension IronDatabaseFilterState {

  /// How multiple filters are combined.
  public enum FilterMode: String, Sendable, CaseIterable, Equatable, Hashable {

    /// All filters must pass (logical AND).
    case and

    /// Any filter must pass (logical OR).
    case or

    // MARK: Public

    /// The display name for this mode.
    public var displayName: String {
      switch self {
      case .and:
        "All"
      case .or:
        "Any"
      }
    }

    /// The accessibility label.
    public var accessibilityLabel: String {
      switch self {
      case .and:
        "Match all filters"
      case .or:
        "Match any filter"
      }
    }
  }
}
