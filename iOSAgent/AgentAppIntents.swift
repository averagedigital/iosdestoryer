import AppIntents

struct OpenAgentWorkspaceIntent: AppIntent {
  static let title: LocalizedStringResource = "Open Agent Workspace"
  static let description = IntentDescription("Open this app's agent workspace.")
  static let openAppWhenRun = true

  func perform() async throws -> some IntentResult {
    .result()
  }
}

struct AgentAppShortcuts: AppShortcutsProvider {
  static var appShortcuts: [AppShortcut] {
    AppShortcut(
      intent: OpenAgentWorkspaceIntent(),
      phrases: ["Open \(.applicationName)"],
      shortTitle: "Open Agent",
      systemImageName: "sparkles")
  }
}
