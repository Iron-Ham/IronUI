import ProjectDescription
import ProjectDescriptionHelpers

let project = Project(
  name: "IronUIDemo",
  organizationName: "IronUI",
  settings: .ironUISettings(),
  targets: [
    .target(
      name: "IronUIDemo",
      destinations: [.iPhone, .iPad, .mac],
      product: .app,
      bundleId: "dev.ironui.demo",
      deploymentTargets: .multiplatform(iOS: "26.0", macOS: "26.0"),
      infoPlist: .extendingDefault(with: [
        "UILaunchScreen": [:],
        "CFBundleDisplayName": "IronUI Demo",
      ]),
      sources: ["Sources/**/*.swift"],
      resources: ["Resources/**"],
      dependencies: [
        .project(target: "IronUI", path: "../..")
      ],
    )
  ],
  schemes: [
    .scheme(
      name: "IronUIDemo",
      shared: true,
      buildAction: .buildAction(targets: [.target("IronUIDemo")]),
      runAction: .runAction(configuration: .debug),
    )
  ],
)
