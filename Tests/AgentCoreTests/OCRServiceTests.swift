import CoreGraphics
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

  func testRecognizesTextFromImageFile() throws {
    let directory = FileManager.default.temporaryDirectory.appending(
      path: UUID().uuidString, directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let url = directory.appending(path: "scan.png")
    try Data([7, 8, 9]).write(to: url)
    let service = OCRService(
      recognizer: StubOCRRecognizer(observations: [
        OCRTextObservation(text: "Act 42", confidence: 0.95)
      ]))

    let result = try service.recognizeText(inFileAt: url)

    XCTAssertEqual(result.text, "Act 42")
  }

  func testRecognizesTextFromPDFFile() throws {
    let directory = FileManager.default.temporaryDirectory.appending(
      path: UUID().uuidString, directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let url = directory.appending(path: "scan.pdf")
    try writeBlankPDF(to: url)
    let service = OCRService(
      recognizer: StubOCRRecognizer(observations: [
        OCRTextObservation(text: "PDF Page", confidence: 0.88)
      ]))

    let result = try service.recognizeText(inFileAt: url)

    XCTAssertEqual(result.text, "PDF Page")
  }

  func testRejectsUnsupportedOCRFileType() throws {
    let directory = FileManager.default.temporaryDirectory.appending(
      path: UUID().uuidString, directoryHint: .isDirectory)
    try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
    let url = directory.appending(path: "notes.txt")
    try Data([1]).write(to: url)
    let service = OCRService(recognizer: StubOCRRecognizer(observations: []))

    XCTAssertThrowsError(try service.recognizeText(inFileAt: url)) { error in
      XCTAssertEqual(error as? OCRServiceError, .unsupportedFileType)
    }
  }
}

private func writeBlankPDF(to url: URL) throws {
  guard let consumer = CGDataConsumer(url: url as CFURL) else {
    XCTFail("Could not create PDF data consumer.")
    return
  }
  var mediaBox = CGRect(x: 0, y: 0, width: 100, height: 100)
  guard let context = CGContext(consumer: consumer, mediaBox: &mediaBox, nil) else {
    XCTFail("Could not create PDF context.")
    return
  }
  context.beginPDFPage(nil)
  context.setFillColor(CGColor(gray: 1, alpha: 1))
  context.fill(mediaBox)
  context.endPDFPage()
  context.closePDF()
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
