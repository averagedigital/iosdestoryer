import Foundation

#if canImport(NaturalLanguage)
  import NaturalLanguage
#endif

public struct LocalModelService {
  private let provider: any LocalModelProvider

  public init(provider: any LocalModelProvider = NaturalLanguageLocalModelProvider()) {
    self.provider = provider
  }

  public func availability() -> LocalModelAvailability {
    provider.availability
  }

  public func summarize(_ text: String) throws -> String {
    try validate(text)
    guard provider.availability.summarize.isAvailable else {
      throw LocalModelError.unavailable("local_model.summarize_if_available")
    }
    return try provider.summarize(text)
  }

  public func classify(_ text: String) throws -> LocalModelClassification {
    try validate(text)
    guard provider.availability.classify.isAvailable else {
      throw LocalModelError.unavailable("local_model.classify_if_available")
    }
    return try provider.classify(text)
  }

  public func embed(_ text: String) throws -> [Double] {
    try validate(text)
    guard provider.availability.embed.isAvailable else {
      throw LocalModelError.unavailable("local_model.embed_if_available")
    }
    return try provider.embed(text)
  }

  private func validate(_ text: String) throws {
    if text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
      throw LocalModelError.emptyInput
    }
  }
}

public protocol LocalModelProvider: Sendable {
  var availability: LocalModelAvailability { get }
  func summarize(_ text: String) throws -> String
  func classify(_ text: String) throws -> LocalModelClassification
  func embed(_ text: String) throws -> [Double]
}

public struct LocalModelAvailability: Equatable, Sendable {
  public let summarize: LocalModelCapability
  public let classify: LocalModelCapability
  public let embed: LocalModelCapability

  public init(
    summarize: LocalModelCapability,
    classify: LocalModelCapability,
    embed: LocalModelCapability
  ) {
    self.summarize = summarize
    self.classify = classify
    self.embed = embed
  }
}

public struct LocalModelCapability: Equatable, Sendable {
  public let isAvailable: Bool
  public let reason: String

  public init(isAvailable: Bool, reason: String) {
    self.isAvailable = isAvailable
    self.reason = reason
  }
}

public struct LocalModelClassification: Equatable, Sendable {
  public let label: String
  public let confidence: Double

  public init(label: String, confidence: Double) {
    self.label = label
    self.confidence = confidence
  }
}

public enum LocalModelError: Error, Equatable {
  case emptyInput
  case unavailable(String)
}

extension LocalModelError: LocalizedError {
  public var errorDescription: String? {
    switch self {
    case .emptyInput:
      "Input text is empty."
    case .unavailable(let toolName):
      "\(toolName) is unavailable on this device or no local model is bundled."
    }
  }
}

public struct NaturalLanguageLocalModelProvider: LocalModelProvider {
  public init() {}

  public var availability: LocalModelAvailability {
    LocalModelAvailability(
      summarize: LocalModelCapability(
        isAvailable: false, reason: "No bundled local summarization model."),
      classify: LocalModelCapability(
        isAvailable: Self.isNaturalLanguageAvailable,
        reason: Self.isNaturalLanguageAvailable
          ? "NaturalLanguage NLLanguageRecognizer is available."
          : "NaturalLanguage framework is unavailable."),
      embed: LocalModelCapability(isAvailable: false, reason: "No bundled local embedding model."))
  }

  public func summarize(_ text: String) throws -> String {
    throw LocalModelError.unavailable("local_model.summarize_if_available")
  }

  public func classify(_ text: String) throws -> LocalModelClassification {
    #if canImport(NaturalLanguage)
      let recognizer = NLLanguageRecognizer()
      recognizer.processString(text)
      guard let best = recognizer.languageHypotheses(withMaximum: 1).first else {
        throw LocalModelError.unavailable("local_model.classify_if_available")
      }
      return LocalModelClassification(label: best.key.rawValue, confidence: Double(best.value))
    #else
      throw LocalModelError.unavailable("local_model.classify_if_available")
    #endif
  }

  public func embed(_ text: String) throws -> [Double] {
    throw LocalModelError.unavailable("local_model.embed_if_available")
  }

  private static var isNaturalLanguageAvailable: Bool {
    #if canImport(NaturalLanguage)
      true
    #else
      false
    #endif
  }
}
