import XCTest

@testable import AgentCore

final class AppIntentServiceTests: XCTestCase {
  func testListsDefaultOwnActions() {
    let actions = AppIntentService().listSupportedActions()

    XCTAssertEqual(actions.map(\.id), ["open_agent_workspace"])
    XCTAssertEqual(actions.first?.title, "Open Agent Workspace")
  }

  func testInvokesKnownOwnAction() throws {
    let service = AppIntentService()

    let invoked = try service.invokeOwnAction(id: "open_agent_workspace")

    XCTAssertEqual(invoked.action.id, "open_agent_workspace")
  }

  func testRejectsUnknownAction() {
    let service = AppIntentService()

    do {
      _ = try service.invokeOwnAction(id: "third_party_control")
      XCTFail("Expected unsupported action")
    } catch {
      XCTAssertEqual(error as? AppIntentServiceError, .unsupportedAction("third_party_control"))
    }
  }
}
