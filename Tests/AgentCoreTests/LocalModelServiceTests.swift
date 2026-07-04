import XCTest

@testable import AgentCore

final class LocalModelServiceTests: XCTestCase {
  func testReportsProviderAvailability() {
    let service = LocalModelService(provider: FakeLocalModelProvider())

    let availability = service.availability()

    XCTAssertFalse(availability.summarize.isAvailable)
    XCTAssertTrue(availability.classify.isAvailable)
    XCTAssertFalse(availability.embed.isAvailable)
  }

  func testClassifiesWithAvailableLocalProvider() throws {
    let service = LocalModelService(provider: FakeLocalModelProvider())

    let result = try service.classify("contract text")

    XCTAssertEqual(result, LocalModelClassification(label: "contract", confidence: 0.9))
  }

  func testUnavailableSummarizeFailsExplicitly() {
    let service = LocalModelService(provider: FakeLocalModelProvider())

    XCTAssertThrowsError(try service.summarize("contract text")) { error in
      XCTAssertEqual(
        error as? LocalModelError,
        .unavailable("local_model.summarize_if_available"))
    }
  }

  func testRejectsEmptyInputBeforeProviderCall() {
    let service = LocalModelService(provider: FakeLocalModelProvider())

    XCTAssertThrowsError(try service.classify(" ")) { error in
      XCTAssertEqual(error as? LocalModelError, .emptyInput)
    }
  }
}

private struct FakeLocalModelProvider: LocalModelProvider {
  let availability = LocalModelAvailability(
    summarize: LocalModelCapability(isAvailable: false, reason: "missing model"),
    classify: LocalModelCapability(isAvailable: true, reason: "fake local classifier"),
    embed: LocalModelCapability(isAvailable: false, reason: "missing model"))

  func summarize(_ text: String) throws -> String {
    throw LocalModelError.unavailable("local_model.summarize_if_available")
  }

  func classify(_ text: String) throws -> LocalModelClassification {
    LocalModelClassification(label: "contract", confidence: 0.9)
  }

  func embed(_ text: String) throws -> [Double] {
    throw LocalModelError.unavailable("local_model.embed_if_available")
  }
}
