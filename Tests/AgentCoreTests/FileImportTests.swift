import XCTest

@testable import AgentCore

final class FileImportTests: XCTestCase {
  func testImportCopiesPickedFileIntoAppContainer() throws {
    let temp = try TemporaryDirectory()
    let source = temp.url.appending(path: "contract.txt")
    try "signed".write(to: source, atomically: true, encoding: .utf8)
    let service = FileImportService(importsDirectory: temp.url.appending(path: "Imports"))

    let imported = try service.importPickedFile(from: source)

    XCTAssertEqual(imported.originalFilename, "contract.txt")
    XCTAssertEqual(try String(contentsOf: imported.localURL, encoding: .utf8), "signed")
    XCTAssertTrue(imported.localURL.path.hasPrefix(service.importsDirectory.path))
  }

  func testImportKeepsExistingFileOnNameCollision() throws {
    let temp = try TemporaryDirectory()
    let source = temp.url.appending(path: "scan.txt")
    try "first".write(to: source, atomically: true, encoding: .utf8)
    let service = FileImportService(importsDirectory: temp.url.appending(path: "Imports"))

    let first = try service.importPickedFile(from: source)
    try "second".write(to: source, atomically: true, encoding: .utf8)
    let second = try service.importPickedFile(from: source)

    XCTAssertNotEqual(first.localURL, second.localURL)
    XCTAssertEqual(try String(contentsOf: first.localURL, encoding: .utf8), "first")
    XCTAssertEqual(try String(contentsOf: second.localURL, encoding: .utf8), "second")
  }

  func testImportRecordsAuditEntry() throws {
    let temp = try TemporaryDirectory()
    let source = temp.url.appending(path: "receipt.txt")
    try "42".write(to: source, atomically: true, encoding: .utf8)
    let service = FileImportService(importsDirectory: temp.url.appending(path: "Imports"))
    var auditLog = AuditLog()

    _ = try service.importPickedFile(from: source, auditLog: &auditLog)

    XCTAssertEqual(auditLog.entries.last?.toolName, "files.pick_file")
    XCTAssertEqual(auditLog.entries.last?.status, .succeeded)
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
