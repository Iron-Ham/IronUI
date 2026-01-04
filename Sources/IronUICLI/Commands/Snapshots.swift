import ArgumentParser
import Foundation
import Noora

#if os(macOS)
extension IronUICLI {
  struct Snapshots: AsyncParsableCommand, IronUICommand {

    // MARK: Internal

    enum Platform: String, ExpressibleByArgument, CaseIterable {
      case all
      case macos
      case ios
    }

    static let configuration = CommandConfiguration(
      abstract: "Runs snapshot tests, optionally recording new baselines."
    )

    @Flag(
      name: [.short, .long],
      help: "Record new reference snapshots instead of validating existing images.",
    )
    var record = false

    @Option(
      name: .long,
      help: "Platform to run tests on: all, macos, or ios.",
    )
    var platform = Platform.all

    @Option(
      name: .long,
      help: "iOS Simulator device name (default: iPhone 17 Pro).",
    )
    var simulator = "iPhone 17 Pro"

    @Flag(
      name: .long,
      help: "Use SPM for macOS tests instead of Tuist.",
    )
    var spm = false

    func run() async throws {
      var environment = [String: String]()
      if record {
        environment["IRONUI_RECORD_SNAPSHOTS"] = "1"
        noora.warning(.alert(
          "Recording mode enabled",
          takeaway: "Snapshots will be re-recorded, not validated",
        ))
      }

      let action = record ? "Recording" : "Verifying"
      var platformsRun = [String]()

      // Generate project first if using Tuist
      if !spm {
        try await runner.runTask(
          "Generating Xcode project",
          command: "/usr/bin/env",
          arguments: ["tuist", "generate"],
        )
      }

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
          ],
        ))
      } else {
        noora.success(.alert(
          "Snapshot tests passed",
          takeaways: [
            "Platforms: \(platformsRun.joined(separator: ", "))",
            "All snapshots match reference images",
          ],
        ))
      }
    }

    // MARK: Private

    private func runMacOSTests(action: String, environment: [String: String]) async throws {
      // Use xcodebuild directly (like iOS) so environment variables are properly passed
      let arguments: [String] =
        if spm {
          [
            "swift",
            "test",
            "--filter",
            "IronUISnapshotTests",
          ]
        } else {
          [
            "xcodebuild",
            "test",
            "-workspace",
            "IronUI.xcworkspace",
            "-scheme",
            "IronUISnapshotTests",
            "-destination",
            "platform=macOS,arch=arm64",
          ]
        }

      // For recording, use environment variable
      // Note: TEST_RUNNER_ prefix required for Xcode 15.3+ to pass env vars to tests
      var env = environment
      if record {
        env["TEST_RUNNER_IRONUI_RECORD_SNAPSHOTS"] = "1"
      }

      let status = try await runner.runTaskWithOutput(
        "\(action) macOS snapshots",
        command: "/usr/bin/env",
        arguments: arguments,
        environment: env,
        allowFailure: record,
        streamOutput: false,
      )
      if record, status != 0 {
        noora.warning(.alert(
          "Recording macOS snapshots finished with issues",
          takeaway: "Re-run without --record to verify the new baselines",
        ))
      }
    }

    private func runiOSTests(action: String, environment: [String: String]) async throws {
      // iOS tests run through the PreviewGallery app target
      let arguments = [
        "xcodebuild",
        "test",
        "-workspace",
        "IronUI.xcworkspace",
        "-scheme",
        "PreviewGallery",
        "-destination",
        "platform=iOS Simulator,name=\(simulator)",
      ]

      // For recording, use environment variable
      // Note: TEST_RUNNER_ prefix required for Xcode 15.3+ to pass env vars to tests
      var env = environment
      if record {
        env["TEST_RUNNER_IRONUI_RECORD_SNAPSHOTS"] = "1"
      }

      let status = try await runner.runTaskWithOutput(
        "\(action) iOS snapshots (\(simulator))",
        command: "/usr/bin/env",
        arguments: arguments,
        environment: env,
        allowFailure: record,
        streamOutput: false,
      )
      if record, status != 0 {
        noora.warning(.alert(
          "Recording iOS snapshots finished with issues",
          takeaway: "Re-run without --record to verify the new baselines",
        ))
      }
    }
  }
}
#endif
