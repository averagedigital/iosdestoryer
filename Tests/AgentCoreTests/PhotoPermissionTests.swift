import XCTest

@testable import AgentCore

final class PhotoPermissionTests: XCTestCase {
  func testReturnsCurrentStatusFromProvider() {
    let service = PhotoPermissionService(
      provider: StubPhotoAuthorizationProvider(status: .limited, requestedStatus: .authorized))

    XCTAssertEqual(service.currentStatus(), .limited)
  }

  func testRequestsAuthorizationThroughProvider() async {
    let service = PhotoPermissionService(
      provider: StubPhotoAuthorizationProvider(status: .notDetermined, requestedStatus: .limited))

    let status = await service.requestAuthorization()

    XCTAssertEqual(status, .limited)
  }

  func testStatusHasInspectableDisplayName() {
    XCTAssertEqual(PhotoPermissionStatus.authorized.displayName, "Authorized")
    XCTAssertEqual(PhotoPermissionStatus.notDetermined.displayName, "Not Determined")
  }
}

private struct StubPhotoAuthorizationProvider: PhotoAuthorizationProviding {
  let status: PhotoPermissionStatus
  let requestedStatus: PhotoPermissionStatus

  func authorizationStatus() -> PhotoPermissionStatus {
    status
  }

  func requestAuthorization() async -> PhotoPermissionStatus {
    requestedStatus
  }
}
