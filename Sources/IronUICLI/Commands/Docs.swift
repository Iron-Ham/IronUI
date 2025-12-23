import ArgumentParser
import Foundation
import Noora

extension IronUICLI {
  struct Docs: AsyncParsableCommand, IronUICommand {

    static let configuration = CommandConfiguration(
      abstract: "Generates DocC documentation for IronUI."
    )

    func run() async throws {
      try await runner.runScript("Scripts/generate-docs.sh")
      noora.success("Documentation generated successfully")
    }
  }
}
