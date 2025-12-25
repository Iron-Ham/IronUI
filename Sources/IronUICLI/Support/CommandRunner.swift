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
    environment: [String: String] = [:],
  ) async throws {
    try await noora.progressStep(
      message: description,
      successMessage: "\(description) completed",
      errorMessage: "\(description) failed",
      showSpinner: true,
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

  /// Runs a command with streaming output using Noora's collapsible step.
  ///
  /// Shows the last few lines of output while the command runs,
  /// collapsing to a summary when complete. Ideal for long-running tasks
  /// where developers want to see progress.
  ///
  /// - Parameters:
  ///   - description: A human-readable description of the task.
  ///   - command: The command executable path.
  ///   - arguments: Arguments to pass to the command.
  ///   - environment: Additional environment variables.
  ///   - visibleLines: Number of output lines to show (default: 5).
  ///   - allowFailure: Whether non-zero exit codes should be treated as success.
  ///   - streamOutput: Whether to stream output updates while the task runs.
  /// - Returns: The process termination status.
  func runTaskWithOutput(
    _ description: String,
    command: String,
    arguments: [String] = [],
    environment: [String: String] = [:],
    visibleLines: UInt = 5,
    allowFailure: Bool = false,
    streamOutput: Bool = true
  ) async throws -> Int32 {
    var terminationStatus: Int32 = 0
    try await noora.collapsibleStep(
      title: "\(description)",
      successMessage: "\(description) completed",
      errorMessage: "\(description) failed",
      visibleLines: visibleLines,
    ) { progress in
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

      // Use a serial queue to coordinate progress updates.
      let progressQueue = DispatchQueue(label: "dev.ironui.cli.progress")
      let sendableProgress = UncheckedSendable(progress)
      let outputBuffer = StreamBuffer(collectErrorOutput: false)
      let errorBuffer = StreamBuffer(collectErrorOutput: true)
      let batcher = LineBatcher(
        queue: progressQueue,
        progress: sendableProgress,
        flushDelay: .seconds(1),
        maxLinesPerFlush: 200,
        streaming: streamOutput
      )

      // Set up readability handlers to stream output.
      outputPipe.fileHandleForReading.readabilityHandler = { handle in
        let data = handle.availableData
        guard !data.isEmpty, let output = String(data: data, encoding: .utf8) else { return }
        let lines = outputBuffer.append(output)
        batcher.enqueue(lines)
      }

      errorPipe.fileHandleForReading.readabilityHandler = { handle in
        let data = handle.availableData
        guard !data.isEmpty, let output = String(data: data, encoding: .utf8) else { return }
        let lines = errorBuffer.append(output)
        batcher.enqueue(lines)
      }

      try process.run()
      process.waitUntilExit()

      // Clean up handlers
      outputPipe.fileHandleForReading.readabilityHandler = nil
      errorPipe.fileHandleForReading.readabilityHandler = nil

      terminationStatus = process.terminationStatus
      let remainingLines = outputBuffer.flushRemainder() + errorBuffer.flushRemainder()
      batcher.enqueue(remainingLines)
      batcher.flush()
      guard terminationStatus == 0 else {
        let remainingErrorData = errorPipe.fileHandleForReading.readDataToEndOfFile()
        if let remainingErrorOutput = String(data: remainingErrorData, encoding: .utf8) {
          let extraLines = errorBuffer.append(remainingErrorOutput)
          batcher.enqueue(extraLines)
          batcher.flush()
        }
        let stderrOutput = errorBuffer.collectedErrorOutput()
        if !stderrOutput.isEmpty {
          fputs(stderrOutput, stderr)
        }
        if allowFailure {
          return
        }
        throw ExitCode(terminationStatus)
      }
    }
    return terminationStatus
  }

  /// Wrapper to make non-Sendable values passable across concurrency boundaries.
  private struct UncheckedSendable<T>: @unchecked Sendable {
    let value: T
    init(_ value: T) { self.value = value }
  }

  private final class StreamBuffer: @unchecked Sendable {
    private let lock = NSLock()
    private var buffer = ""
    private var errorOutput = ""
    private let collectErrorOutput: Bool

    init(collectErrorOutput: Bool) {
      self.collectErrorOutput = collectErrorOutput
    }

    func append(_ output: String) -> [String] {
      lock.lock()
      defer { lock.unlock() }
      let normalized = output.replacingOccurrences(of: "\r", with: "\n")
      buffer.append(normalized)
      if collectErrorOutput {
        errorOutput.append(output)
      }
      var lines: [String] = []
      while let range = buffer.range(of: "\n") {
        let line = String(buffer[..<range.lowerBound])
        buffer.removeSubrange(..<range.upperBound)
        if !line.isEmpty {
          lines.append(line)
        }
      }
      return lines
    }

    func flushRemainder() -> [String] {
      lock.lock()
      defer { lock.unlock() }
      guard !buffer.isEmpty else { return [] }
      let line = buffer
      buffer.removeAll()
      return [line]
    }

    func collectedErrorOutput() -> String {
      lock.lock()
      defer { lock.unlock() }
      return errorOutput
    }
  }

  private final class LineBatcher: @unchecked Sendable {
    private let queue: DispatchQueue
    private let progress: UncheckedSendable<(TerminalText) -> Void>
    private let flushDelay: DispatchTimeInterval
    private let maxLinesPerFlush: Int
    private let streaming: Bool
    private var pendingLines: [String] = []
    private var flushWorkItem: DispatchWorkItem?

    init(
      queue: DispatchQueue,
      progress: UncheckedSendable<(TerminalText) -> Void>,
      flushDelay: DispatchTimeInterval,
      maxLinesPerFlush: Int,
      streaming: Bool
    ) {
      self.queue = queue
      self.progress = progress
      self.flushDelay = flushDelay
      self.maxLinesPerFlush = maxLinesPerFlush
      self.streaming = streaming
    }

    func enqueue(_ lines: [String]) {
      guard !lines.isEmpty else { return }
      queue.async {
        self.pendingLines.append(contentsOf: lines)
        guard self.streaming else { return }
        if self.pendingLines.count >= self.maxLinesPerFlush {
          self.flushInternal(cancelScheduled: true)
          return
        }
        if self.flushWorkItem != nil { return }
        let item = DispatchWorkItem { [weak self] in
          self?.flushInternal(cancelScheduled: false)
        }
        self.flushWorkItem = item
        self.queue.asyncAfter(deadline: .now() + self.flushDelay, execute: item)
      }
    }

    func flush() {
      queue.sync {
        self.flushInternal(cancelScheduled: true)
      }
    }

    private func flushInternal(cancelScheduled: Bool) {
      if cancelScheduled {
        flushWorkItem?.cancel()
      }
      flushWorkItem = nil
      let joined = pendingLines.joined(separator: "\n")
      pendingLines.removeAll()
      guard !joined.isEmpty else { return }
      progress.value(TerminalText(stringLiteral: joined))
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
      relativeTo: URL(fileURLWithPath: FileManager.default.currentDirectoryPath),
    )

    try await runTask(
      "Running \(relativePath)",
      command: "/usr/bin/env",
      arguments: ["bash", scriptURL.path],
      environment: environment,
    )
  }

  // MARK: Private

  private let noora: Noora
}
#endif
