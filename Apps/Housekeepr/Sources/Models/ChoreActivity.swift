import Foundation
import GRDB
import SQLiteData

// MARK: - ChoreActivityType

/// Types of activities that can occur on a chore
enum ChoreActivityType: String, Sendable, Codable, DatabaseValueConvertible, QueryRepresentable, QueryBindable {
  case created
  case completed
  case uncompleted
  case assigned
  case statusChanged
  case edited

  // MARK: Internal

  static var _columnWidth: Int? {
    nil
  }
}

// MARK: - ChoreActivity

/// A record of an action taken on a chore
@Table
struct ChoreActivity: Identifiable, Sendable {

  // MARK: Lifecycle

  init(
    id: UUID = UUID(),
    choreId: UUID,
    choreTitle: String,
    activityType: ChoreActivityType,
    performedById: UUID,
    timestamp: Date = Date(),
    details: String? = nil,
  ) {
    self.id = id
    self.choreId = choreId
    self.choreTitle = choreTitle
    self.activityType = activityType
    self.performedById = performedById
    self.timestamp = timestamp
    self.details = details
  }

  // MARK: Internal

  let id: UUID
  let choreId: UUID
  let choreTitle: String
  let activityType: ChoreActivityType
  let performedById: UUID
  let timestamp: Date
  let details: String?
}

// MARK: - ChoreActivityType Extensions

extension ChoreActivityType {
  var icon: String {
    switch self {
    case .created: "plus.circle.fill"
    case .completed: "checkmark.circle.fill"
    case .uncompleted: "arrow.uturn.backward.circle.fill"
    case .assigned: "person.fill.badge.plus"
    case .statusChanged: "arrow.right.circle.fill"
    case .edited: "pencil.circle.fill"
    }
  }

  var displayName: String {
    switch self {
    case .created: "created"
    case .completed: "completed"
    case .uncompleted: "reopened"
    case .assigned: "assigned"
    case .statusChanged: "moved"
    case .edited: "edited"
    }
  }
}
