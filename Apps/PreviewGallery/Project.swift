import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "PreviewGallery",
  organizationName: "IronUI",
  settings: .ironUISettings(),
  targets: [
    .target(
      name: "PreviewGalleryApp",
      destinations: [.iPhone, .iPad, .mac],
      product: .app,
      bundleId: "dev.ironui.previewgallery",
      deploymentTargets: .multiplatform(iOS: "26.0", macOS: "26.0"),
      infoPlist: .extendingDefault(with: [
        "UILaunchScreen": [:]
      ]),
      sources: ["Sources/**/*.swift"],
      resources: ["Resources/**"],
      dependencies: [
        .project(target: "IronUI", path: "../.."),
        .project(target: "IronCore", path: "../.."),
        .project(target: "IronPrimitives", path: "../.."),
        .project(target: "IronComponents", path: "../.."),
        .project(target: "IronLayouts", path: "../.."),
        .project(target: "IronNavigation", path: "../.."),
        .project(target: "IronForms", path: "../.."),
        .project(target: "IronDataDisplay", path: "../.."),
        .external(name: "PreviewGallery"),
      ],
    ),
    .target(
      name: "PreviewGalleryTests",
      destinations: [.iPhone, .iPad, .mac],
      product: .unitTests,
      bundleId: "dev.ironui.previewgallery.tests",
      deploymentTargets: .multiplatform(iOS: "26.0", macOS: "26.0"),
      sources: ["Tests/**/*.swift"],
      dependencies: [
        .target(name: "PreviewGalleryApp"),
        .external(name: "SnapshotTesting"),
      ],
    ),
  ],
  schemes: [
    .scheme(
      name: "PreviewGallery",
      shared: true,
      buildAction: .buildAction(targets: [.target("PreviewGalleryApp")]),
      testAction: .targets([
        .testableTarget(target: .target("PreviewGalleryTests"))
      ]),
      runAction: .runAction(configuration: .debug),
    ),
    .scheme(
      name: "PreviewGallery-RecordSnapshots",
      shared: true,
      buildAction: .buildAction(targets: [.target("PreviewGalleryApp")]),
      testAction: .targets(
        [.testableTarget(target: .target("PreviewGalleryTests"))],
        arguments: .arguments(
          environmentVariables: ["IRONUI_RECORD_SNAPSHOTS": "1"]
        ),
      ),
    ),
  ],
)
