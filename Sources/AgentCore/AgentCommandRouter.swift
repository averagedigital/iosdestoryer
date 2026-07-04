import Foundation

public struct AgentCommandRouter: Sendable {
  public init() {}

  public func route(_ message: String) -> AgentCommandRoute? {
    let text = message.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    guard !text.isEmpty else { return nil }

    if containsAny(text, ["context bundle", "контекст", "собери context"]) {
      return AgentCommandRoute(toolName: "index.export_context_bundle")
    }
    if containsAny(text, ["напомин", "reminder"]) {
      return AgentCommandRoute(toolName: "reminders.create")
    }
    if containsAny(text, ["контакт", "contact"]) {
      return AgentCommandRoute(toolName: "contacts.create")
    }
    if containsAny(text, ["проскан", "scan", "ocr", "распознай"]) {
      return AgentCommandRoute(toolName: "camera.scan_document")
    }
    if containsAny(text, ["фото", "photo", "скриншот", "чек", "альбом"]) {
      return AgentCommandRoute(toolName: "photos.classify_candidates")
    }
    if containsAny(text, ["найди", "find", "search", "документ"]) {
      return AgentCommandRoute(toolName: "index.search")
    }

    return nil
  }

  private func containsAny(_ text: String, _ needles: [String]) -> Bool {
    needles.contains { text.contains($0) }
  }
}

public struct AgentCommandRoute: Equatable, Sendable {
  public let toolName: String

  public init(toolName: String) {
    self.toolName = toolName
  }
}
