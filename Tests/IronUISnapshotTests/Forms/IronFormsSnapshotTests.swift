import SnapshotTesting
import SwiftUI
import Testing
@testable import IronUI

// MARK: - IronFormFieldSnapshotTests

@Suite("IronFormField Snapshots")
struct IronFormFieldSnapshotTests {

  @Test("FormField - States")
  @MainActor
  func formFieldStates() {
    let view = VStack(spacing: 24) {
      IronFormField("Normal Field") {
        IronTextField("Enter text", text: .constant(""))
      }

      IronFormField("With Hint", hint: "This is helpful information") {
        IronTextField("Enter text", text: .constant(""))
      }

      IronFormField("Required Field", isRequired: true) {
        IronTextField("Enter text", text: .constant(""))
      }

      IronFormField("With Error", error: "This field is required") {
        IronTextField("Enter text", text: .constant(""))
      }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 320)
  }

  @Test("FormField - Input Types")
  @MainActor
  func formFieldInputTypes() {
    let view = VStack(spacing: 24) {
      IronFormField("Text Input") {
        IronTextField("Enter text", text: .constant("Hello"))
      }

      IronFormField("Secure Input") {
        IronSecureField("Enter password", text: .constant("secret"))
      }

      IronFormField("Toggle Option") {
        IronToggle("Enable notifications", isOn: .constant(true))
      }

      IronFormField("Checkbox Option") {
        IronCheckbox("I agree to the terms", isChecked: .constant(true))
      }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 320)
  }
}

// MARK: - IronFormSectionSnapshotTests

@Suite("IronFormSection Snapshots")
struct IronFormSectionSnapshotTests {

  @Test("FormSection - Basic")
  @MainActor
  func formSectionBasic() {
    let view = IronFormSection("Account") {
      IronFormField("Email") {
        IronTextField("Enter email", text: .constant(""))
      }
      IronFormField("Password") {
        IronSecureField("Enter password", text: .constant(""))
      }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 350)
  }

  @Test("FormSection - With Footer")
  @MainActor
  func formSectionWithFooter() {
    let view = IronFormSection("Profile", footer: "This information will be visible to other users") {
      IronFormField("Display Name") {
        IronTextField("Enter name", text: .constant("John Doe"))
      }
      IronFormField("Bio") {
        IronTextField("Tell us about yourself", text: .constant(""))
      }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 350)
  }

  @Test("FormSection - Settings Style")
  @MainActor
  func formSectionSettingsStyle() {
    let view = IronFormSection("Notifications") {
      IronFormField("Push Notifications") {
        IronToggle("Enable push notifications", isOn: .constant(true))
      }
      IronFormField("Email Notifications") {
        IronToggle("Receive email updates", isOn: .constant(false))
      }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 350)
  }
}

// MARK: - IronFormRowSnapshotTests

@Suite("IronFormRow Snapshots")
struct IronFormRowSnapshotTests {

  @Test("FormRow - Side By Side")
  @MainActor
  func formRowSideBySide() {
    let view = IronFormSection("Personal Information") {
      IronFormRow {
        IronFormField("First Name") {
          IronTextField("First", text: .constant("John"))
        }
        IronFormField("Last Name") {
          IronTextField("Last", text: .constant("Doe"))
        }
      }
      IronFormDivider()
      IronFormField("Email") {
        IronTextField("Enter email", text: .constant("john@example.com"))
      }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 400)
  }
}

// MARK: - IronDatePickerSnapshotTests

@Suite("IronDatePicker Snapshots")
struct IronDatePickerSnapshotTests {

  @Test("DatePicker - Compact Style")
  @MainActor
  func datePickerCompactStyle() {
    let view = IronFormField("Event Date") {
      IronDatePicker("Date", selection: .constant(Date()), style: .compact)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 320)
  }

  @Test("DatePicker - With Label")
  @MainActor
  func datePickerWithLabel() {
    let view = VStack(spacing: 24) {
      IronDatePicker("Start Date", selection: .constant(Date()), style: .compact)
      IronTimePicker("Start Time", selection: .constant(Date()), style: .compact)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 350)
  }
}
