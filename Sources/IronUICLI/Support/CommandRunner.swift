import ArgumentParser
import Foundation
@preconcurrency import Noora

#if os(macOS)
struct CommandRunner {

  // MARK: Lifecycle

  init(noora: Noora) {
    self.noora = noora
  }

  // MARK: Internal

  /// Runs a command with progress indication using Noora's progress step.
  ///
  /// Shows a spinner with the task description while the command runs,
  /// and displays success/failure when complete.
  ///
  /// - Parameters:
  ///   - description: A human-readable description of the task.
  ///   - command: The command executable path.
  ///   - arguments: Arguments to pass to the command.
  ///   - environment: Additional environment variables.
  func runTask(
    _ description: String,
    command: String,
    arguments: [String] = [],
    environment: [String: String] = [:]
  ) async throws {
    try await noora.progressStep(
      message: description,
      successMessage: "\(description) completed",
      errorMessage: "\(description) failed",
      showSpinner: true
    ) { _ in
      let process = Process()
      process.executableURL = URL(fileURLWithPath: command)
      process.arguments = arguments
      process.environment = ProcessInfo.processInfo.environment.merging(environment) { _, new in
        new
      }

      let outputPipe = Pipe()
      let errorPipe = Pipe()
      process.standardOutput = outputPipe
      process.standardError = errorPipe

      try process.run()
      process.waitUntilExit()

      guard process.terminationStatus == 0 else {
        // Read error output for diagnostics
        let errorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        if !errorData.isEmpty, let errorOutput = String(data: errorData, encoding: .utf8) {
          fputs(errorOutput, stderr)
        }
        throw ExitCode(process.terminationStatus)
      }
    }
  }

  /// Runs a shell script with progress indication.
  ///
  /// - Parameters:
  ///   - relativePath: The script path relative to the current directory.
  ///   - environment: Additional environment variables.
  func runScript(_ relativePath: String, environment: [String: String] = [:]) async throws {
    let scriptURL = URL(
      fileURLWithPath: relativePath,
      relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
    )

    try await runTask(
      "Running \(relativePath)",
      command: "/usr/bin/env",
      arguments: ["bash", scriptURL.path],
      environment: environment
    )
  }

  // MARK: Private

  private let noora: Noora
}
#endif
