import ArgumentParser
import Foundation

extension IronUICLI {
  struct TestSuite: ParsableCommand, IronUICommand {

    static let configuration = CommandConfiguration(
      commandName: "test",
      abstract: "Runs the full IronUI test suite."
    )

    func run() throws {
      try runner.runScript("Scripts/run-tests.sh")
    }
  }
}
