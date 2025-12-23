// swift-tools-version: 6.2

import PackageDescription

let package = Package(
  name: "IronUI",
  platforms: [
    .iOS(.v26),
    .macOS(.v26),
  ],
  products: [
    // MARK: - Full Library (Umbrella)
    .library(
      name: "IronUI",
      targets: ["IronUI"],
    ),
    // MARK: - Individual Modules
    .library(
      name: "IronCore",
      targets: ["IronCore"],
    ),
    .library(
      name: "IronPrimitives",
      targets: ["IronPrimitives"],
    ),
    .library(
      name: "IronComponents",
      targets: ["IronComponents"],
    ),
    .library(
      name: "IronLayouts",
      targets: ["IronLayouts"],
    ),
    .library(
      name: "IronNavigation",
      targets: ["IronNavigation"],
    ),
    .library(
      name: "IronForms",
      targets: ["IronForms"],
    ),
    .library(
      name: "IronDataDisplay",
      targets: ["IronDataDisplay"],
    ),
    .library(
      name: "IronKitBridge",
      targets: ["IronKitBridge"],
    ),
  ],
  dependencies: [
    // Documentation
    .package(
      url: "https://github.com/swiftlang/swift-docc-plugin",
      from: "1.4.0",
    ),
    // Code Formatting (Airbnb Style Guide)
    .package(
      url: "https://github.com/airbnb/swift",
      from: "1.2.0",
    ),
    // Snapshot Testing (test-only)
    .package(
      url: "https://github.com/pointfreeco/swift-snapshot-testing",
      from: "1.18.0",
    ),
  ],
  targets: [
    // MARK: - Core Module (No internal dependencies)
    .target(
      name: "IronCore",
      dependencies: [],
      path: "Sources/IronCore",
    ),
    .testTarget(
      name: "IronCoreTests",
      dependencies: ["IronCore"],
      path: "Tests/IronCoreTests",
    ),

    // MARK: - Primitives Module
    .target(
      name: "IronPrimitives",
      dependencies: ["IronCore"],
      path: "Sources/IronPrimitives",
    ),
    .testTarget(
      name: "IronPrimitivesTests",
      dependencies: ["IronPrimitives"],
      path: "Tests/IronPrimitivesTests",
    ),

    // MARK: - Layouts Module
    .target(
      name: "IronLayouts",
      dependencies: ["IronCore"],
      path: "Sources/IronLayouts",
    ),

    // MARK: - Components Module
    .target(
      name: "IronComponents",
      dependencies: ["IronCore", "IronPrimitives", "IronLayouts"],
      path: "Sources/IronComponents",
      resources: [
        .process("Resources")
      ],
    ),
    .testTarget(
      name: "IronComponentsTests",
      dependencies: ["IronComponents"],
      path: "Tests/IronComponentsTests",
    ),

    // MARK: - Navigation Module
    .target(
      name: "IronNavigation",
      dependencies: ["IronCore", "IronPrimitives", "IronComponents"],
      path: "Sources/IronNavigation",
    ),

    // MARK: - Forms Module
    .target(
      name: "IronForms",
      dependencies: ["IronCore", "IronPrimitives", "IronComponents"],
      path: "Sources/IronForms",
    ),

    // MARK: - Data Display Module
    .target(
      name: "IronDataDisplay",
      dependencies: ["IronCore", "IronPrimitives", "IronComponents"],
      path: "Sources/IronDataDisplay",
    ),

    // MARK: - Kit Bridge Module
    .target(
      name: "IronKitBridge",
      dependencies: ["IronCore"],
      path: "Sources/IronKitBridge",
    ),

    // MARK: - Umbrella Module
    .target(
      name: "IronUI",
      dependencies: [
        "IronCore",
        "IronPrimitives",
        "IronLayouts",
        "IronComponents",
        "IronNavigation",
        "IronForms",
        "IronDataDisplay",
        "IronKitBridge",
      ],
      path: "Sources/IronUI",
    ),

    // MARK: - Snapshot Tests (XCTest-based)
    .testTarget(
      name: "IronUISnapshotTests",
      dependencies: [
        "IronUI",
        .product(name: "SnapshotTesting", package: "swift-snapshot-testing"),
      ],
      path: "Tests/IronUISnapshotTests",
    ),

    // MARK: - Integration Tests
    .testTarget(
      name: "IronUIIntegrationTests",
      dependencies: ["IronUI"],
      path: "Tests/IronUIIntegrationTests",
    ),
  ],
  swiftLanguageModes: [.v6],
)
