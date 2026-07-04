import XCTest

@testable import AgentCore

final class AppURLServiceTests: XCTestCase {
  func testOpensHTTPURLThroughProvider() async throws {
    let provider = StubURLOpener(result: true)
    let service = AppURLService(provider: provider)

    let opened = try await service.openURL(URL(string: "https://example.com/doc")!)

    XCTAssertEqual(opened.kind, .url)
    XCTAssertEqual(provider.openedURLs.map(\.absoluteString), ["https://example.com/doc"])
  }

  func testRejectsNonHTTPURLForOpenURL() async {
    let service = AppURLService(provider: StubURLOpener(result: true))

    do {
      _ = try await service.openURL(URL(string: "iosagent://import")!)
      XCTFail("Expected unsupported scheme")
    } catch {
      XCTAssertEqual(error as? AppURLServiceError, .unsupportedScheme("iosagent"))
    }
  }

  func testOpensExplicitDeepLinkThroughProvider() async throws {
    let provider = StubURLOpener(result: true)
    let service = AppURLService(provider: provider)

    let opened = try await service.openDeepLink(URL(string: "iosagent://import")!)

    XCTAssertEqual(opened.kind, .deepLink)
    XCTAssertEqual(provider.openedURLs.map(\.absoluteString), ["iosagent://import"])
  }

  func testReportsProviderRejection() async {
    let service = AppURLService(provider: StubURLOpener(result: false))

    do {
      _ = try await service.openURL(URL(string: "https://example.com")!)
      XCTFail("Expected open rejection")
    } catch {
      XCTAssertEqual(error as? AppURLServiceError, .openRejected)
    }
  }
}

private final class StubURLOpener: URLOpening {
  let result: Bool
  var openedURLs: [URL] = []

  init(result: Bool) {
    self.result = result
  }

  func open(_ url: URL) async -> Bool {
    openedURLs.append(url)
    return result
  }
}
