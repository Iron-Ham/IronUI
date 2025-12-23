import IronUI
import SwiftUI

struct ContentView: View {

  // MARK: Internal

  var body: some View {
    VStack {
      // Compact spacing for dense boards
      IronKanban(
        columns: TaskStatus.allCases,
        items: $tasks,
        columnKeyPath: \.status,
        spacing: .compact,
      ) { task in
        IronKanbanCard(priority: task.priority) {
          IronText(task.title, style: .bodySmall, color: .primary)
        }
      } header: { status, _ in
        IronText(status.rawValue, style: .labelMedium, color: .primary)
      }

      // Standard spacing (default) for readability
      IronKanban(
        columns: TaskStatus.allCases,
        items: $tasks,
        columnKeyPath: \.status,
        spacing: .standard,
      ) { task in
        IronKanbanCard(priority: task.priority) {
          IronText(task.title, style: .bodyMedium, color: .primary)
        }
      } header: { status, _ in
        IronText(status.rawValue, style: .titleSmall, color: .primary)
      }
    }
  }

  // MARK: Private

  @State private var tasks: [Task] = // ...

}
