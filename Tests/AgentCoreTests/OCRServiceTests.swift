import Foundation
import XCTest

@testable import AgentCore

final class OCRServiceTests: XCTestCase {
  func testRecognizesTextWithInjectedRecognizer() throws {
    let service = OCRService(
      recognizer: StubOCRRecognizer(observations: [
        OCRTextObservation(text: "Invoice", confidence: 0.9),
        OCRTextObservation(text: "Total 100", confidence: 0.8),
      ]))

    let result = try service.recognizeText(in: Data([1, 2, 3]))

    XCTAssertEqual(result.text, "Invoice\nTotal 100")
    XCTAssertEqual(result.observations.map(\.text), ["Invoice", "Total 100"])
  }

  func testDetectsBarcodesWithInjectedRecognizer() throws {
    let service = OCRService(
      recognizer: StubOCRRecognizer(
        observations: [],
        barcodes: [BarcodeObservation(payload: "123456", symbology: "QR", confidence: 0.7)]))

    let result = try service.detectBarcodes(in: Data([1, 2, 3]))

    XCTAssertEqual(result.barcodes.map(\.payload), ["123456"])
  }

  func testRejectsEmptyImageData() {
    let service = OCRService(recognizer: StubOCRRecognizer(observations: []))

    XCTAssertThrowsError(try service.recognizeText(in: Data())) { error in
      XCTAssertEqual(error as? OCRServiceError, .emptyImageData)
    }
  }
}

private struct StubOCRRecognizer: OCRRecognizing {
  let observations: [OCRTextObservation]
  var barcodes: [BarcodeObservation] = []

  func recognizeText(in imageData: Data) throws -> [OCRTextObservation] {
    observations
  }

  func detectBarcodes(in imageData: Data) throws -> [BarcodeObservation] {
    barcodes
  }
}
