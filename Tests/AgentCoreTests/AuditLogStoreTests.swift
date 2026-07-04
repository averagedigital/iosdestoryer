import XCTest

@testable import AgentCore

final class AuditLogStoreTests: XCTestCase {
  func testSavesAndLoadsAuditLog() throws {
    let temp = FileManager.default.temporaryDirectory.appending(
      path: UUID().uuidString,
      directoryHint: .isDirectory)
    addTeardownBlock {
      try? FileManager.default.removeItem(at: temp)
    }
    let store = AuditLogStore(fileURL: temp.appending(path: "audit-log.json"))
    var log = AuditLog()
    let date = Date(timeIntervalSince1970: 100)
    log.record(toolName: "files.search", summary: "2 matches", status: .succeeded, date: date)

    try store.save(log)

    XCTAssertEqual(try store.load(), log)
  }

  func testMissingAuditLogLoadsEmptyLog() throws {
    let store = AuditLogStore(
      fileURL: URL.temporaryDirectory.appending(path: UUID().uuidString))

    XCTAssertEqual(try store.load(), AuditLog())
  }
}
