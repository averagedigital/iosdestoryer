import Foundation

#if canImport(EventKit)
  import EventKit
#endif

public struct EventPermissionService {
  private let provider: any EventAuthorizationProviding

  public init(provider: any EventAuthorizationProviding = EventKitAuthorizationProvider()) {
    self.provider = provider
  }

  public func currentStatus(for entity: EventPermissionEntity) -> EventPermissionStatus {
    provider.authorizationStatus(for: entity)
  }

  public func requestAuthorization(for entity: EventPermissionEntity) async -> EventPermissionStatus
  {
    await provider.requestAuthorization(for: entity)
  }
}

public protocol EventAuthorizationProviding: Sendable {
  func authorizationStatus(for entity: EventPermissionEntity) -> EventPermissionStatus
  func requestAuthorization(for entity: EventPermissionEntity) async -> EventPermissionStatus
}

public enum EventPermissionEntity: Sendable {
  case calendar
  case reminders
}

public enum EventPermissionStatus: String, Equatable, Sendable {
  case notDetermined
  case restricted
  case denied
  case writeOnly
  case fullAccess
  case authorized
  case unknown

  public var displayName: String {
    switch self {
    case .notDetermined:
      "Not Determined"
    case .restricted:
      "Restricted"
    case .denied:
      "Denied"
    case .writeOnly:
      "Write Only"
    case .fullAccess:
      "Full Access"
    case .authorized:
      "Authorized"
    case .unknown:
      "Unknown"
    }
  }
}

#if canImport(EventKit)
  public struct EventKitAuthorizationProvider: EventAuthorizationProviding, Sendable {
    public init() {}

    public func authorizationStatus(for entity: EventPermissionEntity) -> EventPermissionStatus {
      switch EKEventStore.authorizationStatus(for: entity.eventKitEntityType) {
      case .notDetermined:
        .notDetermined
      case .restricted:
        .restricted
      case .denied:
        .denied
      case .authorized:
        .authorized
      case .writeOnly:
        .writeOnly
      case .fullAccess:
        .fullAccess
      @unknown default:
        .unknown
      }
    }

    public func requestAuthorization(for entity: EventPermissionEntity) async
      -> EventPermissionStatus
    {
      let store = EKEventStore()
      do {
        switch entity {
        case .calendar:
          _ = try await store.requestFullAccessToEvents()
        case .reminders:
          _ = try await store.requestFullAccessToReminders()
        }
        return authorizationStatus(for: entity)
      } catch {
        return authorizationStatus(for: entity)
      }
    }
  }

  extension EventPermissionEntity {
    fileprivate var eventKitEntityType: EKEntityType {
      switch self {
      case .calendar:
        .event
      case .reminders:
        .reminder
      }
    }
  }
#else
  public struct EventKitAuthorizationProvider: EventAuthorizationProviding, Sendable {
    public init() {}

    public func authorizationStatus(for entity: EventPermissionEntity) -> EventPermissionStatus {
      .unknown
    }

    public func requestAuthorization(for entity: EventPermissionEntity) async
      -> EventPermissionStatus
    {
      .unknown
    }
  }
#endif
