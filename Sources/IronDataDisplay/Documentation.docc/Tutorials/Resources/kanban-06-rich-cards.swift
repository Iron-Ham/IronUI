import IronUI
import SwiftUI

// MARK: - Task

struct Task: Identifiable {
  let id = UUID()
  var title: String
  var status: TaskStatus
  var priority: IronKanbanPriority
  var dueDate: Date?
  var assignee: String?
  var tags: [String]
}

// MARK: - ContentView

struct ContentView: View {

  // MARK: Internal

  var body: some View {
    IronKanban(
      columns: TaskStatus.allCases,
      items: $tasks,
      columnKeyPath: \.status,
    ) { task in
      IronKanbanCard(priority: task.priority) {
        VStack(alignment: .leading, spacing: 8) {
          IronText(task.title, style: .bodyMedium, color: .primary)

          if let dueDate = task.dueDate {
            HStack(spacing: 4) {
              IronIcon(systemName: "calendar", size: .xSmall, color: .secondary)
              IronText(dueDate.formatted(date: .abbreviated, time: .omitted), style: .caption, color: .secondary)
            }
          }

          if !task.tags.isEmpty {
            HStack(spacing: 4) {
              ForEach(task.tags, id: \.self) { tag in
                IronChip(tag, size: .small)
              }
            }
          }

          if let assignee = task.assignee {
            HStack(spacing: 4) {
              IronAvatar(initials: String(assignee.prefix(2)), size: .small)
              IronText(assignee, style: .caption, color: .secondary)
            }
          }
        }
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

  @State private var tasks: [Task] = // ...

}
