import XCTest

@testable import AgentCore

final class EventPermissionTests: XCTestCase {
  func testReturnsCalendarStatusFromProvider() {
    let service = EventPermissionService(
      provider: StubEventAuthorizationProvider(status: .fullAccess, requestedStatus: .denied))

    XCTAssertEqual(service.currentStatus(for: .calendar), .fullAccess)
  }

  func testReturnsReminderStatusFromProvider() {
    let service = EventPermissionService(
      provider: StubEventAuthorizationProvider(status: .denied, requestedStatus: .fullAccess))

    XCTAssertEqual(service.currentStatus(for: .reminders), .denied)
  }

  func testRequestsAuthorizationThroughProvider() async {
    let provider = StubEventAuthorizationProvider(
      status: .notDetermined, requestedStatus: .fullAccess)
    let service = EventPermissionService(provider: provider)

    let status = await service.requestAuthorization(for: .reminders)

    XCTAssertEqual(status, .fullAccess)
  }

  func testStatusHasInspectableDisplayName() {
    XCTAssertEqual(EventPermissionStatus.writeOnly.displayName, "Write Only")
    XCTAssertEqual(EventPermissionStatus.notDetermined.displayName, "Not Determined")
  }
}

private struct StubEventAuthorizationProvider: EventAuthorizationProviding {
  let status: EventPermissionStatus
  let requestedStatus: EventPermissionStatus

  func authorizationStatus(for entity: EventPermissionEntity) -> EventPermissionStatus {
    status
  }

  func requestAuthorization(for entity: EventPermissionEntity) async -> EventPermissionStatus {
    requestedStatus
  }
}
