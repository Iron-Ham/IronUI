import IronUI
import SwiftUI

// MARK: - TaskManager

struct TaskManager: View {

  // MARK: Internal

  var body: some View {
    NavigationStack {
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
          IronBadge(count: count, color: statusColor(status), size: .small)
        }
      } emptyState: {
        IronKanbanDefaultEmptyState()
      }
      .navigationTitle("Task Manager")
    }
  }

  // MARK: Private

  @State private var tasks = [
    Task(
      title: "Design system review",
      status: .todo,
      priority: .high,
      dueDate: Date().addingTimeInterval(86400),
      assignee: "Alice",
      tags: ["design"],
    ),
    Task(title: "API integration", status: .todo, priority: .urgent, dueDate: Date(), assignee: "Bob", tags: ["backend"]),
    Task(title: "Write unit tests", status: .inProgress, priority: .medium, dueDate: nil, assignee: "Charlie", tags: ["testing"]),
    Task(title: "Update documentation", status: .inProgress, priority: .low, dueDate: nil, assignee: nil, tags: ["docs"]),
    Task(title: "Deploy to staging", status: .done, priority: .none, dueDate: nil, assignee: "Alice", tags: ["devops"]),
  ]

  private func statusColor(_ status: TaskStatus) -> IronBadgeColor {
    switch status {
    case .todo: .secondary
    case .inProgress: .warning
    case .done: .success
    }
  }
}

// MARK: - TaskStatus

enum TaskStatus: String, CaseIterable, Hashable {
  case todo = "To Do"
  case inProgress = "In Progress"
  case done = "Done"
}

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
