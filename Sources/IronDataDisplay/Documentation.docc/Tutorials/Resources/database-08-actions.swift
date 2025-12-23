import IronUI
import SwiftUI

// MARK: - ContentView

struct ContentView: View {

  // MARK: Lifecycle

  init() {
    var db = IronDatabase(name: "Tasks")
    _ = db.addColumn(name: "Title", type: .text)
    _database = State(initialValue: db)
  }

  // MARK: Internal

  var body: some View {
    IronDatabaseTable(
      database: $database,
      onAddRow: {
        // Add a new empty row
        _ = database.addRow()
      },
      onAddColumn: {
        // Show column creation UI
        showingAddColumn = true
      },
    )
    .sheet(isPresented: $showingAddColumn) {
      AddColumnView(database: $database)
    }
  }

  // MARK: Private

  @State private var database: IronDatabase
  @State private var showingAddColumn = false

}

// MARK: - AddColumnView

struct AddColumnView: View {

  // MARK: Internal

  @Binding var database: IronDatabase

  var body: some View {
    NavigationStack {
      Form {
        TextField("Column Name", text: $columnName)
        Picker("Type", selection: $columnType) {
          Text("Text").tag(IronColumnType.text)
          Text("Number").tag(IronColumnType.number)
          Text("Date").tag(IronColumnType.date)
          Text("Checkbox").tag(IronColumnType.checkbox)
        }
      }
      .navigationTitle("Add Column")
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button("Add") {
            _ = database.addColumn(name: columnName, type: columnType)
            dismiss()
          }
        }
      }
    }
  }

  // MARK: Private

  @State private var columnName = ""
  @State private var columnType = IronColumnType.text
  @Environment(\.dismiss) private var dismiss

}
