import Foundation

#if canImport(AVFoundation)
  import AVFoundation
#endif

public struct CameraPermissionService {
  private let provider: any CameraPermissionProviding

  public init(provider: any CameraPermissionProviding = SystemCameraPermissionProvider()) {
    self.provider = provider
  }

  public func permissionStatus() -> CameraPermissionStatus {
    provider.permissionStatus()
  }

  public func requestPermission() async -> Bool {
    await provider.requestPermission()
  }
}

public protocol CameraPermissionProviding {
  func permissionStatus() -> CameraPermissionStatus
  func requestPermission() async -> Bool
}

public enum CameraPermissionStatus: String, Equatable, Sendable {
  case notDetermined
  case restricted
  case denied
  case authorized
  case unknown
  case unavailable
}

public struct CameraCaptureService {
  private let directory: URL

  public init(directory: URL) {
    self.directory = directory
  }

  public func savePhoto(_ imageData: Data, fileName: String) throws -> CameraCapture {
    guard !imageData.isEmpty else {
      throw CameraCaptureServiceError.emptyImageData
    }

    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let fileURL = directory.appending(path: fileName)
    try imageData.write(to: fileURL, options: .atomic)
    return CameraCapture(kind: .photo, fileURL: fileURL, pageURLs: [fileURL])
  }

  public func saveScannedDocument(_ pages: [Data], basename: String) throws -> CameraCapture {
    guard !pages.isEmpty, pages.allSatisfy({ !$0.isEmpty }) else {
      throw CameraCaptureServiceError.emptyImageData
    }

    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let pageURLs = try pages.enumerated().map { index, pageData in
      let fileURL = directory.appending(path: "\(basename)-\(index + 1).jpg")
      try pageData.write(to: fileURL, options: .atomic)
      return fileURL
    }
    return CameraCapture(kind: .documentScan, fileURL: pageURLs[0], pageURLs: pageURLs)
  }
}

public struct CameraCapture: Equatable, Sendable {
  public let kind: CameraCaptureKind
  public let fileURL: URL
  public let pageURLs: [URL]

  public var pageCount: Int {
    pageURLs.count
  }

  public init(kind: CameraCaptureKind, fileURL: URL, pageURLs: [URL]) {
    self.kind = kind
    self.fileURL = fileURL
    self.pageURLs = pageURLs
  }
}

public enum CameraCaptureKind: Equatable, Sendable {
  case photo
  case documentScan
}

public enum CameraCaptureServiceError: Error, Equatable {
  case emptyImageData
}

extension CameraCaptureServiceError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .emptyImageData:
      "Capture data is empty."
    }
  }
}

#if canImport(AVFoundation)
  public struct SystemCameraPermissionProvider: CameraPermissionProviding {
    public init() {}

    public func permissionStatus() -> CameraPermissionStatus {
      CameraPermissionStatus(AVCaptureDevice.authorizationStatus(for: .video))
    }

    public func requestPermission() async -> Bool {
      await AVCaptureDevice.requestAccess(for: .video)
    }
  }

  extension CameraPermissionStatus {
    fileprivate init(_ status: AVAuthorizationStatus) {
      switch status {
      case .notDetermined:
        self = .notDetermined
      case .restricted:
        self = .restricted
      case .denied:
        self = .denied
      case .authorized:
        self = .authorized
      @unknown default:
        self = .unknown
      }
    }
  }
#else
  public struct SystemCameraPermissionProvider: CameraPermissionProviding {
    public init() {}

    public func permissionStatus() -> CameraPermissionStatus {
      .unavailable
    }

    public func requestPermission() async -> Bool {
      false
    }
  }
#endif
