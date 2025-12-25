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
      help: "Build configuration to use (debug or release).",
    )
    var config = "debug"

    @Option(
      name: .long,
      help: "Platform to build for: macos or ios.",
    )
    var platform = "macos"

    @Flag(
      name: .long,
      help: "Use SPM build instead of Tuist (for CI or quick builds).",
    )
    var spm = false

    func run() async throws {
      let buildConfig = config.lowercased() == "release" ? "release" : "debug"

      if spm {
        // Use SPM for quick builds or CI
        try await runner.runTask(
          "Building IronUI via SPM (\(buildConfig))",
          command: "/usr/bin/env",
          arguments: [
            "swift",
            "build",
            "--configuration",
            buildConfig,
          ],
        )
      } else {
        // Generate project first if needed
        try await runner.runTask(
          "Generating Xcode project",
          command: "/usr/bin/env",
          arguments: ["tuist", "generate"],
        )

        // Use Tuist build
        try await runner.runTask(
          "Building IronUI via Tuist (\(buildConfig), \(platform))",
          command: "/usr/bin/env",
          arguments: [
            "tuist",
            "build",
            "IronUI",
            "--platform",
            platform,
            "--configuration",
            buildConfig == "release" ? "Release" : "Debug",
          ],
        )
      }

      noora.success(.alert(
        "Build successful",
        takeaways: [
          "Configuration: \(buildConfig)",
          "Platform: \(platform)",
          spm ? "Mode: SPM" : "Mode: Tuist",
        ],
      ))
    }
  }
}
#endif
