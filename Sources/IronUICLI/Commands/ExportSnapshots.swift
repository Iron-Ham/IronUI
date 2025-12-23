import ArgumentParser
import Foundation
import Noora

extension IronUICLI {
  struct ExportSnapshots: AsyncParsableCommand, IronUICommand {

    static let configuration = CommandConfiguration(
      commandName: "export-snapshots",
      abstract: "Exports snapshots for documentation usage."
    )

    @Flag(
      name: .long,
      help: "Show what would be copied without making changes."
    )
    var dryRun = false

    /// Module configuration mapping snapshot subdirectories to source module paths.
    private static let moduleConfig: [(snapshotSubdir: String, sourceModule: String)] = [
      ("Primitives", "IronPrimitives"),
      ("Components", "IronComponents"),
      ("Layouts", "IronLayouts"),
      ("Forms", "IronForms"),
      ("DataDisplay", "IronDataDisplay"),
      ("Navigation", "IronNavigation"),
    ]

    func run() async throws {
      let fileManager = FileManager.default
      let rootDir = fileManager.currentDirectoryPath
      let snapshotsDir = (rootDir as NSString).appendingPathComponent("Tests/IronUISnapshotTests")

      if dryRun {
        noora.info(.alert("Dry run mode", takeaways: ["No files will be copied"]))
      }

      var totalCopied = 0

      for (snapshotSubdir, sourceModule) in Self.moduleConfig {
        let sourceDir = (snapshotsDir as NSString).appendingPathComponent("\(snapshotSubdir)/__Snapshots__")
        let resourcesDir = (rootDir as NSString).appendingPathComponent(
          "Sources/\(sourceModule)/Documentation.docc/Resources"
        )

        guard fileManager.fileExists(atPath: sourceDir) else {
          continue
        }

        let copied = try exportSnapshots(
          from: sourceDir,
          to: resourcesDir,
          modulePrefix: snapshotSubdir,
          fileManager: fileManager
        )
        totalCopied += copied
      }

      if totalCopied > 0 {
        noora.success(.alert(
          dryRun ? "Would export snapshots" : "Snapshots exported",
          takeaways: [
            "\(totalCopied) images \(dryRun ? "would be" : "") copied",
            "Format: ComponentName-testName.png (light)",
            "Format: ComponentName-testName~dark.png (dark)",
          ]
        ))
      } else {
        noora.warning(.alert(
          "No snapshots found",
          takeaway: "Run snapshot tests first to generate images"
        ))
      }
    }

    /// Exports snapshots from a source directory to a resources directory.
    /// - Returns: The number of files copied.
    private func exportSnapshots(
      from sourceDir: String,
      to resourcesDir: String,
      modulePrefix: String,
      fileManager: FileManager
    ) throws -> Int {
      var copiedCount = 0

      // Find all test directories (e.g., IronButtonSnapshotTests)
      let testDirs = try fileManager.contentsOfDirectory(atPath: sourceDir)

      for testDir in testDirs {
        let testPath = (sourceDir as NSString).appendingPathComponent(testDir)

        var isDirectory: ObjCBool = false
        guard fileManager.fileExists(atPath: testPath, isDirectory: &isDirectory),
              isDirectory.boolValue
        else {
          continue
        }

        // Extract component name (e.g., "IronButton" from "IronButtonSnapshotTests")
        let componentName = testDir.replacingOccurrences(of: "SnapshotTests", with: "")

        // Find all light mode macOS snapshots
        let snapshots = try fileManager.contentsOfDirectory(atPath: testPath)
        let lightSnapshots = snapshots.filter { $0.hasSuffix(".macOSStandard-standard-light.png") }

        for lightSnapshot in lightSnapshots {
          // Extract test name (e.g., "buttonVariants" from "buttonVariants.macOSStandard-standard-light.png")
          let testName = lightSnapshot.replacingOccurrences(
            of: ".macOSStandard-standard-light.png",
            with: ""
          )

          // Create destination directory if needed
          if !dryRun {
            try fileManager.createDirectory(
              atPath: resourcesDir,
              withIntermediateDirectories: true
            )
          }

          // Copy light version
          let lightSource = (testPath as NSString).appendingPathComponent(lightSnapshot)
          let lightDest = (resourcesDir as NSString).appendingPathComponent(
            "\(componentName)-\(testName).png"
          )

          if !dryRun {
            if fileManager.fileExists(atPath: lightDest) {
              try fileManager.removeItem(atPath: lightDest)
            }
            try fileManager.copyItem(atPath: lightSource, toPath: lightDest)
          }
          copiedCount += 1

          // Copy dark version if it exists
          let darkSnapshot = lightSnapshot.replacingOccurrences(
            of: "standard-light",
            with: "standard-dark"
          )
          let darkSource = (testPath as NSString).appendingPathComponent(darkSnapshot)

          if fileManager.fileExists(atPath: darkSource) {
            let darkDest = (resourcesDir as NSString).appendingPathComponent(
              "\(componentName)-\(testName)~dark.png"
            )

            if !dryRun {
              if fileManager.fileExists(atPath: darkDest) {
                try fileManager.removeItem(atPath: darkDest)
              }
              try fileManager.copyItem(atPath: darkSource, toPath: darkDest)
            }
            copiedCount += 1
          }
        }

        if !lightSnapshots.isEmpty {
          noora.info(.alert(
            "\(dryRun ? "Would copy" : "Copied") \(componentName) snapshots",
            takeaways: ["\(lightSnapshots.count) test cases"]
          ))
        }
      }

      return copiedCount
    }
  }
}
