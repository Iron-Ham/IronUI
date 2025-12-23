import IronUI
import SwiftUI

struct ContentView: View {

  // MARK: Internal

  var body: some View {
    IronKanban(
      columns: TaskStatus.allCases,
      items: $tasks,
      columnKeyPath: \.status,
    ) { task in
      // Use IronKanbanCard for styled cards with priority indicator
      IronKanbanCard(priority: task.priority) {
        IronText(task.title, style: .bodyMedium, color: .primary)
      }
    } header: { status, count in
      HStack {
        IronText(status.rawValue, style: .titleSmall, color: .primary)
        Spacer()
        IronBadge(count: count, color: .secondary, size: .small)
      }
    }
  }

  // MARK: Private

  @State private var tasks = [
    Task(title: "Critical bug fix", status: .todo, priority: .urgent),
    Task(title: "Feature request", status: .todo, priority: .high),
    Task(title: "Documentation", status: .inProgress, priority: .medium),
    Task(title: "Refactoring", status: .done, priority: .low),
  ]

}
