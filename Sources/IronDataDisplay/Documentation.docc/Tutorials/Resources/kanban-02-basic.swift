import IronUI
import SwiftUI

struct ContentView: View {

  // MARK: Internal

  var body: some View {
    IronKanban(
      columns: TaskStatus.allCases, // All possible columns
      items: $tasks, // Binding to items
      columnKeyPath: \.status, // How to group items into columns
    ) { task in
      // Card content for each task
      IronText(task.title, style: .bodyMedium, color: .primary)
        .padding()
    } header: { status, _ in
      // Header for each column
      IronText(status.rawValue, style: .titleSmall, color: .primary)
    }
  }

  // MARK: Private

  @State private var tasks = [
    Task(title: "Design homepage", status: .todo),
    Task(title: "Write tests", status: .inProgress),
    Task(title: "Fix bug #42", status: .done),
  ]

}
