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

  func testRejectsEmptyImageData() {
    let service = OCRService(recognizer: StubOCRRecognizer(observations: []))

    XCTAssertThrowsError(try service.recognizeText(in: Data())) { error in
      XCTAssertEqual(error as? OCRServiceError, .emptyImageData)
    }
  }
}

private struct StubOCRRecognizer: OCRRecognizing {
  let observations: [OCRTextObservation]

  func recognizeText(in imageData: Data) throws -> [OCRTextObservation] {
    observations
  }
}
