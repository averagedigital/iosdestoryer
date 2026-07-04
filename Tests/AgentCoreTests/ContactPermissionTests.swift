import XCTest

@testable import AgentCore

final class ContactPermissionTests: XCTestCase {
  func testReturnsCurrentStatusFromProvider() {
    let service = ContactPermissionService(
      provider: StubContactAuthorizationProvider(status: .authorized, requestedStatus: .denied))

    XCTAssertEqual(service.currentStatus(), .authorized)
  }

  func testRequestsAuthorizationThroughProvider() async {
    let service = ContactPermissionService(
      provider: StubContactAuthorizationProvider(
        status: .notDetermined, requestedStatus: .authorized)
    )

    let status = await service.requestAuthorization()

    XCTAssertEqual(status, .authorized)
  }

  func testStatusHasInspectableDisplayName() {
    XCTAssertEqual(ContactPermissionStatus.denied.displayName, "Denied")
    XCTAssertEqual(ContactPermissionStatus.notDetermined.displayName, "Not Determined")
  }
}

private struct StubContactAuthorizationProvider: ContactAuthorizationProviding {
  let status: ContactPermissionStatus
  let requestedStatus: ContactPermissionStatus

  func authorizationStatus() -> ContactPermissionStatus {
    status
  }

  func requestAuthorization() async -> ContactPermissionStatus {
    requestedStatus
  }
}
