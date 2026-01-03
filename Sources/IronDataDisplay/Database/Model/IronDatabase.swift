import Foundation
import IronCore
import SwiftUI

// MARK: - IronDatabase

/// A runtime-configurable database with rows and columns.
///
/// `IronDatabase` provides a Notion-style inline database where users can
/// add, remove, and reorder columns at runtime. Each column has a type
/// that determines how cells are edited and displayed.
///
/// ## Basic Usage
///
/// ```swift
/// var database = IronDatabase(name: "Tasks")
///
/// // Add columns
/// database.addColumn(name: "Title", type: .text)
/// database.addColumn(name: "Status", type: .select, options: [
///   IronSelectOption(name: "To Do", color: .secondary),
///   IronSelectOption(name: "Done", color: .success),
/// ])
///
/// // Add rows
/// let row = database.addRow()
/// database.setValue(.text("My Task"), for: row.id, column: titleColumn.id)
/// ```
public struct IronDatabase: Identifiable, Sendable, Equatable {

  // MARK: Lifecycle

  /// Creates a new database with a name.
  ///
  /// - Parameter name: The display name of the database.
  public init(name: String) {
    id = UUID()
    self.name = name
    columns = []
    rows = []
  }

  /// Creates a database with existing data.
  ///
  /// - Parameters:
  ///   - id: The unique identifier.
  ///   - name: The display name.
  ///   - columns: The column definitions.
  ///   - rows: The data rows.
  public init(
    id: UUID = UUID(),
    name: String,
    columns: [IronColumn],
    rows: [IronRow],
  ) {
    self.id = id
    self.name = name
    self.columns = columns
    self.rows = rows
  }

  // MARK: Public

  /// The unique identifier for the database.
  public let id: UUID

  /// The display name of the database.
  public var name: String

  /// The column definitions, in display order.
  public var columns: [IronColumn]

  /// The data rows.
  public var rows: [IronRow]

  /// Adds a new column to the database.
  ///
  /// - Parameters:
  ///   - name: The column header name.
  ///   - type: The data type for cells in this column.
  ///   - options: Select options (for `.select` and `.multiSelect` types).
  /// - Returns: The created column.
  @discardableResult
  public mutating func addColumn(
    name: String,
    type: IronColumnType,
    options: [IronSelectOption] = [],
  ) -> IronColumn {
    let column = IronColumn(name: name, type: type, options: options)
    columns.append(column)
    return column
  }

  /// Removes a column and all associated cell data.
  ///
  /// - Parameter columnID: The ID of the column to remove.
  public mutating func removeColumn(_ columnID: IronColumn.ID) {
    columns.removeAll { $0.id == columnID }
    for index in rows.indices {
      rows[index].cells.removeValue(forKey: columnID)
    }
  }

  /// Moves a column to a new position.
  ///
  /// - Parameters:
  ///   - fromIndex: The current index of the column.
  ///   - toIndex: The destination index.
  public mutating func moveColumn(from fromIndex: Int, to toIndex: Int) {
    guard
      fromIndex != toIndex,
      fromIndex >= 0, fromIndex < columns.count,
      toIndex >= 0, toIndex < columns.count
    else {
      return
    }
    let column = columns.remove(at: fromIndex)
    columns.insert(column, at: toIndex)
  }

  /// Adds a new empty row to the database.
  ///
  /// - Returns: The created row.
  @discardableResult
  public mutating func addRow() -> IronRow {
    let row = IronRow()
    rows.append(row)
    return row
  }

  /// Removes a row.
  ///
  /// - Parameter rowID: The ID of the row to remove.
  public mutating func removeRow(_ rowID: IronRow.ID) {
    rows.removeAll { $0.id == rowID }
  }

  /// Moves a row to a new position.
  ///
  /// - Parameters:
  ///   - fromIndex: The current index of the row.
  ///   - toIndex: The destination index.
  public mutating func moveRow(from fromIndex: Int, to toIndex: Int) {
    guard
      fromIndex != toIndex,
      fromIndex >= 0, fromIndex < rows.count,
      toIndex >= 0, toIndex < rows.count
    else {
      return
    }
    let row = rows.remove(at: fromIndex)
    rows.insert(row, at: toIndex)
  }

  /// Gets the value for a cell.
  ///
  /// - Parameters:
  ///   - rowID: The row ID.
  ///   - columnID: The column ID.
  /// - Returns: The cell value, or `.empty` if not set.
  public func value(for rowID: IronRow.ID, column columnID: IronColumn.ID) -> IronCellValue {
    guard let rowIndex = rows.firstIndex(where: { $0.id == rowID }) else {
      return .empty
    }
    return rows[rowIndex].cells[columnID] ?? .empty
  }

  /// Sets the value for a cell.
  ///
  /// - Parameters:
  ///   - value: The value to set.
  ///   - rowID: The row ID.
  ///   - columnID: The column ID.
  public mutating func setValue(
    _ value: IronCellValue,
    for rowID: IronRow.ID,
    column columnID: IronColumn.ID,
  ) {
    guard let rowIndex = rows.firstIndex(where: { $0.id == rowID }) else {
      return
    }
    rows[rowIndex].cells[columnID] = value
  }

  /// Gets a column by ID.
  ///
  /// - Parameter columnID: The column ID.
  /// - Returns: The column, or nil if not found.
  public func column(_ columnID: IronColumn.ID) -> IronColumn? {
    columns.first { $0.id == columnID }
  }

  /// Gets a row by ID.
  ///
  /// - Parameter rowID: The row ID.
  /// - Returns: The row, or nil if not found.
  public func row(_ rowID: IronRow.ID) -> IronRow? {
    rows.first { $0.id == rowID }
  }
}

// MARK: - IronColumn

/// A column definition in an IronDatabase.
///
/// Columns define the schema of the database. Each column has a type
/// that determines how cell values are displayed and edited.
public struct IronColumn: Identifiable, Sendable, Equatable {

  // MARK: Lifecycle

  /// Creates a new column.
  ///
  /// - Parameters:
  ///   - id: The unique identifier (auto-generated if not provided).
  ///   - name: The column header name.
  ///   - type: The data type for cells.
  ///   - width: Optional fixed width (legacy, prefer `widthMode`).
  ///   - widthMode: The column width mode.
  ///   - options: Select options (for select types).
  ///   - isResizable: Whether the user can resize this column.
  ///   - isSortable: Whether this column can be sorted.
  public init(
    id: UUID = UUID(),
    name: String,
    type: IronColumnType,
    width: CGFloat? = nil,
    widthMode: IronColumnWidthMode = .default,
    options: [IronSelectOption] = [],
    isResizable: Bool = true,
    isSortable: Bool = true,
  ) {
    self.id = id
    self.name = name
    self.type = type
    self.width = width
    self.widthMode = widthMode
    self.options = options
    self.isResizable = isResizable
    self.isSortable = isSortable
  }

  // MARK: Public

  /// The unique identifier for the column.
  public let id: UUID

  /// The display name in the column header.
  public var name: String

  /// The data type for cells in this column.
  public var type: IronColumnType

  /// Optional fixed width for the column (legacy).
  ///
  /// Prefer using `widthMode` for more flexible column sizing.
  /// If set, this takes precedence over `widthMode`.
  public var width: CGFloat?

  /// The width mode for this column.
  ///
  /// Determines how the column width is calculated. If `width` is set,
  /// it takes precedence over this property.
  public var widthMode: IronColumnWidthMode

  /// Select options (for `.select` and `.multiSelect` types).
  public var options: [IronSelectOption]

  /// Whether the user can resize this column by dragging.
  public var isResizable: Bool

  /// Whether this column can be sorted.
  public var isSortable: Bool

  /// The resolved width for this column.
  ///
  /// Returns the explicit `width` if set, otherwise calculates
  /// based on `widthMode`. For modes that require container width
  /// or content measurement, returns the minimum width.
  public var resolvedWidth: CGFloat {
    if let width {
      return width
    }
    return widthMode.minimumWidth
  }
}

// MARK: - IronColumnType

/// The data type for a database column.
public enum IronColumnType: String, Sendable, CaseIterable, Equatable {
  /// Plain text content.
  case text
  /// Numeric value.
  case number
  /// Date value.
  case date
  /// Boolean checkbox.
  case checkbox
  /// Single-select from options.
  case select
  /// Multi-select from options.
  case multiSelect
  /// Person/user reference.
  case person
  /// URL link.
  case url
  /// Email address.
  case email
  /// Phone number.
  case phone

  // MARK: Public

  /// The system icon name for this column type.
  public var iconName: String {
    switch self {
    case .text: "text.alignleft"
    case .number: "number"
    case .date: "calendar"
    case .checkbox: "checkmark.square"
    case .select: "list.bullet"
    case .multiSelect: "checklist"
    case .person: "person"
    case .url: "link"
    case .email: "envelope"
    case .phone: "phone"
    }
  }

  /// The display name for this column type.
  public var displayName: String {
    switch self {
    case .text: "Text"
    case .number: "Number"
    case .date: "Date"
    case .checkbox: "Checkbox"
    case .select: "Select"
    case .multiSelect: "Multi-select"
    case .person: "Person"
    case .url: "URL"
    case .email: "Email"
    case .phone: "Phone"
    }
  }
}

// MARK: - IronRow

/// A data row in an IronDatabase.
///
/// Rows contain cell values mapped by column ID.
public struct IronRow: Identifiable, Sendable, Equatable {

  // MARK: Lifecycle

  /// Creates a new empty row.
  ///
  /// - Parameter id: The unique identifier (auto-generated if not provided).
  public init(id: UUID = UUID()) {
    self.id = id
    cells = [:]
  }

  /// Creates a row with existing cell data.
  ///
  /// - Parameters:
  ///   - id: The unique identifier.
  ///   - cells: The cell values mapped by column ID.
  public init(id: UUID = UUID(), cells: [UUID: IronCellValue]) {
    self.id = id
    self.cells = cells
  }

  // MARK: Public

  /// The unique identifier for the row.
  public let id: UUID

  /// Cell values mapped by column ID.
  public var cells: [UUID: IronCellValue]

  /// Gets the value for a column, or `.empty` if not set.
  public subscript(columnID: IronColumn.ID) -> IronCellValue {
    get { cells[columnID] ?? .empty }
    set { cells[columnID] = newValue }
  }
}

// MARK: - IronCellValue

/// A cell value in an IronDatabase row.
///
/// Each case corresponds to an `IronColumnType` and holds the appropriate
/// data type for that column.
public enum IronCellValue: Sendable, Equatable {
  /// Empty/null value.
  case empty
  /// Text content.
  case text(String)
  /// Numeric value.
  case number(Double)
  /// Date value.
  case date(Date)
  /// Boolean value.
  case checkbox(Bool)
  /// Single selected option ID.
  case select(UUID?)
  /// Multiple selected option IDs.
  case multiSelect(Set<UUID>)
  /// Person reference.
  case person(IronPerson?)
  /// URL value.
  case url(URL?)
  /// Email address.
  case email(String)
  /// Phone number.
  case phone(String)

  // MARK: Public

  /// Returns true if this value is empty or nil.
  public var isEmpty: Bool {
    switch self {
    case .empty:
      true
    case .text(let string):
      string.isEmpty
    case .number:
      false
    case .date:
      false
    case .checkbox:
      false
    case .select(let id):
      id == nil
    case .multiSelect(let ids):
      ids.isEmpty
    case .person(let person):
      person == nil
    case .url(let url):
      url == nil
    case .email(let string):
      string.isEmpty
    case .phone(let string):
      string.isEmpty
    }
  }

  /// Extracts the text representation of this value.
  public var textValue: String {
    switch self {
    case .empty:
      ""
    case .text(let string):
      string
    case .number(let value):
      String(value)
    case .date(let date):
      date.formatted(date: .abbreviated, time: .omitted)
    case .checkbox(let value):
      value ? "Yes" : "No"
    case .select:
      "" // Needs option lookup
    case .multiSelect:
      "" // Needs option lookup
    case .person(let person):
      person?.name ?? ""
    case .url(let url):
      url?.absoluteString ?? ""
    case .email(let string):
      string
    case .phone(let string):
      string
    }
  }
}

// MARK: - IronPerson

/// A person/user reference in a database cell.
public struct IronPerson: Sendable, Equatable, Identifiable {

  // MARK: Lifecycle

  /// Creates a person reference.
  ///
  /// - Parameters:
  ///   - id: The unique identifier.
  ///   - name: The display name.
  ///   - avatarURL: Optional URL for the avatar image.
  public init(
    id: UUID = UUID(),
    name: String,
    avatarURL: URL? = nil,
  ) {
    self.id = id
    self.name = name
    self.avatarURL = avatarURL
  }

  // MARK: Public

  /// The unique identifier for the person.
  public let id: UUID

  /// The display name.
  public var name: String

  /// Optional URL for the avatar image.
  public var avatarURL: URL?
}

// MARK: - IronSelectOption

/// A select option for single or multi-select columns.
public struct IronSelectOption: Sendable, Equatable, Identifiable {

  // MARK: Lifecycle

  /// Creates a select option.
  ///
  /// - Parameters:
  ///   - id: The unique identifier (auto-generated if not provided).
  ///   - name: The display name.
  ///   - color: The semantic color for the option tag.
  public init(
    id: UUID = UUID(),
    name: String,
    color: IronSemanticColor = .secondary,
  ) {
    self.id = id
    self.name = name
    self.color = color
  }

  // MARK: Public

  /// The unique identifier for the option.
  public let id: UUID

  /// The display name.
  public var name: String

  /// The semantic color for the option tag.
  public var color: IronSemanticColor
}

// MARK: - IronSemanticColor

/// Semantic colors for database elements.
public enum IronSemanticColor: String, Sendable, CaseIterable, Equatable {
  /// Primary brand color.
  case primary
  /// Secondary/neutral color.
  case secondary
  /// Success/positive color.
  case success
  /// Warning color.
  case warning
  /// Error/destructive color.
  case error
  /// Informational color.
  case info
  /// Accent color.
  case accent

  // MARK: Public

  /// Returns a SwiftUI Color representation of this semantic color.
  public var swiftUIColor: Color {
    switch self {
    case .primary:
      .blue
    case .secondary:
      .gray
    case .success:
      .green
    case .warning:
      .orange
    case .error:
      .red
    case .info:
      .cyan
    case .accent:
      .purple
    }
  }
}
