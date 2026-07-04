import Foundation
import UIKit
import UniformTypeIdentifiers

final class ShareViewController: UIViewController {
  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    importSharedItems()
  }

  private func importSharedItems() {
    do {
      let inboxDirectory = try ShareInboxService.appGroupInboxDirectory()
      let service = ShareInboxService(inboxDirectory: inboxDirectory)
      let providers =
        extensionContext?.inputItems
        .compactMap { $0 as? NSExtensionItem }
        .flatMap { $0.attachments ?? [] } ?? []

      guard !providers.isEmpty else {
        complete()
        return
      }

      let group = DispatchGroup()
      let lock = NSLock()
      var lastError: Error?

      func recordError(_ error: Error) {
        lock.lock()
        lastError = error
        lock.unlock()
      }

      for provider in providers {
        if provider.hasItemConformingToTypeIdentifier(UTType.plainText.identifier) {
          loadText(from: provider, into: service, group: group, onError: recordError)
        } else if provider.hasItemConformingToTypeIdentifier(UTType.url.identifier) {
          loadURL(
            from: provider, typeIdentifier: UTType.url.identifier, into: service, group: group,
            onError: recordError)
        } else if provider.hasItemConformingToTypeIdentifier(UTType.image.identifier) {
          loadImage(from: provider, into: service, group: group, onError: recordError)
        } else if provider.hasItemConformingToTypeIdentifier(UTType.fileURL.identifier) {
          loadURL(
            from: provider, typeIdentifier: UTType.fileURL.identifier, into: service, group: group,
            onError: recordError)
        }
      }

      group.notify(queue: .main) {
        if let lastError {
          self.extensionContext?.cancelRequest(withError: lastError)
        } else {
          self.complete()
        }
      }
    } catch {
      extensionContext?.cancelRequest(withError: error)
    }
  }

  private func loadText(
    from provider: NSItemProvider,
    into service: ShareInboxService,
    group: DispatchGroup,
    onError: @escaping (Error) -> Void
  ) {
    group.enter()
    provider.loadItem(forTypeIdentifier: UTType.plainText.identifier, options: nil) { item, error in
      defer { group.leave() }
      if let error {
        onError(error)
        return
      }

      do {
        if let text = item as? String {
          _ = try service.importText(text)
        } else if let data = item as? Data, let text = String(data: data, encoding: .utf8) {
          _ = try service.importText(text)
        }
      } catch {
        onError(error)
      }
    }
  }

  private func loadURL(
    from provider: NSItemProvider,
    typeIdentifier: String,
    into service: ShareInboxService,
    group: DispatchGroup,
    onError: @escaping (Error) -> Void
  ) {
    group.enter()
    provider.loadItem(forTypeIdentifier: typeIdentifier, options: nil) { item, error in
      defer { group.leave() }
      if let error {
        onError(error)
        return
      }

      do {
        let url: URL?
        if let loadedURL = item as? URL {
          url = loadedURL
        } else if let loadedURL = item as? NSURL {
          url = loadedURL as URL
        } else {
          url = nil
        }

        guard let url else { return }
        if url.isFileURL {
          let didAccess = url.startAccessingSecurityScopedResource()
          defer {
            if didAccess {
              url.stopAccessingSecurityScopedResource()
            }
          }
          _ = try service.importFile(from: url)
        } else {
          _ = try service.importURL(url)
        }
      } catch {
        onError(error)
      }
    }
  }

  private func loadImage(
    from provider: NSItemProvider,
    into service: ShareInboxService,
    group: DispatchGroup,
    onError: @escaping (Error) -> Void
  ) {
    group.enter()
    provider.loadDataRepresentation(forTypeIdentifier: UTType.image.identifier) { data, error in
      defer { group.leave() }
      if let error {
        onError(error)
        return
      }

      do {
        if let data {
          _ = try service.importImage(data)
        }
      } catch {
        onError(error)
      }
    }
  }

  private func complete() {
    extensionContext?.completeRequest(returningItems: nil)
  }
}
