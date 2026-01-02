import Foundation
import SQLiteData

/// Sample data for demonstrating the app
enum SampleData {
  static let members: [HouseholdMember] = [
    HouseholdMember(
      id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
      name: "Alex",
      avatarEmoji: "🧑‍💻",
      colorHex: "#6366F1",
    ),
    HouseholdMember(
      id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
      name: "Jordan",
      avatarEmoji: "🎨",
      colorHex: "#EC4899",
    ),
    HouseholdMember(
      id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
      name: "Sam",
      avatarEmoji: "🌱",
      colorHex: "#10B981",
    ),
  ]

  static let chores: [Chore] = [
    Chore(
      id: UUID(uuidString: "10000000-0000-0000-0000-000000000001")!,
      title: "Do the dishes",
      notes: "Don't forget the pots!",
      category: .kitchen,
      frequency: .daily,
      dueDate: Date(),
      status: .inProgress,
      assigneeId: members[0].id,
    ),
    Chore(
      id: UUID(uuidString: "10000000-0000-0000-0000-000000000002")!,
      title: "Vacuum living room",
      category: .general,
      frequency: .weekly,
      dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
      status: .todo,
      assigneeId: members[1].id,
    ),
    Chore(
      id: UUID(uuidString: "10000000-0000-0000-0000-000000000003")!,
      title: "Clean bathroom",
      notes: "Scrub the shower",
      category: .bathroom,
      frequency: .weekly,
      dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
      status: .todo,
      assigneeId: members[2].id,
    ),
    Chore(
      id: UUID(uuidString: "10000000-0000-0000-0000-000000000004")!,
      title: "Do laundry",
      category: .laundry,
      frequency: .weekly,
      dueDate: Date(),
      status: .inProgress,
      assigneeId: members[0].id,
    ),
    Chore(
      id: UUID(uuidString: "10000000-0000-0000-0000-000000000005")!,
      title: "Water the plants",
      category: .outdoor,
      frequency: .daily,
      dueDate: Date(),
      status: .todo,
      assigneeId: members[1].id,
    ),
    Chore(
      id: UUID(uuidString: "10000000-0000-0000-0000-000000000006")!,
      title: "Take out trash",
      category: .general,
      frequency: .daily,
      dueDate: Date(),
      status: .done,
      isCompleted: true,
      completedAt: Date(),
      assigneeId: members[2].id,
    ),
    Chore(
      id: UUID(uuidString: "10000000-0000-0000-0000-000000000007")!,
      title: "Mow the lawn",
      notes: "Check gas level first",
      category: .outdoor,
      frequency: .weekly,
      dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
      status: .todo,
      assigneeId: members[0].id,
    ),
    Chore(
      id: UUID(uuidString: "10000000-0000-0000-0000-000000000008")!,
      title: "Make the beds",
      category: .bedroom,
      frequency: .daily,
      dueDate: Date(),
      status: .done,
      isCompleted: true,
      completedAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date()),
      assigneeId: members[1].id,
    ),
  ]

  static let activities: [ChoreActivity] = [
    ChoreActivity(
      choreId: chores[7].id,
      choreTitle: chores[7].title,
      activityType: .completed,
      performedById: members[1].id,
      timestamp: Calendar.current.date(byAdding: .hour, value: -2, to: Date())!,
    ),
    ChoreActivity(
      choreId: chores[5].id,
      choreTitle: chores[5].title,
      activityType: .completed,
      performedById: members[2].id,
      timestamp: Calendar.current.date(byAdding: .hour, value: -1, to: Date())!,
    ),
    ChoreActivity(
      choreId: chores[0].id,
      choreTitle: chores[0].title,
      activityType: .statusChanged,
      performedById: members[0].id,
      timestamp: Calendar.current.date(byAdding: .minute, value: -45, to: Date())!,
      details: "To Do → In Progress",
    ),
    ChoreActivity(
      choreId: chores[3].id,
      choreTitle: chores[3].title,
      activityType: .statusChanged,
      performedById: members[0].id,
      timestamp: Calendar.current.date(byAdding: .minute, value: -30, to: Date())!,
      details: "To Do → In Progress",
    ),
    ChoreActivity(
      choreId: chores[1].id,
      choreTitle: chores[1].title,
      activityType: .assigned,
      performedById: members[0].id,
      timestamp: Calendar.current.date(byAdding: .minute, value: -15, to: Date())!,
      details: "Assigned to Jordan",
    ),
  ]

  static func seedIfNeeded(db: DatabaseQueue) throws {
    try db.write { db in
      let existingMembers = try HouseholdMember.fetchAll(db)
      if existingMembers.isEmpty {
        for member in members {
          try HouseholdMember.insert { member }.execute(db)
        }
        for chore in chores {
          try Chore.insert { chore }.execute(db)
        }
        for activity in activities {
          try ChoreActivity.insert { activity }.execute(db)
        }
      }
    }
  }
}
