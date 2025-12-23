import Foundation

struct Event: Identifiable {
  let id = UUID()
  let title: String
  let subtitle: String?
  let date: Date
}
