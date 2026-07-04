import XCTest

@testable import AgentCore

final class FileReadTests: XCTestCase {
  func testReadsUTF8File() throws {
    let temp = try TemporaryDirectory()
    let file = temp.url.appending(path: "contract.txt")
    try "water supply".write(to: file, atomically: true, encoding: .utf8)

    let document = try FileReadService().read(url: file)

    XCTAssertEqual(document.filename, "contract.txt")
    XCTAssertEqual(document.text, "water supply")
  }

  func testRejectsNonTextFile() throws {
    let temp = try TemporaryDirectory()
    let file = temp.url.appending(path: "scan.bin")
    try Data([0xff, 0xfe]).write(to: file)

    XCTAssertThrowsError(try FileReadService().read(url: file)) { error in
      XCTAssertEqual(error as? FileReadError, .notUTF8Text)
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
