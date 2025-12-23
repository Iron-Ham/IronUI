import Foundation
import IronUI

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
  var priority: IronKanbanPriority // Add priority
}
