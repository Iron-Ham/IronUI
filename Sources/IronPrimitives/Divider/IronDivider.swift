import IronCore
import SwiftUI

// MARK: - IronDivider

/// A themed divider component for separating content.
///
/// `IronDivider` provides consistent visual separation across your app
/// using the theme's divider color and spacing tokens.
///
/// ## Basic Usage
///
/// ```swift
/// VStack {
///   Text("Above")
///   IronDivider()
///   Text("Below")
/// }
/// ```
///
/// ## Vertical Dividers
///
/// ```swift
/// HStack {
///   Text("Left")
///   IronDivider(axis: .vertical)
///   Text("Right")
/// }
/// ```
///
/// ## Styled Dividers
///
/// ```swift
/// IronDivider(style: .subtle)
/// IronDivider(style: .prominent)
/// IronDivider(style: .accent)
/// ```
///
/// ## Labeled Dividers
///
/// ```swift
/// IronDivider(label: "OR")
/// IronDivider(label: "Continue with", style: .subtle)
/// ```
public struct IronDivider<Label: View>: View {

  // MARK: Lifecycle

  /// Creates a themed divider.
  ///
  /// - Parameters:
  ///   - axis: The orientation of the divider.
  ///   - style: The visual style of the divider.
  ///   - insets: Edge insets to apply to the divider.
  public init(
    axis: IronDividerAxis = .horizontal,
    style: IronDividerStyle = .standard,
    insets: EdgeInsets = EdgeInsets(),
  )
    where Label == EmptyView
  {
    self.axis = axis
    self.style = style
    self.insets = insets
    label = nil
  }

  /// Creates a labeled divider with a text label.
  ///
  /// - Parameters:
  ///   - label: The text to display in the divider.
  ///   - style: The visual style of the divider.
  public init(
    label: LocalizedStringKey,
    style: IronDividerStyle = .standard,
  )
    where Label == Text
  {
    axis = .horizontal
    self.style = style
    insets = EdgeInsets()
    self.label = Text(label)
  }

  /// Creates a labeled divider with a custom label view.
  ///
  /// - Parameters:
  ///   - style: The visual style of the divider.
  ///   - label: A view builder that creates the label.
  public init(
    style: IronDividerStyle = .standard,
    @ViewBuilder label: () -> Label,
  ) {
    axis = .horizontal
    self.style = style
    insets = EdgeInsets()
    self.label = label()
  }

  // MARK: Public

  public var body: some View {
    Group {
      if let label {
        labeledDivider(label: label)
      } else {
        simpleDivider
      }
    }
    .padding(insets)
  }

  // MARK: Private

  @Environment(\.ironTheme) private var theme

  private let axis: IronDividerAxis
  private let style: IronDividerStyle
  private let insets: EdgeInsets
  private let label: Label?

  private var dividerColor: Color {
    switch style {
    case .subtle: theme.colors.divider.opacity(0.5)
    case .standard: theme.colors.divider
    case .prominent: theme.colors.border
    case .accent: theme.colors.primary.opacity(0.5)
    }
  }

  private var thickness: CGFloat {
    switch style {
    case .subtle: 0.5
    case .standard: 1
    case .prominent: 2
    case .accent: 1
    }
  }

  @ViewBuilder
  private var simpleDivider: some View {
    switch axis {
    case .horizontal:
      Rectangle()
        .fill(dividerColor)
        .frame(height: thickness)
        .frame(maxWidth: .infinity)

    case .vertical:
      Rectangle()
        .fill(dividerColor)
        .frame(width: thickness)
        .frame(maxHeight: .infinity)
    }
  }

  private func labeledDivider(label: Label) -> some View {
    HStack(spacing: theme.spacing.md) {
      Rectangle()
        .fill(dividerColor)
        .frame(height: thickness)
      label
        .font(theme.typography.caption)
        .foregroundStyle(theme.colors.textSecondary)
      Rectangle()
        .fill(dividerColor)
        .frame(height: thickness)
    }
  }
}

// MARK: - IronDividerAxis

/// The orientation of an `IronDivider`.
public enum IronDividerAxis: Sendable, CaseIterable {
  /// A horizontal divider that spans the width.
  case horizontal
  /// A vertical divider that spans the height.
  case vertical
}

// MARK: - IronDividerStyle

/// Visual styles for `IronDivider`.
public enum IronDividerStyle: Sendable, CaseIterable {
  /// A subtle, thin divider with reduced opacity.
  case subtle
  /// The standard divider appearance.
  case standard
  /// A thicker, more prominent divider.
  case prominent
  /// A divider using the accent color.
  case accent
}

// MARK: - Previews

#Preview("IronDivider - Horizontal") {
  VStack(spacing: 16) {
    Text("Content above")
    IronDivider()
    Text("Content below")
  }
  .padding()
}

#Preview("IronDivider - Vertical") {
  HStack(spacing: 16) {
    Text("Left")
    IronDivider(axis: .vertical)
    Text("Right")
  }
  .frame(height: 50)
  .padding()
}

#Preview("IronDivider - Styles") {
  VStack(spacing: 24) {
    VStack(spacing: 4) {
      Text("Subtle").font(.caption)
      IronDivider(style: .subtle)
    }
    VStack(spacing: 4) {
      Text("Standard").font(.caption)
      IronDivider(style: .standard)
    }
    VStack(spacing: 4) {
      Text("Prominent").font(.caption)
      IronDivider(style: .prominent)
    }
    VStack(spacing: 4) {
      Text("Accent").font(.caption)
      IronDivider(style: .accent)
    }
  }
  .padding()
}

#Preview("IronDivider - Labeled") {
  VStack(spacing: 24) {
    IronDivider(label: "OR")
    IronDivider(label: "Continue with", style: .subtle)
    IronDivider(style: .standard) {
      HStack(spacing: 4) {
        Image(systemName: "star.fill")
        Text("Featured")
      }
    }
  }
  .padding()
}

#Preview("IronDivider - With Insets") {
  VStack(spacing: 16) {
    Text("Full width divider")
    IronDivider()
    Text("Inset divider")
    IronDivider(insets: EdgeInsets(top: 0, leading: 44, bottom: 0, trailing: 0))
    Text("Content with leading icon inset")
  }
  .padding()
}
