import GRDB
import IronCore
import IronUI
import OSLog
import SQLiteData
import SwiftUI

private let logger = Logger(subsystem: "Housekeepr", category: "Database")

// MARK: - HousekeeprApp

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

      var configuration = Configuration()
      #if DEBUG
      configuration.prepareDatabase { db in
        db.trace(options: .profile) {
          logger.debug("\($0.expandedDescription)")
        }
      }
      #endif

      let db = try DatabaseQueue(path: dbURL.path, configuration: configuration)
      logger.info("Opened database at '\(dbURL.path)'")

      var migrator = DatabaseMigrator()
      #if DEBUG
      migrator.eraseDatabaseOnSchemaChange = true
      #endif

      migrator.registerMigration("v2_create_tables") { db in
        // Drop existing tables to ensure clean schema (sample app only)
        try #sql("DROP TABLE IF EXISTS \"householdMembers\"").execute(db)
        try #sql("DROP TABLE IF EXISTS \"chores\"").execute(db)
        try #sql("DROP TABLE IF EXISTS \"choreActivities\"").execute(db)

        try #sql("""
          CREATE TABLE "householdMembers" (
            "id" TEXT NOT NULL PRIMARY KEY,
            "name" TEXT NOT NULL,
            "avatarEmoji" TEXT NOT NULL,
            "colorHex" TEXT NOT NULL
          )
          """)
        .execute(db)

        try #sql("""
          CREATE TABLE "chores" (
            "id" TEXT NOT NULL PRIMARY KEY,
            "title" TEXT NOT NULL,
            "notes" TEXT NOT NULL,
            "category" TEXT NOT NULL,
            "frequency" TEXT NOT NULL,
            "dueDate" TEXT,
            "status" TEXT NOT NULL DEFAULT 'To Do',
            "isCompleted" INTEGER NOT NULL,
            "completedAt" TEXT,
            "assigneeId" TEXT
          )
          """)
        .execute(db)

        try #sql("""
          CREATE TABLE "choreActivities" (
            "id" TEXT NOT NULL PRIMARY KEY,
            "choreId" TEXT NOT NULL,
            "choreTitle" TEXT NOT NULL,
            "activityType" TEXT NOT NULL,
            "performedById" TEXT NOT NULL,
            "timestamp" TEXT NOT NULL,
            "details" TEXT
          )
          """)
        .execute(db)
      }

      try migrator.migrate(db)
      try SampleData.seedIfNeeded(db: db)

      return db
    } catch {
      fatalError("Failed to initialize database: \(error)")
    }
  }
}
