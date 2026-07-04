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
      AgentTool(
        name: "files.list_allowed_sources", domain: .files, appleFrameworks: ["Foundation"]),
      AgentTool(name: "files.read", domain: .files, appleFrameworks: ["Foundation"]),
      AgentTool(name: "files.write", domain: .files, appleFrameworks: ["Foundation"]),
      AgentTool(name: "files.copy", domain: .files, appleFrameworks: ["Foundation"]),
      AgentTool(name: "files.move", domain: .files, appleFrameworks: ["Foundation"]),
      AgentTool(name: "files.extract_text", domain: .files, appleFrameworks: ["Foundation"]),
      AgentTool(name: "files.search", domain: .index, appleFrameworks: ["Foundation"]),
      AgentTool(name: "files.context_bundle", domain: .index, appleFrameworks: ["Foundation"]),
      AgentTool(name: "files.index_folder", domain: .index, appleFrameworks: ["Foundation"]),
      AgentTool(name: "index.add_source", domain: .index, appleFrameworks: ["Foundation"]),
      AgentTool(name: "index.rebuild", domain: .index, appleFrameworks: ["Foundation"]),
      AgentTool(name: "index.search", domain: .index, appleFrameworks: ["Foundation"]),
      AgentTool(name: "index.get_chunks", domain: .index, appleFrameworks: ["Foundation"]),
      AgentTool(
        name: "index.export_context_bundle", domain: .index, appleFrameworks: ["Foundation"]),
      AgentTool(
        name: "files.delete_with_preview", domain: .files, appleFrameworks: ["Foundation"],
        isDestructive: true),
      AgentTool(name: "photos.permission_status", domain: .photos, appleFrameworks: ["Photos"]),
      AgentTool(name: "photos.list_assets", domain: .photos, appleFrameworks: ["Photos"]),
      AgentTool(name: "photos.find_screenshots", domain: .photos, appleFrameworks: ["Photos"]),
      AgentTool(name: "photos.find_documents", domain: .photos, appleFrameworks: ["Photos"]),
      AgentTool(
        name: "photos.find_duplicates_or_candidates", domain: .photos,
        appleFrameworks: ["Photos"]),
      AgentTool(name: "photos.create_album", domain: .photos, appleFrameworks: ["Photos"]),
      AgentTool(name: "photos.add_to_album", domain: .photos, appleFrameworks: ["Photos"]),
      AgentTool(
        name: "photos.remove_from_album_with_preview", domain: .photos,
        appleFrameworks: ["Photos"], isDestructive: true),
      AgentTool(name: "photos.favorite", domain: .photos, appleFrameworks: ["Photos"]),
      AgentTool(
        name: "photos.hide_with_preview", domain: .photos, appleFrameworks: ["Photos"],
        isDestructive: true),
      AgentTool(
        name: "photos.classify_candidates", domain: .photos, appleFrameworks: ["Photos"]),
      AgentTool(
        name: "photos.delete_with_preview", domain: .photos, appleFrameworks: ["Photos"],
        isDestructive: true),
      AgentTool(
        name: "contacts.permission_status", domain: .contacts, appleFrameworks: ["Contacts"]),
      AgentTool(name: "contacts.search", domain: .contacts, appleFrameworks: ["Contacts"]),
      AgentTool(name: "contacts.create", domain: .contacts, appleFrameworks: ["Contacts"]),
      AgentTool(
        name: "contacts.update_with_preview", domain: .contacts, appleFrameworks: ["Contacts"]),
      AgentTool(
        name: "contacts.find_duplicate_candidates", domain: .contacts,
        appleFrameworks: ["Contacts"]),
      AgentTool(name: "contacts.merge_preview", domain: .contacts, appleFrameworks: ["Contacts"]),
      AgentTool(
        name: "contacts.delete_with_preview", domain: .contacts, appleFrameworks: ["Contacts"],
        isDestructive: true),
      AgentTool(
        name: "calendar.permission_status", domain: .calendar, appleFrameworks: ["EventKit"]),
      AgentTool(name: "calendar.search_events", domain: .calendar, appleFrameworks: ["EventKit"]),
      AgentTool(name: "calendar.create_event", domain: .calendar, appleFrameworks: ["EventKit"]),
      AgentTool(
        name: "calendar.update_event_with_preview", domain: .calendar,
        appleFrameworks: ["EventKit"]),
      AgentTool(
        name: "calendar.delete_event_with_preview", domain: .calendar,
        appleFrameworks: ["EventKit"], isDestructive: true),
      AgentTool(
        name: "reminders.permission_status", domain: .calendar, appleFrameworks: ["EventKit"]),
      AgentTool(name: "reminders.search", domain: .calendar, appleFrameworks: ["EventKit"]),
      AgentTool(name: "reminders.create", domain: .calendar, appleFrameworks: ["EventKit"]),
      AgentTool(
        name: "reminders.update_with_preview", domain: .calendar, appleFrameworks: ["EventKit"]),
      AgentTool(name: "reminders.complete", domain: .calendar, appleFrameworks: ["EventKit"]),
      AgentTool(
        name: "notify.schedule", domain: .notifications,
        appleFrameworks: ["UserNotifications"]),
      AgentTool(
        name: "notify.cancel", domain: .notifications,
        appleFrameworks: ["UserNotifications"]),
      AgentTool(
        name: "share.import_text", domain: .share,
        appleFrameworks: ["UIKit", "UniformTypeIdentifiers"]),
      AgentTool(
        name: "share.import_url", domain: .share,
        appleFrameworks: ["UIKit", "UniformTypeIdentifiers"]),
      AgentTool(
        name: "share.import_file", domain: .share,
        appleFrameworks: ["UIKit", "UniformTypeIdentifiers"]),
      AgentTool(
        name: "share.import_image", domain: .share,
        appleFrameworks: ["UIKit", "UniformTypeIdentifiers"]),
      AgentTool(name: "share.list_inbox", domain: .share, appleFrameworks: ["Foundation"]),
      AgentTool(name: "app.open_url", domain: .app, appleFrameworks: ["UIKit"]),
      AgentTool(name: "app.open_deeplink", domain: .app, appleFrameworks: ["UIKit"]),
      AgentTool(name: "vision.ocr_image", domain: .vision, appleFrameworks: ["Vision"]),
      AgentTool(
        name: "app_intents.list_supported_actions", domain: .appIntents,
        appleFrameworks: ["AppIntents"]),
      AgentTool(
        name: "app_intents.invoke_own_action", domain: .appIntents,
        appleFrameworks: ["AppIntents"]),
      AgentTool(
        name: "shortcuts.run_user_configured_shortcut", domain: .appIntents,
        appleFrameworks: ["AppIntents"]),
      AgentTool(name: "audio.record", domain: .audio, appleFrameworks: ["AVFoundation"]),
      AgentTool(name: "speech.transcribe", domain: .audio, appleFrameworks: ["Speech"]),
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
  case notifications = "Notifications"
  case share = "Share"
  case app = "App"
  case vision = "Vision"
  case appIntents = "App Intents"
  case audio = "Audio"
}
