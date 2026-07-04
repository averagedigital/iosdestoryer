import XCTest

@testable import AgentCore

final class FileSearchTests: XCTestCase {
  func testSearchFindsImportedFilesByNameAndContent() throws {
    let temp = try TemporaryDirectory()
    try "pump station notes".write(
      to: temp.url.appending(path: "water-contract.txt"), atomically: true, encoding: .utf8)
    try "invoice for office".write(
      to: temp.url.appending(path: "receipt.txt"), atomically: true, encoding: .utf8)
    let service = FileSearchService(rootDirectory: temp.url)

    let report = try service.search(query: "water")

    XCTAssertEqual(report.matches.map(\.filename), ["water-contract.txt"])
    XCTAssertTrue(report.skippedFiles.isEmpty)
  }

  func testSearchRejectsBlankQuery() throws {
    let service = FileSearchService(rootDirectory: FileManager.default.temporaryDirectory)

    XCTAssertThrowsError(try service.search(query: "  ")) { error in
      XCTAssertEqual(error as? FileSearchError, .emptyQuery)
    }
  }

  func testSearchReportsNonTextFilesAsSkipped() throws {
    let temp = try TemporaryDirectory()
    try Data([0xff, 0xfe]).write(to: temp.url.appending(path: "scan.bin"))
    let service = FileSearchService(rootDirectory: temp.url)

    let report = try service.search(query: "scan")

    XCTAssertTrue(report.matches.isEmpty)
    XCTAssertEqual(report.skippedFiles.map(\.filename), ["scan.bin"])
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
