import XCTest

@testable import AgentCore

final class EventKitServiceTests: XCTestCase {
  func testSearchEventsFiltersByTitleAndNotes() async throws {
    let service = EventKitService(provider: StubEventKitProvider())

    let contractResults = try await service.searchEvents(
      "contract", from: .distantPast, to: .distantFuture)
    let waterResults = try await service.searchEvents(
      "water", from: .distantPast, to: .distantFuture)

    XCTAssertEqual(contractResults.map(\.id), ["event-1"])
    XCTAssertEqual(waterResults.map(\.id), ["event-2"])
  }

  func testCreateEventReturnsProviderSummary() async throws {
    let service = EventKitService(provider: StubEventKitProvider())
    let draft = CalendarEventDraft(
      title: "Call", notes: "Discuss contract", startDate: .distantPast,
      endDate: .distantFuture)

    let event = try await service.createEvent(draft)

    XCTAssertEqual(event.title, "Call")
    XCTAssertEqual(event.notes, "Discuss contract")
  }

  func testBuildsCalendarUpdateAndDeletePreviews() {
    let service = EventKitService(provider: StubEventKitProvider())
    let event = CalendarEventSummary(
      id: "event-1", title: "Old", notes: "", startDate: .distantPast, endDate: .distantFuture)
    let draft = CalendarEventDraft(
      title: "New", notes: "", startDate: .distantPast, endDate: .distantFuture)

    let update = service.updateEventPreview(event: event, draft: draft)
    let delete = service.deleteEventPreview(event: event)

    XCTAssertEqual(update.action, .updateEvent)
    XCTAssertEqual(update.itemID, "event-1")
    XCTAssertTrue(update.summary.contains("Update"))
    XCTAssertEqual(delete.action, .deleteEvent)
    XCTAssertEqual(delete.itemID, "event-1")
  }

  func testSearchRemindersFiltersByTitleAndNotes() async throws {
    let service = EventKitService(provider: StubEventKitProvider())

    let contractResults = try await service.searchReminders("contract")
    let actResults = try await service.searchReminders("paper")

    XCTAssertEqual(contractResults.map(\.id), ["reminder-1"])
    XCTAssertEqual(actResults.map(\.id), ["reminder-2"])
  }

  func testCreateReminderReturnsProviderSummary() async throws {
    let service = EventKitService(provider: StubEventKitProvider())
    let draft = ReminderDraft(title: "Review", notes: "Contract", dueDate: nil)

    let reminder = try await service.createReminder(draft)

    XCTAssertEqual(reminder.title, "Review")
    XCTAssertFalse(reminder.isCompleted)
  }

  func testBuildsReminderUpdatePreviewAndCompletesReminder() async throws {
    let service = EventKitService(provider: StubEventKitProvider())
    let reminder = ReminderSummary(
      id: "reminder-1", title: "Old", notes: "", isCompleted: false, dueDate: nil)
    let draft = ReminderDraft(title: "New", notes: "", dueDate: nil)

    let preview = service.updateReminderPreview(reminder: reminder, draft: draft)
    let completed = try await service.completeReminder(id: reminder.id)

    XCTAssertEqual(preview.action, .updateReminder)
    XCTAssertEqual(preview.itemID, "reminder-1")
    XCTAssertTrue(completed.isCompleted)
  }
}

private struct StubEventKitProvider: EventKitProviding {
  func fetchEvents(from startDate: Date, to endDate: Date) async throws -> [CalendarEventSummary] {
    [
      CalendarEventSummary(
        id: "event-1", title: "Contract review", notes: "", startDate: startDate,
        endDate: endDate),
      CalendarEventSummary(
        id: "event-2", title: "Meeting", notes: "Water supply", startDate: startDate,
        endDate: endDate),
    ]
  }

  func createEvent(_ draft: CalendarEventDraft) async throws -> CalendarEventSummary {
    CalendarEventSummary(
      id: "created-event", title: draft.title, notes: draft.notes, startDate: draft.startDate,
      endDate: draft.endDate)
  }

  func fetchReminders() async throws -> [ReminderSummary] {
    [
      ReminderSummary(
        id: "reminder-1", title: "Contract follow-up", notes: "", isCompleted: false,
        dueDate: nil),
      ReminderSummary(
        id: "reminder-2", title: "Scan", notes: "Paper act", isCompleted: false, dueDate: nil),
    ]
  }

  func createReminder(_ draft: ReminderDraft) async throws -> ReminderSummary {
    ReminderSummary(
      id: "created-reminder", title: draft.title, notes: draft.notes, isCompleted: false,
      dueDate: draft.dueDate)
  }

  func completeReminder(id: String) async throws -> ReminderSummary {
    ReminderSummary(
      id: id, title: "Contract follow-up", notes: "", isCompleted: true, dueDate: nil)
  }
}
