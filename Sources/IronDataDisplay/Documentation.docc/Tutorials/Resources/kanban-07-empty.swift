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
      IronKanbanCard(priority: task.priority) {
        IronText(task.title, style: .bodyMedium, color: .primary)
      }
    } header: { status, count in
      IronText("\(status.rawValue) (\(count))", style: .titleSmall, color: .primary)
    } emptyState: {
      // Custom empty state for columns with no items
      VStack(spacing: 8) {
        IronIcon(systemName: "tray", size: .large, color: .secondary)
        IronText("No tasks", style: .bodySmall, color: .secondary)
      }
      .frame(maxWidth: .infinity)
      .padding()
      .background(
        RoundedRectangle(cornerRadius: 8)
          .strokeBorder(style: StrokeStyle(lineWidth: 1, dash: [5, 5]))
          .foregroundStyle(.secondary.opacity(0.3))
      )
    }
  }

  // MARK: Private

  @State private var tasks: [Task] = // ...

}
