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
      help: "Also remove derived data and package caches.",
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

        // Clean Xcode derived data for this project
        let xcodeProject = "IronUI.xcodeproj"
        if fileManager.fileExists(atPath: xcodeProject) {
          noora.info(.alert(
            "Note: Xcode derived data",
            takeaways: ["Clean manually via Xcode or remove ~/Library/Developer/Xcode/DerivedData"],
          ))
        }
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
          takeaways: ["Use --all to also remove Package.resolved"],
        ))
      }
    }
  }
}
#endif
