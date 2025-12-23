import IronUI

var database = IronDatabase(name: "My Tasks")

// Columns defined above...
let titleColumn = database.addColumn(name: "Title", type: .text)
let statusColumn = database.addColumn(name: "Status", type: .select, options: [
  IronSelectOption(name: "To Do", color: .secondary),
  IronSelectOption(name: "In Progress", color: .warning),
  IronSelectOption(name: "Done", color: .success),
])
let dueDateColumn = database.addColumn(name: "Due Date", type: .date)

/// Add a row
let row = database.addRow()

// Set cell values for the row
database.setValue(.text("Design homepage"), for: row.id, column: titleColumn.id)
database.setValue(.select(statusColumn.options[1].id), for: row.id, column: statusColumn.id)
database.setValue(.date(Date()), for: row.id, column: dueDateColumn.id)
