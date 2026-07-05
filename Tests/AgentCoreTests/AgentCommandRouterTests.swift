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

  func testRoutesNotificationRequest() {
    XCTAssertEqual(router.route("создай уведомление через минуту")?.toolName, "notify.schedule")
  }

  func testRoutesAudioRecordingRequest() {
    XCTAssertEqual(router.route("запиши аудио заметку")?.toolName, "audio.record")
  }

  func testRoutesShortcutRequest() {
    XCTAssertEqual(
      router.route("запусти shortcut Daily Review")?.toolName,
      "shortcuts.run_user_configured_shortcut")
  }

  func testRoutesLocalClassificationRequest() {
    XCTAssertEqual(
      router.route("классифицируй текст договора")?.toolName,
      "local_model.classify_if_available")
  }

  func testRoutesContextBundleRequest() {
    XCTAssertEqual(
      router.route("собери context bundle по теме")?.toolName,
      "index.export_context_bundle")
  }

  func testRoutesFolderIndexRequest() {
    XCTAssertEqual(router.route("проиндексируй папку")?.toolName, "files.index_folder")
  }

  func testRoutesGetChunksRequest() {
    XCTAssertEqual(router.route("покажи чанки water.txt")?.toolName, "index.get_chunks")
  }

  func testReturnsNilForUnsupportedMessage() {
    XCTAssertNil(router.route("привет"))
  }
}
