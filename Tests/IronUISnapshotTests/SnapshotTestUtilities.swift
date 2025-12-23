import SnapshotTesting
import SwiftUI
import Testing

#if canImport(UIKit)
import UIKit
#endif

#if canImport(AppKit)
import AppKit
#endif

// MARK: - SnapshotDevice

/// Device configurations for snapshot testing across iPhone, iPad, and macOS.
enum SnapshotDevice: String, CaseIterable, Sendable {
  /// iPhone 17 Pro (402x874 @3x)
  case iPhone17Pro

  /// iPhone 17 Pro Max (440x956 @3x)
  case iPhone17ProMax

  /// iPad Pro 11" (834x1194 @2x)
  case iPadPro11

  /// iPad Pro 13" (1032x1376 @2x)
  case iPadPro13

  /// macOS standard window (800x600)
  case macOSStandard

  /// macOS large window (1200x900)
  case macOSLarge

  // MARK: Internal

  /// Commonly used devices for component testing (one of each class).
  static var common: [SnapshotDevice] {
    [.iPhone17Pro, .iPadPro11, .macOSStandard]
  }

  /// All iOS devices.
  static var iOSDevices: [SnapshotDevice] {
    [.iPhone17Pro, .iPhone17ProMax, .iPadPro11, .iPadPro13]
  }

  /// The display name for this device.
  var displayName: String {
    switch self {
    case .iPhone17Pro: "iPhone 17 Pro"
    case .iPhone17ProMax: "iPhone 17 Pro Max"
    case .iPadPro11: "iPad Pro 11\""
    case .iPadPro13: "iPad Pro 13\""
    case .macOSStandard: "macOS Standard"
    case .macOSLarge: "macOS Large"
    }
  }

  /// The screen size for this device.
  var size: CGSize {
    switch self {
    case .iPhone17Pro: CGSize(width: 402, height: 874)
    case .iPhone17ProMax: CGSize(width: 440, height: 956)
    case .iPadPro11: CGSize(width: 834, height: 1194)
    case .iPadPro13: CGSize(width: 1032, height: 1376)
    case .macOSStandard: CGSize(width: 800, height: 600)
    case .macOSLarge: CGSize(width: 1200, height: 900)
    }
  }

  /// The scale factor for this device.
  var scale: CGFloat {
    switch self {
    case .iPhone17Pro, .iPhone17ProMax: 3.0
    case .iPadPro11, .iPadPro13, .macOSStandard, .macOSLarge: 2.0
    }
  }

  /// Whether this device is iOS-based.
  var isiOS: Bool {
    switch self {
    case .iPhone17Pro, .iPhone17ProMax, .iPadPro11, .iPadPro13: true
    case .macOSStandard, .macOSLarge: false
    }
  }

  /// Whether this device is an iPhone.
  var isiPhone: Bool {
    switch self {
    case .iPhone17Pro, .iPhone17ProMax: true
    default: false
    }
  }

  /// Whether this device is an iPad.
  var isiPad: Bool {
    switch self {
    case .iPadPro11, .iPadPro13: true
    default: false
    }
  }

  /// Whether this device is macOS.
  var isMacOS: Bool {
    switch self {
    case .macOSStandard, .macOSLarge: true
    default: false
    }
  }

}

// MARK: - SnapshotDynamicType

/// Dynamic Type sizes for accessibility testing.
enum SnapshotDynamicType: String, CaseIterable, Sendable {
  /// Extra small text (.xSmall)
  case extraSmall

  /// Standard/default text size (.large)
  case standard

  /// Extra large text (.xxxLarge)
  case extraLarge

  /// Accessibility extra extra extra large (.accessibilityExtraExtraExtraLarge)
  case accessibility

  // MARK: Internal

  /// Commonly used dynamic type sizes (standard + accessibility extremes).
  static var common: [SnapshotDynamicType] {
    [.standard, .accessibility]
  }

  /// The display name for this dynamic type size.
  var displayName: String {
    switch self {
    case .extraSmall: "XS"
    case .standard: "Default"
    case .extraLarge: "XL"
    case .accessibility: "A11y"
    }
  }

  #if os(iOS)
  /// The UIContentSizeCategory for this dynamic type.
  var contentSizeCategory: UIContentSizeCategory {
    switch self {
    case .extraSmall: .extraSmall
    case .standard: .large
    case .extraLarge: .extraExtraExtraLarge
    case .accessibility: .accessibilityExtraExtraExtraLarge
    }
  }
  #endif

  /// The SwiftUI DynamicTypeSize for this dynamic type.
  var dynamicTypeSize: DynamicTypeSize {
    switch self {
    case .extraSmall: .xSmall
    case .standard: .large
    case .extraLarge: .xxxLarge
    case .accessibility: .accessibility5
    }
  }

}

// MARK: - SnapshotColorScheme

/// Color scheme variants for snapshot testing.
enum SnapshotColorScheme: String, CaseIterable, Sendable {
  case light
  case dark

  // MARK: Internal

  /// The SwiftUI ColorScheme value.
  var colorScheme: ColorScheme {
    switch self {
    case .light: .light
    case .dark: .dark
    }
  }

  /// The display name suffix for file naming.
  var suffix: String {
    rawValue
  }
}

// MARK: - SnapshotConfiguration

/// A complete configuration for a snapshot test.
struct SnapshotConfiguration: Sendable {

  // MARK: Lifecycle

  /// Creates a configuration for the current platform.
  ///
  /// - Parameters:
  ///   - device: The device to render on.
  ///   - dynamicType: The dynamic type size.
  ///   - colorScheme: The color scheme.
  init(
    device: SnapshotDevice,
    dynamicType: SnapshotDynamicType = .standard,
    colorScheme: SnapshotColorScheme = .light,
  ) {
    self.device = device
    self.dynamicType = dynamicType
    self.colorScheme = colorScheme
  }

  // MARK: Internal

  /// Creates all common configurations (iPhone, iPad, macOS x light/dark x standard/a11y).
  static var all: [SnapshotConfiguration] {
    var configs = [SnapshotConfiguration]()
    for device in SnapshotDevice.common {
      for dynamicType in SnapshotDynamicType.common {
        for colorScheme in SnapshotColorScheme.allCases {
          configs.append(SnapshotConfiguration(
            device: device,
            dynamicType: dynamicType,
            colorScheme: colorScheme,
          ))
        }
      }
    }
    return configs
  }

  /// Creates quick configurations for testing (iPhone and macOS light/dark).
  /// Includes both iOS and macOS configurations - only the platform-appropriate
  /// ones will actually run assertions.
  static var quick: [SnapshotConfiguration] {
    [
      // iOS configurations (run when testing on iOS)
      SnapshotConfiguration(device: .iPhone17Pro, colorScheme: .light),
      SnapshotConfiguration(device: .iPhone17Pro, colorScheme: .dark),
      // macOS configurations (run when testing on macOS)
      SnapshotConfiguration(device: .macOSStandard, colorScheme: .light),
      SnapshotConfiguration(device: .macOSStandard, colorScheme: .dark),
    ]
  }

  /// Creates configurations for light mode only across common devices.
  static var lightOnly: [SnapshotConfiguration] {
    SnapshotDevice.common.map { device in
      SnapshotConfiguration(device: device, colorScheme: .light)
    }
  }

  /// The device to render on.
  let device: SnapshotDevice

  /// The dynamic type size.
  let dynamicType: SnapshotDynamicType

  /// The color scheme (light/dark).
  let colorScheme: SnapshotColorScheme

  /// The name for this configuration (used in snapshot file names).
  var name: String {
    "\(device.rawValue)-\(dynamicType.rawValue)-\(colorScheme.suffix)"
  }

  /// The size for this configuration's viewport.
  var size: CGSize {
    device.size
  }

  /// Creates configurations for a single device with all color schemes and dynamic types.
  static func forDevice(_ device: SnapshotDevice) -> [SnapshotConfiguration] {
    var configs = [SnapshotConfiguration]()
    for dynamicType in SnapshotDynamicType.common {
      for colorScheme in SnapshotColorScheme.allCases {
        configs.append(SnapshotConfiguration(
          device: device,
          dynamicType: dynamicType,
          colorScheme: colorScheme,
        ))
      }
    }
    return configs
  }

}

// MARK: - Snapshot Helpers

/// Returns the appropriate background color for the given color scheme.
private func systemBackground(for colorScheme: SnapshotColorScheme) -> Color {
  colorScheme == .light ? Color.white : Color.black
}

/// Asserts auto-sizing snapshots for a view across multiple configurations.
///
/// The view will be sized to its intrinsic content size, respecting Dynamic Type.
/// Use this for most component snapshots to capture their natural layout.
///
/// - Parameters:
///   - view: The view to snapshot.
///   - configurations: The configurations to test.
///   - record: Whether to record new reference images.
///   - file: The file where the assertion is made.
///   - testName: The name of the test function.
///   - line: The line where the assertion is made.
/// Set to true to record new reference snapshots, false to verify against existing ones.
/// Change this to `true` when you need to update or create new reference images.
private let isRecordingSnapshots = false

@MainActor
func ironAssertSnapshots(
  of view: some View,
  configurations: [SnapshotConfiguration] = SnapshotConfiguration.quick,
  record: Bool = isRecordingSnapshots,
  file: StaticString = #filePath,
  testName: String = #function,
  line: UInt = #line,
) {
  for configuration in configurations {
    let configured = view
      .environment(\.dynamicTypeSize, configuration.dynamicType.dynamicTypeSize)
      .environment(\.colorScheme, configuration.colorScheme.colorScheme)
      .fixedSize()
      .padding(1) // Minimal padding to ensure content isn't clipped
      .background(systemBackground(for: configuration.colorScheme))

    #if os(iOS)
    if configuration.device.isiOS {
      assertSnapshot(
        of: configured,
        as: .image(
          precision: 0.99,
          perceptualPrecision: 0.98,
          traits: UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceStyle: configuration.colorScheme == .light ? .light : .dark),
            UITraitCollection(preferredContentSizeCategory: configuration.dynamicType.contentSizeCategory),
          ]),
        ),
        named: configuration.name,
        record: record,
        file: file,
        testName: testName,
        line: line,
      )
    }
    #endif

    #if os(macOS)
    if configuration.device.isMacOS {
      let hostingController = NSHostingController(rootView: AnyView(configured))

      // Let the view size itself to its intrinsic content size
      hostingController.view.layoutSubtreeIfNeeded()
      let fittingSize = hostingController.view.fittingSize
      hostingController.view.frame = CGRect(origin: .zero, size: fittingSize)

      let snapshotting = Snapshotting<NSView, NSImage>.image(
        precision: 0.99,
        perceptualPrecision: 0.98,
        size: fittingSize,
      )
      assertSnapshot(
        of: hostingController.view,
        as: snapshotting,
        named: configuration.name,
        record: record,
        file: file,
        testName: testName,
        line: line,
      )
    }
    #endif
  }
}

/// Asserts snapshots for a view with a fixed width but auto-sizing height.
///
/// Use this for components that need a constrained width (like text fields, full-width buttons)
/// but should size vertically based on content.
///
/// - Parameters:
///   - view: The view to snapshot.
///   - configurations: The configurations to test.
///   - width: The fixed width for the view.
///   - record: Whether to record new reference images.
///   - file: The file where the assertion is made.
///   - testName: The name of the test function.
///   - line: The line where the assertion is made.
@MainActor
func ironAssertSnapshots(
  of view: some View,
  configurations: [SnapshotConfiguration] = SnapshotConfiguration.quick,
  width: CGFloat,
  record: Bool = isRecordingSnapshots,
  file: StaticString = #filePath,
  testName: String = #function,
  line: UInt = #line,
) {
  for configuration in configurations {
    let configured = view
      .environment(\.dynamicTypeSize, configuration.dynamicType.dynamicTypeSize)
      .environment(\.colorScheme, configuration.colorScheme.colorScheme)
      .frame(width: width)
      .fixedSize(horizontal: false, vertical: true)
      .padding(1)
      .background(systemBackground(for: configuration.colorScheme))

    #if os(iOS)
    if configuration.device.isiOS {
      assertSnapshot(
        of: configured,
        as: .image(
          precision: 0.99,
          perceptualPrecision: 0.98,
          traits: UITraitCollection(traitsFrom: [
            UITraitCollection(userInterfaceStyle: configuration.colorScheme == .light ? .light : .dark),
            UITraitCollection(preferredContentSizeCategory: configuration.dynamicType.contentSizeCategory),
          ]),
        ),
        named: configuration.name,
        record: record,
        file: file,
        testName: testName,
        line: line,
      )
    }
    #endif

    #if os(macOS)
    if configuration.device.isMacOS {
      let hostingController = NSHostingController(rootView: AnyView(configured))

      hostingController.view.layoutSubtreeIfNeeded()
      let fittingSize = hostingController.view.fittingSize
      hostingController.view.frame = CGRect(origin: .zero, size: fittingSize)

      let snapshotting = Snapshotting<NSView, NSImage>.image(
        precision: 0.99,
        perceptualPrecision: 0.98,
        size: fittingSize,
      )
      assertSnapshot(
        of: hostingController.view,
        as: snapshotting,
        named: configuration.name,
        record: record,
        file: file,
        testName: testName,
        line: line,
      )
    }
    #endif
  }
}

/// Asserts an auto-sizing snapshot for a single view with a specific name.
///
/// - Parameters:
///   - view: The view to snapshot.
///   - name: The snapshot name.
///   - colorScheme: The color scheme.
///   - dynamicTypeSize: The dynamic type size.
///   - record: Whether to record new reference images.
///   - file: The file where the assertion is made.
///   - testName: The name of the test function.
///   - line: The line where the assertion is made.
@MainActor
func ironAssertSnapshot(
  of view: some View,
  named name: String,
  colorScheme: ColorScheme = .light,
  dynamicTypeSize: DynamicTypeSize = .large,
  record: Bool = isRecordingSnapshots,
  file: StaticString = #filePath,
  testName: String = #function,
  line: UInt = #line,
) {
  let backgroundColor: Color = colorScheme == .light ? .white : .black
  let wrapped = view
    .environment(\.colorScheme, colorScheme)
    .environment(\.dynamicTypeSize, dynamicTypeSize)
    .fixedSize()
    .padding(1)
    .background(backgroundColor)

  #if os(iOS)
  assertSnapshot(
    of: wrapped,
    as: .image(
      precision: 0.99,
      perceptualPrecision: 0.98,
      traits: UITraitCollection(userInterfaceStyle: colorScheme == .light ? .light : .dark),
    ),
    named: name,
    record: record,
    file: file,
    testName: testName,
    line: line,
  )
  #endif

  #if os(macOS)
  let hostingController = NSHostingController(rootView: AnyView(wrapped))
  hostingController.view.layoutSubtreeIfNeeded()
  let fittingSize = hostingController.view.fittingSize
  hostingController.view.frame = CGRect(origin: .zero, size: fittingSize)

  let snapshotting = Snapshotting<NSView, NSImage>.image(
    precision: 0.99,
    perceptualPrecision: 0.98,
    size: fittingSize,
  )
  assertSnapshot(
    of: hostingController.view,
    as: snapshotting,
    named: name,
    record: record,
    file: file,
    testName: testName,
    line: line,
  )
  #endif
}
