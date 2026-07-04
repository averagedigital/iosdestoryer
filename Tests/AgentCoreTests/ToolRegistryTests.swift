import XCTest

@testable import AgentCore

final class ToolRegistryTests: XCTestCase {
  func testDefaultRegistryContainsOnlyPermissionScopedTools() {
    let registry = ToolRegistry.defaultRegistry()

    let expectedToolNames: Set<String> = [
      "files.pick_file",
      "files.pick_folder",
      "files.list_allowed_sources",
      "files.read",
      "files.write",
      "files.copy",
      "files.move",
      "files.extract_text",
      "files.search",
      "files.context_bundle",
      "files.index_folder",
      "index.add_source",
      "index.rebuild",
      "index.search",
      "index.get_chunks",
      "index.export_context_bundle",
      "files.delete_with_preview",
      "photos.permission_status",
      "photos.list_assets",
      "photos.find_screenshots",
      "photos.find_documents",
      "photos.find_duplicates_or_candidates",
      "photos.create_album",
      "photos.add_to_album",
      "photos.remove_from_album_with_preview",
      "photos.favorite",
      "photos.hide_with_preview",
      "photos.classify_candidates",
      "photos.delete_with_preview",
      "contacts.permission_status",
      "contacts.search",
      "contacts.create",
      "contacts.update_with_preview",
      "contacts.find_duplicate_candidates",
      "contacts.merge_preview",
      "contacts.delete_with_preview",
      "calendar.permission_status",
      "calendar.search_events",
      "calendar.create_event",
      "calendar.update_event_with_preview",
      "calendar.delete_event_with_preview",
      "reminders.permission_status",
      "reminders.search",
      "reminders.create",
      "reminders.update_with_preview",
      "reminders.complete",
      "notify.permission_status",
      "notify.permission",
      "notify.schedule",
      "notify.cancel",
      "share.import_text",
      "share.import_url",
      "share.import_file",
      "share.import_image",
      "share.list_inbox",
      "app.open_url",
      "app.open_deeplink",
      "vision.ocr_image",
      "vision.ocr_pdf_or_file_image",
      "vision.detect_barcodes_if_easy",
      "camera.permission_status",
      "camera.permission",
      "camera.take_photo",
      "camera.scan_document",
      "app_intents.list_supported_actions",
      "app_intents.invoke_own_action",
      "shortcuts.run_user_configured_shortcut",
      "audio.permission_status",
      "audio.permission",
      "audio.record",
      "speech.transcribe",
      "local_model.summarize_if_available",
      "local_model.classify_if_available",
      "local_model.embed_if_available",
    ]

    XCTAssertEqual(Set(registry.tools.map(\.name)), expectedToolNames)
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
    XCTAssertNotNil(registry.tool(named: "notify.permission_status"))
    XCTAssertNotNil(registry.tool(named: "notify.permission"))
    XCTAssertNotNil(registry.tool(named: "notify.schedule"))
    XCTAssertNotNil(registry.tool(named: "notify.cancel"))
    XCTAssertNotNil(registry.tool(named: "share.import_text"))
    XCTAssertNotNil(registry.tool(named: "share.import_url"))
    XCTAssertNotNil(registry.tool(named: "share.import_file"))
    XCTAssertNotNil(registry.tool(named: "share.import_image"))
    XCTAssertNotNil(registry.tool(named: "share.list_inbox"))
    XCTAssertNotNil(registry.tool(named: "app.open_url"))
    XCTAssertNotNil(registry.tool(named: "app.open_deeplink"))
    XCTAssertNotNil(registry.tool(named: "camera.take_photo"))
    XCTAssertNotNil(registry.tool(named: "camera.permission_status"))
    XCTAssertNotNil(registry.tool(named: "camera.permission"))
    XCTAssertNotNil(registry.tool(named: "camera.scan_document"))
    XCTAssertNotNil(registry.tool(named: "vision.ocr_pdf_or_file_image"))
    XCTAssertNotNil(registry.tool(named: "vision.detect_barcodes_if_easy"))
    XCTAssertNotNil(registry.tool(named: "app_intents.list_supported_actions"))
    XCTAssertNotNil(registry.tool(named: "app_intents.invoke_own_action"))
    XCTAssertNotNil(registry.tool(named: "shortcuts.run_user_configured_shortcut"))
    XCTAssertNotNil(registry.tool(named: "audio.permission_status"))
    XCTAssertNotNil(registry.tool(named: "audio.permission"))
    XCTAssertNotNil(registry.tool(named: "audio.record"))
    XCTAssertNotNil(registry.tool(named: "speech.transcribe"))
    XCTAssertNotNil(registry.tool(named: "local_model.summarize_if_available"))
    XCTAssertNotNil(registry.tool(named: "local_model.classify_if_available"))
    XCTAssertNotNil(registry.tool(named: "local_model.embed_if_available"))
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
