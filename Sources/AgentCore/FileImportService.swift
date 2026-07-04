import Foundation

public struct FileImportService {
  public let importsDirectory: URL

  public init(importsDirectory: URL) {
    self.importsDirectory = importsDirectory
  }

  public func importPickedFile(from sourceURL: URL, auditLog: inout AuditLog) throws -> ImportedFile
  {
    let imported = try importPickedFile(from: sourceURL)
    auditLog.record(
      toolName: "files.pick_file", summary: imported.originalFilename, status: .succeeded)
    return imported
  }

  public func importPickedFile(from sourceURL: URL) throws -> ImportedFile {
    try FileManager.default.createDirectory(at: importsDirectory, withIntermediateDirectories: true)

    let didAccess = sourceURL.startAccessingSecurityScopedResource()
    defer {
      if didAccess {
        sourceURL.stopAccessingSecurityScopedResource()
      }
    }

    let destinationURL = availableDestinationURL(for: sourceURL.lastPathComponent)
    try FileManager.default.copyItem(at: sourceURL, to: destinationURL)
    return ImportedFile(originalFilename: sourceURL.lastPathComponent, localURL: destinationURL)
  }

  private func availableDestinationURL(for filename: String) -> URL {
    let candidate = importsDirectory.appending(path: filename)
    guard FileManager.default.fileExists(atPath: candidate.path) else {
      return candidate
    }

    let ext = candidate.pathExtension
    let baseName = candidate.deletingPathExtension().lastPathComponent
    var counter = 2

    while true {
      let numberedName = ext.isEmpty ? "\(baseName)-\(counter)" : "\(baseName)-\(counter).\(ext)"
      let numberedURL = importsDirectory.appending(path: numberedName)
      if !FileManager.default.fileExists(atPath: numberedURL.path) {
        return numberedURL
      }
      counter += 1
    }
  }
}

public struct ImportedFile: Equatable, Sendable {
  public let originalFilename: String
  public let localURL: URL

  public init(originalFilename: String, localURL: URL) {
    self.originalFilename = originalFilename
    self.localURL = localURL
  }
}
