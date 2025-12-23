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

    @Flag(
      name: .long,
      help: "Enable parallel test execution.",
    )
    var parallel = false

    @Flag(
      name: .long,
      help: "Show verbose test output.",
    )
    var verbose = false

    func run() async throws {
      var arguments = ["swift", "test"]

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
        arguments: arguments,
      )

      noora.success(.alert("Tests passed", takeaways: ["\(description)"]))
    }

    // MARK: Private

    private func buildDescription() -> String {
      var parts = ["Running all tests"]

      if parallel {
        parts.append("(parallel)")
      }

      return parts.joined(separator: " ")
    }
  }
}
#endif
