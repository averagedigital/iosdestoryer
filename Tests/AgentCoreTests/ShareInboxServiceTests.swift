import XCTest

@testable import AgentCore

final class ShareInboxServiceTests: XCTestCase {
  func testImportsTextAndListsSharedInbox() throws {
    let temp = try TemporaryDirectory()
    let service = ShareInboxService(inboxDirectory: temp.url)

    let item = try service.importText("contract notes", preferredName: "contract")
    let items = try service.listItems()

    XCTAssertEqual(item.kind, .text)
    XCTAssertEqual(items, [item])
    XCTAssertEqual(try String(contentsOf: item.url, encoding: .utf8), "contract notes")
  }

  func testImportUsesAvailableNameOnCollision() throws {
    let temp = try TemporaryDirectory()
    let service = ShareInboxService(inboxDirectory: temp.url)

    let first = try service.importText("first", preferredName: "note")
    let second = try service.importText("second", preferredName: "note")

    XCTAssertEqual(first.url.lastPathComponent, "note.txt")
    XCTAssertEqual(second.url.lastPathComponent, "note-2.txt")
  }

  func testImportsURLAndImageKinds() throws {
    let temp = try TemporaryDirectory()
    let service = ShareInboxService(inboxDirectory: temp.url)

    let urlItem = try service.importURL(URL(string: "https://example.com/doc")!)
    let imageItem = try service.importImage(Data([9, 8, 7]))

    XCTAssertEqual(urlItem.kind, .url)
    XCTAssertEqual(imageItem.kind, .image)
  }

  func testImportsFileCopyIntoInbox() throws {
    let temp = try TemporaryDirectory()
    let source = temp.url.appending(path: "source.pdf")
    try Data([1, 2, 3]).write(to: source)
    let inbox = temp.url.appending(path: "Inbox", directoryHint: .isDirectory)

    let item = try ShareInboxService(inboxDirectory: inbox).importFile(from: source)

    XCTAssertEqual(item.kind, .file)
    XCTAssertEqual(try Data(contentsOf: item.url), Data([1, 2, 3]))
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
