import Foundation

#if canImport(Photos)
  import Photos
#endif

public struct PhotoPermissionService {
  private let provider: any PhotoAuthorizationProviding

  public init(provider: any PhotoAuthorizationProviding = PhotoKitAuthorizationProvider()) {
    self.provider = provider
  }

  public func currentStatus() -> PhotoPermissionStatus {
    provider.authorizationStatus()
  }
}

public protocol PhotoAuthorizationProviding {
  func authorizationStatus() -> PhotoPermissionStatus
}

public enum PhotoPermissionStatus: String, Equatable, Sendable {
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

#if canImport(Photos)
  public struct PhotoKitAuthorizationProvider: PhotoAuthorizationProviding {
    public init() {}

    public func authorizationStatus() -> PhotoPermissionStatus {
      switch PHPhotoLibrary.authorizationStatus(for: .readWrite) {
      case .notDetermined:
        .notDetermined
      case .restricted:
        .restricted
      case .denied:
        .denied
      case .limited:
        .limited
      case .authorized:
        .authorized
      @unknown default:
        .unknown
      }
    }
  }
#else
  public struct PhotoKitAuthorizationProvider: PhotoAuthorizationProviding {
    public init() {}

    public func authorizationStatus() -> PhotoPermissionStatus {
      .unknown
    }
  }
#endif
