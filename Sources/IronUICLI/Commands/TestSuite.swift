import ArgumentParser
import Foundation
import Noora

extension IronUICLI {
  struct TestSuite: AsyncParsableCommand, IronUICommand {

    static let configuration = CommandConfiguration(
      commandName: "test",
      abstract: "Runs the full IronUI test suite."
    )

    @Option(
      name: .long,
      help: "Run only tests matching the specified filter pattern."
    )
    var filter: String?

    @Option(
      name: .long,
      help: "Run tests for a specific target (e.g., IronCoreTests)."
    )
    var testTarget: String?

    @Flag(
      name: .long,
      help: "Enable parallel test execution."
    )
    var parallel = false

    @Flag(
      name: .long,
      help: "Show verbose test output."
    )
    var verbose = false

    func run() async throws {
      var arguments = ["swift", "test"]

      if let filter {
        arguments.append(contentsOf: ["--filter", filter])
      }

      if let testTarget {
        arguments.append(contentsOf: ["--test-target", testTarget])
      }

      if parallel {
        arguments.append("--parallel")
      }

      if verbose {
        arguments.append("--verbose")
      }

      let description = buildDescription()
      try await runner.runTask(
        description,
        command: "/usr/bin/env",
        arguments: arguments
      )

      noora.success(.alert("Tests passed", takeaways: ["\(description)"]))
    }

    private func buildDescription() -> String {
      var parts = ["Running"]

      if let testTarget {
        parts.append(testTarget)
      } else {
        parts.append("all tests")
      }

      if let filter {
        parts.append("matching '\(filter)'")
      }

      if parallel {
        parts.append("(parallel)")
      }

      return parts.joined(separator: " ")
    }
  }
}
