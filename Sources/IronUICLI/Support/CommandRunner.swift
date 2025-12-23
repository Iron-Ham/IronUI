import ArgumentParser
import Foundation
import Noora

struct CommandRunner {

  // MARK: Lifecycle

  init(printer: Noora.Printer) {
    self.printer = printer
  }

  // MARK: Internal

  func runTask(
    _ description: String,
    command: String,
    arguments: [String] = [],
    environment: [String: String] = [:]
  ) throws {
    printer.task(description)

    let process = Process()
    process.executableURL = URL(fileURLWithPath: command)
    process.arguments = arguments
    process.environment = ProcessInfo.processInfo.environment.merging(environment) { _, new in
      new
    }

    let pipe = Pipe()
    process.standardOutput = pipe
    process.standardError = pipe

    try process.run()

    let data = pipe.fileHandleForReading.readDataToEndOfFile()
    if !data.isEmpty {
      FileHandle.standardOutput.write(data)
    }

    process.waitUntilExit()
    guard process.terminationStatus == 0 else {
      printer.failure("Command exited with code \(process.terminationStatus).")
      throw ExitCode(process.terminationStatus)
    }

    printer.success("\(description) completed.")
  }

  func runScript(_ relativePath: String, environment: [String: String] = [:]) throws {
    let scriptURL = URL(
      fileURLWithPath: relativePath,
      relativeTo: URL(fileURLWithPath: fileManager.currentDirectoryPath)
    )

    try runTask(
      "Running \(relativePath)",
      command: "/usr/bin/env",
      arguments: ["bash", scriptURL.path],
      environment: environment
    )
  }

  // MARK: Private

  private let printer: Noora.Printer
  private let fileManager = FileManager.default
}
