import ArgumentParser
import Foundation

extension IronUICLI {
  struct Build: ParsableCommand, IronUICommand {

    static let configuration = CommandConfiguration(
      abstract: "Builds the IronUI package."
    )

    @Option(
      name: [.short, .long],
      help: "Build configuration to use (debug or release)."
    )
    var configuration: String = "debug"

    func run() throws {
      let configuration = configuration.lowercased() == "release" ? "release" : "debug"

      try runner.runTask(
        "Building IronUI (\(configuration))",
        command: "/usr/bin/env",
        arguments: [
          "swift",
          "build",
          "--configuration",
          configuration,
        ]
      )
    }
  }
}
