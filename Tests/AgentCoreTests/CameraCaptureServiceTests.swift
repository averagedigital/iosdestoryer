import XCTest

@testable import AgentCore

final class CameraCaptureServiceTests: XCTestCase {
  func testSavesCapturedPhotoData() throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    let service = CameraCaptureService(directory: directory)

    let capture = try service.savePhoto(Data([1, 2, 3]), fileName: "photo.jpg")

    XCTAssertEqual(capture.kind, .photo)
    XCTAssertEqual(capture.fileURL.lastPathComponent, "photo.jpg")
    XCTAssertEqual(try Data(contentsOf: capture.fileURL), Data([1, 2, 3]))
  }

  func testSavesScannedDocumentPages() throws {
    let directory = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
    let service = CameraCaptureService(directory: directory)

    let scan = try service.saveScannedDocument([Data([1]), Data([2])], basename: "scan")

    XCTAssertEqual(scan.kind, .documentScan)
    XCTAssertEqual(scan.pageCount, 2)
    XCTAssertEqual(scan.pageURLs.map(\.lastPathComponent), ["scan-1.jpg", "scan-2.jpg"])
  }

  func testRejectsEmptyCaptureData() {
    let service = CameraCaptureService(directory: URL.temporaryDirectory)

    XCTAssertThrowsError(try service.savePhoto(Data(), fileName: "photo.jpg")) { error in
      XCTAssertEqual(error as? CameraCaptureServiceError, .emptyImageData)
    }
  }
}
