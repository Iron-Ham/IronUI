import Foundation
import GRDB
import SQLiteData

// MARK: - ChoreStatus

/// Workflow status for kanban-style chore management
enum ChoreStatus: String, CaseIterable, Sendable, Hashable, Codable, DatabaseValueConvertible, QueryRepresentable, QueryBindable {
  case todo = "To Do"
  case inProgress = "In Progress"
  case done = "Done"

  // MARK: Internal

  static var _columnWidth: Int? {
    nil
  }
}

// MARK: - Chore

/// A household chore that can be assigned and tracked
@Table
struct Chore: Identifiable, Sendable, Equatable {

  // MARK: Lifecycle

  init(
    id: UUID = UUID(),
    title: String,
    notes: String = "",
    category: ChoreCategory = .general,
    frequency: ChoreFrequency = .once,
    dueDate: Date? = nil,
    status: ChoreStatus = .todo,
    isCompleted: Bool = false,
    completedAt: Date? = nil,
    assigneeId: UUID? = nil,
  ) {
    self.id = id
    self.title = title
    self.notes = notes
    self.category = category
    self.frequency = frequency
    self.dueDate = dueDate
    self.status = status
    self.isCompleted = isCompleted
    self.completedAt = completedAt
    self.assigneeId = assigneeId
  }

  // MARK: Internal

  let id: UUID
  var title: String
  var notes: String
  var category: ChoreCategory
  var frequency: ChoreFrequency
  var dueDate: Date?
  var status: ChoreStatus
  var isCompleted: Bool
  var completedAt: Date?
  var assigneeId: UUID?

  var isOverdue: Bool {
    guard let dueDate, !isCompleted else { return false }
    return dueDate < Date()
  }

  var isDueToday: Bool {
    guard let dueDate else { return false }
    return Calendar.current.isDateInToday(dueDate)
  }

  var isDueThisWeek: Bool {
    guard let dueDate else { return false }
    let calendar = Calendar.current
    guard
      let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: Date())),
      let weekEnd = calendar.date(byAdding: .day, value: 7, to: weekStart)
    else {
      return false
    }
    return dueDate >= weekStart && dueDate < weekEnd
  }
}
