import Foundation

public struct FileOperationService {
  public let rootDirectory: URL

  public init(rootDirectory: URL) {
    self.rootDirectory = rootDirectory
  }

  public func writeText(_ text: String, to relativePath: String) throws -> FileSearchResult {
    let url = try resolve(relativePath)
    if FileManager.default.fileExists(atPath: url.path) {
      throw FileOperationError.destinationExists(relativePath)
    }
    try FileManager.default.createDirectory(
      at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
    try text.write(to: url, atomically: true, encoding: .utf8)
    return FileSearchResult(filename: url.lastPathComponent, url: url)
  }

  public func copy(from sourceRelativePath: String, to destinationRelativePath: String) throws
    -> FileSearchResult
  {
    let source = try existingFile(sourceRelativePath)
    let destination = try resolve(destinationRelativePath)
    if FileManager.default.fileExists(atPath: destination.path) {
      throw FileOperationError.destinationExists(destinationRelativePath)
    }
    try FileManager.default.createDirectory(
      at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
    try FileManager.default.copyItem(at: source, to: destination)
    return FileSearchResult(filename: destination.lastPathComponent, url: destination)
  }

  public func move(from sourceRelativePath: String, to destinationRelativePath: String) throws
    -> FileSearchResult
  {
    let source = try existingFile(sourceRelativePath)
    let destination = try resolve(destinationRelativePath)
    if FileManager.default.fileExists(atPath: destination.path) {
      throw FileOperationError.destinationExists(destinationRelativePath)
    }
    try FileManager.default.createDirectory(
      at: destination.deletingLastPathComponent(), withIntermediateDirectories: true)
    try FileManager.default.moveItem(at: source, to: destination)
    return FileSearchResult(filename: destination.lastPathComponent, url: destination)
  }

  public func extractText(from relativePath: String) throws -> FileDocument {
    try FileReadService().read(url: existingFile(relativePath))
  }

  public func deletePreview(for relativePath: String) throws -> FileDeletePreview {
    let url = try existingFile(relativePath)
    let attributes = try FileManager.default.attributesOfItem(atPath: url.path)
    return FileDeletePreview(
      relativePath: relativePath, filename: url.lastPathComponent, url: url,
      byteCount: attributes[.size] as? Int ?? 0)
  }

  public func delete(_ preview: FileDeletePreview) throws {
    let url = try existingFile(preview.relativePath)
    guard url.standardizedFileURL == preview.url.standardizedFileURL else {
      throw FileOperationError.pathEscapesRoot(preview.relativePath)
    }
    try FileManager.default.removeItem(at: url)
  }

  private func existingFile(_ relativePath: String) throws -> URL {
    let url = try resolve(relativePath)
    var isDirectory = ObjCBool(false)
    guard FileManager.default.fileExists(atPath: url.path, isDirectory: &isDirectory),
      !isDirectory.boolValue
    else {
      throw FileOperationError.sourceMissing(relativePath)
    }
    return url
  }

  private func resolve(_ relativePath: String) throws -> URL {
    let trimmed = relativePath.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else {
      throw FileOperationError.emptyPath
    }
    guard !trimmed.hasPrefix("/") else {
      throw FileOperationError.pathEscapesRoot(relativePath)
    }

    let root = rootDirectory.standardizedFileURL
    try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
    let candidate = root.appending(path: trimmed).standardizedFileURL
    let rootPath = root.path
    guard candidate.path == rootPath || candidate.path.hasPrefix(rootPath + "/") else {
      throw FileOperationError.pathEscapesRoot(relativePath)
    }
    return candidate
  }
}

public struct FileDeletePreview: Equatable, Sendable {
  public let relativePath: String
  public let filename: String
  public let url: URL
  public let byteCount: Int

  public init(relativePath: String, filename: String, url: URL, byteCount: Int) {
    self.relativePath = relativePath
    self.filename = filename
    self.url = url
    self.byteCount = byteCount
  }
}

public enum FileOperationError: Error, Equatable {
  case emptyPath
  case pathEscapesRoot(String)
  case sourceMissing(String)
  case destinationExists(String)
}

extension FileOperationError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .emptyPath:
      "File path is empty."
    case .pathEscapesRoot:
      "File path must stay inside Imports."
    case .sourceMissing(let path):
      "File does not exist: \(path)"
    case .destinationExists(let path):
      "Destination already exists: \(path)"
    }
  }
}
