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
      after: draft.title,
      calendarDraft: draft)
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
      after: draft.title,
      reminderDraft: draft)
  }

  public func completeReminder(id: String) async throws -> ReminderSummary {
    try await provider.completeReminder(id: id)
  }

  public func apply(_ preview: EventKitChangePreview) async throws -> EventKitApplyResult {
    switch preview.action {
    case .updateEvent:
      guard let draft = preview.calendarDraft else {
        throw EventKitServiceError.missingDraft
      }
      return .event(try await provider.updateEvent(id: preview.itemID, draft: draft))
    case .deleteEvent:
      try await provider.deleteEvent(id: preview.itemID)
      return .deleted(preview.itemID)
    case .updateReminder:
      guard let draft = preview.reminderDraft else {
        throw EventKitServiceError.missingDraft
      }
      return .reminder(try await provider.updateReminder(id: preview.itemID, draft: draft))
    }
  }
}

public protocol EventKitProviding {
  func fetchEvents(from startDate: Date, to endDate: Date) async throws -> [CalendarEventSummary]
  func createEvent(_ draft: CalendarEventDraft) async throws -> CalendarEventSummary
  func updateEvent(id: String, draft: CalendarEventDraft) async throws -> CalendarEventSummary
  func deleteEvent(id: String) async throws
  func fetchReminders() async throws -> [ReminderSummary]
  func createReminder(_ draft: ReminderDraft) async throws -> ReminderSummary
  func updateReminder(id: String, draft: ReminderDraft) async throws -> ReminderSummary
  func completeReminder(id: String) async throws -> ReminderSummary
}

public struct EventKitChangePreview: Equatable, Sendable {
  public let action: EventKitChangeAction
  public let itemID: String
  public let summary: String
  public let before: String
  public let after: String
  public let calendarDraft: CalendarEventDraft?
  public let reminderDraft: ReminderDraft?

  public init(
    action: EventKitChangeAction,
    itemID: String,
    summary: String,
    before: String,
    after: String,
    calendarDraft: CalendarEventDraft? = nil,
    reminderDraft: ReminderDraft? = nil
  ) {
    self.action = action
    self.itemID = itemID
    self.summary = summary
    self.before = before
    self.after = after
    self.calendarDraft = calendarDraft
    self.reminderDraft = reminderDraft
  }
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
  case missingDraft
  case calendarItemNotFound(String)
}

public enum EventKitApplyResult: Equatable, Sendable {
  case event(CalendarEventSummary)
  case reminder(ReminderSummary)
  case deleted(String)
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
      apply(draft, to: event)
      event.calendar = calendar
      try store.save(event, span: .thisEvent, commit: true)
      return CalendarEventSummary(event: event)
    }

    public func updateEvent(id: String, draft: CalendarEventDraft) async throws
      -> CalendarEventSummary
    {
      guard let event = store.event(withIdentifier: id) else {
        throw EventKitServiceError.calendarItemNotFound(id)
      }
      apply(draft, to: event)
      try store.save(event, span: .thisEvent, commit: true)
      return CalendarEventSummary(event: event)
    }

    public func deleteEvent(id: String) async throws {
      guard let event = store.event(withIdentifier: id) else {
        throw EventKitServiceError.calendarItemNotFound(id)
      }
      try store.remove(event, span: .thisEvent, commit: true)
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
      apply(draft, to: reminder)
      reminder.calendar = calendar
      try store.save(reminder, commit: true)
      return ReminderSummary(reminder: reminder)
    }

    public func updateReminder(id: String, draft: ReminderDraft) async throws -> ReminderSummary {
      guard let reminder = store.calendarItem(withIdentifier: id) as? EKReminder else {
        throw EventKitServiceError.calendarItemNotFound(id)
      }
      apply(draft, to: reminder)
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

    private func apply(_ draft: CalendarEventDraft, to event: EKEvent) {
      event.title = draft.title
      event.notes = draft.notes
      event.startDate = draft.startDate
      event.endDate = draft.endDate
    }

    private func apply(_ draft: ReminderDraft, to reminder: EKReminder) {
      reminder.title = draft.title
      reminder.notes = draft.notes
      reminder.dueDateComponents = draft.dueDate.map {
        Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: $0)
      }
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

    public func updateEvent(id: String, draft: CalendarEventDraft) async throws
      -> CalendarEventSummary
    {
      throw EventKitServiceError.calendarItemNotFound(id)
    }

    public func deleteEvent(id: String) async throws {
      throw EventKitServiceError.calendarItemNotFound(id)
    }

    public func fetchReminders() async throws -> [ReminderSummary] {
      []
    }

    public func createReminder(_ draft: ReminderDraft) async throws -> ReminderSummary {
      throw EventKitServiceError.noDefaultCalendar
    }

    public func updateReminder(id: String, draft: ReminderDraft) async throws -> ReminderSummary {
      throw EventKitServiceError.calendarItemNotFound(id)
    }

    public func completeReminder(id: String) async throws -> ReminderSummary {
      throw EventKitServiceError.calendarItemNotFound(id)
    }
  }
#endif
