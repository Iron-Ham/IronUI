import Foundation
import os

// MARK: - IronLogLevel

/// Log levels for IronUI logging, matching OSLog levels.
///
/// Levels are ordered by severity from least to most severe:
/// - `debug`: Detailed information for debugging
/// - `info`: General informational messages
/// - `notice`: Notable events that are not errors
/// - `warning`: Potential issues that should be investigated
/// - `error`: Errors that don't prevent operation
/// - `fault`: Critical errors that may cause data loss or crashes
public enum IronLogLevel: Int, Comparable, Sendable, CaseIterable {
  /// Detailed debugging information. Not persisted by default.
  case debug = 0
  /// General informational messages.
  case info = 1
  /// Notable events that are not errors.
  case notice = 2
  /// Potential issues that should be investigated.
  case warning = 3
  /// Errors that don't prevent continued operation.
  case error = 4
  /// Critical errors that may cause data loss or crashes.
  case fault = 5

  // MARK: Public

  /// The corresponding OSLogType for this level.
  public var osLogType: OSLogType {
    switch self {
    case .debug: .debug
    case .info: .info
    case .notice: .default
    case .warning: .default
    case .error: .error
    case .fault: .fault
    }
  }

  /// A human-readable label for this level.
  public var label: String {
    switch self {
    case .debug: "DEBUG"
    case .info: "INFO"
    case .notice: "NOTICE"
    case .warning: "WARNING"
    case .error: "ERROR"
    case .fault: "FAULT"
    }
  }

  /// An emoji indicator for this level (useful in debug output).
  public var emoji: String {
    switch self {
    case .debug: "🔍"
    case .info: "ℹ️"
    case .notice: "📋"
    case .warning: "⚠️"
    case .error: "❌"
    case .fault: "💥"
    }
  }

  public static func <(lhs: IronLogLevel, rhs: IronLogLevel) -> Bool {
    lhs.rawValue < rhs.rawValue
  }

}

// MARK: - IronLogMetadata

/// Metadata that can be attached to log messages.
///
/// Metadata provides additional context for log messages without
/// cluttering the main message. Common uses include:
/// - Request/session identifiers
/// - User identifiers (anonymized)
/// - Component or feature names
/// - Timing information
///
/// ## Example
///
/// ```swift
/// logger.info("Button tapped", metadata: [
///   "component": "IronButton",
///   "variant": "filled",
///   "action": "submit"
/// ])
/// ```
public struct IronLogMetadata: Sendable, ExpressibleByDictionaryLiteral {

  // MARK: Lifecycle

  public init(dictionaryLiteral elements: (String, Value)...) {
    storage = Dictionary(uniqueKeysWithValues: elements)
  }

  public init(_ dictionary: [String: Value] = [:]) {
    storage = dictionary
  }

  // MARK: Public

  /// A metadata value that can be a string, integer, or nested metadata.
  public enum Value: Sendable, CustomStringConvertible {
    case string(String)
    case int(Int)
    case double(Double)
    case bool(Bool)
    case metadata(IronLogMetadata)

    // MARK: Public

    public var description: String {
      switch self {
      case .string(let value): value
      case .int(let value): String(value)
      case .double(let value): String(value)
      case .bool(let value): String(value)
      case .metadata(let value): value.description
      }
    }
  }

  /// An empty metadata instance.
  public static let empty = IronLogMetadata()

  /// The underlying storage.
  public private(set) var storage: [String: Value]

  /// Whether this metadata is empty.
  public var isEmpty: Bool {
    storage.isEmpty
  }

  /// Access metadata values by key.
  public subscript(key: String) -> Value? {
    get { storage[key] }
    set { storage[key] = newValue }
  }

  /// Merges this metadata with another, with the other taking precedence.
  public func merging(_ other: IronLogMetadata) -> IronLogMetadata {
    IronLogMetadata(storage.merging(other.storage) { _, new in new })
  }
}

// MARK: CustomStringConvertible

extension IronLogMetadata: CustomStringConvertible {
  public var description: String {
    guard !isEmpty else { return "" }
    let pairs = storage.map { "\($0.key)=\($0.value)" }
    return "[\(pairs.joined(separator: ", "))]"
  }
}

// MARK: - IronLogMetadata.Value + ExpressibleByStringLiteral

extension IronLogMetadata.Value: ExpressibleByStringLiteral {
  public init(stringLiteral value: String) {
    self = .string(value)
  }
}

// MARK: - IronLogMetadata.Value + ExpressibleByIntegerLiteral

extension IronLogMetadata.Value: ExpressibleByIntegerLiteral {
  public init(integerLiteral value: Int) {
    self = .int(value)
  }
}

// MARK: - IronLogMetadata.Value + ExpressibleByFloatLiteral

extension IronLogMetadata.Value: ExpressibleByFloatLiteral {
  public init(floatLiteral value: Double) {
    self = .double(value)
  }
}

// MARK: - IronLogMetadata.Value + ExpressibleByBooleanLiteral

extension IronLogMetadata.Value: ExpressibleByBooleanLiteral {
  public init(booleanLiteral value: Bool) {
    self = .bool(value)
  }
}

// MARK: - IronLogHandler

/// A handler that processes log messages.
///
/// Implement this protocol to create custom log destinations such as
/// file logging, remote logging services, or test log capture.
public protocol IronLogHandler: Sendable {
  /// The minimum log level this handler will process.
  var minimumLevel: IronLogLevel { get }

  /// Process a log message.
  ///
  /// - Parameters:
  ///   - level: The severity level of the message.
  ///   - message: The log message.
  ///   - metadata: Additional context for the message.
  ///   - source: The source of the log (typically the module or file).
  ///   - file: The file where the log was called.
  ///   - function: The function where the log was called.
  ///   - line: The line number where the log was called.
  func log(
    level: IronLogLevel,
    message: @autoclosure () -> String,
    metadata: IronLogMetadata,
    source: String,
    file: String,
    function: String,
    line: UInt,
  )
}

// MARK: - IronOSLogHandler

/// A log handler that writes to Apple's unified logging system (OSLog).
///
/// This is the default handler for IronUI and integrates with Console.app
/// and Instruments for viewing logs.
public struct IronOSLogHandler: IronLogHandler {

  // MARK: Lifecycle

  /// Creates a new OSLog handler.
  ///
  /// - Parameters:
  ///   - subsystem: The subsystem identifier (typically reverse-DNS, e.g., "com.app.IronUI").
  ///   - category: The category within the subsystem (e.g., "Button", "Theme").
  ///   - minimumLevel: The minimum level to log. Messages below this level are ignored.
  public init(
    subsystem: String,
    category: String,
    minimumLevel: IronLogLevel = .debug,
  ) {
    self.subsystem = subsystem
    self.category = category
    self.minimumLevel = minimumLevel
    logger = Logger(subsystem: subsystem, category: category)
  }

  // MARK: Public

  public let subsystem: String
  public let category: String
  public let minimumLevel: IronLogLevel

  public func log(
    level: IronLogLevel,
    message: @autoclosure () -> String,
    metadata: IronLogMetadata,
    source _: String,
    file _: String,
    function _: String,
    line _: UInt,
  ) {
    guard level >= minimumLevel else { return }

    let msg = message()
    let metadataString = metadata.isEmpty ? "" : " \(metadata)"

    // Use os.Logger for structured logging
    logger.log(level: level.osLogType, "\(msg, privacy: .public)\(metadataString, privacy: .public)")
  }

  // MARK: Private

  private let logger: Logger
}

// MARK: - IronPrintHandler

/// A simple log handler that writes to the system log using `NSLog`.
///
/// Useful for debugging in Xcode or when OSLog is not available.
/// Includes timestamps, levels, and source information.
public struct IronPrintHandler: IronLogHandler {

  // MARK: Lifecycle

  /// Creates a new print handler.
  ///
  /// - Parameters:
  ///   - label: A label to prefix log messages with.
  ///   - minimumLevel: The minimum level to log.
  ///   - isTimestampIncluded: Whether to include timestamps in output.
  ///   - isSourceIncluded: Whether to include source file/line information.
  public init(
    label: String,
    minimumLevel: IronLogLevel = .debug,
    isTimestampIncluded: Bool = true,
    isSourceIncluded: Bool = true,
  ) {
    self.label = label
    self.minimumLevel = minimumLevel
    self.isTimestampIncluded = isTimestampIncluded
    self.isSourceIncluded = isSourceIncluded
  }

  // MARK: Public

  public let label: String
  public let minimumLevel: IronLogLevel
  public let isTimestampIncluded: Bool
  public let isSourceIncluded: Bool

  public func log(
    level: IronLogLevel,
    message: @autoclosure () -> String,
    metadata: IronLogMetadata,
    source _: String,
    file: String,
    function _: String,
    line: UInt,
  ) {
    guard level >= minimumLevel else { return }

    var components = [String]()

    if isTimestampIncluded {
      components.append(Self.timestampFormatter.string(from: Date()))
    }

    components.append("[\(label)]")
    components.append(level.emoji)
    components.append(level.label)

    if isSourceIncluded {
      let fileName = (file as NSString).lastPathComponent
      components.append("(\(fileName):\(line))")
    }

    components.append(message())

    if !metadata.isEmpty {
      components.append(metadata.description)
    }

    NSLog("%@", components.joined(separator: " "))
  }

  // MARK: Private

  private static let timestampFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "HH:mm:ss.SSS"
    return formatter
  }()
}

// MARK: - IronTestLogHandler

/// A log handler that captures logs for testing.
///
/// Use this handler in tests to verify that expected log messages
/// are produced without cluttering test output.
///
/// ## Example
///
/// ```swift
/// let handler = IronTestLogHandler()
/// let logger = IronLogger(handlers: [handler])
///
/// logger.info("Test message")
///
/// #expect(handler.logs.count == 1)
/// #expect(handler.logs[0].level == .info)
/// #expect(handler.logs[0].message == "Test message")
/// ```
// Thread-safety is ensured by NSLock protecting all mutable state (_logs array).
// swiftlint:disable:next no_unchecked_sendable
public final class IronTestLogHandler: IronLogHandler, @unchecked Sendable {

  // MARK: Lifecycle

  public init(minimumLevel: IronLogLevel = .debug) {
    self.minimumLevel = minimumLevel
  }

  // MARK: Public

  /// A captured log entry.
  public struct LogEntry: Sendable {
    public let level: IronLogLevel
    public let message: String
    public let metadata: IronLogMetadata
    public let source: String
    public let file: String
    public let function: String
    public let line: UInt
    public let timestamp: Date
  }

  public let minimumLevel: IronLogLevel

  /// All captured log entries.
  public var logs: [LogEntry] {
    lock.withLock { _logs }
  }

  /// Clears all captured logs.
  public func clear() {
    lock.withLock { _logs.removeAll() }
  }

  /// Returns logs filtered by level.
  public func logs(at level: IronLogLevel) -> [LogEntry] {
    logs.filter { $0.level == level }
  }

  /// Returns logs containing the specified substring.
  public func logs(containing substring: String) -> [LogEntry] {
    logs.filter { $0.message.contains(substring) }
  }

  public func log(
    level: IronLogLevel,
    message: @autoclosure () -> String,
    metadata: IronLogMetadata,
    source: String,
    file: String,
    function: String,
    line: UInt,
  ) {
    guard level >= minimumLevel else { return }

    let entry = LogEntry(
      level: level,
      message: message(),
      metadata: metadata,
      source: source,
      file: file,
      function: function,
      line: line,
      timestamp: Date(),
    )

    lock.withLock { _logs.append(entry) }
  }

  // MARK: Private

  private var _logs = [LogEntry]()
  private let lock = NSLock()
}

// MARK: - IronLogger

/// The main logging interface for IronUI.
///
/// `IronLogger` provides a flexible, Swift 6 concurrency-safe logging
/// system that integrates with Apple's unified logging (OSLog) while
/// supporting custom handlers for testing and other destinations.
///
/// ## Basic Usage
///
/// ```swift
/// let logger = IronLogger.ui
///
/// logger.debug("View appeared")
/// logger.info("User tapped button", metadata: ["button": "submit"])
/// logger.warning("Network request slow", metadata: ["duration": 2.5])
/// logger.error("Failed to load data", metadata: ["code": 404])
/// ```
///
/// ## Custom Logger
///
/// ```swift
/// let logger = IronLogger(
///   subsystem: "com.myapp",
///   category: "Authentication"
/// )
/// ```
///
/// ## Testing
///
/// ```swift
/// let testHandler = IronTestLogHandler()
/// let logger = IronLogger(handlers: [testHandler])
///
/// // ... perform actions that log ...
///
/// #expect(testHandler.logs.count == expectedCount)
/// ```
public struct IronLogger: Sendable {

  // MARK: Lifecycle

  /// Creates a logger with custom handlers.
  ///
  /// - Parameter handlers: The handlers to process log messages.
  public init(handlers: [any IronLogHandler]) {
    self.handlers = handlers
  }

  /// Creates a logger using OSLog (or print in SwiftUI Previews).
  ///
  /// In SwiftUI Previews, OSLog output doesn't appear in Xcode's console,
  /// so we automatically use `IronPrintHandler` for visibility.
  ///
  /// - Parameters:
  ///   - subsystem: The subsystem identifier.
  ///   - category: The category within the subsystem.
  ///   - minimumLevel: The minimum level to log.
  public init(
    subsystem: String,
    category: String,
    minimumLevel: IronLogLevel = .debug,
  ) {
    if Self.isRunningInPreview {
      handlers = [
        IronPrintHandler(
          label: "\(subsystem).\(category)",
          minimumLevel: minimumLevel,
        )
      ]
    } else {
      handlers = [
        IronOSLogHandler(
          subsystem: subsystem,
          category: category,
          minimumLevel: minimumLevel,
        )
      ]
    }
  }

  // MARK: Public

  /// The default logger for IronUI components.
  public static let ui = IronLogger(
    subsystem: "com.ironui",
    category: "UI",
  )

  /// A logger for theming-related messages.
  public static let theme = IronLogger(
    subsystem: "com.ironui",
    category: "Theme",
  )

  /// A logger for animation-related messages.
  public static let animation = IronLogger(
    subsystem: "com.ironui",
    category: "Animation",
  )

  /// A logger for accessibility-related messages.
  public static let accessibility = IronLogger(
    subsystem: "com.ironui",
    category: "Accessibility",
  )

  /// A disabled logger that produces no output.
  public static let disabled = IronLogger(handlers: [])

  /// Whether the code is currently running in a SwiftUI Preview.
  ///
  /// Use this to conditionally enable/disable features in previews.
  public static var isRunningInPreview: Bool {
    ProcessInfo.processInfo.environment["XCODE_RUNNING_FOR_PREVIEWS"] == "1"
  }

  /// Logs a debug message.
  public func debug(
    _ message: @autoclosure () -> String,
    metadata: IronLogMetadata = .empty,
    source: String = "IronUI",
    file: String = #file,
    function: String = #function,
    line: UInt = #line,
  ) {
    log(level: .debug, message: message(), metadata: metadata, source: source, file: file, function: function, line: line)
  }

  /// Logs an info message.
  public func info(
    _ message: @autoclosure () -> String,
    metadata: IronLogMetadata = .empty,
    source: String = "IronUI",
    file: String = #file,
    function: String = #function,
    line: UInt = #line,
  ) {
    log(level: .info, message: message(), metadata: metadata, source: source, file: file, function: function, line: line)
  }

  /// Logs a notice message.
  public func notice(
    _ message: @autoclosure () -> String,
    metadata: IronLogMetadata = .empty,
    source: String = "IronUI",
    file: String = #file,
    function: String = #function,
    line: UInt = #line,
  ) {
    log(level: .notice, message: message(), metadata: metadata, source: source, file: file, function: function, line: line)
  }

  /// Logs a warning message.
  public func warning(
    _ message: @autoclosure () -> String,
    metadata: IronLogMetadata = .empty,
    source: String = "IronUI",
    file: String = #file,
    function: String = #function,
    line: UInt = #line,
  ) {
    log(level: .warning, message: message(), metadata: metadata, source: source, file: file, function: function, line: line)
  }

  /// Logs an error message.
  public func error(
    _ message: @autoclosure () -> String,
    metadata: IronLogMetadata = .empty,
    source: String = "IronUI",
    file: String = #file,
    function: String = #function,
    line: UInt = #line,
  ) {
    log(level: .error, message: message(), metadata: metadata, source: source, file: file, function: function, line: line)
  }

  /// Logs a fault message (critical error).
  public func fault(
    _ message: @autoclosure () -> String,
    metadata: IronLogMetadata = .empty,
    source: String = "IronUI",
    file: String = #file,
    function: String = #function,
    line: UInt = #line,
  ) {
    log(level: .fault, message: message(), metadata: metadata, source: source, file: file, function: function, line: line)
  }

  /// Logs a message at the specified level.
  public func log(
    level: IronLogLevel,
    message: @autoclosure () -> String,
    metadata: IronLogMetadata = .empty,
    source: String = "IronUI",
    file: String = #file,
    function: String = #function,
    line: UInt = #line,
  ) {
    let msg = message()
    for handler in handlers {
      handler.log(
        level: level,
        message: msg,
        metadata: metadata,
        source: source,
        file: file,
        function: function,
        line: line,
      )
    }
  }

  // MARK: Private

  private let handlers: [any IronLogHandler]
}
