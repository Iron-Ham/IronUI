import ArgumentParser
import Foundation

extension IronUICLI {
  struct ExportSnapshots: ParsableCommand, IronUICommand {

    static let configuration = CommandConfiguration(
      commandName: "export-snapshots",
      abstract: "Exports snapshots for documentation usage."
    )

    func run() throws {
      try runner.runScript("Scripts/export-snapshots-for-docs.sh")
    }
  }
}
