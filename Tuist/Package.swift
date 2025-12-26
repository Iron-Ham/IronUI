// swift-tools-version: 6.2
import PackageDescription

#if TUIST
import ProjectDescription
import ProjectDescriptionHelpers

let packageSettings = PackageSettings(
  productTypes: [
    "SnapshotTesting": .staticFramework,
    "ArgumentParser": .staticFramework,
    "Noora": .staticFramework,
  ],
  baseSettings: .settings(
    configurations: [
      .debug(name: .debug),
      .release(name: .release),
    ]
  ),
)
#endif

let package = Package(
  name: "IronUIDependencies",
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
    // CLI
    .package(
      url: "https://github.com/apple/swift-argument-parser",
      from: "1.7.0",
    ),
    // Styled console output
    .package(
      url: "https://github.com/tuist/Noora",
      branch: "main",
    ),
    // Preview Gallery (for PreviewGallery app)
    .package(
      url: "https://github.com/EmergeTools/SnapshotPreviews",
      from: "0.11.0",
    ),
  ],
)
