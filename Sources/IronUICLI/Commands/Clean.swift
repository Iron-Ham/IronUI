import ArgumentParser
import Foundation
import Noora

#if os(macOS)
extension IronUICLI {
  struct Clean: AsyncParsableCommand, IronUICommand {

    static let configuration = CommandConfiguration(
      abstract: "Cleans build artifacts and caches."
    )

    @Flag(
      name: .long,
      help: "Also remove derived data, package caches, and Tuist cache.",
    )
    var all = false

    @Flag(
      name: .long,
      help: "Show what would be removed without making changes.",
    )
    var dryRun = false

    func run() async throws {
      let fileManager = FileManager.default
      if dryRun {
        noora.info(.alert("Dry run mode", takeaways: ["No files will be removed"]))
      }

      var removedItems = [String]()

      // Always clean .build directory
      let buildDir = ".build"
      if fileManager.fileExists(atPath: buildDir) {
        if dryRun {
          noora.info(.alert("Would remove", takeaways: ["\(buildDir)"]))
        } else {
          try fileManager.removeItem(atPath: buildDir)
        }
        removedItems.append(buildDir)
      }

      // Clean Tuist generated files
      let tuistGeneratedFiles = [
        "IronUI.xcworkspace",
        "IronUI.xcodeproj",
        "Derived",
      ]

      for file in tuistGeneratedFiles {
        if fileManager.fileExists(atPath: file) {
          if dryRun {
            noora.info(.alert("Would remove", takeaways: ["\(file)"]))
          } else {
            try fileManager.removeItem(atPath: file)
          }
          removedItems.append(file)
        }
      }

      // Run tuist clean if not dry run
      if !dryRun {
        do {
          try await runner.runTask(
            "Running tuist clean",
            command: "/usr/bin/env",
            arguments: ["tuist", "clean"],
          )
          removedItems.append("Tuist cache")
        } catch {
          // Tuist clean may fail if not initialized, that's okay
          noora.info(.alert("Note", takeaways: ["Tuist clean skipped (not initialized)"]))
        }
      }

      if all {
        // Clean package resolved
        let packageResolved = "Package.resolved"
        if fileManager.fileExists(atPath: packageResolved) {
          if dryRun {
            noora.info(.alert("Would remove", takeaways: ["\(packageResolved)"]))
          } else {
            try fileManager.removeItem(atPath: packageResolved)
          }
          removedItems.append(packageResolved)
        }

        // Clean Tuist dependencies
        let tuistDeps = "Tuist/.build"
        if fileManager.fileExists(atPath: tuistDeps) {
          if dryRun {
            noora.info(.alert("Would remove", takeaways: ["\(tuistDeps)"]))
          } else {
            try fileManager.removeItem(atPath: tuistDeps)
          }
          removedItems.append(tuistDeps)
        }

        // Note about Xcode derived data
        noora.info(.alert(
          "Note: Xcode derived data",
          takeaways: ["Clean manually via Xcode or remove ~/Library/Developer/Xcode/DerivedData"],
        ))
      }

      if removedItems.isEmpty {
        noora.info("Nothing to clean")
      } else {
        let takeaways: [TerminalText] = removedItems.map { "Removed \($0)" }
        noora.success(.alert(
          dryRun ? "Would clean" : "Cleaned",
          takeaways: takeaways,
        ))
      }

      if !all {
        noora.info(.alert(
          "Tip",
          takeaways: ["Use --all to also remove Package.resolved and Tuist cache"],
        ))
      }
    }
  }
}
#endif
