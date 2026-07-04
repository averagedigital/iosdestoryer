import Foundation

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
