import Foundation

public struct ContextBundleService {
  public init() {}

  public func build(title: String, files: [FileSearchResult]) throws -> ContextBundle {
    var markdown = "# \(title.trimmingCharacters(in: .whitespacesAndNewlines))\n\n"
    var skippedFiles: [SkippedFile] = []

    for file in files.sorted(by: { $0.filename < $1.filename }) {
      do {
        let text = try String(contentsOf: file.url, encoding: .utf8)
        markdown += "## \(file.filename)\n\n\(text)\n\n"
      } catch {
        skippedFiles.append(
          SkippedFile(filename: file.filename, reason: "not UTF-8 text"))
      }
    }

    return ContextBundle(markdown: markdown, skippedFiles: skippedFiles)
  }
}

public struct ContextBundle: Equatable, Sendable {
  public let markdown: String
  public let skippedFiles: [SkippedFile]

  public init(markdown: String, skippedFiles: [SkippedFile]) {
    self.markdown = markdown
    self.skippedFiles = skippedFiles
  }
}
