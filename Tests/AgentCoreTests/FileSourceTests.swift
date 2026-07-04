import XCTest

@testable import AgentCore

final class FileSourceTests: XCTestCase {
  func testListsImportsDirectoryAsAllowedSource() throws {
    let temp = try TemporaryDirectory()
    let imports = temp.url.appending(path: "Imports", directoryHint: .isDirectory)

    let sources = try FileSourceService(importsDirectory: imports).listAllowedSources()

    XCTAssertEqual(sources, [AllowedFileSource(name: "Imports", url: imports)])
    XCTAssertTrue(FileManager.default.fileExists(atPath: imports.path))
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
