import ArgumentParser
import Foundation
import Noora

@main
struct IronUICLI: ParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "ironui",
    abstract: "Automation toolkit for IronUI development workflows.",
    subcommands: [
      Build.self,
      Format.self,
      TestSuite.self,
      Snapshots.self,
      Docs.self,
      ExportSnapshots.self,
    ]
  )
}

protocol IronUICommand: ParsableCommand {}

extension IronUICommand {
  var printer: Noora.Printer {
    Noora.Printer()
  }

  var runner: CommandRunner {
    CommandRunner(printer: printer)
  }
}
