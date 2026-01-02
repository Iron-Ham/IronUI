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
      title: "Do the dishes",
      notes: "Don't forget the pots!",
      category: .kitchen,
      frequency: .daily,
      dueDate: Date(),
      assigneeId: members[0].id,
    ),
    Chore(
      title: "Vacuum living room",
      category: .general,
      frequency: .weekly,
      dueDate: Calendar.current.date(byAdding: .day, value: 1, to: Date()),
      assigneeId: members[1].id,
    ),
    Chore(
      title: "Clean bathroom",
      notes: "Scrub the shower",
      category: .bathroom,
      frequency: .weekly,
      dueDate: Calendar.current.date(byAdding: .day, value: 2, to: Date()),
      assigneeId: members[2].id,
    ),
    Chore(
      title: "Do laundry",
      category: .laundry,
      frequency: .weekly,
      dueDate: Date(),
      assigneeId: members[0].id,
    ),
    Chore(
      title: "Water the plants",
      category: .outdoor,
      frequency: .daily,
      dueDate: Date(),
      assigneeId: members[1].id,
    ),
    Chore(
      title: "Take out trash",
      category: .general,
      frequency: .daily,
      dueDate: Date(),
      isCompleted: true,
      completedAt: Date(),
      assigneeId: members[2].id,
    ),
    Chore(
      title: "Mow the lawn",
      notes: "Check gas level first",
      category: .outdoor,
      frequency: .weekly,
      dueDate: Calendar.current.date(byAdding: .day, value: 3, to: Date()),
      assigneeId: members[0].id,
    ),
    Chore(
      title: "Make the beds",
      category: .bedroom,
      frequency: .daily,
      dueDate: Date(),
      isCompleted: true,
      completedAt: Calendar.current.date(byAdding: .hour, value: -2, to: Date()),
      assigneeId: members[1].id,
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
      }
    }
  }
}
