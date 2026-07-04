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

  public func importPickedFolder(from sourceURL: URL) throws -> ImportedFolder {
    try FileManager.default.createDirectory(at: importsDirectory, withIntermediateDirectories: true)

    let didAccess = sourceURL.startAccessingSecurityScopedResource()
    defer {
      if didAccess {
        sourceURL.stopAccessingSecurityScopedResource()
      }
    }

    let destinationFolder = availableDestinationURL(for: sourceURL.lastPathComponent)
    try FileManager.default.createDirectory(
      at: destinationFolder, withIntermediateDirectories: true)

    let fileManager = FileManager.default
    guard
      let enumerator = fileManager.enumerator(
        at: sourceURL, includingPropertiesForKeys: [.isRegularFileKey])
    else {
      throw FileImportError.unreadableFolder(sourceURL.lastPathComponent)
    }

    var importedFiles: [ImportedFile] = []
    var skippedFiles: [String] = []
    let sourceRoot = sourceURL.resolvingSymlinksInPath().standardizedFileURL.path

    for case let fileURL as URL in enumerator {
      do {
        let values = try fileURL.resourceValues(forKeys: [.isRegularFileKey])
        guard values.isRegularFile == true else { continue }

        let filePath = fileURL.resolvingSymlinksInPath().standardizedFileURL.path
        guard filePath.hasPrefix(sourceRoot + "/") else {
          skippedFiles.append(fileURL.lastPathComponent)
          continue
        }

        let relativePath = String(filePath.dropFirst(sourceRoot.count + 1))
        let destinationURL = relativePath.split(separator: "/").reduce(destinationFolder) {
          partialURL, component in
          partialURL.appending(path: String(component))
        }
        try fileManager.createDirectory(
          at: destinationURL.deletingLastPathComponent(), withIntermediateDirectories: true)
        try fileManager.copyItem(at: fileURL, to: destinationURL)
        importedFiles.append(
          ImportedFile(originalFilename: relativePath, localURL: destinationURL))
      } catch {
        skippedFiles.append(fileURL.lastPathComponent)
      }
    }

    return ImportedFolder(
      originalFolderName: sourceURL.lastPathComponent,
      localURL: destinationFolder,
      importedFiles: importedFiles,
      skippedFiles: skippedFiles)
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

public enum FileImportError: Error, Equatable {
  case unreadableFolder(String)
}

extension FileImportError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .unreadableFolder(let name):
      "Could not read folder \(name)."
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

public struct ImportedFolder: Equatable, Sendable {
  public let originalFolderName: String
  public let localURL: URL
  public let importedFiles: [ImportedFile]
  public let skippedFiles: [String]

  public init(
    originalFolderName: String,
    localURL: URL,
    importedFiles: [ImportedFile],
    skippedFiles: [String]
  ) {
    self.originalFolderName = originalFolderName
    self.localURL = localURL
    self.importedFiles = importedFiles
    self.skippedFiles = skippedFiles
  }
}
