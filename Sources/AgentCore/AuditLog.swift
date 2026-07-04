import Foundation

public struct AuditLog: Equatable, Codable, Sendable {
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

public struct AuditEntry: Identifiable, Equatable, Codable, Sendable {
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

public enum AuditStatus: String, Equatable, Codable, Sendable {
  case succeeded
  case failed
  case needsConfirmation
}

public struct AuditLogStore: Sendable {
  public let fileURL: URL

  public init(fileURL: URL) {
    self.fileURL = fileURL
  }

  public static func defaultStore() throws -> AuditLogStore {
    let directory = try FileManager.default.url(
      for: .applicationSupportDirectory,
      in: .userDomainMask,
      appropriateFor: nil,
      create: true)
    return AuditLogStore(fileURL: directory.appending(path: "audit-log.json"))
  }

  public func load() throws -> AuditLog {
    guard FileManager.default.fileExists(atPath: fileURL.path) else {
      return AuditLog()
    }
    let data = try Data(contentsOf: fileURL)
    return try JSONDecoder().decode(AuditLog.self, from: data)
  }

  public func save(_ log: AuditLog) throws {
    try FileManager.default.createDirectory(
      at: fileURL.deletingLastPathComponent(),
      withIntermediateDirectories: true)
    let data = try JSONEncoder().encode(log)
    try data.write(to: fileURL, options: .atomic)
  }
}
