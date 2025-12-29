import Foundation
import Testing
@testable import IronDataDisplay

// MARK: - IronDatabaseTests

@Suite("IronDatabase")
struct IronDatabaseTests {

  @Test("initializes with name and empty collections")
  func initializesWithNameAndEmptyCollections() {
    let database = IronDatabase(name: "Tasks")

    #expect(database.name == "Tasks")
    #expect(database.columns.isEmpty)
    #expect(database.rows.isEmpty)
  }

  @Test("initializes with existing data")
  func initializesWithExistingData() {
    let columns = [
      IronColumn(name: "Title", type: .text),
      IronColumn(name: "Status", type: .select),
    ]
    let rows = [IronRow(), IronRow()]

    let database = IronDatabase(
      name: "Projects",
      columns: columns,
      rows: rows,
    )

    #expect(database.name == "Projects")
    #expect(database.columns.count == 2)
    #expect(database.rows.count == 2)
  }

  @Test("addColumn appends column and returns it")
  func addColumnAppendsAndReturns() {
    var database = IronDatabase(name: "Test")

    let column = database.addColumn(name: "Title", type: .text)

    #expect(database.columns.count == 1)
    #expect(database.columns[0].id == column.id)
    #expect(column.name == "Title")
    #expect(column.type == .text)
  }

  @Test("addColumn with options stores options")
  func addColumnWithOptionsStoresOptions() {
    var database = IronDatabase(name: "Test")
    let options = [
      IronSelectOption(name: "To Do", color: .secondary),
      IronSelectOption(name: "Done", color: .success),
    ]

    let column = database.addColumn(name: "Status", type: .select, options: options)

    #expect(column.options.count == 2)
    #expect(column.options[0].name == "To Do")
    #expect(column.options[1].name == "Done")
  }

  @Test("removeColumn removes column by ID")
  func removeColumnRemovesByID() {
    var database = IronDatabase(name: "Test")
    let col1 = database.addColumn(name: "First", type: .text)
    let col2 = database.addColumn(name: "Second", type: .number)

    database.removeColumn(col1.id)

    #expect(database.columns.count == 1)
    #expect(database.columns[0].id == col2.id)
  }

  @Test("removeColumn also removes cell data for that column")
  func removeColumnRemovesCellData() {
    var database = IronDatabase(name: "Test")
    let col1 = database.addColumn(name: "Title", type: .text)
    let col2 = database.addColumn(name: "Count", type: .number)
    let row = database.addRow()

    database.setValue(.text("Hello"), for: row.id, column: col1.id)
    database.setValue(.number(42), for: row.id, column: col2.id)

    database.removeColumn(col1.id)

    // col1 data should be gone, col2 data should remain
    #expect(database.value(for: row.id, column: col1.id) == .empty)
    #expect(database.value(for: row.id, column: col2.id) == .number(42))
  }

  @Test("moveColumn reorders columns correctly")
  func moveColumnReorders() {
    var database = IronDatabase(name: "Test")
    let col1 = database.addColumn(name: "A", type: .text)
    let col2 = database.addColumn(name: "B", type: .text)
    let col3 = database.addColumn(name: "C", type: .text)

    database.moveColumn(from: 0, to: 2)

    #expect(database.columns[0].id == col2.id)
    #expect(database.columns[1].id == col3.id)
    #expect(database.columns[2].id == col1.id)
  }

  @Test("moveColumn ignores invalid indices")
  func moveColumnIgnoresInvalidIndices() {
    var database = IronDatabase(name: "Test")
    let col1 = database.addColumn(name: "A", type: .text)
    let col2 = database.addColumn(name: "B", type: .text)

    // Invalid: negative index
    database.moveColumn(from: -1, to: 0)
    #expect(database.columns[0].id == col1.id)

    // Invalid: out of bounds
    database.moveColumn(from: 0, to: 10)
    #expect(database.columns[0].id == col1.id)

    // No-op: same index
    database.moveColumn(from: 0, to: 0)
    #expect(database.columns[0].id == col1.id)
  }

  @Test("addRow creates empty row and returns it")
  func addRowCreatesEmptyRow() {
    var database = IronDatabase(name: "Test")

    let row = database.addRow()

    #expect(database.rows.count == 1)
    #expect(database.rows[0].id == row.id)
    #expect(row.cells.isEmpty)
  }

  @Test("removeRow removes row by ID")
  func removeRowRemovesByID() {
    var database = IronDatabase(name: "Test")
    let row1 = database.addRow()
    let row2 = database.addRow()

    database.removeRow(row1.id)

    #expect(database.rows.count == 1)
    #expect(database.rows[0].id == row2.id)
  }

  @Test("moveRow reorders rows correctly")
  func moveRowReorders() {
    var database = IronDatabase(name: "Test")
    let row1 = database.addRow()
    let row2 = database.addRow()
    let row3 = database.addRow()

    database.moveRow(from: 2, to: 0)

    #expect(database.rows[0].id == row3.id)
    #expect(database.rows[1].id == row1.id)
    #expect(database.rows[2].id == row2.id)
  }

  @Test("moveRow ignores invalid indices")
  func moveRowIgnoresInvalidIndices() {
    var database = IronDatabase(name: "Test")
    let row1 = database.addRow()
    _ = database.addRow()

    database.moveRow(from: -1, to: 0)
    #expect(database.rows[0].id == row1.id)

    database.moveRow(from: 0, to: 100)
    #expect(database.rows[0].id == row1.id)
  }

  @Test("setValue and getValue work correctly")
  func setValueAndGetValueWork() {
    var database = IronDatabase(name: "Test")
    let column = database.addColumn(name: "Title", type: .text)
    let row = database.addRow()

    database.setValue(.text("Hello World"), for: row.id, column: column.id)

    let value = database.value(for: row.id, column: column.id)
    #expect(value == .text("Hello World"))
  }

  @Test("getValue returns empty for nonexistent row")
  func getValueReturnsEmptyForNonexistentRow() {
    var database = IronDatabase(name: "Test")
    let column = database.addColumn(name: "Title", type: .text)
    let nonexistentRowID = UUID()

    let value = database.value(for: nonexistentRowID, column: column.id)
    #expect(value == .empty)
  }

  @Test("getValue returns empty for unset cell")
  func getValueReturnsEmptyForUnsetCell() {
    var database = IronDatabase(name: "Test")
    let column = database.addColumn(name: "Title", type: .text)
    let row = database.addRow()

    let value = database.value(for: row.id, column: column.id)
    #expect(value == .empty)
  }

  @Test("setValue ignores nonexistent row")
  func setValueIgnoresNonexistentRow() {
    var database = IronDatabase(name: "Test")
    let column = database.addColumn(name: "Title", type: .text)
    let nonexistentRowID = UUID()

    // Should not crash
    database.setValue(.text("Test"), for: nonexistentRowID, column: column.id)

    // No rows should have been affected
    #expect(database.rows.isEmpty)
  }

  @Test("column lookup by ID returns correct column")
  func columnLookupReturnsCorrectColumn() {
    var database = IronDatabase(name: "Test")
    let col = database.addColumn(name: "Title", type: .text)

    let found = database.column(col.id)

    #expect(found?.id == col.id)
    #expect(found?.name == "Title")
  }

  @Test("column lookup returns nil for unknown ID")
  func columnLookupReturnsNilForUnknownID() {
    let database = IronDatabase(name: "Test")

    let found = database.column(UUID())

    #expect(found == nil)
  }

  @Test("row lookup by ID returns correct row")
  func rowLookupReturnsCorrectRow() {
    var database = IronDatabase(name: "Test")
    let row = database.addRow()

    let found = database.row(row.id)

    #expect(found?.id == row.id)
  }

  @Test("row lookup returns nil for unknown ID")
  func rowLookupReturnsNilForUnknownID() {
    let database = IronDatabase(name: "Test")

    let found = database.row(UUID())

    #expect(found == nil)
  }
}

// MARK: - IronColumnTests

@Suite("IronColumn")
struct IronColumnTests {

  @Test("initializes with required properties")
  func initializesWithRequiredProperties() {
    let column = IronColumn(name: "Title", type: .text)

    #expect(column.name == "Title")
    #expect(column.type == .text)
    #expect(column.width == nil)
    #expect(column.options.isEmpty)
  }

  @Test("initializes with all properties")
  func initializesWithAllProperties() {
    let options = [IronSelectOption(name: "Option 1")]
    let column = IronColumn(
      name: "Status",
      type: .select,
      width: 150,
      options: options,
    )

    #expect(column.name == "Status")
    #expect(column.type == .select)
    #expect(column.width == 150)
    #expect(column.options.count == 1)
  }
}

// MARK: - IronColumnTypeTests

@Suite("IronColumnType")
struct IronColumnTypeTests {

  @Test("all types have icon names")
  func allTypesHaveIconNames() {
    for type in IronColumnType.allCases {
      #expect(!type.iconName.isEmpty, "Type \(type) should have an icon name")
    }
  }

  @Test("all types have display names")
  func allTypesHaveDisplayNames() {
    for type in IronColumnType.allCases {
      #expect(!type.displayName.isEmpty, "Type \(type) should have a display name")
    }
  }

  @Test("icon names are valid SF Symbols format")
  func iconNamesAreValidFormat() {
    // SF Symbol names are lowercase with dots
    for type in IronColumnType.allCases {
      let icon = type.iconName
      #expect(icon == icon.lowercased() || icon.contains("."), "Icon \(icon) should be SF Symbol format")
    }
  }
}

// MARK: - IronRowTests

@Suite("IronRow")
struct IronRowTests {

  @Test("initializes with empty cells")
  func initializesWithEmptyCells() {
    let row = IronRow()

    #expect(row.cells.isEmpty)
  }

  @Test("initializes with existing cells")
  func initializesWithExistingCells() {
    let columnID = UUID()
    let cells: [UUID: IronCellValue] = [columnID: .text("Hello")]

    let row = IronRow(cells: cells)

    #expect(row.cells.count == 1)
    #expect(row[columnID] == .text("Hello"))
  }

  @Test("subscript getter returns value or empty")
  func subscriptGetterReturnsValueOrEmpty() {
    let columnID = UUID()
    let otherColumnID = UUID()
    let row = IronRow(cells: [columnID: .number(42)])

    #expect(row[columnID] == .number(42))
    #expect(row[otherColumnID] == .empty)
  }

  @Test("subscript setter updates cells")
  func subscriptSetterUpdatesCells() {
    let columnID = UUID()
    var row = IronRow()

    row[columnID] = .checkbox(true)

    #expect(row[columnID] == .checkbox(true))
  }
}

// MARK: - IronCellValueTests

@Suite("IronCellValue")
struct IronCellValueTests {

  @Test("isEmpty returns true for empty cases")
  func isEmptyReturnsTrueForEmptyCases() {
    #expect(IronCellValue.empty.isEmpty)
    #expect(IronCellValue.text("").isEmpty)
    #expect(IronCellValue.select(nil).isEmpty)
    #expect(IronCellValue.multiSelect([]).isEmpty)
    #expect(IronCellValue.person(nil).isEmpty)
    #expect(IronCellValue.url(nil).isEmpty)
    #expect(IronCellValue.email("").isEmpty)
    #expect(IronCellValue.phone("").isEmpty)
  }

  @Test("isEmpty returns false for non-empty cases")
  func isEmptyReturnsFalseForNonEmptyCases() {
    #expect(!IronCellValue.text("Hello").isEmpty)
    #expect(!IronCellValue.number(0).isEmpty) // Even 0 is not empty
    #expect(!IronCellValue.date(Date()).isEmpty)
    #expect(!IronCellValue.checkbox(false).isEmpty) // false is still a value
    #expect(!IronCellValue.select(UUID()).isEmpty)
    #expect(!IronCellValue.multiSelect([UUID()]).isEmpty)
    #expect(!IronCellValue.email("test@example.com").isEmpty)
    #expect(!IronCellValue.phone("555-1234").isEmpty)
  }

  @Test("textValue returns correct string representations")
  func textValueReturnsCorrectStrings() {
    #expect(IronCellValue.empty.textValue == "")
    #expect(IronCellValue.text("Hello").textValue == "Hello")
    #expect(IronCellValue.number(42.5).textValue == "42.5")
    #expect(IronCellValue.checkbox(true).textValue == "Yes")
    #expect(IronCellValue.checkbox(false).textValue == "No")
    #expect(IronCellValue.email("test@example.com").textValue == "test@example.com")
    #expect(IronCellValue.phone("555-1234").textValue == "555-1234")
  }

  @Test("textValue for date formats correctly")
  func textValueForDateFormatsCorrectly() {
    let date = Date(timeIntervalSince1970: 0) // Jan 1, 1970
    let value = IronCellValue.date(date)

    // Should contain some date components (format varies by locale)
    let text = value.textValue
    #expect(!text.isEmpty)
  }

  @Test("textValue for URL returns absolute string")
  func textValueForURLReturnsAbsoluteString() throws {
    let url = try #require(URL(string: "https://example.com/path"))
    let value = IronCellValue.url(url)

    #expect(value.textValue == "https://example.com/path")
  }

  @Test("textValue for person returns name")
  func textValueForPersonReturnsName() {
    let person = IronPerson(name: "John Doe")
    let value = IronCellValue.person(person)

    #expect(value.textValue == "John Doe")
  }

  @Test("Equatable conformance works correctly")
  func equatableWorks() {
    #expect(IronCellValue.empty == IronCellValue.empty)
    #expect(IronCellValue.text("A") == IronCellValue.text("A"))
    #expect(IronCellValue.text("A") != IronCellValue.text("B"))
    #expect(IronCellValue.number(1) != IronCellValue.number(2))
    #expect(IronCellValue.checkbox(true) == IronCellValue.checkbox(true))
  }
}

// MARK: - IronPersonTests

@Suite("IronPerson")
struct IronPersonTests {

  @Test("initializes with required name")
  func initializesWithName() {
    let person = IronPerson(name: "Jane Doe")

    #expect(person.name == "Jane Doe")
    #expect(person.avatarURL == nil)
  }

  @Test("initializes with avatar URL")
  func initializesWithAvatarURL() {
    let url = URL(string: "https://example.com/avatar.png")
    let person = IronPerson(name: "John", avatarURL: url)

    #expect(person.name == "John")
    #expect(person.avatarURL == url)
  }

  @Test("Equatable conformance works")
  func equatableWorks() {
    let id = UUID()
    let person1 = IronPerson(id: id, name: "Test")
    let person2 = IronPerson(id: id, name: "Test")
    let person3 = IronPerson(name: "Other")

    #expect(person1 == person2)
    #expect(person1 != person3)
  }
}

// MARK: - IronSelectOptionTests

@Suite("IronSelectOption")
struct IronSelectOptionTests {

  @Test("initializes with default color")
  func initializesWithDefaultColor() {
    let option = IronSelectOption(name: "To Do")

    #expect(option.name == "To Do")
    #expect(option.color == .secondary)
  }

  @Test("initializes with custom color")
  func initializesWithCustomColor() {
    let option = IronSelectOption(name: "Done", color: .success)

    #expect(option.name == "Done")
    #expect(option.color == .success)
  }
}

// MARK: - IronSemanticColorTests

@Suite("IronSemanticColor")
struct IronSemanticColorTests {

  @Test("all cases are defined")
  func allCasesAreDefined() {
    let expected: Set<IronSemanticColor> = [
      .primary,
      .secondary,
      .success,
      .warning,
      .error,
      .info,
      .accent,
    ]

    #expect(Set(IronSemanticColor.allCases) == expected)
  }

  @Test("raw values are strings")
  func rawValuesAreStrings() {
    for color in IronSemanticColor.allCases {
      #expect(!color.rawValue.isEmpty)
    }
  }
}
