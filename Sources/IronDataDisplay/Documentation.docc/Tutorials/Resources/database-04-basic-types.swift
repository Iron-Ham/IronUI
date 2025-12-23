import IronUI

var database = IronDatabase(name: "Products")

// Text: Free-form text input
let nameColumn = database.addColumn(name: "Name", type: .text)

// Number: Numeric values
let priceColumn = database.addColumn(name: "Price", type: .number)

// Checkbox: Boolean yes/no
let inStockColumn = database.addColumn(name: "In Stock", type: .checkbox)

// Date: Date picker
let releaseDateColumn = database.addColumn(name: "Release Date", type: .date)

/// Set values
let row = database.addRow()
database.setValue(.text("iPhone 17 Pro"), for: row.id, column: nameColumn.id)
database.setValue(.number(999.99), for: row.id, column: priceColumn.id)
database.setValue(.checkbox(true), for: row.id, column: inStockColumn.id)
database.setValue(.date(Date()), for: row.id, column: releaseDateColumn.id)
