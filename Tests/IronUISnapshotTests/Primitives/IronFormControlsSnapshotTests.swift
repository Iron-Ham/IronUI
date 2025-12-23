import SnapshotTesting
import SwiftUI
import Testing
@testable import IronUI

// MARK: - IronCheckboxSnapshotTests

@Suite("IronCheckbox Snapshots")
struct IronCheckboxSnapshotTests {

  @Test("Checkbox - States")
  @MainActor
  func checkboxStates() {
    let view = VStack(alignment: .leading, spacing: 16) {
      IronCheckbox("Unchecked", isChecked: .constant(false))
      IronCheckbox("Checked", isChecked: .constant(true))
      IronCheckbox("Disabled Unchecked", isChecked: .constant(false))
        .disabled(true)
      IronCheckbox("Disabled Checked", isChecked: .constant(true))
        .disabled(true)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }
}

// MARK: - IronToggleSnapshotTests

@Suite("IronToggle Snapshots")
struct IronToggleSnapshotTests {

  @Test("Toggle - States")
  @MainActor
  func toggleStates() {
    let view = VStack(alignment: .leading, spacing: 16) {
      IronToggle("Off", isOn: .constant(false))
      IronToggle("On", isOn: .constant(true))
      IronToggle("Disabled Off", isOn: .constant(false))
        .disabled(true)
      IronToggle("Disabled On", isOn: .constant(true))
        .disabled(true)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }
}

// MARK: - IronRadioSnapshotTests

@Suite("IronRadio Snapshots")
struct IronRadioSnapshotTests {

  // MARK: Internal

  @Test("Radio - States")
  @MainActor
  func radioStates() {
    // Using different selections to show selected/unselected states
    let view = VStack(alignment: .leading, spacing: 16) {
      IronRadio("Unselected", value: Option.a, selection: .constant(Option.b))
      IronRadio("Selected", value: Option.a, selection: .constant(Option.a))
      IronRadio("Disabled Unselected", value: Option.a, selection: .constant(Option.b))
        .disabled(true)
      IronRadio("Disabled Selected", value: Option.a, selection: .constant(Option.a))
        .disabled(true)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Radio - Group")
  @MainActor
  func radioGroup() {
    let view = VStack(alignment: .leading, spacing: 12) {
      IronText("Choose an option:", style: .labelMedium, color: .primary)
      IronRadio("Option A", value: Option.a, selection: .constant(Option.a))
      IronRadio("Option B", value: Option.b, selection: .constant(Option.a))
      IronRadio("Option C", value: Option.c, selection: .constant(Option.a))
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  // MARK: Private

  private enum Option: String {
    case a
    case b
    case c
    case d
  }

}

// MARK: - IronTextFieldSnapshotTests

@Suite("IronTextField Snapshots")
struct IronTextFieldSnapshotTests {

  @Test("TextField - States")
  @MainActor
  func textFieldStates() {
    let view = VStack(spacing: 16) {
      IronTextField("Placeholder", text: .constant(""))
      IronTextField("With Value", text: .constant("Hello World"))
      IronTextField("Disabled", text: .constant("Disabled text"))
        .disabled(true)
    }
    .padding()

    // Text fields need constrained width
    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 280)
  }
}

// MARK: - IronSecureFieldSnapshotTests

@Suite("IronSecureField Snapshots")
struct IronSecureFieldSnapshotTests {

  @Test("SecureField - States")
  @MainActor
  func secureFieldStates() {
    let view = VStack(spacing: 16) {
      IronSecureField("Password", text: .constant(""))
      IronSecureField("Password", text: .constant("secret123"))
      IronSecureField("Disabled", text: .constant("disabled"))
        .disabled(true)
    }
    .padding()

    // Secure fields need constrained width
    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 280)
  }
}
