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
}
