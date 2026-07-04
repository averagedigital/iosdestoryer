import XCTest

@testable import AgentCore

final class LocalIndexTests: XCTestCase {
  func testRebuildCreatesSearchableChunksFromUTF8Files() throws {
    let temp = try TemporaryDirectory()
    try "water supply contract alpha beta gamma".write(
      to: temp.url.appending(path: "water.txt"), atomically: true, encoding: .utf8)
    try "office receipt".write(
      to: temp.url.appending(path: "receipt.txt"), atomically: true, encoding: .utf8)

    let index = try LocalIndexService(rootDirectory: temp.url, maxChunkLength: 12).rebuild()

    XCTAssertEqual(index.skippedFiles, [])
    XCTAssertGreaterThan(index.chunks.count, 2)
    XCTAssertEqual(try index.search(query: "contract").map(\.filename), ["water.txt"])
  }

  func testRebuildReportsNonTextFilesAsSkipped() throws {
    let temp = try TemporaryDirectory()
    try Data([0xff, 0xfe]).write(to: temp.url.appending(path: "scan.bin"))

    let index = try LocalIndexService(rootDirectory: temp.url).rebuild()

    XCTAssertTrue(index.chunks.isEmpty)
    XCTAssertEqual(
      index.skippedFiles, [SkippedFile(filename: "scan.bin", reason: "not UTF-8 text")])
  }

  func testGetChunksAndExportContextBundle() throws {
    let temp = try TemporaryDirectory()
    try "first chunk second chunk".write(
      to: temp.url.appending(path: "notes.txt"), atomically: true, encoding: .utf8)
    let index = try LocalIndexService(rootDirectory: temp.url, maxChunkLength: 10).rebuild()

    let chunks = index.chunks(for: "notes.txt")
    let markdown = index.exportContextBundle(title: "Notes", chunks: chunks)

    XCTAssertEqual(chunks.map(\.filename), Array(repeating: "notes.txt", count: chunks.count))
    XCTAssertTrue(markdown.contains("# Notes"))
    XCTAssertTrue(markdown.contains("## notes.txt #1"))
    XCTAssertTrue(markdown.contains("first chun"))
  }

  func testSearchRejectsBlankQuery() throws {
    let index = LocalIndex(chunks: [], skippedFiles: [])

    XCTAssertThrowsError(try index.search(query: " ")) { error in
      XCTAssertEqual(error as? LocalIndexError, .emptyQuery)
    }
  }

  func testRebuildRejectsInvalidChunkLength() throws {
    let temp = try TemporaryDirectory()
    let service = LocalIndexService(rootDirectory: temp.url, maxChunkLength: 0)

    XCTAssertThrowsError(try service.rebuild()) { error in
      XCTAssertEqual(error as? LocalIndexError, .invalidChunkLength)
    }
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
