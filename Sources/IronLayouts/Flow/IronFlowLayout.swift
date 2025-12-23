import IronCore
import SwiftUI

// MARK: - IronFlow

/// A layout that arranges views in rows, wrapping to the next line when needed.
///
/// `IronFlow` implements flexbox-style wrapping behavior, ideal for:
/// - Tag lists and labels
/// - Filter chips
/// - Skill badges
/// - Any content that should flow naturally within available space
///
/// ## Basic Usage
///
/// ```swift
/// IronFlow {
///   ForEach(tags, id: \.self) { tag in
///     IronChip(tag)
///   }
/// }
/// ```
///
/// ## With Custom Spacing
///
/// ```swift
/// IronFlow(horizontalSpacing: 6, verticalSpacing: 8) {
///   ForEach(labels) { label in
///     Text(label.name)
///       .padding(.horizontal, 8)
///       .padding(.vertical, 4)
///       .background(label.color)
///       .clipShape(Capsule())
///   }
/// }
/// ```
///
/// ## Alignment
///
/// ```swift
/// IronFlow(alignment: .center) { ... }  // Center items in each row
/// IronFlow(alignment: .leading) { ... } // Left-align (default)
/// IronFlow(alignment: .trailing) { ... } // Right-align
/// ```
public struct IronFlow: Layout {

  // MARK: Lifecycle

  /// Creates a flow layout with the specified spacing and alignment.
  ///
  /// - Parameters:
  ///   - horizontalSpacing: Space between items in a row. Defaults to 8pt.
  ///   - verticalSpacing: Space between rows. Defaults to 8pt.
  ///   - alignment: Horizontal alignment of items within each row.
  public init(
    horizontalSpacing: CGFloat = 8,
    verticalSpacing: CGFloat = 8,
    alignment: HorizontalAlignment = .leading,
  ) {
    self.horizontalSpacing = horizontalSpacing
    self.verticalSpacing = verticalSpacing
    self.alignment = alignment
  }

  // MARK: Public

  /// Cache for layout calculations.
  public struct CacheData {
    var rows = [[Int]]()
    var sizes = [CGSize]()
  }

  public func makeCache(subviews _: Subviews) -> CacheData {
    CacheData()
  }

  public func sizeThatFits(
    proposal: ProposedViewSize,
    subviews: Subviews,
    cache: inout CacheData,
  ) -> CGSize {
    let result = computeLayout(proposal: proposal, subviews: subviews)
    cache.rows = result.rows
    cache.sizes = result.sizes
    return result.size
  }

  public func placeSubviews(
    in bounds: CGRect,
    proposal _: ProposedViewSize,
    subviews: Subviews,
    cache: inout CacheData,
  ) {
    var y = bounds.minY

    for rowIndices in cache.rows {
      guard !rowIndices.isEmpty else { continue }

      // Calculate row dimensions
      var rowWidth: CGFloat = 0
      var rowHeight: CGFloat = 0

      for index in rowIndices {
        let size = cache.sizes[index]
        rowWidth += size.width
        rowHeight = max(rowHeight, size.height)
      }
      rowWidth += CGFloat(rowIndices.count - 1) * horizontalSpacing

      // Calculate starting x based on alignment
      let rowStartX: CGFloat =
        switch alignment {
        case .leading:
          bounds.minX
        case .center:
          bounds.minX + (bounds.width - rowWidth) / 2
        case .trailing:
          bounds.maxX - rowWidth
        default:
          bounds.minX
        }

      var x = rowStartX

      for index in rowIndices {
        let size = cache.sizes[index]
        let itemY = y + (rowHeight - size.height) / 2

        subviews[index].place(
          at: CGPoint(x: x, y: itemY),
          proposal: ProposedViewSize(size),
        )

        x += size.width + horizontalSpacing
      }

      y += rowHeight + verticalSpacing
    }
  }

  // MARK: Private

  private struct LayoutResult {
    let rows: [[Int]]
    let sizes: [CGSize]
    let size: CGSize
  }

  private let horizontalSpacing: CGFloat
  private let verticalSpacing: CGFloat
  private let alignment: HorizontalAlignment

  private func computeLayout(
    proposal: ProposedViewSize,
    subviews: Subviews,
  ) -> LayoutResult {
    let maxWidth = proposal.width ?? .infinity
    var rows = [[Int]]()
    var currentRow = [Int]()
    var currentRowWidth: CGFloat = 0
    var sizes = [CGSize]()

    for (index, subview) in subviews.enumerated() {
      let size = subview.sizeThatFits(.unspecified)
      sizes.append(size)

      let itemWidth = currentRow.isEmpty ? size.width : horizontalSpacing + size.width
      let wouldExceed = currentRowWidth + itemWidth > maxWidth

      if wouldExceed, !currentRow.isEmpty {
        rows.append(currentRow)
        currentRow = []
        currentRowWidth = 0
      }

      currentRow.append(index)
      currentRowWidth += currentRow.count == 1 ? size.width : horizontalSpacing + size.width
    }

    if !currentRow.isEmpty {
      rows.append(currentRow)
    }

    // Calculate total size
    var totalHeight: CGFloat = 0
    var maxRowWidth: CGFloat = 0

    for rowIndices in rows {
      var rowWidth: CGFloat = 0
      var rowHeight: CGFloat = 0

      for index in rowIndices {
        rowWidth += sizes[index].width
        rowHeight = max(rowHeight, sizes[index].height)
      }
      rowWidth += CGFloat(max(0, rowIndices.count - 1)) * horizontalSpacing

      maxRowWidth = max(maxRowWidth, rowWidth)
      totalHeight += rowHeight
    }

    totalHeight += CGFloat(max(0, rows.count - 1)) * verticalSpacing

    return LayoutResult(
      rows: rows,
      sizes: sizes,
      size: CGSize(width: maxRowWidth, height: totalHeight),
    )
  }
}

// MARK: - Previews

#Preview("IronFlow - Tags") {
  let tags = ["Swift", "SwiftUI", "iOS", "macOS", "Xcode", "UIKit", "Combine", "Async/Await"]

  VStack(alignment: .leading, spacing: 24) {
    Text("Tags")
      .font(.headline)

    IronFlow(horizontalSpacing: 8, verticalSpacing: 8) {
      ForEach(tags, id: \.self) { tag in
        Text(tag)
          .font(.subheadline)
          .padding(.horizontal, 12)
          .padding(.vertical, 6)
          .background(Color.blue.opacity(0.1))
          .foregroundStyle(.blue)
          .clipShape(Capsule())
      }
    }
  }
  .padding()
}

#Preview("IronFlow - GitHub Labels") {
  let labels: [(name: String, color: Color)] = [
    ("bug", .red),
    ("enhancement", .blue),
    ("good first issue", .green),
    ("help wanted", .orange),
    ("documentation", .purple),
    ("duplicate", .gray),
  ]

  VStack(alignment: .leading, spacing: 16) {
    Text("Issue Labels")
      .font(.headline)

    IronFlow(horizontalSpacing: 6, verticalSpacing: 6) {
      ForEach(labels, id: \.name) { label in
        Text(label.name)
          .font(.caption)
          .fontWeight(.medium)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(label.color.opacity(0.2))
          .foregroundStyle(label.color)
          .clipShape(RoundedRectangle(cornerRadius: 4))
      }
    }
  }
  .padding()
}

#Preview("IronFlow - Alignment") {
  let items = ["One", "Two", "Three", "Four", "Five"]

  VStack(spacing: 32) {
    VStack(alignment: .leading) {
      Text("Leading")
        .font(.caption)
        .foregroundStyle(.secondary)
      IronFlow(horizontalSpacing: 8, verticalSpacing: 8, alignment: .leading) {
        ForEach(items, id: \.self) { item in
          Text(item)
            .padding(8)
            .background(Color.blue.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
      }
      .frame(maxWidth: 200)
      .background(Color.gray.opacity(0.1))
    }

    VStack(alignment: .leading) {
      Text("Center")
        .font(.caption)
        .foregroundStyle(.secondary)
      IronFlow(horizontalSpacing: 8, verticalSpacing: 8, alignment: .center) {
        ForEach(items, id: \.self) { item in
          Text(item)
            .padding(8)
            .background(Color.green.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
      }
      .frame(maxWidth: 200)
      .background(Color.gray.opacity(0.1))
    }

    VStack(alignment: .leading) {
      Text("Trailing")
        .font(.caption)
        .foregroundStyle(.secondary)
      IronFlow(horizontalSpacing: 8, verticalSpacing: 8, alignment: .trailing) {
        ForEach(items, id: \.self) { item in
          Text(item)
            .padding(8)
            .background(Color.orange.opacity(0.2))
            .clipShape(RoundedRectangle(cornerRadius: 8))
        }
      }
      .frame(maxWidth: 200)
      .background(Color.gray.opacity(0.1))
    }
  }
  .padding()
}

#Preview("IronFlow - Variable Sizes") {
  let words = [
    "Swift",
    "is",
    "a",
    "powerful",
    "and",
    "intuitive",
    "programming",
    "language",
    "for",
    "Apple",
    "platforms",
  ]

  VStack(alignment: .leading, spacing: 16) {
    Text("Variable Size Items")
      .font(.headline)

    IronFlow(horizontalSpacing: 4, verticalSpacing: 4) {
      ForEach(words, id: \.self) { word in
        Text(word)
          .padding(.horizontal, 6)
          .padding(.vertical, 2)
          .background(Color.secondary.opacity(0.1))
          .clipShape(RoundedRectangle(cornerRadius: 4))
      }
    }
  }
  .padding()
}
