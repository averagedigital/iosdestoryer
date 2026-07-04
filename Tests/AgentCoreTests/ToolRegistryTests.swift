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
    XCTAssertNotNil(registry.tool(named: "photos.create_album"))
    XCTAssertNotNil(registry.tool(named: "photos.add_to_album"))
    XCTAssertNotNil(registry.tool(named: "photos.remove_from_album_with_preview"))
    XCTAssertNotNil(registry.tool(named: "photos.favorite"))
    XCTAssertNotNil(registry.tool(named: "photos.hide_with_preview"))
    XCTAssertNotNil(registry.tool(named: "contacts.search"))
    XCTAssertNotNil(registry.tool(named: "contacts.create"))
    XCTAssertNotNil(registry.tool(named: "contacts.update_with_preview"))
    XCTAssertNotNil(registry.tool(named: "contacts.find_duplicate_candidates"))
    XCTAssertNotNil(registry.tool(named: "contacts.merge_preview"))
    XCTAssertNotNil(registry.tool(named: "calendar.search_events"))
    XCTAssertNotNil(registry.tool(named: "calendar.create_event"))
    XCTAssertNotNil(registry.tool(named: "calendar.update_event_with_preview"))
    XCTAssertNotNil(registry.tool(named: "calendar.delete_event_with_preview"))
    XCTAssertNotNil(registry.tool(named: "reminders.search"))
    XCTAssertNotNil(registry.tool(named: "reminders.create"))
    XCTAssertNotNil(registry.tool(named: "reminders.update_with_preview"))
    XCTAssertNotNil(registry.tool(named: "reminders.complete"))
    XCTAssertNotNil(registry.tool(named: "notify.schedule"))
    XCTAssertNotNil(registry.tool(named: "notify.cancel"))
    XCTAssertNotNil(registry.tool(named: "share.import_text"))
    XCTAssertNotNil(registry.tool(named: "share.import_url"))
    XCTAssertNotNil(registry.tool(named: "share.import_file"))
    XCTAssertNotNil(registry.tool(named: "share.import_image"))
    XCTAssertNotNil(registry.tool(named: "share.list_inbox"))
    XCTAssertNotNil(registry.tool(named: "app.open_url"))
    XCTAssertNotNil(registry.tool(named: "app.open_deeplink"))
    XCTAssertNotNil(registry.tool(named: "app_intents.list_supported_actions"))
    XCTAssertNotNil(registry.tool(named: "app_intents.invoke_own_action"))
    XCTAssertNotNil(registry.tool(named: "shortcuts.run_user_configured_shortcut"))
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
