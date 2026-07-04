import XCTest

@testable import AgentCore

final class NotificationServiceTests: XCTestCase {
  func testReadsPermissionStatusThroughProvider() async {
    let service = NotificationService(provider: StubNotificationProvider())

    let status = await service.permissionStatus()

    XCTAssertEqual(status, .authorized)
  }

  func testRequestsPermissionThroughProvider() async throws {
    let service = NotificationService(provider: StubNotificationProvider())

    let granted = try await service.requestPermission()

    XCTAssertTrue(granted)
  }

  func testSchedulesNotificationThroughProvider() async throws {
    let service = NotificationService(provider: StubNotificationProvider())

    let scheduled = try await service.schedule(
      NotificationDraft(id: "notify-1", title: "Review", body: "Contract", delaySeconds: 60))

    XCTAssertEqual(scheduled.id, "notify-1")
    XCTAssertEqual(scheduled.title, "Review")
    XCTAssertEqual(scheduled.delaySeconds, 60)
  }

  func testRejectsNonPositiveDelay() async {
    let service = NotificationService(provider: StubNotificationProvider())

    do {
      _ = try await service.schedule(
        NotificationDraft(id: "bad", title: "Bad", body: "", delaySeconds: 0))
      XCTFail("Expected invalid delay")
    } catch {
      XCTAssertEqual(error as? NotificationServiceError, .invalidDelay)
    }
  }

  func testCancelsByIdentifier() {
    let provider = StubNotificationProvider()
    let service = NotificationService(provider: provider)

    service.cancel(id: "notify-1")

    XCTAssertEqual(provider.cancelledIDs, ["notify-1"])
  }
}

private final class StubNotificationProvider: NotificationProviding {
  var cancelledIDs: [String] = []

  func permissionStatus() async -> NotificationPermissionStatus {
    .authorized
  }

  func requestPermission() async throws -> Bool {
    true
  }

  func schedule(_ draft: NotificationDraft) async throws -> ScheduledNotification {
    ScheduledNotification(id: draft.id, title: draft.title, delaySeconds: draft.delaySeconds)
  }

  func cancel(id: String) {
    cancelledIDs.append(id)
  }
}
