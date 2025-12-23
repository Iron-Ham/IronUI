import IronUI
import SwiftUI

struct TaskTracker: View {

  // MARK: Lifecycle

  init() {
    var db = IronDatabase(name: "Task Tracker")

    // Define columns
    let titleColumn = db.addColumn(name: "Task", type: .text)
    let statusColumn = db.addColumn(name: "Status", type: .select, options: [
      IronSelectOption(name: "Backlog", color: .secondary),
      IronSelectOption(name: "To Do", color: .info),
      IronSelectOption(name: "In Progress", color: .warning),
      IronSelectOption(name: "Review", color: .primary),
      IronSelectOption(name: "Done", color: .success),
    ])
    let priorityColumn = db.addColumn(name: "Priority", type: .select, options: [
      IronSelectOption(name: "Low", color: .secondary),
      IronSelectOption(name: "Medium", color: .warning),
      IronSelectOption(name: "High", color: .error),
    ])
    let assigneeColumn = db.addColumn(name: "Assignee", type: .person)
    let dueDateColumn = db.addColumn(name: "Due Date", type: .date)
    let tagsColumn = db.addColumn(name: "Tags", type: .multiSelect, options: [
      IronSelectOption(name: "Bug", color: .error),
      IronSelectOption(name: "Feature", color: .success),
      IronSelectOption(name: "Chore", color: .secondary),
    ])

    // Add sample data
    let row1 = db.addRow()
    db.setValue(.text("Fix login bug"), for: row1.id, column: titleColumn.id)
    db.setValue(.select(statusColumn.options[2].id), for: row1.id, column: statusColumn.id)
    db.setValue(.select(priorityColumn.options[2].id), for: row1.id, column: priorityColumn.id)
    db.setValue(.person(IronPerson(name: "Alice")), for: row1.id, column: assigneeColumn.id)
    db.setValue(.date(Date()), for: row1.id, column: dueDateColumn.id)
    db.setValue(.multiSelect(Set([tagsColumn.options[0].id])), for: row1.id, column: tagsColumn.id)

    let row2 = db.addRow()
    db.setValue(.text("Add dark mode"), for: row2.id, column: titleColumn.id)
    db.setValue(.select(statusColumn.options[1].id), for: row2.id, column: statusColumn.id)
    db.setValue(.select(priorityColumn.options[1].id), for: row2.id, column: priorityColumn.id)
    db.setValue(.person(IronPerson(name: "Bob")), for: row2.id, column: assigneeColumn.id)
    db.setValue(.multiSelect(Set([tagsColumn.options[1].id])), for: row2.id, column: tagsColumn.id)

    let row3 = db.addRow()
    db.setValue(.text("Update dependencies"), for: row3.id, column: titleColumn.id)
    db.setValue(.select(statusColumn.options[0].id), for: row3.id, column: statusColumn.id)
    db.setValue(.select(priorityColumn.options[0].id), for: row3.id, column: priorityColumn.id)
    db.setValue(.multiSelect(Set([tagsColumn.options[2].id])), for: row3.id, column: tagsColumn.id)

    _database = State(initialValue: db)
  }

  // MARK: Internal

  var body: some View {
    NavigationStack {
      IronDatabaseTable(
        database: $database,
        onAddRow: {
          _ = database.addRow()
        },
        onAddColumn: {
          // In a real app, show column creation UI
        },
      )
      .navigationTitle("Task Tracker")
      .toolbar {
        ToolbarItem(placement: .primaryAction) {
          Button {
            _ = database.addRow()
          } label: {
            Label("Add Task", systemImage: "plus")
          }
        }
      }
    }
  }

  // MARK: Private

  @State private var database: IronDatabase

}
