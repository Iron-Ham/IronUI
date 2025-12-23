import ArgumentParser
import Foundation
import Noora

#if os(macOS)
extension IronUICLI {
  struct Build: AsyncParsableCommand, IronUICommand {

    static let configuration = CommandConfiguration(
      abstract: "Builds the IronUI package."
    )

    @Option(
      name: [.short, .long],
      help: "Build configuration to use (debug or release)."
    )
    var config: String = "debug"

    func run() async throws {
      let buildConfig = config.lowercased() == "release" ? "release" : "debug"

      try await runner.runTask(
        "Building IronUI (\(buildConfig))",
        command: "/usr/bin/env",
        arguments: [
          "swift",
          "build",
          "--configuration",
          buildConfig,
        ]
      )

      noora.success(.alert(
        "Build successful",
        takeaways: ["Configuration: \(buildConfig)"]
      ))
    }
  }
}
#endif
