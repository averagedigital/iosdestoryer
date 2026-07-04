import Foundation

#if canImport(CoreGraphics) && canImport(ImageIO) && canImport(Vision)
  import CoreGraphics
  import ImageIO
  import Vision
#endif

public struct OCRService {
  private let recognizer: any OCRRecognizing

  public init(recognizer: any OCRRecognizing = VisionTextRecognizer()) {
    self.recognizer = recognizer
  }

  public func recognizeText(in imageData: Data) throws -> OCRResult {
    guard !imageData.isEmpty else {
      throw OCRServiceError.emptyImageData
    }

    let observations = try recognizer.recognizeText(in: imageData)
    return OCRResult(
      text: observations.map(\.text).joined(separator: "\n"),
      observations: observations)
  }

  public func detectBarcodes(in imageData: Data) throws -> BarcodeResult {
    guard !imageData.isEmpty else {
      throw OCRServiceError.emptyImageData
    }

    return BarcodeResult(barcodes: try recognizer.detectBarcodes(in: imageData))
  }
}

public protocol OCRRecognizing {
  func recognizeText(in imageData: Data) throws -> [OCRTextObservation]
  func detectBarcodes(in imageData: Data) throws -> [BarcodeObservation]
}

public struct OCRResult: Equatable, Sendable {
  public let text: String
  public let observations: [OCRTextObservation]

  public init(text: String, observations: [OCRTextObservation]) {
    self.text = text
    self.observations = observations
  }
}

public struct OCRTextObservation: Equatable, Sendable {
  public let text: String
  public let confidence: Float

  public init(text: String, confidence: Float) {
    self.text = text
    self.confidence = confidence
  }
}

public struct BarcodeResult: Equatable, Sendable {
  public let barcodes: [BarcodeObservation]

  public init(barcodes: [BarcodeObservation]) {
    self.barcodes = barcodes
  }
}

public struct BarcodeObservation: Equatable, Sendable {
  public let payload: String
  public let symbology: String
  public let confidence: Float

  public init(payload: String, symbology: String, confidence: Float) {
    self.payload = payload
    self.symbology = symbology
    self.confidence = confidence
  }
}

public enum OCRServiceError: Error, Equatable {
  case emptyImageData
  case unsupportedImageData
  case visionUnavailable
}

extension OCRServiceError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .emptyImageData:
      "Image data is empty."
    case .unsupportedImageData:
      "The selected file is not a supported image."
    case .visionUnavailable:
      "Vision text recognition is not available on this platform."
    }
  }
}

#if canImport(CoreGraphics) && canImport(ImageIO) && canImport(Vision)
  public struct VisionTextRecognizer: OCRRecognizing {
    public init() {}

    public func recognizeText(in imageData: Data) throws -> [OCRTextObservation] {
      guard
        let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
        let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
      else {
        throw OCRServiceError.unsupportedImageData
      }

      let request = VNRecognizeTextRequest()
      request.recognitionLevel = .accurate

      let handler = VNImageRequestHandler(cgImage: image)
      try handler.perform([request])

      return (request.results ?? []).compactMap { observation in
        guard let candidate = observation.topCandidates(1).first else {
          return nil
        }
        return OCRTextObservation(text: candidate.string, confidence: candidate.confidence)
      }
    }

    public func detectBarcodes(in imageData: Data) throws -> [BarcodeObservation] {
      guard
        let imageSource = CGImageSourceCreateWithData(imageData as CFData, nil),
        let image = CGImageSourceCreateImageAtIndex(imageSource, 0, nil)
      else {
        throw OCRServiceError.unsupportedImageData
      }

      let request = VNDetectBarcodesRequest()
      let handler = VNImageRequestHandler(cgImage: image)
      try handler.perform([request])

      return (request.results ?? []).compactMap { observation in
        guard let payload = observation.payloadStringValue else {
          return nil
        }
        return BarcodeObservation(
          payload: payload,
          symbology: observation.symbology.rawValue,
          confidence: observation.confidence)
      }
    }
  }
#else
  public struct VisionTextRecognizer: OCRRecognizing {
    public init() {}

    public func recognizeText(in imageData: Data) throws -> [OCRTextObservation] {
      throw OCRServiceError.visionUnavailable
    }

    public func detectBarcodes(in imageData: Data) throws -> [BarcodeObservation] {
      throw OCRServiceError.visionUnavailable
    }
  }
#endif
