import ArgumentParser
import Foundation
import Noora

extension IronUICLI {
  struct Snapshots: AsyncParsableCommand, IronUICommand {

    static let configuration = CommandConfiguration(
      abstract: "Runs snapshot tests, optionally recording new baselines."
    )

    @Flag(
      name: [.short, .long],
      help: "Record new reference snapshots instead of validating existing images."
    )
    var record = false

    @Option(
      name: [.customLong("filter")],
      help: "Optional filter passed through to `swift test --filter`."
    )
    var filterPattern: String?

    func run() async throws {
      var arguments = [
        "swift",
        "test",
        "--test-target",
        "IronUISnapshotTests",
      ]

      if let filterPattern {
        arguments.append(contentsOf: ["--filter", filterPattern])
      }

      var environment: [String: String] = [:]
      if record {
        environment["IRONUI_RECORD_SNAPSHOTS"] = "1"
        noora.warning(.alert(
          "Recording mode enabled",
          takeaway: "Snapshots will be re-recorded, not validated"
        ))
      }

      let taskDescription = record ? "Recording snapshots" : "Verifying snapshots"
      try await runner.runTask(
        taskDescription,
        command: "/usr/bin/env",
        arguments: arguments,
        environment: environment
      )

      if record {
        noora.success(.alert(
          "Snapshots recorded",
          takeaways: ["New reference images have been saved"]
        ))
      } else {
        noora.success(.alert(
          "Snapshot tests passed",
          takeaways: ["All snapshots match reference images"]
        ))
      }
    }
  }
}
