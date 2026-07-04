import XCTest

@testable import AgentCore

final class PhotoPermissionTests: XCTestCase {
  func testReturnsCurrentStatusFromProvider() {
    let service = PhotoPermissionService(
      provider: StubPhotoAuthorizationProvider(status: .limited))

    XCTAssertEqual(service.currentStatus(), .limited)
  }

  func testStatusHasInspectableDisplayName() {
    XCTAssertEqual(PhotoPermissionStatus.authorized.displayName, "Authorized")
    XCTAssertEqual(PhotoPermissionStatus.notDetermined.displayName, "Not Determined")
  }
}

private struct StubPhotoAuthorizationProvider: PhotoAuthorizationProviding {
  let status: PhotoPermissionStatus

  func authorizationStatus() -> PhotoPermissionStatus {
    status
  }
}
