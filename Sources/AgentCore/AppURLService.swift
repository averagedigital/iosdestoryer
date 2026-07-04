import Foundation

#if canImport(UIKit)
  import UIKit
#endif

public struct AppURLService {
  private let provider: any URLOpening

  public init(provider: any URLOpening = SystemURLOpener()) {
    self.provider = provider
  }

  public func openURL(_ url: URL) async throws -> OpenedURL {
    guard ["http", "https"].contains(url.scheme?.lowercased()) else {
      throw AppURLServiceError.unsupportedScheme(url.scheme ?? "")
    }
    return try await open(url, kind: .url)
  }

  public func openDeepLink(_ url: URL) async throws -> OpenedURL {
    guard let scheme = url.scheme, !scheme.isEmpty else {
      throw AppURLServiceError.missingScheme
    }
    return try await open(url, kind: .deepLink)
  }

  public func runShortcut(named name: String, text: String? = nil) async throws -> OpenedURL {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else {
      throw AppURLServiceError.blankShortcutName
    }

    var components = URLComponents()
    components.scheme = "shortcuts"
    components.host = "run-shortcut"
    components.queryItems = [URLQueryItem(name: "name", value: trimmedName)]
    if let text = text?.trimmingCharacters(in: .whitespacesAndNewlines), !text.isEmpty {
      components.queryItems?.append(URLQueryItem(name: "input", value: "text"))
      components.queryItems?.append(URLQueryItem(name: "text", value: text))
    }
    guard let url = components.url else {
      throw AppURLServiceError.invalidShortcutURL
    }
    return try await open(url, kind: .shortcut)
  }

  private func open(_ url: URL, kind: OpenedURL.Kind) async throws -> OpenedURL {
    let opened = await provider.open(url)
    guard opened else {
      throw AppURLServiceError.openRejected
    }
    return OpenedURL(kind: kind, url: url)
  }
}

public protocol URLOpening {
  func open(_ url: URL) async -> Bool
}

public struct OpenedURL: Equatable, Sendable {
  public enum Kind: String, Sendable {
    case url
    case deepLink
    case shortcut
  }

  public let kind: Kind
  public let url: URL

  public init(kind: Kind, url: URL) {
    self.kind = kind
    self.url = url
  }
}

public enum AppURLServiceError: Error, Equatable {
  case missingScheme
  case unsupportedScheme(String)
  case blankShortcutName
  case invalidShortcutURL
  case openRejected
}

#if canImport(UIKit)
  public struct SystemURLOpener: URLOpening {
    public init() {}

    @MainActor
    public func open(_ url: URL) async -> Bool {
      await UIApplication.shared.open(url)
    }
  }
#else
  public struct SystemURLOpener: URLOpening {
    public init() {}

    public func open(_ url: URL) async -> Bool {
      false
    }
  }
#endif
