import GRDB
import IronCore
import IronUI
import SQLiteData
import SwiftUI

@main
struct HousekeeprApp: App {

  // MARK: Lifecycle

  init() {
    prepareDependencies {
      $0.defaultDatabase = Self.createDatabase()
    }
  }

  // MARK: Internal

  var body: some Scene {
    WindowGroup {
      ContentView()
        .ironTheme(IronDefaultTheme())
    }
  }

  // MARK: Private

  private static func createDatabase() -> DatabaseQueue {
    do {
      let fileManager = FileManager.default
      let appSupport = try fileManager.url(
        for: .applicationSupportDirectory,
        in: .userDomainMask,
        appropriateFor: nil,
        create: true,
      )
      let dbURL = appSupport.appendingPathComponent("housekeepr.sqlite")
      let db = try DatabaseQueue(path: dbURL.path)

      try db.write { db in
        try db.create(table: "householdMembers", ifNotExists: true) { t in
          t.column("id", .text).primaryKey()
          t.column("name", .text).notNull()
          t.column("avatarEmoji", .text).notNull()
          t.column("colorHex", .text).notNull()
        }

        try db.create(table: "chores", ifNotExists: true) { t in
          t.column("id", .text).primaryKey()
          t.column("title", .text).notNull()
          t.column("notes", .text).notNull()
          t.column("category", .text).notNull()
          t.column("frequency", .text).notNull()
          t.column("dueDate", .datetime)
          t.column("isCompleted", .boolean).notNull()
          t.column("completedAt", .datetime)
          t.column("assigneeId", .text)
        }
      }

      try SampleData.seedIfNeeded(db: db)

      return db
    } catch {
      fatalError("Failed to initialize database: \(error)")
    }
  }
}
