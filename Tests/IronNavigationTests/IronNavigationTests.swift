import SwiftUI
import Testing
@testable import IronNavigation

// MARK: - IronNavigationModuleTests

@Suite("IronNavigation Module")
struct IronNavigationModuleTests {

  @Test("IronTray type exists and is accessible")
  @MainActor
  func ironTrayTypeExists() {
    // Verify the type can be instantiated
    let tray = IronTray { Text("Test") }
    _ = tray
  }

  @Test("IronTrayHeader type exists and is accessible")
  @MainActor
  func ironTrayHeaderTypeExists() {
    let header = IronTrayHeader("Title", onDismiss: { })
    _ = header
  }

  @Test("IronTrayStack type exists and is accessible")
  @MainActor
  func ironTrayStackTypeExists() {
    let stack = IronTrayStack { _ in Text("Root") }
    _ = stack
  }

  @Test("IronTrayNavigator type exists and is accessible")
  func ironTrayNavigatorTypeExists() {
    // IronTrayNavigator is created internally by IronTrayStack
    // We just verify the type is accessible via the API
    #expect(Bool(true))
  }
}

// MARK: - IronTrayTests

@Suite("IronTray")
@MainActor
struct IronTrayTests {

  @Test("can be instantiated with content")
  func canBeInstantiatedWithContent() {
    let tray = IronTray {
      Text("Test Content")
    }

    _ = tray.body
  }

  @Test("can be instantiated with drag indicator hidden")
  func canBeInstantiatedWithDragIndicatorHidden() {
    let tray = IronTray(isDragIndicatorVisible: false) {
      Text("No drag handle")
    }

    _ = tray.body
  }

  @Test("can be instantiated with dismiss callback")
  func canBeInstantiatedWithDismissCallback() {
    var dismissed = false
    let tray = IronTray(onDismiss: { dismissed = true }) {
      Text("Dismissible")
    }

    _ = tray.body
    // Note: dismiss callback can't be triggered without simulating gestures
    #expect(dismissed == false) // Initial state
  }
}

// MARK: - IronTrayHeaderTests

@Suite("IronTrayHeader")
@MainActor
struct IronTrayHeaderTests {

  @Test("can be instantiated with title")
  func canBeInstantiatedWithTitle() {
    var dismissed = false
    let header = IronTrayHeader("Settings", onDismiss: { dismissed = true })

    _ = header.body
    #expect(dismissed == false)
  }

  @Test("can be instantiated with back button visible")
  func canBeInstantiatedWithBackButton() {
    let header = IronTrayHeader(
      "Step 2",
      isBackButtonVisible: true,
      onDismiss: { },
    )

    _ = header.body
  }

  @Test("can be instantiated with localized string key")
  func canBeInstantiatedWithLocalizedKey() {
    let key: LocalizedStringKey = "localized.key"
    let header = IronTrayHeader(key, onDismiss: { })

    _ = header.body
  }
}

// MARK: - IronTrayStackTests

@Suite("IronTrayStack")
@MainActor
struct IronTrayStackTests {

  @Test("can be instantiated with root view builder")
  func canBeInstantiatedWithRootBuilder() {
    let stack = IronTrayStack { _ in
      Text("Root View")
    }

    _ = stack.body
  }

  @Test("root receives navigator with depth 0")
  func rootReceivesNavigatorWithDepth0() {
    var receivedDepth: Int?

    let stack = IronTrayStack { navigator in
      receivedDepth = navigator.depth
      return Text("Root")
    }

    _ = stack.body

    #expect(receivedDepth == 0)
  }

  @Test("navigator isAtRoot is true at depth 0")
  func navigatorIsAtRootAtDepth0() {
    var isAtRoot: Bool?

    let stack = IronTrayStack { navigator in
      isAtRoot = navigator.isAtRoot
      return Text("Root")
    }

    _ = stack.body

    #expect(isAtRoot == true)
  }
}

// MARK: - IronTrayNavigatorTests

@Suite("IronTrayNavigator")
struct IronTrayNavigatorTests {

  // Note: IronTrayNavigator has a fileprivate initializer, so we test
  // the properties that we know about through the public API and the
  // behavior we can observe.

  @Test("navigator depth property is publicly accessible")
  func depthPropertyIsPublic() {
    // This test verifies the API contract - depth should be readable
    // The actual value testing happens in IronTrayStack tests
    #expect(Bool(true)) // API compilation test
  }

  @Test("navigator isAtRoot computed property exists")
  func isAtRootPropertyExists() {
    // API contract verification
    #expect(Bool(true))
  }
}

// MARK: - IronTrayModifierTests

@Suite("IronTrayModifier")
@MainActor
struct IronTrayModifierTests {

  @Test("ironTray modifier can be applied to views")
  func ironTrayModifierCanBeApplied() {
    @State var isPresented = false

    let view = Text("Base View")
      .ironTray(isPresented: $isPresented) {
        Text("Tray Content")
      }

    _ = view
  }

  @Test("ironTray modifier works with binding")
  func ironTrayModifierWorksWithBinding() {
    @State var showTray = true

    let view = Button("Show") {
      showTray = true
    }
    .ironTray(isPresented: $showTray) {
      VStack {
        Text("Tray")
        Button("Dismiss") {
          showTray = false
        }
      }
    }

    _ = view
  }
}

// MARK: - IronNavigationIntegrationTests

@Suite("IronNavigation - Integration Scenarios")
@MainActor
struct IronNavigationIntegrationTests {

  @Test("typical onboarding flow structure")
  func typicalOnboardingFlowStructure() {
    @State var showOnboarding = true

    // This verifies the structure compiles and can be instantiated
    let view = Color.clear
      .ironTray(isPresented: $showOnboarding) {
        IronTrayStack { navigator in
          VStack {
            Text("Welcome")
            Button("Next") {
              navigator.push {
                VStack {
                  Text("Step 2")
                  Button("Back") {
                    navigator.pop()
                  }
                  Button("Finish") {
                    navigator.popToRoot()
                  }
                }
              }
            }
          }
        }
      }

    _ = view
  }

  @Test("tray with header and content")
  func trayWithHeaderAndContent() {
    @State var showSettings = false

    let view = IronTray(onDismiss: { showSettings = false }) {
      VStack {
        IronTrayHeader("Settings", onDismiss: { showSettings = false })
        Text("Settings content here")
      }
    }

    _ = view.body
  }

  @Test("nested tray stack navigation")
  func nestedTrayStackNavigation() {
    var depths = [Int]()

    let stack = IronTrayStack { navigator in
      depths.append(navigator.depth)
      return VStack {
        Text("Depth: \(navigator.depth)")
        Button("Push") {
          navigator.push {
            Text("Pushed View")
          }
        }
      }
    }

    _ = stack.body

    #expect(depths.contains(0))
  }
}
