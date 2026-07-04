import Foundation

public struct ShareInboxService {
  public let inboxDirectory: URL

  public init(inboxDirectory: URL) {
    self.inboxDirectory = inboxDirectory
  }

  public func importText(_ text: String, preferredName: String = "shared-text") throws
    -> SharedInboxItem
  {
    try write(
      text.data(using: .utf8) ?? Data(), kind: .text, preferredName: preferredName, ext: "txt")
  }

  public func importURL(_ url: URL, preferredName: String = "shared-url") throws -> SharedInboxItem
  {
    try write(
      url.absoluteString.data(using: .utf8) ?? Data(), kind: .url, preferredName: preferredName,
      ext: "url")
  }

  public func importImage(_ data: Data, preferredName: String = "shared-image") throws
    -> SharedInboxItem
  {
    try write(data, kind: .image, preferredName: preferredName, ext: "jpg")
  }

  public func importFile(from sourceURL: URL) throws -> SharedInboxItem {
    try FileManager.default.createDirectory(at: inboxDirectory, withIntermediateDirectories: true)
    let destination = availableDestinationURL(for: sourceURL.lastPathComponent)
    try FileManager.default.copyItem(at: sourceURL, to: destination)
    return SharedInboxItem(kind: .file, url: destination.standardizedFileURL)
  }

  public func listItems() throws -> [SharedInboxItem] {
    try FileManager.default.createDirectory(at: inboxDirectory, withIntermediateDirectories: true)
    let urls = try FileManager.default.contentsOfDirectory(
      at: inboxDirectory,
      includingPropertiesForKeys: [.contentModificationDateKey],
      options: [.skipsHiddenFiles])
    return urls.sorted { $0.lastPathComponent < $1.lastPathComponent }.map {
      SharedInboxItem(kind: kind(for: $0), url: $0.standardizedFileURL)
    }
  }

  private func write(_ data: Data, kind: SharedInboxItem.Kind, preferredName: String, ext: String)
    throws -> SharedInboxItem
  {
    try FileManager.default.createDirectory(at: inboxDirectory, withIntermediateDirectories: true)
    let destination = availableDestinationURL(for: "\(preferredName).\(ext)")
    try data.write(to: destination, options: [.atomic])
    return SharedInboxItem(kind: kind, url: destination.standardizedFileURL)
  }

  private func kind(for url: URL) -> SharedInboxItem.Kind {
    switch url.pathExtension.lowercased() {
    case "txt":
      return .text
    case "url":
      return .url
    case "jpg", "jpeg", "png", "heic":
      return .image
    default:
      return .file
    }
  }

  private func availableDestinationURL(for filename: String) -> URL {
    let candidate = inboxDirectory.appending(path: filename)
    guard FileManager.default.fileExists(atPath: candidate.path) else {
      return candidate
    }

    let ext = candidate.pathExtension
    let baseName = candidate.deletingPathExtension().lastPathComponent
    var counter = 2

    while true {
      let numberedName = ext.isEmpty ? "\(baseName)-\(counter)" : "\(baseName)-\(counter).\(ext)"
      let numberedURL = inboxDirectory.appending(path: numberedName)
      if !FileManager.default.fileExists(atPath: numberedURL.path) {
        return numberedURL
      }
      counter += 1
    }
  }
}

public struct SharedInboxItem: Equatable, Identifiable, Sendable {
  public enum Kind: String, Sendable {
    case text
    case url
    case image
    case file
  }

  public var id: String { url.path }
  public let kind: Kind
  public let url: URL

  public init(kind: Kind, url: URL) {
    self.kind = kind
    self.url = url
  }
}
