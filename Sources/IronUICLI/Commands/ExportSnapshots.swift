import ArgumentParser
import Foundation
import Noora

extension IronUICLI {
  struct ExportSnapshots: AsyncParsableCommand, IronUICommand {

    static let configuration = CommandConfiguration(
      commandName: "export-snapshots",
      abstract: "Exports snapshots for documentation usage."
    )

    func run() async throws {
      try await runner.runScript("Scripts/export-snapshots-for-docs.sh")
      noora.success("Snapshots exported for documentation")
    }
  }
}
