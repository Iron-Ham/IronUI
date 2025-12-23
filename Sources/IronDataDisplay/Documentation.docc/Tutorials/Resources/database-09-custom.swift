import IronUI
import SwiftUI

struct ContentView: View {

  // MARK: Internal

  var body: some View {
    NavigationStack {
      IronDatabaseTable(
        database: $database,
        onAddRow: { _ = database.addRow() },
        onAddColumn: { },
      )
      .navigationTitle(database.name)
      .toolbar {
        ToolbarItem {
          Menu {
            Button("Add Row", systemImage: "plus.rectangle") {
              _ = database.addRow()
            }
            Button("Export", systemImage: "square.and.arrow.up") {
              // Export functionality
            }
          } label: {
            IronIcon(systemName: "ellipsis.circle", size: .medium, color: .primary)
          }
        }
      }
    }
  }

  // MARK: Private

  @State private var database: IronDatabase

}
