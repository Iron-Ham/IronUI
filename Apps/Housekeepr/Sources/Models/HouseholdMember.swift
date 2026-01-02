import Foundation
import SQLiteData
import SwiftUI

// MARK: - HouseholdMember

/// A member of the household who can be assigned chores
@Table
struct HouseholdMember: Identifiable, Sendable {

  // MARK: Lifecycle

  init(
    id: UUID = UUID(),
    name: String,
    avatarEmoji: String = "😊",
    colorHex: String = "#6366F1",
  ) {
    self.id = id
    self.name = name
    self.avatarEmoji = avatarEmoji
    self.colorHex = colorHex
  }

  // MARK: Internal

  let id: UUID
  var name: String
  var avatarEmoji: String
  var colorHex: String

  var color: Color {
    Color(hex: colorHex) ?? .blue
  }
}

extension Color {
  init?(hex: String) {
    var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
    hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

    guard
      hexSanitized.count == 6,
      let int = UInt64(hexSanitized, radix: 16)
    else {
      return nil
    }

    let r = Double((int >> 16) & 0xFF) / 255.0
    let g = Double((int >> 8) & 0xFF) / 255.0
    let b = Double(int & 0xFF) / 255.0

    self.init(red: r, green: g, blue: b)
  }
}
