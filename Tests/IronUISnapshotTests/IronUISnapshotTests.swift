import Testing
@testable import IronUI

// MARK: - IronUI Snapshot Tests

/// IronUI is an umbrella module that re-exports all sub-modules.
/// Snapshot tests for components live in their respective module test directories:
/// - Primitives: `Primitives/`
/// - Components: `Components/`
/// - DataDisplay: `DataDisplay/`
/// - Layouts: `Layouts/`
///
/// This file is intentionally kept as a stub.

@Suite("IronUI Module")
struct IronUIModuleTests {

  @Test("IronUI re-exports all sub-modules")
  func umbrellaModuleExports() {
    // IronUI is an umbrella module - actual tests are in sub-module test directories
    #expect(true)
  }

}
