import Testing
@testable import IronUI

@Suite("IronUI Integration")
struct IronUIIntegrationTests {
  @Test("umbrella module exposes all submodules")
  func umbrellaModuleWorks() {
    #expect(!IronUI.version.isEmpty)
    #expect(!IronCore.version.isEmpty)
    #expect(!IronPrimitives.version.isEmpty)
    #expect(!IronComponents.version.isEmpty)
    #expect(!IronLayouts.version.isEmpty)
    #expect(!IronNavigation.version.isEmpty)
    #expect(!IronForms.version.isEmpty)
    #expect(!IronDataDisplay.version.isEmpty)
    #expect(!IronKitBridge.version.isEmpty)
  }
}
