import XCTest

@testable import AgentCore

final class ContactPermissionTests: XCTestCase {
  func testReturnsCurrentStatusFromProvider() {
    let service = ContactPermissionService(
      provider: StubContactAuthorizationProvider(status: .authorized))

    XCTAssertEqual(service.currentStatus(), .authorized)
  }

  func testStatusHasInspectableDisplayName() {
    XCTAssertEqual(ContactPermissionStatus.denied.displayName, "Denied")
    XCTAssertEqual(ContactPermissionStatus.notDetermined.displayName, "Not Determined")
  }
}

private struct StubContactAuthorizationProvider: ContactAuthorizationProviding {
  let status: ContactPermissionStatus

  func authorizationStatus() -> ContactPermissionStatus {
    status
  }
}
