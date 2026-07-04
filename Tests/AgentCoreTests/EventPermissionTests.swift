import XCTest

@testable import AgentCore

final class EventPermissionTests: XCTestCase {
  func testReturnsCalendarStatusFromProvider() {
    let service = EventPermissionService(
      provider: StubEventAuthorizationProvider(status: .fullAccess))

    XCTAssertEqual(service.currentStatus(for: .calendar), .fullAccess)
  }

  func testReturnsReminderStatusFromProvider() {
    let service = EventPermissionService(provider: StubEventAuthorizationProvider(status: .denied))

    XCTAssertEqual(service.currentStatus(for: .reminders), .denied)
  }

  func testStatusHasInspectableDisplayName() {
    XCTAssertEqual(EventPermissionStatus.writeOnly.displayName, "Write Only")
    XCTAssertEqual(EventPermissionStatus.notDetermined.displayName, "Not Determined")
  }
}

private struct StubEventAuthorizationProvider: EventAuthorizationProviding {
  let status: EventPermissionStatus

  func authorizationStatus(for entity: EventPermissionEntity) -> EventPermissionStatus {
    status
  }
}
