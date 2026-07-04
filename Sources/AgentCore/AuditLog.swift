import Foundation

public struct AuditLog: Sendable {
  public private(set) var entries: [AuditEntry]

  public init(entries: [AuditEntry] = []) {
    self.entries = entries
  }

  public mutating func record(
    toolName: String, summary: String, status: AuditStatus, date: Date = Date()
  ) {
    entries.append(AuditEntry(toolName: toolName, summary: summary, status: status, date: date))
  }
}

public struct AuditEntry: Identifiable, Equatable, Sendable {
  public let id: UUID
  public let toolName: String
  public let summary: String
  public let status: AuditStatus
  public let date: Date

  public init(id: UUID = UUID(), toolName: String, summary: String, status: AuditStatus, date: Date)
  {
    self.id = id
    self.toolName = toolName
    self.summary = summary
    self.status = status
    self.date = date
  }
}

public enum AuditStatus: String, Equatable, Sendable {
  case succeeded
  case failed
  case needsConfirmation
}
