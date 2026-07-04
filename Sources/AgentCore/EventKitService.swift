import Foundation

#if canImport(EventKit)
  import EventKit
#endif

public struct EventKitService {
  private let provider: any EventKitProviding

  public init(provider: any EventKitProviding = EventStoreProvider()) {
    self.provider = provider
  }

  public func searchEvents(_ query: String, from startDate: Date, to endDate: Date) async throws
    -> [CalendarEventSummary]
  {
    let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    let events = try await provider.fetchEvents(from: startDate, to: endDate)
    guard !needle.isEmpty else { return events }
    return events.filter { $0.searchText.contains(needle) }
  }

  public func createEvent(_ draft: CalendarEventDraft) async throws -> CalendarEventSummary {
    try await provider.createEvent(draft)
  }

  public func updateEventPreview(event: CalendarEventSummary, draft: CalendarEventDraft)
    -> EventKitChangePreview
  {
    EventKitChangePreview(
      action: .updateEvent,
      itemID: event.id,
      summary: "Update event \(event.title) to \(draft.title)",
      before: event.title,
      after: draft.title)
  }

  public func deleteEventPreview(event: CalendarEventSummary) -> EventKitChangePreview {
    EventKitChangePreview(
      action: .deleteEvent,
      itemID: event.id,
      summary: "Delete event \(event.title)",
      before: event.title,
      after: "")
  }

  public func searchReminders(_ query: String) async throws -> [ReminderSummary] {
    let needle = query.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    let reminders = try await provider.fetchReminders()
    guard !needle.isEmpty else { return reminders }
    return reminders.filter { $0.searchText.contains(needle) }
  }

  public func createReminder(_ draft: ReminderDraft) async throws -> ReminderSummary {
    try await provider.createReminder(draft)
  }

  public func updateReminderPreview(reminder: ReminderSummary, draft: ReminderDraft)
    -> EventKitChangePreview
  {
    EventKitChangePreview(
      action: .updateReminder,
      itemID: reminder.id,
      summary: "Update reminder \(reminder.title) to \(draft.title)",
      before: reminder.title,
      after: draft.title)
  }

  public func completeReminder(id: String) async throws -> ReminderSummary {
    try await provider.completeReminder(id: id)
  }
}

public protocol EventKitProviding {
  func fetchEvents(from startDate: Date, to endDate: Date) async throws -> [CalendarEventSummary]
  func createEvent(_ draft: CalendarEventDraft) async throws -> CalendarEventSummary
  func fetchReminders() async throws -> [ReminderSummary]
  func createReminder(_ draft: ReminderDraft) async throws -> ReminderSummary
  func completeReminder(id: String) async throws -> ReminderSummary
}

public struct EventKitChangePreview: Equatable, Sendable {
  public let action: EventKitChangeAction
  public let itemID: String
  public let summary: String
  public let before: String
  public let after: String
}

public enum EventKitChangeAction: String, Sendable {
  case updateEvent
  case deleteEvent
  case updateReminder
}

public struct CalendarEventDraft: Equatable, Sendable {
  public let title: String
  public let notes: String
  public let startDate: Date
  public let endDate: Date

  public init(title: String, notes: String, startDate: Date, endDate: Date) {
    self.title = title
    self.notes = notes
    self.startDate = startDate
    self.endDate = endDate
  }
}

public struct CalendarEventSummary: Equatable, Identifiable, Sendable {
  public let id: String
  public let title: String
  public let notes: String
  public let startDate: Date
  public let endDate: Date

  public init(id: String, title: String, notes: String, startDate: Date, endDate: Date) {
    self.id = id
    self.title = title
    self.notes = notes
    self.startDate = startDate
    self.endDate = endDate
  }

  fileprivate var searchText: String {
    [title, notes].joined(separator: " ").lowercased()
  }
}

public struct ReminderDraft: Equatable, Sendable {
  public let title: String
  public let notes: String
  public let dueDate: Date?

  public init(title: String, notes: String, dueDate: Date?) {
    self.title = title
    self.notes = notes
    self.dueDate = dueDate
  }
}

public struct ReminderSummary: Equatable, Identifiable, Sendable {
  public let id: String
  public let title: String
  public let notes: String
  public let isCompleted: Bool
  public let dueDate: Date?

  public init(id: String, title: String, notes: String, isCompleted: Bool, dueDate: Date?) {
    self.id = id
    self.title = title
    self.notes = notes
    self.isCompleted = isCompleted
    self.dueDate = dueDate
  }

  fileprivate var searchText: String {
    [title, notes].joined(separator: " ").lowercased()
  }
}

public enum EventKitServiceError: Error, Equatable {
  case noDefaultCalendar
  case calendarItemNotFound(String)
}

#if canImport(EventKit)
  public final class EventStoreProvider: EventKitProviding {
    private let store: EKEventStore

    public init(store: EKEventStore = EKEventStore()) {
      self.store = store
    }

    public func fetchEvents(from startDate: Date, to endDate: Date) async throws
      -> [CalendarEventSummary]
    {
      let predicate = store.predicateForEvents(withStart: startDate, end: endDate, calendars: nil)
      return store.events(matching: predicate).map(CalendarEventSummary.init(event:))
    }

    public func createEvent(_ draft: CalendarEventDraft) async throws -> CalendarEventSummary {
      guard let calendar = store.defaultCalendarForNewEvents else {
        throw EventKitServiceError.noDefaultCalendar
      }

      let event = EKEvent(eventStore: store)
      event.title = draft.title
      event.notes = draft.notes
      event.startDate = draft.startDate
      event.endDate = draft.endDate
      event.calendar = calendar
      try store.save(event, span: .thisEvent, commit: true)
      return CalendarEventSummary(event: event)
    }

    public func fetchReminders() async throws -> [ReminderSummary] {
      let predicate = store.predicateForReminders(in: nil)
      return await withCheckedContinuation { continuation in
        store.fetchReminders(matching: predicate) { reminders in
          continuation.resume(returning: (reminders ?? []).map(ReminderSummary.init(reminder:)))
        }
      }
    }

    public func createReminder(_ draft: ReminderDraft) async throws -> ReminderSummary {
      guard let calendar = store.defaultCalendarForNewReminders() else {
        throw EventKitServiceError.noDefaultCalendar
      }

      let reminder = EKReminder(eventStore: store)
      reminder.title = draft.title
      reminder.notes = draft.notes
      reminder.calendar = calendar
      if let dueDate = draft.dueDate {
        reminder.dueDateComponents = Calendar.current.dateComponents(
          [.year, .month, .day, .hour, .minute], from: dueDate)
      }
      try store.save(reminder, commit: true)
      return ReminderSummary(reminder: reminder)
    }

    public func completeReminder(id: String) async throws -> ReminderSummary {
      guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else {
        throw EventKitServiceError.calendarItemNotFound(id)
      }
      reminder.isCompleted = true
      try store.save(reminder, commit: true)
      return ReminderSummary(reminder: reminder)
    }
  }

  extension CalendarEventSummary {
    fileprivate init(event: EKEvent) {
      self.init(
        id: event.eventIdentifier ?? UUID().uuidString,
        title: event.title ?? "",
        notes: event.notes ?? "",
        startDate: event.startDate,
        endDate: event.endDate)
    }
  }

  extension ReminderSummary {
    fileprivate init(reminder: EKReminder) {
      self.init(
        id: reminder.calendarItemIdentifier,
        title: reminder.title ?? "",
        notes: reminder.notes ?? "",
        isCompleted: reminder.isCompleted,
        dueDate: reminder.dueDateComponents?.date)
    }
  }
#else
  public struct EventStoreProvider: EventKitProviding {
    public init() {}

    public func fetchEvents(from startDate: Date, to endDate: Date) async throws
      -> [CalendarEventSummary]
    {
      []
    }

    public func createEvent(_ draft: CalendarEventDraft) async throws -> CalendarEventSummary {
      throw EventKitServiceError.noDefaultCalendar
    }

    public func fetchReminders() async throws -> [ReminderSummary] {
      []
    }

    public func createReminder(_ draft: ReminderDraft) async throws -> ReminderSummary {
      throw EventKitServiceError.noDefaultCalendar
    }

    public func completeReminder(id: String) async throws -> ReminderSummary {
      throw EventKitServiceError.calendarItemNotFound(id)
    }
  }
#endif
