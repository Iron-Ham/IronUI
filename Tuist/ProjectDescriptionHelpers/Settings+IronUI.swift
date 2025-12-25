import ProjectDescription

extension Settings {
  /// Standard IronUI settings with warnings-as-errors enabled
  public static func ironUISettings(
    base: SettingsDictionary = [:],
    debug: SettingsDictionary = [:],
    release: SettingsDictionary = [:],
  ) -> Settings {
    let warningsAsErrors: SettingsDictionary = [
      "SWIFT_TREAT_WARNINGS_AS_ERRORS": "YES",
      "GCC_TREAT_WARNINGS_AS_ERRORS": "YES",
      "SWIFT_STRICT_CONCURRENCY": "complete",
      "SWIFT_VERSION": "6.0",
    ]

    let combined = warningsAsErrors.merging(base) { _, new in new }

    return .settings(
      base: combined,
      configurations: [
        .debug(
          name: .debug,
          settings: debug,
          xcconfig: nil,
        ),
        .release(
          name: .release,
          settings: release.merging([
            "SWIFT_OPTIMIZATION_LEVEL": "-O"
          ]) { _, new in new },
          xcconfig: nil,
        ),
      ],
    )
  }
}
