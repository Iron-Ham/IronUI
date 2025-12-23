import IronUI

var database = IronDatabase(name: "Projects")

// Select: Single choice from options
let statusColumn = database.addColumn(name: "Status", type: .select, options: [
  IronSelectOption(name: "Planning", color: .secondary),
  IronSelectOption(name: "Active", color: .info),
  IronSelectOption(name: "Completed", color: .success),
  IronSelectOption(name: "On Hold", color: .warning),
])

// Multi-select: Multiple choices from options
let tagsColumn = database.addColumn(name: "Tags", type: .multiSelect, options: [
  IronSelectOption(name: "Frontend", color: .primary),
  IronSelectOption(name: "Backend", color: .info),
  IronSelectOption(name: "DevOps", color: .warning),
  IronSelectOption(name: "Design", color: .success),
])

/// Set values
let row = database.addRow()
database.setValue(.select(statusColumn.options[1].id), for: row.id, column: statusColumn.id)
database.setValue(.multiSelect(Set([tagsColumn.options[0].id, tagsColumn.options[1].id])), for: row.id, column: tagsColumn.id)
