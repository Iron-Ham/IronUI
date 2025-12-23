import SwiftUI

// MARK: - IronMorphingText

/// A text view that animates smoothly between different string values.
///
/// `IronMorphingText` creates Family-style text transitions where the text
/// morphs from one value to another, with shared characters appearing to
/// stay in place while differing characters animate.
///
/// ## Basic Usage
///
/// ```swift
/// @State private var label = "Continue"
///
/// IronMorphingText(label)
///   .font(.headline)
///
/// Button("Change") {
///   withAnimation(.smooth) {
///     label = "Confirm"
///   }
/// }
/// ```
///
/// ## With Numbers
///
/// For numeric values, the transition animates digit-by-digit:
///
/// ```swift
/// IronMorphingText("\(count)", isNumeric: true)
/// ```
public struct IronMorphingText: View {

  // MARK: Lifecycle

  /// Creates a morphing text view.
  ///
  /// - Parameters:
  ///   - text: The text to display.
  ///   - isNumeric: If true, uses numeric text transition for smoother digit animation.
  public init(_ text: String, isNumeric: Bool = false) {
    self.text = text
    self.isNumeric = isNumeric
  }

  /// Creates a morphing text view from a localized string key.
  ///
  /// - Parameters:
  ///   - key: The localized string key.
  ///   - isNumeric: If true, uses numeric text transition.
  public init(_ key: LocalizedStringKey, isNumeric: Bool = false) {
    // Convert to string for animation purposes
    // Note: This loses localization - for production, consider alternatives
    text = "\(key)"
    self.isNumeric = isNumeric
  }

  // MARK: Public

  public var body: some View {
    Text(text)
      .contentTransition(isNumeric ? .numericText() : .interpolate)
  }

  // MARK: Private

  private let text: String
  private let isNumeric: Bool
}

// MARK: - View Extension

extension View {
  /// Applies morphing text transition to the view's text content.
  ///
  /// Use this modifier when you want text changes within a view to animate
  /// smoothly rather than cross-fading.
  ///
  /// ```swift
  /// Text(buttonLabel)
  ///   .ironMorphingText()
  /// ```
  ///
  /// - Parameter isNumeric: If true, uses numeric text transition.
  /// - Returns: A view with morphing text transition applied.
  public func ironMorphingText(isNumeric: Bool = false) -> some View {
    contentTransition(isNumeric ? .numericText() : .interpolate)
  }
}

// MARK: - IronCountingText

/// A text view that animates counting between numeric values.
///
/// `IronCountingText` displays a number that smoothly counts up or down
/// when the value changes, with proper formatting.
///
/// ## Basic Usage
///
/// ```swift
/// @State private var count = 0
///
/// IronCountingText(count)
///
/// Button("Add") {
///   withAnimation(.smooth) {
///     count += 100
///   }
/// }
/// ```
///
/// ## Custom Formatting
///
/// ```swift
/// IronCountingText(
///   price,
///   format: .currency(code: "USD")
/// )
/// ```
public struct IronCountingText<F: FormatStyle>: View where F.FormatInput: BinaryInteger, F.FormatOutput == String {

  // MARK: Lifecycle

  /// Creates a counting text view with a format style.
  ///
  /// - Parameters:
  ///   - value: The numeric value to display.
  ///   - format: The format style for displaying the number.
  public init(_ value: F.FormatInput, format: F) {
    self.value = value
    self.format = format
  }

  // MARK: Public

  public var body: some View {
    Text(value, format: format)
      .contentTransition(.numericText())
  }

  // MARK: Private

  private let value: F.FormatInput
  private let format: F
}

extension IronCountingText where F == IntegerFormatStyle<Int> {
  /// Creates a counting text view with default integer formatting.
  ///
  /// - Parameter value: The integer value to display.
  public init(_ value: Int) {
    self.value = value
    format = .number
  }
}

// MARK: - Previews

#Preview("IronMorphingText") {
  @Previewable @State var label = "Continue"

  VStack(spacing: 32) {
    IronMorphingText(label)
      .font(.title)
      .fontWeight(.semibold)

    HStack(spacing: 16) {
      Button("Continue") {
        withAnimation(.smooth) {
          label = "Continue"
        }
      }
      Button("Confirm") {
        withAnimation(.smooth) {
          label = "Confirm"
        }
      }
      Button("Complete") {
        withAnimation(.smooth) {
          label = "Complete"
        }
      }
    }
    .buttonStyle(.bordered)
  }
  .padding()
}

#Preview("IronCountingText") {
  @Previewable @State var count = 0

  VStack(spacing: 32) {
    IronCountingText(count)
      .font(.system(size: 48, weight: .bold, design: .rounded))
      .monospacedDigit()

    HStack(spacing: 16) {
      Button("-100") {
        withAnimation(.smooth) {
          count -= 100
        }
      }
      Button("-10") {
        withAnimation(.smooth) {
          count -= 10
        }
      }
      Button("+10") {
        withAnimation(.smooth) {
          count += 10
        }
      }
      Button("+100") {
        withAnimation(.smooth) {
          count += 100
        }
      }
    }
    .buttonStyle(.bordered)
  }
  .padding()
}

#Preview("Morphing Modifier") {
  @Previewable @State var step = 1

  VStack(spacing: 32) {
    Text("Step \(step) of 3")
      .font(.headline)
      .ironMorphingText(isNumeric: true)

    Button("Next Step") {
      withAnimation(.smooth) {
        step = step < 3 ? step + 1 : 1
      }
    }
    .buttonStyle(.borderedProminent)
  }
  .padding()
}
