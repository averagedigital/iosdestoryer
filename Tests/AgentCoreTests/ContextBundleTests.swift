import XCTest

@testable import AgentCore

final class ContextBundleTests: XCTestCase {
  func testBuildsMarkdownBundleFromTextFiles() throws {
    let temp = try TemporaryDirectory()
    let first = temp.url.appending(path: "b.txt")
    let second = temp.url.appending(path: "a.txt")
    try "second body".write(to: first, atomically: true, encoding: .utf8)
    try "first body".write(to: second, atomically: true, encoding: .utf8)
    let service = ContextBundleService()

    let bundle = try service.build(
      title: "Water",
      files: [
        FileSearchResult(filename: first.lastPathComponent, url: first),
        FileSearchResult(filename: second.lastPathComponent, url: second),
      ])

    XCTAssertTrue(bundle.markdown.hasPrefix("# Water\n\n"))
    XCTAssertLessThan(
      bundle.markdown.range(of: "## a.txt")!.lowerBound,
      bundle.markdown.range(of: "## b.txt")!.lowerBound)
    XCTAssertTrue(bundle.markdown.contains("first body"))
    XCTAssertTrue(bundle.markdown.contains("second body"))
    XCTAssertTrue(bundle.skippedFiles.isEmpty)
  }

  func testReportsUnreadableFilesAsSkipped() throws {
    let temp = try TemporaryDirectory()
    let binary = temp.url.appending(path: "scan.bin")
    try Data([0xff, 0xfe]).write(to: binary)
    let service = ContextBundleService()

    let bundle = try service.build(
      title: "Scan",
      files: [FileSearchResult(filename: binary.lastPathComponent, url: binary)])

    XCTAssertFalse(bundle.markdown.contains("## scan.bin"))
    XCTAssertEqual(bundle.skippedFiles.map(\.filename), ["scan.bin"])
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
