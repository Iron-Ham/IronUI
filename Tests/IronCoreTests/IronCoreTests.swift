import Testing
@testable import IronCore

@Suite("IronCore")
struct IronCoreTests {
  @Test("version is defined")
  func versionIsDefined() {
    #expect(!IronCore.version.isEmpty)
  }
}
