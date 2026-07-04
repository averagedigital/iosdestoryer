import XCTest

@testable import AgentCore

final class ToolRegistryTests: XCTestCase {
  func testDefaultRegistryContainsOnlyPermissionScopedTools() {
    let registry = ToolRegistry.defaultRegistry()

    XCTAssertNotNil(registry.tool(named: "files.pick_file"))
    XCTAssertNotNil(registry.tool(named: "files.write"))
    XCTAssertNotNil(registry.tool(named: "files.copy"))
    XCTAssertNotNil(registry.tool(named: "files.move"))
    XCTAssertNotNil(registry.tool(named: "files.extract_text"))
    XCTAssertNotNil(registry.tool(named: "files.index_folder"))
    XCTAssertNotNil(registry.tool(named: "files.search"))
    XCTAssertNotNil(registry.tool(named: "index.rebuild"))
    XCTAssertNotNil(registry.tool(named: "index.search"))
    XCTAssertNotNil(registry.tool(named: "index.get_chunks"))
    XCTAssertNotNil(registry.tool(named: "index.export_context_bundle"))
    XCTAssertNotNil(registry.tool(named: "photos.permission_status"))
    XCTAssertNotNil(registry.tool(named: "photos.list_assets"))
    XCTAssertNotNil(registry.tool(named: "photos.find_screenshots"))
    XCTAssertNotNil(registry.tool(named: "photos.find_documents"))
    XCTAssertNotNil(registry.tool(named: "photos.classify_candidates"))
    XCTAssertNil(registry.tool(named: "apps.control_gui"))
    XCTAssertTrue(registry.tools.allSatisfy(\.usesPublicAppleAPI))
  }

  func testDestructiveToolsRequirePreview() {
    let registry = ToolRegistry.defaultRegistry()

    let destructiveTools = registry.tools.filter(\.isDestructive)

    XCTAssertFalse(destructiveTools.isEmpty)
    XCTAssertTrue(destructiveTools.allSatisfy(\.requiresPreview))
  }

  func testAuditLogRecordsToolResultsInOrder() {
    var log = AuditLog()

    log.record(toolName: "files.search", summary: "2 matches", status: .succeeded)
    log.record(
      toolName: "photos.delete_with_preview", summary: "preview created", status: .needsConfirmation
    )

    XCTAssertEqual(log.entries.map(\.toolName), ["files.search", "photos.delete_with_preview"])
    XCTAssertEqual(log.entries.last?.status, .needsConfirmation)
  }
}
