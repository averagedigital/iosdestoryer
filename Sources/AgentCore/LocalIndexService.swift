import Foundation

public struct LocalIndexService {
  public let rootDirectory: URL
  public let maxChunkLength: Int

  public init(rootDirectory: URL, maxChunkLength: Int = 900) {
    self.rootDirectory = rootDirectory
    self.maxChunkLength = maxChunkLength
  }

  public func rebuild() throws -> LocalIndex {
    guard maxChunkLength > 0 else {
      throw LocalIndexError.invalidChunkLength
    }

    guard
      let urls = FileManager.default.enumerator(
        at: rootDirectory,
        includingPropertiesForKeys: [.isRegularFileKey],
        options: [.skipsHiddenFiles])
    else {
      return LocalIndex(chunks: [], skippedFiles: [])
    }

    var chunks: [IndexedChunk] = []
    var skippedFiles: [SkippedFile] = []

    for case let url as URL in urls {
      let values = try url.resourceValues(forKeys: [.isRegularFileKey])
      guard values.isRegularFile == true else { continue }

      do {
        let text = try String(contentsOf: url, encoding: .utf8)
        chunks.append(
          contentsOf: makeChunks(text: text, filename: url.lastPathComponent, url: url))
      } catch {
        skippedFiles.append(
          SkippedFile(filename: url.lastPathComponent, reason: "not UTF-8 text"))
      }
    }

    return LocalIndex(
      chunks: chunks.sorted { $0.id < $1.id },
      skippedFiles: skippedFiles.sorted { $0.filename < $1.filename })
  }

  private func makeChunks(text: String, filename: String, url: URL) -> [IndexedChunk] {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmed.isEmpty else { return [] }

    var chunks: [IndexedChunk] = []
    var start = trimmed.startIndex
    var number = 1

    while start < trimmed.endIndex {
      let end =
        trimmed.index(start, offsetBy: maxChunkLength, limitedBy: trimmed.endIndex)
        ?? trimmed.endIndex
      let chunkText = String(trimmed[start..<end])
      chunks.append(
        IndexedChunk(
          id: "\(url.path)#\(number)", filename: filename, url: url, number: number,
          text: chunkText))
      start = end
      number += 1
    }

    return chunks
  }
}

public struct LocalIndex: Equatable, Sendable {
  public let chunks: [IndexedChunk]
  public let skippedFiles: [SkippedFile]

  public init(chunks: [IndexedChunk], skippedFiles: [SkippedFile]) {
    self.chunks = chunks
    self.skippedFiles = skippedFiles
  }

  public func search(query rawQuery: String, limit: Int = 10) throws -> [IndexedChunk] {
    let query = rawQuery.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !query.isEmpty else {
      throw LocalIndexError.emptyQuery
    }

    return
      chunks
      .filter {
        $0.filename.localizedCaseInsensitiveContains(query)
          || $0.text.localizedCaseInsensitiveContains(query)
      }
      .prefix(limit)
      .map { $0 }
  }

  public func chunks(for filename: String) -> [IndexedChunk] {
    chunks.filter { $0.filename == filename }
  }

  public func exportContextBundle(title: String, chunks selectedChunks: [IndexedChunk]) -> String {
    var markdown = "# \(title.trimmingCharacters(in: .whitespacesAndNewlines))\n\n"
    for chunk in selectedChunks.sorted(by: { $0.id < $1.id }) {
      markdown += "## \(chunk.filename) #\(chunk.number)\n\n\(chunk.text)\n\n"
    }
    return markdown
  }
}

public struct IndexedChunk: Equatable, Identifiable, Sendable {
  public let id: String
  public let filename: String
  public let url: URL
  public let number: Int
  public let text: String

  public init(id: String, filename: String, url: URL, number: Int, text: String) {
    self.id = id
    self.filename = filename
    self.url = url
    self.number = number
    self.text = text
  }
}

public enum LocalIndexError: Error, Equatable {
  case emptyQuery
  case invalidChunkLength
}
