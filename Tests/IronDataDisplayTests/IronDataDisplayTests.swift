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

// MARK: - IronDatabaseFilterTests

@Suite("IronDatabaseFilter")
struct IronDatabaseFilterTests {

  @Test("text filter contains matches substring")
  func textFilterContainsMatchesSubstring() {
    let filter = IronDatabaseFilter.text(.contains("hello"))

    #expect(filter.evaluate(.text("hello world")))
    #expect(filter.evaluate(.text("say HELLO"))) // case insensitive
    #expect(!filter.evaluate(.text("hi there")))
  }

  @Test("text filter equals matches exact string")
  func textFilterEqualsMatchesExact() {
    let filter = IronDatabaseFilter.text(.equals("hello"))

    #expect(filter.evaluate(.text("hello")))
    #expect(filter.evaluate(.text("HELLO"))) // case insensitive
    #expect(!filter.evaluate(.text("hello world")))
  }

  @Test("text filter startsWith matches prefix")
  func textFilterStartsWithMatchesPrefix() {
    let filter = IronDatabaseFilter.text(.startsWith("hello"))

    #expect(filter.evaluate(.text("hello world")))
    #expect(filter.evaluate(.text("HELLO")))
    #expect(!filter.evaluate(.text("say hello")))
  }

  @Test("text filter endsWith matches suffix")
  func textFilterEndsWithMatchesSuffix() {
    let filter = IronDatabaseFilter.text(.endsWith("world"))

    #expect(filter.evaluate(.text("hello world")))
    #expect(filter.evaluate(.text("WORLD")))
    #expect(!filter.evaluate(.text("world peace")))
  }

  @Test("text filter isEmpty checks emptiness")
  func textFilterIsEmptyChecksEmptiness() {
    let filter = IronDatabaseFilter.text(.isEmpty)

    #expect(filter.evaluate(.text("")))
    #expect(filter.evaluate(.empty))
    #expect(!filter.evaluate(.text("hello")))
  }

  @Test("text filter isNotEmpty checks non-emptiness")
  func textFilterIsNotEmptyChecksNonEmptiness() {
    let filter = IronDatabaseFilter.text(.isNotEmpty)

    #expect(filter.evaluate(.text("hello")))
    #expect(!filter.evaluate(.text("")))
    #expect(!filter.evaluate(.empty))
  }

  @Test("number filter equals matches value")
  func numberFilterEqualsMatchesValue() {
    let filter = IronDatabaseFilter.number(.equals(42))

    #expect(filter.evaluate(.number(42)))
    #expect(!filter.evaluate(.number(43)))
  }

  @Test("number filter greaterThan compares correctly")
  func numberFilterGreaterThanComparesCorrectly() {
    let filter = IronDatabaseFilter.number(.greaterThan(10))

    #expect(filter.evaluate(.number(11)))
    #expect(filter.evaluate(.number(100)))
    #expect(!filter.evaluate(.number(10)))
    #expect(!filter.evaluate(.number(5)))
  }

  @Test("number filter lessThan compares correctly")
  func numberFilterLessThanComparesCorrectly() {
    let filter = IronDatabaseFilter.number(.lessThan(10))

    #expect(filter.evaluate(.number(9)))
    #expect(filter.evaluate(.number(0)))
    #expect(!filter.evaluate(.number(10)))
    #expect(!filter.evaluate(.number(15)))
  }

  @Test("number filter between checks inclusive range")
  func numberFilterBetweenChecksInclusiveRange() {
    let filter = IronDatabaseFilter.number(.between(min: 10, max: 20))

    #expect(filter.evaluate(.number(10)))
    #expect(filter.evaluate(.number(15)))
    #expect(filter.evaluate(.number(20)))
    #expect(!filter.evaluate(.number(9)))
    #expect(!filter.evaluate(.number(21)))
  }

  @Test("checkbox filter checked matches true")
  func checkboxFilterCheckedMatchesTrue() {
    let filter = IronDatabaseFilter.checkbox(.checked)

    #expect(filter.evaluate(.checkbox(true)))
    #expect(!filter.evaluate(.checkbox(false)))
  }

  @Test("checkbox filter unchecked matches false")
  func checkboxFilterUncheckedMatchesFalse() {
    let filter = IronDatabaseFilter.checkbox(.unchecked)

    #expect(filter.evaluate(.checkbox(false)))
    #expect(!filter.evaluate(.checkbox(true)))
  }

  @Test("select filter includes checks for any matching ID")
  func selectFilterIncludesChecksForAnyMatchingID() {
    let id1 = UUID()
    let id2 = UUID()
    let id3 = UUID()

    let filter = IronDatabaseFilter.select(.includes([id1, id2]))

    #expect(filter.evaluate(.select(id1)))
    #expect(filter.evaluate(.select(id2)))
    #expect(!filter.evaluate(.select(id3)))
    #expect(filter.evaluate(.multiSelect([id1, id3])))
    #expect(!filter.evaluate(.multiSelect([id3])))
  }

  @Test("select filter excludes checks for no matching IDs")
  func selectFilterExcludesChecksForNoMatchingIDs() {
    let id1 = UUID()
    let id2 = UUID()
    let id3 = UUID()

    let filter = IronDatabaseFilter.select(.excludes([id1, id2]))

    #expect(!filter.evaluate(.select(id1)))
    #expect(!filter.evaluate(.select(id2)))
    #expect(filter.evaluate(.select(id3)))
    #expect(!filter.evaluate(.multiSelect([id1, id3])))
    #expect(filter.evaluate(.multiSelect([id3])))
  }

  @Test("filter state combines filters with AND logic")
  func filterStateCombinesFiltersWithAndLogic() throws {
    var database = IronDatabase(name: "Test")
    let numCol = database.addColumn(name: "Number", type: .number)
    let textCol = database.addColumn(name: "Text", type: .text)

    let addedRow = database.addRow()
    database.setValue(.number(15), for: addedRow.id, column: numCol.id)
    database.setValue(.text("hello"), for: addedRow.id, column: textCol.id)

    // Get the actual row from the database (not the copy returned by addRow)
    let row = try #require(database.row(addedRow.id))

    var filterState = IronDatabaseFilterState()
    filterState.mode = .and
    filterState.filters[numCol.id] = .number(.greaterThan(10))
    filterState.filters[textCol.id] = .text(.contains("hello"))

    #expect(filterState.evaluate(row: row, in: database))

    // Change filter to fail
    filterState.filters[numCol.id] = .number(.greaterThan(20))
    #expect(!filterState.evaluate(row: row, in: database))
  }

  @Test("filter state combines filters with OR logic")
  func filterStateCombinesFiltersWithOrLogic() throws {
    var database = IronDatabase(name: "Test")
    let numCol = database.addColumn(name: "Number", type: .number)
    let textCol = database.addColumn(name: "Text", type: .text)

    let addedRow = database.addRow()
    database.setValue(.number(5), for: addedRow.id, column: numCol.id)
    database.setValue(.text("hello"), for: addedRow.id, column: textCol.id)

    // Get the actual row from the database (not the copy returned by addRow)
    let row = try #require(database.row(addedRow.id))

    var filterState = IronDatabaseFilterState()
    filterState.mode = .or
    filterState.filters[numCol.id] = .number(.greaterThan(10)) // fails
    filterState.filters[textCol.id] = .text(.contains("hello")) // passes

    #expect(filterState.evaluate(row: row, in: database)) // passes because OR

    // Both fail
    filterState.filters[textCol.id] = .text(.contains("world"))
    #expect(!filterState.evaluate(row: row, in: database))
  }
}

// MARK: - IronDatabaseSortStateTests

@Suite("IronDatabaseSortState")
struct IronDatabaseSortStateTests {

  @Test("toggle direction switches between ascending and descending")
  func toggleDirectionSwitches() {
    var sortState = IronDatabaseSortState(columnID: UUID(), direction: .ascending)

    #expect(sortState.direction == .ascending)

    sortState.toggleDirection()
    #expect(sortState.direction == .descending)

    sortState.toggleDirection()
    #expect(sortState.direction == .ascending)
  }

  @Test("toggled returns new state with opposite direction")
  func toggledReturnsNewState() {
    let original = IronDatabaseSortState(columnID: UUID(), direction: .ascending)
    let toggled = original.toggled()

    #expect(original.direction == .ascending)
    #expect(toggled.direction == .descending)
    #expect(original.columnID == toggled.columnID)
  }

  @Test("compare sorts text values correctly")
  func compareSortsTextValuesCorrectly() {
    let a = IronCellValue.text("Apple")
    let b = IronCellValue.text("Banana")

    #expect(IronDatabaseSortState.compare(a, b, direction: .ascending))
    #expect(!IronDatabaseSortState.compare(a, b, direction: .descending))
  }

  @Test("compare sorts number values correctly")
  func compareSortsNumberValuesCorrectly() {
    let a = IronCellValue.number(10)
    let b = IronCellValue.number(20)

    #expect(IronDatabaseSortState.compare(a, b, direction: .ascending))
    #expect(!IronDatabaseSortState.compare(a, b, direction: .descending))
  }

  @Test("compare sorts date values correctly")
  func compareSortsDateValuesCorrectly() {
    let earlier = IronCellValue.date(Date(timeIntervalSince1970: 0))
    let later = IronCellValue.date(Date(timeIntervalSince1970: 1000))

    #expect(IronDatabaseSortState.compare(earlier, later, direction: .ascending))
    #expect(!IronDatabaseSortState.compare(earlier, later, direction: .descending))
  }

  @Test("compare handles empty values correctly")
  func compareHandlesEmptyValuesCorrectly() {
    let value = IronCellValue.text("Hello")
    let empty = IronCellValue.empty

    // In ascending, value should come before empty (value < empty)
    #expect(IronDatabaseSortState.compare(value, empty, direction: .ascending))

    // In descending, value vs empty: ascending returns true, descending negates it
    // This means empty will sort after value in both directions (correct behavior)
    // The compare function returns true if lhs < rhs in sorted order
    // For descending, we want larger values first, but empty always last
    // Since ascending puts value before empty (true), descending puts empty after value (false)
    #expect(!IronDatabaseSortState.compare(value, empty, direction: .descending))

    // Two empty values should be equal
    #expect(!IronDatabaseSortState.compare(empty, empty, direction: .ascending))
  }

  @Test("sort direction icon names are correct")
  func sortDirectionIconNamesAreCorrect() {
    #expect(IronDatabaseSortState.SortDirection.ascending.iconName == "chevron.up")
    #expect(IronDatabaseSortState.SortDirection.descending.iconName == "chevron.down")
  }
}

// MARK: - IronColumnWidthModeTests

@Suite("IronColumnWidthMode")
struct IronColumnWidthModeTests {

  @Test("fixed width mode has correct bounds")
  func fixedWidthModeHasCorrectBounds() {
    let mode = IronColumnWidthMode.fixed(100)

    #expect(mode.minimumWidth == 100)
    #expect(mode.maximumWidth == 100)
    #expect(!mode.allowsUserResizing)
  }

  @Test("flexible width mode has correct bounds")
  func flexibleWidthModeHasCorrectBounds() {
    let mode = IronColumnWidthMode.flexible(min: 80, max: 400)

    #expect(mode.minimumWidth == 80)
    #expect(mode.maximumWidth == 400)
    #expect(mode.allowsUserResizing)
  }

  @Test("fill width mode has correct defaults")
  func fillWidthModeHasCorrectDefaults() {
    let mode = IronColumnWidthMode.fill(weight: 1.0)

    // Fill mode should have minimum but no maximum
    #expect(mode.minimumWidth >= 0)
    #expect(mode.maximumWidth == nil)
  }

  @Test("default mode is flexible")
  func defaultModeIsFlexible() {
    let mode = IronColumnWidthMode.default

    if case .flexible(let min, let max) = mode {
      #expect(min > 0)
      #expect(max > min)
    } else {
      Issue.record("Expected default to be .flexible")
    }
  }
}
