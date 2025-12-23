import ArgumentParser
import Foundation
import Noora

extension IronUICLI {
  struct TestSuite: AsyncParsableCommand, IronUICommand {

    static let configuration = CommandConfiguration(
      commandName: "test",
      abstract: "Runs the full IronUI test suite."
    )

    func run() async throws {
      try await runner.runScript("Scripts/run-tests.sh")
      noora.success("All tests passed")
    }
  }
}
