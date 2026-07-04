import Foundation

public struct FileReadService {
  public init() {}

  public func read(url: URL) throws -> FileDocument {
    do {
      return FileDocument(
        filename: url.lastPathComponent,
        text: try String(contentsOf: url, encoding: .utf8))
    } catch {
      throw FileReadError.notUTF8Text
    }
  }
}

public struct FileDocument: Equatable, Sendable {
  public let filename: String
  public let text: String

  public init(filename: String, text: String) {
    self.filename = filename
    self.text = text
  }
}

public enum FileReadError: Error, Equatable {
  case notUTF8Text
}

extension FileReadError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .notUTF8Text:
      "The selected file is not UTF-8 text."
    }
  }
}
