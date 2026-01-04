import Foundation

// MARK: - IronColumnWidthMode

/// Defines how a column width is calculated in an `IronDatabaseTable`.
///
/// Column width modes provide flexibility in how table columns size themselves,
/// from fixed pixel widths to dynamic content-based sizing.
///
/// ## Usage
///
/// ```swift
/// // Fixed width column
/// column.widthMode = .fixed(200)
///
/// // Flexible column with constraints
/// column.widthMode = .flexible(min: 100, max: 300)
///
/// // Auto-size based on content
/// column.widthMode = .fitContent()
///
/// // Fill remaining space
/// column.widthMode = .fill()
/// ```
public enum IronColumnWidthMode: Sendable, Equatable, Hashable {

  /// Fixed width in points.
  ///
  /// The column will always render at exactly this width,
  /// regardless of content or container size.
  ///
  /// - Parameter width: The exact width in points.
  case fixed(CGFloat)

  /// Flexible width with optional min/max constraints.
  ///
  /// The column will size itself within the given bounds,
  /// allowing for responsive layouts.
  ///
  /// - Parameters:
  ///   - min: Minimum width (default: 100 points).
  ///   - max: Maximum width (default: 400 points).
  case flexible(min: CGFloat = 100, max: CGFloat = 400)

  /// Width calculated to fit content.
  ///
  /// The column width is computed by sampling cell content
  /// to determine the optimal width. For performance with large
  /// datasets, only a sample of rows is measured.
  ///
  /// - Parameter sampleSize: Number of rows to sample (default: 50).
  case fitContent(sampleSize: Int = 50)

  /// Fills remaining space proportionally.
  ///
  /// Multiple `.fill` columns share the remaining horizontal space
  /// proportionally based on their weights.
  ///
  /// - Parameter weight: Proportion of remaining space (default: 1.0).
  case fill(weight: CGFloat = 1.0)

  /// Width calculated to fit the header text.
  ///
  /// Unlike `.fitContent` which samples row data, this mode sizes the column
  /// based solely on the header name. Useful for columns with short content
  /// but descriptive headers (e.g., "Status" column with single-character values).
  ///
  /// - Parameter padding: Additional horizontal padding for sort indicator and margins (default: 24 points).
  case fitHeader(padding: CGFloat = 24)

  // MARK: Public

  /// The minimum width for this mode.
  public var minimumWidth: CGFloat {
    switch self {
    case .fixed(let width):
      width
    case .flexible(let min, _):
      min
    case .fitContent:
      40 // Absolute minimum for any content
    case .fill:
      40 // Absolute minimum for fill columns
    case .fitHeader:
      40 // Absolute minimum, actual width determined by header text
    }
  }

  /// The maximum width for this mode, or nil if unbounded.
  public var maximumWidth: CGFloat? {
    switch self {
    case .fixed(let width):
      width
    case .flexible(_, let max):
      max
    case .fitContent:
      nil // No maximum, determined by content
    case .fill:
      nil // No maximum, fills available space
    case .fitHeader:
      nil // No maximum, determined by header text
    }
  }

  /// Whether this mode allows user resizing.
  public var allowsUserResizing: Bool {
    switch self {
    case .fixed:
      false
    case .flexible, .fitContent, .fill, .fitHeader:
      true
    }
  }
}

// MARK: - Default Values

extension IronColumnWidthMode {

  /// The default width mode for new columns.
  ///
  /// Uses `.fitHeader()` to automatically size columns based on header content,
  /// which provides a clean, consistent appearance while allowing user resizing.
  public static var `default`: IronColumnWidthMode {
    .fitHeader()
  }

  /// A narrow column mode suitable for checkboxes or icons.
  public static var narrow: IronColumnWidthMode {
    .fixed(60)
  }

  /// A standard column mode for typical text content.
  public static var standard: IronColumnWidthMode {
    .flexible(min: 100, max: 250)
  }

  /// A wide column mode for longer text or descriptions.
  public static var wide: IronColumnWidthMode {
    .flexible(min: 200, max: 500)
  }

  /// A column mode sized to fit the header text.
  public static var fitHeader: IronColumnWidthMode {
    .fitHeader()
  }
}
