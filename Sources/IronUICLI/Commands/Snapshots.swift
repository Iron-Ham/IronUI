import ArgumentParser
import Foundation

extension IronUICLI {
  struct Snapshots: ParsableCommand, IronUICommand {

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

    func run() throws {
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
        printer.info("IRONUI_RECORD_SNAPSHOTS enabled; snapshots will be re-recorded.")
      }

      try runner.runTask(
        record ? "Recording snapshots" : "Verifying snapshots",
        command: "/usr/bin/env",
        arguments: arguments,
        environment: environment
      )
    }
  }
}
