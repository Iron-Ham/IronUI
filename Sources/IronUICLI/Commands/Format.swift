import ArgumentParser
import Foundation
import Noora

#if os(macOS)
extension IronUICLI {
  struct Format: AsyncParsableCommand, IronUICommand {

    static let configuration = CommandConfiguration(
      abstract: "Formats Swift sources using the Airbnb Swift Style Guide."
    )

    @Flag(
      name: .long,
      help: "Show what would be changed without making changes.",
    )
    var dryRun = false

    func run() async throws {
      var arguments = [
        "swift",
        "package",
        "--allow-writing-to-package-directory",
        "format",
      ]

      if dryRun {
        arguments.append("--lint")
        noora.info(.alert("Dry run mode", takeaways: ["No files will be modified"]))
      }

      try await runner.runTask(
        dryRun ? "Checking formatting" : "Formatting Swift files",
        command: "/usr/bin/env",
        arguments: arguments,
      )

      noora.success(dryRun ? "Formatting check complete" : "Formatting complete")
    }
  }
}
#endif
