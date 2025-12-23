import ArgumentParser
import Foundation
import Noora

@main
struct IronUICLI: AsyncParsableCommand {
  static let configuration = CommandConfiguration(
    commandName: "ironui",
    abstract: "Automation toolkit for IronUI development workflows.",
    subcommands: [
      Build.self,
      Clean.self,
      Docs.self,
      ExportSnapshots.self,
      Format.self,
      Snapshots.self,
      TestSuite.self,
    ]
  )
}

/// Protocol for IronUI CLI commands with shared Noora integration.
protocol IronUICommand: AsyncParsableCommand {}

extension IronUICommand {
  var noora: Noora {
    Noora()
  }

  var runner: CommandRunner {
    CommandRunner(noora: noora)
  }
}
