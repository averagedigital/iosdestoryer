import XCTest

@testable import AgentCore

final class AgentCommandRouterTests: XCTestCase {
  private let router = AgentCommandRouter()

  func testRoutesSearchRequestToIndexSearch() {
    XCTAssertEqual(router.route("найди документ по водоснабжению")?.toolName, "index.search")
  }

  func testRoutesReminderRequest() {
    XCTAssertEqual(router.route("поставь напоминание по договору")?.toolName, "reminders.create")
  }

  func testRoutesScanRequest() {
    XCTAssertEqual(router.route("просканируй бумажный акт")?.toolName, "camera.scan_document")
  }

  func testRoutesPhotoSortingRequest() {
    XCTAssertEqual(
      router.route("разбери последние фото и скриншоты")?.toolName,
      "photos.classify_candidates")
  }

  func testRoutesContextBundleRequest() {
    XCTAssertEqual(
      router.route("собери context bundle по теме")?.toolName,
      "index.export_context_bundle")
  }

  func testReturnsNilForUnsupportedMessage() {
    XCTAssertNil(router.route("привет"))
  }
}
