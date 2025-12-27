import SnapshotTesting
import SwiftUI
import Testing
@testable import IronCore
@testable import IronNavigation
@testable import IronPrimitives

// MARK: - IronTrayHeaderSnapshotTests

@Suite("IronTrayHeader Snapshots")
struct IronTrayHeaderSnapshotTests {

  @Test("TrayHeader - Close Button")
  @MainActor
  func trayHeaderCloseButton() {
    let view = IronTrayHeader("Settings") { }
      .padding()
      .background(Color.gray.opacity(0.1))

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 350)
  }

  @Test("TrayHeader - Back Button")
  @MainActor
  func trayHeaderBackButton() {
    let view = IronTrayHeader("Profile Details", isBackButtonVisible: true) { }
      .padding()
      .background(Color.gray.opacity(0.1))

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 350)
  }

  @Test("TrayHeader - Comparison")
  @MainActor
  func trayHeaderComparison() {
    let view = VStack(spacing: 16) {
      VStack(alignment: .leading, spacing: 4) {
        IronText("Root Level (Close)", style: .caption, color: .secondary)
        IronTrayHeader("Welcome") { }
          .background(Color.gray.opacity(0.1))
      }

      IronDivider()

      VStack(alignment: .leading, spacing: 4) {
        IronText("Nested Level (Back)", style: .caption, color: .secondary)
        IronTrayHeader("Step 2", isBackButtonVisible: true) { }
          .background(Color.gray.opacity(0.1))
      }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 350)
  }
}

// MARK: - IronTraySnapshotTests

@Suite("IronTray Snapshots")
struct IronTraySnapshotTests {

  @Test("Tray - Content Example")
  @MainActor
  func trayContentExample() {
    // Test the tray content layout structure (without the full overlay behavior)
    let view = VStack(spacing: 0) {
      // Drag indicator
      Capsule()
        .fill(Color.secondary.opacity(0.4))
        .frame(width: 36, height: 5)
        .padding(.top, 8)
        .padding(.bottom, 4)

      VStack(spacing: 16) {
        IronTrayHeader("Welcome") { }

        IronText("This tray sizes to fit its content.", style: .bodyMedium, color: .secondary)
          .padding(.horizontal)

        IronButton("Got it", variant: .filled) { }
          .padding(.bottom)
      }
    }
    .background(.ultraThinMaterial)
    .clipShape(
      UnevenRoundedRectangle(
        topLeadingRadius: 20,
        topTrailingRadius: 20,
      )
    )
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 350)
  }

  @Test("Tray - Multi-step Content")
  @MainActor
  func trayMultiStepContent() {
    // Test tray with more content to show height variation
    let view = VStack(spacing: 0) {
      // Drag indicator
      Capsule()
        .fill(Color.secondary.opacity(0.4))
        .frame(width: 36, height: 5)
        .padding(.top, 8)
        .padding(.bottom, 4)

      VStack(spacing: 16) {
        IronTrayHeader("Choose Option", isBackButtonVisible: true) { }

        ForEach(["Option A", "Option B", "Option C"], id: \.self) { option in
          HStack {
            IronText(option, style: .bodyMedium, color: .primary)
            Spacer()
            IronIcon(systemName: "chevron.right", size: .small, color: .secondary)
          }
          .padding()
          .background(Color.gray.opacity(0.1))
          .clipShape(RoundedRectangle(cornerRadius: 10))
        }
        .padding(.horizontal)

        IronButton("Cancel", variant: .outlined) { }
          .padding(.bottom)
      }
    }
    .background(.ultraThinMaterial)
    .clipShape(
      UnevenRoundedRectangle(
        topLeadingRadius: 20,
        topTrailingRadius: 20,
      )
    )
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 350)
  }
}

// MARK: - IronToastSnapshotTests

@Suite("IronToast Snapshots")
struct IronToastSnapshotTests {

  @Test("Toast - Variants")
  @MainActor
  func toastVariants() {
    let view = VStack(spacing: 16) {
      IronToast("This is an informational message", variant: .info)
      IronToast("Your changes have been saved successfully", variant: .success)
      IronToast("Please review the highlighted fields", variant: .warning)
      IronToast("An error occurred while processing", variant: .error)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 350)
  }

  @Test("Toast - With Titles")
  @MainActor
  func toastWithTitles() {
    let view = VStack(spacing: 16) {
      IronToast("Update Available", message: "A new version is ready", variant: .info)
      IronToast("Payment Successful", message: "Your order has been confirmed", variant: .success)
      IronToast("Low Storage", message: "Less than 500MB remaining", variant: .warning)
      IronToast("Connection Failed", message: "Check your internet", variant: .error)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 350)
  }

  @Test("Toast - With Actions")
  @MainActor
  func toastWithActions() {
    let view = VStack(spacing: 16) {
      IronToast(
        "Item deleted",
        variant: .info,
        action: IronToastAction("Undo") { },
      )

      IronToast(
        "Network error",
        variant: .error,
        action: IronToastAction("Retry") { },
      )

      IronToast(
        "File Uploaded",
        message: "document.pdf uploaded successfully",
        variant: .success,
        action: IronToastAction("View") { },
      )
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 350)
  }

  @Test("Toast - Custom Icons")
  @MainActor
  func toastCustomIcons() {
    let view = VStack(spacing: 16) {
      IronToast("Celebration time!", variant: .success, icon: {
        Text("🎉")
          .font(.title3)
      })

      IronToast("Sparkly success", variant: .success, icon: {
        Image(systemName: "sparkles")
          .foregroundStyle(.yellow)
          .font(.title3)
      })
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 350)
  }
}
