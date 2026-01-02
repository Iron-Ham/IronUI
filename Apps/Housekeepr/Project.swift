import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "Housekeepr",
  organizationName: "IronUI",
  settings: .ironUISettings(),
  targets: [
    .target(
      name: "Housekeepr",
      destinations: [.iPhone, .iPad, .mac],
      product: .app,
      bundleId: "dev.ironui.housekeepr",
      deploymentTargets: .multiplatform(iOS: "26.0", macOS: "26.0"),
      infoPlist: .extendingDefault(with: [
        "UILaunchScreen": [:],
        "CFBundleDisplayName": "Housekeepr",
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
        .external(name: "SQLiteData"),
      ],
    )
  ],
)
