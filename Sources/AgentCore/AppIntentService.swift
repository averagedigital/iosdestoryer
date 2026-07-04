import Foundation

public struct AppIntentService {
  public let actions: [SupportedAppAction]

  public init(actions: [SupportedAppAction] = SupportedAppAction.defaultActions) {
    self.actions = actions
  }

  public func listSupportedActions() -> [SupportedAppAction] {
    actions
  }

  public func invokeOwnAction(id: String) throws -> InvokedAppAction {
    guard let action = actions.first(where: { $0.id == id }) else {
      throw AppIntentServiceError.unsupportedAction(id)
    }
    return InvokedAppAction(action: action)
  }
}

public struct SupportedAppAction: Equatable, Identifiable, Sendable {
  public let id: String
  public let title: String
  public let summary: String

  public init(id: String, title: String, summary: String) {
    self.id = id
    self.title = title
    self.summary = summary
  }

  public static let defaultActions = [
    SupportedAppAction(
      id: "open_agent_workspace",
      title: "Open Agent Workspace",
      summary: "Opens this app's agent workspace from Shortcuts or Siri.")
  ]
}

public struct InvokedAppAction: Equatable, Sendable {
  public let action: SupportedAppAction

  public init(action: SupportedAppAction) {
    self.action = action
  }
}

public enum AppIntentServiceError: Error, Equatable {
  case unsupportedAction(String)
}
