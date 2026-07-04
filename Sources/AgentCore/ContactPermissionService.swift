import Foundation

#if canImport(Contacts)
  import Contacts
#endif

public struct ContactPermissionService {
  private let provider: any ContactAuthorizationProviding

  public init(provider: any ContactAuthorizationProviding = ContactStoreAuthorizationProvider()) {
    self.provider = provider
  }

  public func currentStatus() -> ContactPermissionStatus {
    provider.authorizationStatus()
  }
}

public protocol ContactAuthorizationProviding {
  func authorizationStatus() -> ContactPermissionStatus
}

public enum ContactPermissionStatus: String, Equatable, Sendable {
  case notDetermined
  case restricted
  case denied
  case limited
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
    case .limited:
      "Limited"
    case .authorized:
      "Authorized"
    case .unknown:
      "Unknown"
    }
  }
}

#if canImport(Contacts)
  public struct ContactStoreAuthorizationProvider: ContactAuthorizationProviding {
    public init() {}

    public func authorizationStatus() -> ContactPermissionStatus {
      let status = CNContactStore.authorizationStatus(for: .contacts)
      #if os(iOS)
        if #available(iOS 18.0, macOS 15.0, *), status == .limited {
          return .limited
        }
      #endif

      switch status {
      case .notDetermined:
        return .notDetermined
      case .restricted:
        return .restricted
      case .denied:
        return .denied
      #if os(iOS)
        case .limited:
          return .limited
      #endif
      case .authorized:
        return .authorized
      @unknown default:
        return .unknown
      }
    }
  }
#else
  public struct ContactStoreAuthorizationProvider: ContactAuthorizationProviding {
    public init() {}

    public func authorizationStatus() -> ContactPermissionStatus {
      .unknown
    }
  }
#endif
