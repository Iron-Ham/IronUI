import ProjectDescription

extension Target {
  /// Creates an IronUI library target for iOS and macOS
  public static func ironUILibrary(
    name: String,
    dependencies: [TargetDependency] = [],
    resources: ResourceFileElements? = nil,
  ) -> Target {
    .target(
      name: name,
      destinations: [.iPhone, .iPad, .mac],
      product: .framework,
      bundleId: "dev.ironui.\(name.lowercased())",
      deploymentTargets: .multiplatform(iOS: "26.0", macOS: "26.0"),
      sources: ["Sources/\(name)/**/*.swift"],
      resources: resources,
      dependencies: dependencies,
      settings: .ironUISettings(),
    )
  }

  /// Creates an IronUI unit test target
  public static func ironUITests(
    name: String,
    dependencies: [TargetDependency],
  ) -> Target {
    .target(
      name: name,
      destinations: [.iPhone, .iPad, .mac],
      product: .unitTests,
      bundleId: "dev.ironui.\(name.lowercased())",
      deploymentTargets: .multiplatform(iOS: "26.0", macOS: "26.0"),
      sources: ["Tests/\(name)/**/*.swift"],
      dependencies: dependencies,
      settings: .ironUISettings(),
    )
  }

  /// Creates a macOS-only executable target (for CLI)
  public static func ironUICLI(
    name: String,
    dependencies: [TargetDependency],
  ) -> Target {
    .target(
      name: name,
      destinations: .macOS,
      product: .commandLineTool,
      bundleId: "dev.ironui.cli",
      deploymentTargets: .macOS("26.0"),
      sources: ["Sources/\(name)/**/*.swift"],
      dependencies: dependencies,
      settings: .ironUISettings(
        base: [
          "IRONUI_CLI_ENABLED": "1"
        ]
      ),
    )
  }
}
