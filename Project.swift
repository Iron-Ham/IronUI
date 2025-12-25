import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "IronUI",
  organizationName: "IronUI",
  settings: .ironUISettings(),
  targets: [
    // MARK: - Core Module (No internal dependencies)
    .ironUILibrary(
      name: "IronCore",
      dependencies: [],
    ),
    .ironUITests(
      name: "IronCoreTests",
      dependencies: [.target(name: "IronCore")],
    ),

    // MARK: - Primitives Module
    .ironUILibrary(
      name: "IronPrimitives",
      dependencies: [.target(name: "IronCore")],
    ),
    .ironUITests(
      name: "IronPrimitivesTests",
      dependencies: [.target(name: "IronPrimitives")],
    ),

    // MARK: - Layouts Module
    .ironUILibrary(
      name: "IronLayouts",
      dependencies: [.target(name: "IronCore")],
    ),

    // MARK: - Components Module (with resources)
    .ironUILibrary(
      name: "IronComponents",
      dependencies: [
        .target(name: "IronCore"),
        .target(name: "IronPrimitives"),
        .target(name: "IronLayouts"),
      ],
      resources: .resources(["Sources/IronComponents/Resources/**"]),
    ),
    .ironUITests(
      name: "IronComponentsTests",
      dependencies: [.target(name: "IronComponents")],
    ),

    // MARK: - Navigation Module
    .ironUILibrary(
      name: "IronNavigation",
      dependencies: [
        .target(name: "IronCore"),
        .target(name: "IronPrimitives"),
        .target(name: "IronComponents"),
      ],
    ),

    // MARK: - Forms Module
    .ironUILibrary(
      name: "IronForms",
      dependencies: [
        .target(name: "IronCore"),
        .target(name: "IronPrimitives"),
        .target(name: "IronComponents"),
      ],
    ),

    // MARK: - Data Display Module
    .ironUILibrary(
      name: "IronDataDisplay",
      dependencies: [
        .target(name: "IronCore"),
        .target(name: "IronPrimitives"),
        .target(name: "IronComponents"),
      ],
    ),

    // MARK: - Umbrella Module
    .ironUILibrary(
      name: "IronUI",
      dependencies: [
        .target(name: "IronCore"),
        .target(name: "IronPrimitives"),
        .target(name: "IronLayouts"),
        .target(name: "IronComponents"),
        .target(name: "IronNavigation"),
        .target(name: "IronForms"),
        .target(name: "IronDataDisplay"),
      ],
    ),

    // MARK: - Snapshot Tests (cross-platform)
    .ironUITests(
      name: "IronUISnapshotTests",
      dependencies: [
        .target(name: "IronUI"),
        .external(name: "SnapshotTesting"),
      ],
    ),

    // MARK: - Integration Tests
    .ironUITests(
      name: "IronUIIntegrationTests",
      dependencies: [.target(name: "IronUI")],
    ),

    // MARK: - CLI (macOS only)
    .ironUICLI(
      name: "IronUICLI",
      dependencies: [
        .target(name: "IronUI"),
        .external(name: "ArgumentParser"),
        .external(name: "Noora"),
      ],
    ),
  ],
  schemes: [
    .scheme(
      name: "IronUI-AllTests",
      shared: true,
      buildAction: .buildAction(targets: [
        .target("IronUI")
      ]),
      testAction: .targets([
        .testableTarget(target: .target("IronCoreTests")),
        .testableTarget(target: .target("IronPrimitivesTests")),
        .testableTarget(target: .target("IronComponentsTests")),
        .testableTarget(target: .target("IronUISnapshotTests")),
        .testableTarget(target: .target("IronUIIntegrationTests")),
      ]),
    )
  ],
)
