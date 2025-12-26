import ArgumentParser
import Foundation
import Noora

#if os(macOS)
extension IronUICLI {
  struct TestSuite: AsyncParsableCommand, IronUICommand {

    // MARK: Internal

    static let configuration = CommandConfiguration(
      commandName: "test",
      abstract: "Runs the full IronUI test suite.",
    )

    @Option(
      name: .long,
      help: "Platform to test on: macos or ios.",
    )
    var platform = "macos"

    @Flag(
      name: .long,
      help: "Use SPM test instead of Tuist (excludes snapshot tests).",
    )
    var spm = false

    @Flag(
      name: .long,
      help: "Show verbose test output.",
    )
    var verbose = false

    func run() async throws {
      let description = buildDescription()

      if spm {
        // SPM mode - excludes snapshot tests
        var arguments = ["swift", "test"]

        if verbose {
          arguments.append("--verbose")
        }

        try await runner.runTask(
          description,
          command: "/usr/bin/env",
          arguments: arguments,
        )
      } else {
        // Tuist mode - generate and test
        try await runner.runTask(
          "Generating Xcode project",
          command: "/usr/bin/env",
          arguments: ["tuist", "generate"],
        )

        var arguments = [
          "tuist",
          "test",
          "--platform",
          platform,
        ]

        if verbose {
          arguments.append("--verbose")
        }

        try await runner.runTask(
          description,
          command: "/usr/bin/env",
          arguments: arguments,
        )
      }

      noora.success(.alert("Tests passed", takeaways: ["\(description)"]))
    }

    // MARK: Private

    private func buildDescription() -> String {
      var parts = ["Running all tests"]

      parts.append("(\(platform))")

      if spm {
        parts.append("[SPM]")
      }

      return parts.joined(separator: " ")
    }
  }
}
#endif
