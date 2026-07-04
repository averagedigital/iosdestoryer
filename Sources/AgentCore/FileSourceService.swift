import Foundation

public struct FileSourceService {
  public let importsDirectory: URL

  public init(importsDirectory: URL) {
    self.importsDirectory = importsDirectory
  }

  public func listAllowedSources() throws -> [AllowedFileSource] {
    try FileManager.default.createDirectory(at: importsDirectory, withIntermediateDirectories: true)
    return [AllowedFileSource(name: "Imports", url: importsDirectory)]
  }
}

public struct AllowedFileSource: Equatable, Identifiable, Sendable {
  public var id: String { url.path }
  public let name: String
  public let url: URL

  public init(name: String, url: URL) {
    self.name = name
    self.url = url
  }
}
