import Foundation

public struct ToolRegistry: Sendable {
  public let tools: [AgentTool]

  public init(tools: [AgentTool]) {
    self.tools = tools
  }

  public func tool(named name: String) -> AgentTool? {
    tools.first { $0.name == name }
  }

  public static func defaultRegistry() -> ToolRegistry {
    ToolRegistry(tools: [
      AgentTool(
        name: "files.pick_file", domain: .files,
        appleFrameworks: ["UIKit", "UniformTypeIdentifiers"]),
      AgentTool(name: "files.pick_folder", domain: .files, appleFrameworks: ["UIKit"]),
      AgentTool(name: "files.read", domain: .files, appleFrameworks: ["Foundation"]),
      AgentTool(name: "files.search", domain: .index, appleFrameworks: ["Foundation"]),
      AgentTool(name: "files.context_bundle", domain: .index, appleFrameworks: ["Foundation"]),
      AgentTool(
        name: "files.delete_with_preview", domain: .files, appleFrameworks: ["Foundation"],
        isDestructive: true),
      AgentTool(name: "photos.permission_status", domain: .photos, appleFrameworks: ["Photos"]),
      AgentTool(
        name: "photos.delete_with_preview", domain: .photos, appleFrameworks: ["Photos"],
        isDestructive: true),
      AgentTool(
        name: "contacts.permission_status", domain: .contacts, appleFrameworks: ["Contacts"]),
      AgentTool(
        name: "contacts.delete_with_preview", domain: .contacts, appleFrameworks: ["Contacts"],
        isDestructive: true),
      AgentTool(
        name: "calendar.permission_status", domain: .calendar, appleFrameworks: ["EventKit"]),
      AgentTool(
        name: "reminders.permission_status", domain: .calendar, appleFrameworks: ["EventKit"]),
      AgentTool(name: "vision.ocr_image", domain: .vision, appleFrameworks: ["Vision"]),
      AgentTool(
        name: "app_intents.list_supported_actions", domain: .appIntents,
        appleFrameworks: ["AppIntents"]),
    ])
  }
}

public struct AgentTool: Identifiable, Equatable, Sendable {
  public var id: String { name }
  public let name: String
  public let domain: ToolDomain
  public let appleFrameworks: [String]
  public let isDestructive: Bool

  public var requiresPreview: Bool {
    isDestructive
  }

  public var usesPublicAppleAPI: Bool {
    !appleFrameworks.isEmpty
  }

  public init(
    name: String, domain: ToolDomain, appleFrameworks: [String], isDestructive: Bool = false
  ) {
    self.name = name
    self.domain = domain
    self.appleFrameworks = appleFrameworks
    self.isDestructive = isDestructive
  }
}

public enum ToolDomain: String, CaseIterable, Sendable {
  case files = "Files"
  case index = "Index"
  case photos = "Photos"
  case contacts = "Contacts"
  case calendar = "Calendar"
  case vision = "Vision"
  case appIntents = "App Intents"
}
