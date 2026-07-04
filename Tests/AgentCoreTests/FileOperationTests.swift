import XCTest

@testable import AgentCore

final class FileOperationTests: XCTestCase {
  func testWritesCopiesMovesExtractsAndDeletesInsideRoot() throws {
    let temp = try TemporaryDirectory()
    let service = FileOperationService(rootDirectory: temp.url)

    let written = try service.writeText("water supply", to: "docs/source.txt")
    XCTAssertEqual(written.filename, "source.txt")

    let copied = try service.copy(from: "docs/source.txt", to: "docs/copy.txt")
    XCTAssertEqual(try String(contentsOf: copied.url, encoding: .utf8), "water supply")

    let moved = try service.move(from: "docs/copy.txt", to: "archive/moved.txt")
    XCTAssertEqual(moved.filename, "moved.txt")
    XCTAssertFalse(
      FileManager.default.fileExists(atPath: temp.url.appending(path: "docs/copy.txt").path))

    let document = try service.extractText(from: "archive/moved.txt")
    XCTAssertEqual(document.text, "water supply")

    let preview = try service.deletePreview(for: "archive/moved.txt")
    XCTAssertEqual(preview.filename, "moved.txt")
    XCTAssertTrue(FileManager.default.fileExists(atPath: preview.url.path))

    try service.delete(preview)
    XCTAssertFalse(FileManager.default.fileExists(atPath: preview.url.path))
  }

  func testRejectsPathsOutsideRoot() throws {
    let temp = try TemporaryDirectory()
    let service = FileOperationService(rootDirectory: temp.url)

    XCTAssertThrowsError(try service.writeText("nope", to: "../escape.txt")) { error in
      XCTAssertEqual(error as? FileOperationError, .pathEscapesRoot("../escape.txt"))
    }
    XCTAssertThrowsError(try service.copy(from: "/tmp/source.txt", to: "copy.txt")) { error in
      XCTAssertEqual(error as? FileOperationError, .pathEscapesRoot("/tmp/source.txt"))
    }
  }

  func testWriteDoesNotOverwriteExistingFile() throws {
    let temp = try TemporaryDirectory()
    let service = FileOperationService(rootDirectory: temp.url)

    _ = try service.writeText("first", to: "note.txt")

    XCTAssertThrowsError(try service.writeText("second", to: "note.txt")) { error in
      XCTAssertEqual(error as? FileOperationError, .destinationExists("note.txt"))
    }
    XCTAssertEqual(
      try String(contentsOf: temp.url.appending(path: "note.txt"), encoding: .utf8), "first")
  }
}

private struct TemporaryDirectory {
  let url: URL

  init() throws {
    url = FileManager.default.temporaryDirectory.appending(
      path: UUID().uuidString, directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
  }
}
