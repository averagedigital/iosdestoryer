import Foundation

#if canImport(UserNotifications)
  import UserNotifications
#endif

public struct NotificationService {
  private let provider: any NotificationProviding

  public init(provider: any NotificationProviding = UserNotificationProvider()) {
    self.provider = provider
  }

  public func permissionStatus() async -> NotificationPermissionStatus {
    await provider.permissionStatus()
  }

  public func requestPermission() async throws -> Bool {
    try await provider.requestPermission()
  }

  public func schedule(_ draft: NotificationDraft) async throws -> ScheduledNotification {
    guard draft.delaySeconds > 0 else {
      throw NotificationServiceError.invalidDelay
    }
    return try await provider.schedule(draft)
  }

  public func cancel(id: String) {
    provider.cancel(id: id)
  }
}

public protocol NotificationProviding {
  func permissionStatus() async -> NotificationPermissionStatus
  func requestPermission() async throws -> Bool
  func schedule(_ draft: NotificationDraft) async throws -> ScheduledNotification
  func cancel(id: String)
}

public enum NotificationPermissionStatus: String, Equatable, Sendable {
  case notDetermined
  case denied
  case authorized
  case provisional
  case ephemeral
  case unknown
  case unavailable
}

public struct NotificationDraft: Equatable, Sendable {
  public let id: String
  public let title: String
  public let body: String
  public let delaySeconds: TimeInterval

  public init(id: String, title: String, body: String, delaySeconds: TimeInterval) {
    self.id = id
    self.title = title
    self.body = body
    self.delaySeconds = delaySeconds
  }
}

public struct ScheduledNotification: Equatable, Identifiable, Sendable {
  public let id: String
  public let title: String
  public let delaySeconds: TimeInterval

  public init(id: String, title: String, delaySeconds: TimeInterval) {
    self.id = id
    self.title = title
    self.delaySeconds = delaySeconds
  }
}

public enum NotificationServiceError: Error, Equatable {
  case invalidDelay
}

#if canImport(UserNotifications)
  public struct UserNotificationProvider: NotificationProviding {
    public init() {}

    public func permissionStatus() async -> NotificationPermissionStatus {
      let settings = await UNUserNotificationCenter.current().notificationSettings()
      return NotificationPermissionStatus(settings.authorizationStatus)
    }

    public func requestPermission() async throws -> Bool {
      try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
    }

    public func schedule(_ draft: NotificationDraft) async throws -> ScheduledNotification {
      let content = UNMutableNotificationContent()
      content.title = draft.title
      content.body = draft.body

      let trigger = UNTimeIntervalNotificationTrigger(
        timeInterval: draft.delaySeconds,
        repeats: false)
      let request = UNNotificationRequest(
        identifier: draft.id,
        content: content,
        trigger: trigger)
      try await UNUserNotificationCenter.current().add(request)
      return ScheduledNotification(
        id: draft.id,
        title: draft.title,
        delaySeconds: draft.delaySeconds)
    }

    public func cancel(id: String) {
      UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }
  }

  extension NotificationPermissionStatus {
    fileprivate init(_ status: UNAuthorizationStatus) {
      switch status {
      case .notDetermined:
        self = .notDetermined
      case .denied:
        self = .denied
      case .authorized:
        self = .authorized
      case .provisional:
        self = .provisional
      case .ephemeral:
        self = .ephemeral
      @unknown default:
        self = .unknown
      }
    }
  }
#else
  public struct UserNotificationProvider: NotificationProviding {
    public init() {}

    public func permissionStatus() async -> NotificationPermissionStatus {
      .unavailable
    }

    public func requestPermission() async throws -> Bool {
      false
    }

    public func schedule(_ draft: NotificationDraft) async throws -> ScheduledNotification {
      ScheduledNotification(id: draft.id, title: draft.title, delaySeconds: draft.delaySeconds)
    }

    public func cancel(id: String) {}
  }
#endif
