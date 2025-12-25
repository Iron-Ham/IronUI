import ArgumentParser
import Foundation
import Noora

#if os(macOS)
extension IronUICLI {
  struct Docs: AsyncParsableCommand, IronUICommand {

    // MARK: Internal

    static let configuration = CommandConfiguration(
      abstract: "Generates DocC documentation for IronUI."
    )

    @Option(
      name: .long,
      help: "Output directory for generated documentation.",
    )
    var output = "./docs"

    @Flag(
      name: .long,
      help: "Preview documentation in a local server.",
    )
    var preview = false

    func run() async throws {
      if preview {
        try await previewDocs()
      } else {
        try await generateDocs()
      }
    }

    // MARK: Private

    private static let targets = [
      "IronCore",
      "IronPrimitives",
      "IronComponents",
      "IronLayouts",
      "IronNavigation",
      "IronForms",
      "IronDataDisplay",
      "IronUI",
    ]

    private var archivePath: String {
      ".build/plugins/Swift-DocC/outputs/IronUI.doccarchive"
    }

    private func generateDocs() async throws {
      var arguments = [
        "swift",
        "package",
        "generate-documentation",
        "--enable-experimental-combined-documentation",
        "--enable-mentioned-in",
        "--enable-parameters-and-returns-validation",
      ]

      // Add all targets
      for target in Self.targets {
        arguments.append(contentsOf: ["--target", target])
      }

      arguments.append(contentsOf: [
        "--disable-indexing",
        "--transform-for-static-hosting",
        "--hosting-base-path",
        "IronUI",
      ])

      _ = try await runner.runTaskWithOutput(
        "Generating combined documentation",
        command: "/usr/bin/env",
        arguments: arguments,
        streamOutput: false,
      )

      // Verify archive exists
      let fileManager = FileManager.default
      guard fileManager.fileExists(atPath: archivePath) else {
        noora.error(.alert(
          "Documentation archive not found",
          takeaways: ["Expected at: \(archivePath)"],
        ))
        throw ExitCode.failure
      }

      // Copy to output directory
      noora.info(.alert("Copying to output directory", takeaways: ["\(output)"]))

      if fileManager.fileExists(atPath: output) {
        try fileManager.removeItem(atPath: output)
      }
      try fileManager.createDirectory(atPath: output, withIntermediateDirectories: true)

      let archiveContents = try fileManager.contentsOfDirectory(atPath: archivePath)
      for item in archiveContents {
        let source = (archivePath as NSString).appendingPathComponent(item)
        let destination = (output as NSString).appendingPathComponent(item)
        try fileManager.copyItem(atPath: source, toPath: destination)
      }

      noora.success(.alert(
        "Documentation generated",
        takeaways: [
          "Output: \(output)",
          "Targets: \(Self.targets.count) modules",
        ],
      ))
    }

    private func previewDocs() async throws {
      var arguments = [
        "swift",
        "package",
        "--disable-sandbox",
        "preview-documentation",
      ]

      // Add all targets
      for target in Self.targets {
        arguments.append(contentsOf: ["--target", target])
      }

      noora.info(.alert(
        "Starting documentation preview server",
        takeaways: ["Press Ctrl+C to stop"],
      ))

      try await runner.runTask(
        "Previewing documentation",
        command: "/usr/bin/env",
        arguments: arguments,
      )
    }
  }
}
#endif
