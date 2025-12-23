import SwiftUI

// MARK: - FirstLineAlignment

/// Provides first-line text alignment for use in HStack layouts.
///
/// This extension adds the `firstLine` vertical alignment, which centers
/// content with the first line of text in an adjacent view. This is particularly
/// useful for timeline-style layouts, lists with icons, and any UI where an
/// element should align with the top line of multiline text.
extension VerticalAlignment {

  // MARK: Public

  /// Aligns content to the center of the first line of text.
  ///
  /// This alignment is analogous to the default behavior of SwiftUI's `Label`, where
  /// the icon is vertically centered with the first line of the label text. Unlike
  /// `Label`, this alignment can be used with any view, any spacing, and any number
  /// of subviews.
  ///
  /// The alignment uses SwiftUI's text baseline alignment guides to calculate the
  /// center of the first line. It works by finding the difference between the first
  /// and last text baselines, then computing the midpoint of the remaining height.
  ///
  /// ## Usage
  ///
  /// Use `.firstLine` as the alignment parameter for `HStack`:
  ///
  /// ```swift
  /// HStack(alignment: .firstLine, spacing: 12) {
  ///   Image(systemName: "star.fill")
  ///     .foregroundStyle(.yellow)
  ///   VStack(alignment: .leading) {
  ///     Text("First Line")
  ///       .font(.headline)
  ///     Text("Second Line")
  ///     Text("Third Line")
  ///   }
  /// }
  /// ```
  ///
  /// The star icon will be vertically centered with "First Line", regardless of how
  /// many additional lines of text appear below.
  ///
  /// ## Common Use Cases
  ///
  /// - **Timeline entries**: Align node indicators with the first line of event descriptions
  /// - **List items**: Align icons or checkboxes with the first line of multiline labels
  /// - **Form fields**: Align validation icons with the first line of error messages
  /// - **Comments/Reviews**: Align avatars with the first line of comment text
  ///
  /// ## How It Works
  ///
  /// The alignment calculates:
  /// 1. The height after the first line: `lastTextBaseline - firstTextBaseline`
  /// 2. The height of the first line: `totalHeight - heightAfterFirstLine`
  /// 3. The center point: `heightOfFirstLine / 2`
  ///
  /// This positions the alignment guide at the vertical center of the first line of text.
  public static let firstLine = Self(FirstLineAlignment.self)

  // MARK: Private

  private enum FirstLineAlignment: AlignmentID {
    static func defaultValue(in context: ViewDimensions) -> CGFloat {
      // Calculate the height of text after the first line
      let heightAfterFirstLine = context[.lastTextBaseline] - context[.firstTextBaseline]
      // Calculate the height of the first line
      let heightOfFirstLine = context.height - heightAfterFirstLine
      // Return the center of the first line
      return heightOfFirstLine / 2
    }
  }
}
