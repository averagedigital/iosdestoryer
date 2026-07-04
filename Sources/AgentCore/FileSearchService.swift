import Foundation

public struct FileSearchService {
  public let rootDirectory: URL

  public init(rootDirectory: URL) {
    self.rootDirectory = rootDirectory
  }

  public func search(query rawQuery: String) throws -> FileSearchReport {
    let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !query.isEmpty else {
      throw FileSearchError.emptyQuery
    }

    guard
      let urls = FileManager.default.enumerator(
        at: rootDirectory,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles]
      )
    else {
      return FileSearchReport(matches: [], skippedFiles: [])
    }

    var matches: [FileSearchResult] = []
    var skippedFiles: [SkippedFile] = []

    for case let url as URL in urls {
      let values = try url.resourceValues(forKeys: [.isRegularFileKey])
      guard values.isRegularFile == true else { continue }

      do {
        let text = try String(contentsOf: url, encoding: .utf8)
        if url.lastPathComponent.localizedCaseInsensitiveContains(query)
          || text.localizedCaseInsensitiveContains(query)
        {
          matches.append(FileSearchResult(filename: url.lastPathComponent, url: url))
        }
      } catch {
        skippedFiles.append(
          SkippedFile(filename: url.lastPathComponent, reason: "not UTF-8 text"))
      }
    }

    return FileSearchReport(
      matches: matches.sorted { $0.filename < $1.filename },
      skippedFiles: skippedFiles.sorted { $0.filename < $1.filename })
  }
}

public struct FileSearchReport: Equatable, Sendable {
  public let matches: [FileSearchResult]
  public let skippedFiles: [SkippedFile]

  public init(matches: [FileSearchResult], skippedFiles: [SkippedFile]) {
    self.matches = matches
    self.skippedFiles = skippedFiles
  }
}

public struct FileSearchResult: Equatable, Identifiable, Sendable {
  public var id: String { url.path }
  public let filename: String
  public let url: URL

  public init(filename: String, url: URL) {
    self.filename = filename
    self.url = url
  }
}

public struct SkippedFile: Equatable, Sendable {
  public let filename: String
  public let reason: String

  public init(filename: String, reason: String) {
    self.filename = filename
    self.reason = reason
  }
}

public enum FileSearchError: Error, Equatable {
  case emptyQuery
}
