import Foundation
import SQLiteData

/// A household chore that can be assigned and tracked
@Table
struct Chore: Identifiable, Sendable {

  // MARK: Lifecycle

  init(
    id: UUID = UUID(),
    title: String,
    notes: String = "",
    category: ChoreCategory = .general,
    frequency: ChoreFrequency = .once,
    dueDate: Date? = nil,
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
