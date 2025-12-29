import ArgumentParser
import Foundation
import Noora

#if os(macOS)
extension IronUICLI {
  struct Format: AsyncParsableCommand, IronUICommand {

    // MARK: Internal

    static let configuration = CommandConfiguration(
      abstract: "Formats Swift sources using the Airbnb Swift Style Guide."
    )

    @Flag(
      name: .long,
      help: "Show what would be changed without making changes.",
    )
    var dryRun = false

    func run() async throws {
      let packageDir = FileManager.default.currentDirectoryPath
      let swiftlintConfig = "\(packageDir)/.swiftlint.yml"

      var arguments = [
        "swift",
        "package",
        "--allow-writing-to-package-directory",
        "format",
        "--swift-lint-config",
        swiftlintConfig,
      ]

      if dryRun {
        arguments.append("--lint")
        noora.info(.alert("Dry run mode", takeaways: ["No files will be modified"]))
      }

      // Add source directories to format
      for dir in Self.sourceDirectories {
        arguments.append("\(packageDir)/\(dir)")
      }

      _ = try await runner.runTaskWithOutput(
        dryRun ? "Checking formatting" : "Formatting Swift files",
        command: "/usr/bin/env",
        arguments: arguments,
      )
    }

    // MARK: Private

    /// Directories containing source code to format.
    /// Excludes Tuist (uses DSL that swift-format can't parse), Derived, docs, etc.
    private static let sourceDirectories = [
      "Sources",
      "Tests",
      "Apps",
    ]

  }
}
#endif
