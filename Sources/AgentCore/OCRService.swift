import Foundation

#if canImport(UniformTypeIdentifiers)
  import UniformTypeIdentifiers
#endif

#if canImport(CoreGraphics) && canImport(ImageIO) && canImport(Vision)
  import CoreGraphics
  import ImageIO
  import Vision
#endif

#if canImport(CoreGraphics) && canImport(ImageIO) && canImport(PDFKit)
  import PDFKit
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

  public func recognizeText(inFileAt url: URL) throws -> OCRResult {
    switch OCRFileType(url: url) {
    case .image:
      return try recognizeText(in: Data(contentsOf: url))
    case .pdf:
      return try recognizeTextInPDF(at: url)
    case .unsupported:
      throw OCRServiceError.unsupportedFileType
    }
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
  case unsupportedFileType
  case unsupportedPDFData
  case pdfRenderingUnavailable
  case visionUnavailable
}

extension OCRServiceError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .emptyImageData:
      "Image data is empty."
    case .unsupportedImageData:
      "The selected file is not a supported image."
    case .unsupportedFileType:
      "The selected file is not a supported image or PDF."
    case .unsupportedPDFData:
      "The selected PDF could not be rendered for OCR."
    case .pdfRenderingUnavailable:
      "PDF OCR rendering is not available on this platform."
    case .visionUnavailable:
      "Vision text recognition is not available on this platform."
    }
  }
}

private enum OCRFileType {
  case image
  case pdf
  case unsupported

  init(url: URL) {
    #if canImport(UniformTypeIdentifiers)
      if let type = UTType(filenameExtension: url.pathExtension) {
        if type.conforms(to: .image) {
          self = .image
          return
        }
        if type.conforms(to: .pdf) {
          self = .pdf
          return
        }
      }
    #endif

    switch url.pathExtension.lowercased() {
    case "png", "jpg", "jpeg", "heic", "tiff", "gif":
      self = .image
    case "pdf":
      self = .pdf
    default:
      self = .unsupported
    }
  }
}

extension OCRService {
  private func recognizeTextInPDF(at url: URL) throws -> OCRResult {
    #if canImport(CoreGraphics) && canImport(ImageIO) && canImport(PDFKit)
      guard let document = PDFDocument(url: url), document.pageCount > 0 else {
        throw OCRServiceError.unsupportedPDFData
      }

      var observations: [OCRTextObservation] = []
      for pageIndex in 0..<document.pageCount {
        guard let page = document.page(at: pageIndex) else { continue }
        let pageData = try renderPageImageData(page)
        observations.append(contentsOf: try recognizer.recognizeText(in: pageData))
      }

      return OCRResult(
        text: observations.map(\.text).joined(separator: "\n"),
        observations: observations)
    #else
      throw OCRServiceError.pdfRenderingUnavailable
    #endif
  }

  #if canImport(CoreGraphics) && canImport(ImageIO) && canImport(PDFKit)
    private func renderPageImageData(_ page: PDFPage) throws -> Data {
      let bounds = page.bounds(for: .mediaBox)
      let scale: CGFloat = 2
      let width = max(Int(bounds.width * scale), 1)
      let height = max(Int(bounds.height * scale), 1)
      let colorSpace = CGColorSpaceCreateDeviceRGB()

      guard
        let context = CGContext(
          data: nil,
          width: width,
          height: height,
          bitsPerComponent: 8,
          bytesPerRow: 0,
          space: colorSpace,
          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
      else {
        throw OCRServiceError.unsupportedPDFData
      }

      context.setFillColor(CGColor(gray: 1, alpha: 1))
      context.fill(CGRect(x: 0, y: 0, width: width, height: height))
      context.saveGState()
      context.scaleBy(x: scale, y: scale)
      context.translateBy(x: -bounds.minX, y: bounds.height - bounds.minY)
      context.scaleBy(x: 1, y: -1)
      page.draw(with: .mediaBox, to: context)
      context.restoreGState()

      guard let image = context.makeImage() else {
        throw OCRServiceError.unsupportedPDFData
      }

      let data = NSMutableData()
      #if canImport(UniformTypeIdentifiers)
        let pngIdentifier = UTType.png.identifier as CFString
      #else
        let pngIdentifier = "public.png" as CFString
      #endif

      guard let destination = CGImageDestinationCreateWithData(data, pngIdentifier, 1, nil) else {
        throw OCRServiceError.unsupportedPDFData
      }
      CGImageDestinationAddImage(destination, image, nil)
      guard CGImageDestinationFinalize(destination) else {
        throw OCRServiceError.unsupportedPDFData
      }
      return data as Data
    }
  #endif
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
