import IronUI
import SwiftUI

struct ContentView: View {

  // MARK: Lifecycle

  init() {
    var db = IronDatabase(name: "Tasks")
    _ = db.addColumn(name: "Title", type: .text)
    _ = db.addColumn(name: "Status", type: .select, options: [
      IronSelectOption(name: "To Do", color: .secondary),
      IronSelectOption(name: "Done", color: .success),
    ])
    _database = State(initialValue: db)
  }

  // MARK: Internal

  var body: some View {
    IronDatabaseTable(
      database: $database,
      onAddRow: { },
      onAddColumn: { },
    )
  }

  // MARK: Private

  @State private var database: IronDatabase

}
