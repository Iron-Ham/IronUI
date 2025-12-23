import IronUI

var database = IronDatabase(name: "My Tasks")

// Add columns with different types
let titleColumn = database.addColumn(name: "Title", type: .text)
let statusColumn = database.addColumn(name: "Status", type: .select, options: [
  IronSelectOption(name: "To Do", color: .secondary),
  IronSelectOption(name: "In Progress", color: .warning),
  IronSelectOption(name: "Done", color: .success),
])
let dueDateColumn = database.addColumn(name: "Due Date", type: .date)
let priorityColumn = database.addColumn(name: "Priority", type: .number)
let completedColumn = database.addColumn(name: "Completed", type: .checkbox)
