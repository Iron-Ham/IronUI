import SnapshotTesting
import SwiftUI
import Testing
@testable import IronUI

// MARK: - IronProgressSnapshotTests

@Suite("IronProgress Snapshots")
struct IronProgressSnapshotTests {

  @Test("Progress - Linear Values")
  @MainActor
  func progressLinearValues() {
    let view = VStack(spacing: 16) {
      IronProgress(value: 0.0)
      IronProgress(value: 0.25)
      IronProgress(value: 0.5)
      IronProgress(value: 0.75)
      IronProgress(value: 1.0)
    }
    .padding()

    // Linear progress needs constrained width
    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 250)
  }

  @Test("Progress - Circular Values")
  @MainActor
  func progressCircularValues() {
    let view = HStack(spacing: 24) {
      IronProgress(value: 0.25, style: .circular)
      IronProgress(value: 0.5, style: .circular)
      IronProgress(value: 0.75, style: .circular)
      IronProgress(value: 1.0, style: .circular)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Progress - Sizes")
  @MainActor
  func progressSizes() {
    let view = VStack(spacing: 16) {
      IronProgress(value: 0.6, size: .small)
      IronProgress(value: 0.6, size: .medium)
      IronProgress(value: 0.6, size: .large)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 200)
  }

  @Test("Progress - Colors")
  @MainActor
  func progressColors() {
    let view = VStack(spacing: 12) {
      IronProgress(value: 0.7, color: .primary)
      IronProgress(value: 0.7, color: .success)
      IronProgress(value: 0.7, color: .warning)
      IronProgress(value: 0.7, color: .error)
      IronProgress(value: 0.7, color: .info)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 200)
  }
}

// MARK: - IronSpinnerSnapshotTests

@Suite("IronSpinner Snapshots")
struct IronSpinnerSnapshotTests {

  @Test("Spinner - Sizes")
  @MainActor
  func spinnerSizes() {
    let view = HStack(spacing: 24) {
      IronSpinner(size: .small)
      IronSpinner(size: .medium)
      IronSpinner(size: .large)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Spinner - Colors")
  @MainActor
  func spinnerColors() {
    let view = HStack(spacing: 20) {
      IronSpinner(color: .primary)
      IronSpinner(color: .success)
      IronSpinner(color: .warning)
      IronSpinner(color: .error)
      IronSpinner(color: .info)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }
}

// MARK: - IronAlertSnapshotTests

@Suite("IronAlert Snapshots")
struct IronAlertSnapshotTests {

  @Test("Alert - Variants")
  @MainActor
  func alertVariants() {
    let view = VStack(spacing: 12) {
      IronAlert("Information message", variant: .info)
      IronAlert("Success message", variant: .success)
      IronAlert("Warning message", variant: .warning)
      IronAlert("Error message", variant: .error)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 320)
  }

  @Test("Alert - With Title")
  @MainActor
  func alertWithTitle() {
    let view = VStack(spacing: 12) {
      IronAlert("Update Available", message: "A new version is ready", variant: .info)
      IronAlert("Payment Successful", message: "Order confirmed", variant: .success)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 320)
  }
}

// MARK: - IronBadgeSnapshotTests

@Suite("IronBadge Snapshots")
struct IronBadgeSnapshotTests {

  @Test("Badge - Counts")
  @MainActor
  func badgeCounts() {
    let view = HStack(spacing: 16) {
      IronBadge(count: 1)
      IronBadge(count: 9)
      IronBadge(count: 42)
      IronBadge(count: 100, maxCount: 99)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Badge - Text")
  @MainActor
  func badgeText() {
    let view = HStack(spacing: 12) {
      IronBadge("New")
      IronBadge("Beta", color: .info)
      IronBadge("Pro", color: .warning)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Badge - Dots")
  @MainActor
  func badgeDots() {
    let view = HStack(spacing: 16) {
      IronBadge(color: .primary, size: .small)
      IronBadge(color: .success, size: .medium)
      IronBadge(color: .error, size: .large)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Badge - Styles")
  @MainActor
  func badgeStyles() {
    let view = HStack(spacing: 12) {
      IronBadge(count: 5, style: .filled)
      IronBadge(count: 5, style: .soft)
      IronBadge(count: 5, style: .outlined)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }

  @Test("Badge - Colors")
  @MainActor
  func badgeColors() {
    let view = HStack(spacing: 8) {
      IronBadge(count: 3, color: .primary)
      IronBadge(count: 3, color: .success)
      IronBadge(count: 3, color: .warning)
      IronBadge(count: 3, color: .error)
      IronBadge(count: 3, color: .info)
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick)
  }
}

// MARK: - IronCardSnapshotTests

@Suite("IronCard Snapshots")
struct IronCardSnapshotTests {

  @Test("Card - Styles")
  @MainActor
  func cardStyles() {
    let view = VStack(spacing: 16) {
      IronCard(style: .elevated) {
        IronText("Elevated Card", style: .bodyMedium, color: .primary)
      }
      IronCard(style: .filled) {
        IronText("Filled Card", style: .bodyMedium, color: .primary)
      }
      IronCard(style: .outlined) {
        IronText("Outlined Card", style: .bodyMedium, color: .primary)
      }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 280)
  }

  @Test("Card - Padding")
  @MainActor
  func cardPadding() {
    let view = VStack(spacing: 12) {
      IronCard(padding: .compact) {
        IronText("Compact", style: .bodyMedium, color: .primary)
      }
      IronCard(padding: .standard) {
        IronText("Standard", style: .bodyMedium, color: .primary)
      }
      IronCard(padding: .spacious) {
        IronText("Spacious", style: .bodyMedium, color: .primary)
      }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 280)
  }
}

// MARK: - IronDividerSnapshotTests

@Suite("IronDivider Snapshots")
struct IronDividerSnapshotTests {

  @Test("Divider - Styles")
  @MainActor
  func dividerStyles() {
    let view = VStack(spacing: 24) {
      VStack(spacing: 4) {
        IronText("Subtle", style: .caption, color: .secondary)
        IronDivider(style: .subtle)
      }
      VStack(spacing: 4) {
        IronText("Standard", style: .caption, color: .secondary)
        IronDivider(style: .standard)
      }
      VStack(spacing: 4) {
        IronText("Prominent", style: .caption, color: .secondary)
        IronDivider(style: .prominent)
      }
      VStack(spacing: 4) {
        IronText("Accent", style: .caption, color: .secondary)
        IronDivider(style: .accent)
      }
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 250)
  }

  @Test("Divider - Labeled")
  @MainActor
  func dividerLabeled() {
    let view = VStack(spacing: 20) {
      IronDivider(label: "OR")
      IronDivider(label: "Continue with")
    }
    .padding()

    ironAssertSnapshots(of: view, configurations: SnapshotConfiguration.quick, width: 280)
  }
}
