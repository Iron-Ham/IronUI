import ArgumentParser
import Foundation

extension IronUICLI {
  struct Docs: ParsableCommand, IronUICommand {

    static let configuration = CommandConfiguration(
      abstract: "Generates DocC documentation for IronUI."
    )

    func run() throws {
      try runner.runScript("Scripts/generate-docs.sh")
    }
  }
}
