import Testing
@testable import IronPrimitives

@Suite("IronPrimitives")
struct IronPrimitivesTests {
  @Test("version is defined")
  func versionIsDefined() {
    #expect(!IronPrimitives.version.isEmpty)
  }
}
