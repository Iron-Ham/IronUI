import SwiftUI

extension EnvironmentValues {
  /// When `true`, IronUI components skip entrance animations and render in their final state.
  ///
  /// This is useful for:
  /// - Snapshot testing where animations would cause inconsistent results
  /// - Accessibility when `reduceMotion` is preferred
  /// - Debug/preview scenarios
  ///
  /// ## Usage
  ///
  /// ```swift
  /// // In snapshot tests:
  /// view.environment(\.ironSkipEntranceAnimations, true)
  /// ```
  @Entry public var ironSkipEntranceAnimations = false
}
