import Foundation

// MARK: - TaskStatus

/// Define your column type as a Hashable enum
enum TaskStatus: String, CaseIterable, Hashable {
  case todo = "To Do"
  case inProgress = "In Progress"
  case done = "Done"
}

// MARK: - Task

/// Define your item model with an Identifiable conformance
struct Task: Identifiable {
  let id = UUID()
  var title: String
  var status: TaskStatus // Key path used for column grouping
}
