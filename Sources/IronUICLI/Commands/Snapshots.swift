import ArgumentParser
import Foundation
import Noora

#if os(macOS)
extension IronUICLI {
  struct Snapshots: AsyncParsableCommand, IronUICommand {

    static let configuration = CommandConfiguration(
      abstract: "Runs snapshot tests, optionally recording new baselines."
    )

    enum Platform: String, ExpressibleByArgument, CaseIterable {
      case all
      case macos
      case ios
    }

    @Flag(
      name: [.short, .long],
      help: "Record new reference snapshots instead of validating existing images."
    )
    var record = false

    @Option(
      name: .long,
      help: "Platform to run tests on: all, macos, or ios."
    )
    var platform: Platform = .all

    @Option(
      name: .long,
      help: "iOS Simulator device name (default: iPhone 17 Pro)."
    )
    var simulator: String = "iPhone 17 Pro"

    func run() async throws {
      var environment: [String: String] = [:]
      if record {
        environment["IRONUI_RECORD_SNAPSHOTS"] = "1"
        noora.warning(.alert(
          "Recording mode enabled",
          takeaway: "Snapshots will be re-recorded, not validated"
        ))
      }

      let action = record ? "Recording" : "Verifying"
      var platformsRun: [String] = []

      // Run macOS tests
      if platform == .all || platform == .macos {
        try await runMacOSTests(action: action, environment: environment)
        platformsRun.append("macOS")
      }

      // Run iOS tests
      if platform == .all || platform == .ios {
        try await runiOSTests(action: action, environment: environment)
        platformsRun.append("iOS")
      }

      if record {
        noora.success(.alert(
          "Snapshots recorded",
          takeaways: [
            "Platforms: \(platformsRun.joined(separator: ", "))",
            "New reference images have been saved",
          ]
        ))
      } else {
        noora.success(.alert(
          "Snapshot tests passed",
          takeaways: [
            "Platforms: \(platformsRun.joined(separator: ", "))",
            "All snapshots match reference images",
          ]
        ))
      }
    }

    private func runMacOSTests(action: String, environment: [String: String]) async throws {
      let arguments = [
        "swift", "test",
        "--filter", "IronUISnapshotTests",
      ]

      try await runner.runTask(
        "\(action) macOS snapshots",
        command: "/usr/bin/env",
        arguments: arguments,
        environment: environment
      )
    }

    private func runiOSTests(action: String, environment: [String: String]) async throws {
      let arguments = [
        "xcodebuild", "test",
        "-scheme", "IronUI-Package",
        "-destination", "platform=iOS Simulator,name=\(simulator)",
        "-only-testing", "IronUISnapshotTests",
      ]

      try await runner.runTask(
        "\(action) iOS snapshots (\(simulator))",
        command: "/usr/bin/env",
        arguments: arguments,
        environment: environment
      )
    }
  }
}
#endif
