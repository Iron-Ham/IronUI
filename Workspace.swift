import ProjectDescription

let workspace = Workspace(
  name: "IronUI",
  projects: [
    ".",
    "Apps/PreviewGallery",
    "Apps/IronUIDemo",
    "Apps/Housekeepr",
  ],
  schemes: [
    .scheme(
      name: "IronUI-CI",
      shared: true,
      buildAction: .buildAction(targets: [
        .project(path: ".", target: "IronUI"),
        .project(path: "Apps/PreviewGallery", target: "PreviewGallery"),
      ]),
      testAction: .targets([
        .testableTarget(target: .project(path: ".", target: "IronCoreTests")),
        .testableTarget(target: .project(path: ".", target: "IronPrimitivesTests")),
        .testableTarget(target: .project(path: ".", target: "IronComponentsTests")),
        .testableTarget(target: .project(path: ".", target: "IronUISnapshotTests")),
        .testableTarget(target: .project(path: ".", target: "IronUIIntegrationTests")),
      ]),
    )
  ],
  additionalFiles: [
    "README.md",
    "CHANGELOG.md",
    "CONTRIBUTING.md",
    "AGENTS.md",
  ],
)
