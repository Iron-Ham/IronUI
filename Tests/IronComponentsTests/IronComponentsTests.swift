import Testing
@testable import IronComponents

@Suite("IronComponents")
struct IronComponentsTests {
  @Test("version is defined")
  func versionIsDefined() {
    #expect(!IronComponents.version.isEmpty)
  }
}
