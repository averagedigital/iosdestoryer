import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
  private let registry = ToolRegistry.defaultRegistry()
  @State private var message = ""
  @State private var auditLog = AuditLog()
  @State private var isImportingFile = false
  @State private var isImportingOCRImage = false
  @State private var importedFileName: String?
  @State private var allowedSources: [AllowedFileSource] = []
  @State private var fileWriteName = "note.txt"
  @State private var fileWriteText = ""
  @State private var fileOperationStatus = ""
  @State private var fileSearchQuery = ""
  @State private var fileSearchReport = FileSearchReport(matches: [], skippedFiles: [])
  @State private var readFileText = ""
  @State private var contextBundleMarkdown = ""
  @State private var pendingDeletePreview: FileDeletePreview?
  @State private var localIndex = LocalIndex(chunks: [], skippedFiles: [])
  @State private var indexQuery = ""
  @State private var indexResults: [IndexedChunk] = []
  @State private var indexBundleMarkdown = ""
  @State private var ocrText = ""
  @State private var photoPermissionStatus = "Not Checked"
  @State private var photoAssets: [PhotoAssetSummary] = []
  @State private var photoClassifications: [PhotoClassificationResult] = []
  @State private var contactPermissionStatus = "Not Checked"
  @State private var contactQuery = ""
  @State private var contactResults: [ContactSummary] = []
  @State private var calendarPermissionStatus = "Not Checked"
  @State private var reminderPermissionStatus = "Not Checked"
  @State private var calendarQuery = ""
  @State private var calendarEventTitle = "New event"
  @State private var calendarEvents: [CalendarEventSummary] = []
  @State private var reminderQuery = ""
  @State private var reminderTitle = "New reminder"
  @State private var reminders: [ReminderSummary] = []

  var body: some View {
    NavigationStack {
      VStack(spacing: 0) {
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 14) {
            ChatBubble(
              text:
                "Ask me to work with a file you import from Files, photos you choose, contacts, calendar items, OCR, or your app shortcuts. I will preview risky changes first.",
              isUser: false)
            FileImportSection(
              importedFileName: importedFileName,
              allowedSources: allowedSources,
              fileWriteName: $fileWriteName,
              fileWriteText: $fileWriteText,
              fileOperationStatus: fileOperationStatus,
              searchQuery: $fileSearchQuery,
              searchReport: fileSearchReport,
              readFileText: readFileText,
              contextBundleMarkdown: contextBundleMarkdown,
              pendingDeletePreview: pendingDeletePreview,
              onImportTapped: { isImportingFile = true },
              onSourcesTapped: listAllowedSources,
              onWriteTapped: writeTextFile,
              onSearchTapped: searchImportedFiles,
              onReadTapped: readFile,
              onDeletePreviewTapped: previewDelete,
              onConfirmDeleteTapped: confirmDelete,
              onBundleTapped: buildContextBundle)
            IndexSection(
              index: localIndex,
              query: $indexQuery,
              results: indexResults,
              bundleMarkdown: indexBundleMarkdown,
              onRebuildTapped: rebuildIndex,
              onSearchTapped: searchIndex,
              onExportTapped: exportIndexBundle)
            VisionSection(
              ocrText: ocrText,
              onOCRImageTapped: { isImportingOCRImage = true })
            PhotosSection(
              status: photoPermissionStatus,
              assets: photoAssets,
              classifications: photoClassifications,
              onCheckTapped: checkPhotoPermission,
              onListTapped: listPhotoAssets,
              onScreenshotsTapped: findScreenshots,
              onClassifyTapped: classifyPhotoCandidates)
            ContactsSection(
              status: contactPermissionStatus,
              query: $contactQuery,
              contacts: contactResults,
              onCheckTapped: checkContactPermission,
              onSearchTapped: searchContacts,
              onDuplicatesTapped: findDuplicateContacts)
            EventKitSection(
              calendarStatus: calendarPermissionStatus,
              reminderStatus: reminderPermissionStatus,
              calendarQuery: $calendarQuery,
              calendarEventTitle: $calendarEventTitle,
              calendarEvents: calendarEvents,
              reminderQuery: $reminderQuery,
              reminderTitle: $reminderTitle,
              reminders: reminders,
              onCalendarTapped: checkCalendarPermission,
              onRemindersTapped: checkReminderPermission,
              onCalendarSearchTapped: searchCalendarEvents,
              onCalendarCreateTapped: createCalendarEvent,
              onReminderSearchTapped: searchReminders,
              onReminderCreateTapped: createReminder)
            ToolSection(registry: registry)
            AuditSection(entries: auditLog.entries)
          }
          .padding()
        }

        HStack(spacing: 10) {
          TextField("Message", text: $message, axis: .vertical)
            .textFieldStyle(.roundedBorder)
            .lineLimit(1...4)

          Button("Send") {
            auditLog.record(
              toolName: "agent.chat", summary: message.isEmpty ? "empty message ignored" : message,
              status: .succeeded)
            message = ""
          }
          .buttonStyle(.borderedProminent)
          .disabled(message.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
        .padding()
        .background(.regularMaterial)
      }
      .navigationTitle("iOS Agent")
      .fileImporter(
        isPresented: $isImportingFile,
        allowedContentTypes: [.data],
        allowsMultipleSelection: false,
        onCompletion: handleFileImport
      )
      .fileImporter(
        isPresented: $isImportingOCRImage,
        allowedContentTypes: [.image],
        allowsMultipleSelection: false,
        onCompletion: handleOCRImageImport
      )
    }
  }

  private func handleFileImport(_ result: Result<[URL], Error>) {
    switch result {
    case .success(let urls):
      guard let url = urls.first else { return }
      do {
        let imported = try FileImportService(importsDirectory: importsDirectory)
          .importPickedFile(from: url, auditLog: &auditLog)
        importedFileName = imported.originalFilename
      } catch {
        importedFileName = nil
        auditLog.record(
          toolName: "files.pick_file", summary: error.localizedDescription, status: .failed)
      }
    case .failure(let error):
      importedFileName = nil
      auditLog.record(
        toolName: "files.pick_file", summary: error.localizedDescription, status: .failed)
    }
  }

  private func listAllowedSources() {
    do {
      allowedSources = try FileSourceService(importsDirectory: importsDirectory)
        .listAllowedSources()
      auditLog.record(
        toolName: "files.list_allowed_sources",
        summary: "\(allowedSources.count) sources",
        status: .succeeded)
    } catch {
      allowedSources = []
      auditLog.record(
        toolName: "files.list_allowed_sources", summary: error.localizedDescription,
        status: .failed)
    }
  }

  private func searchImportedFiles() {
    do {
      let report = try FileSearchService(rootDirectory: importsDirectory).search(
        query: fileSearchQuery)
      fileSearchReport = report
      readFileText = ""
      pendingDeletePreview = nil
      auditLog.record(
        toolName: "files.search", summary: "\(report.matches.count) matches",
        status: .succeeded)
    } catch {
      fileSearchReport = FileSearchReport(matches: [], skippedFiles: [])
      readFileText = ""
      pendingDeletePreview = nil
      auditLog.record(
        toolName: "files.search", summary: error.localizedDescription, status: .failed)
    }
  }

  private func writeTextFile() {
    do {
      let result = try FileOperationService(rootDirectory: importsDirectory)
        .writeText(fileWriteText, to: fileWriteName)
      importedFileName = result.filename
      fileOperationStatus = "Created \(result.filename)"
      auditLog.record(toolName: "files.write", summary: result.filename, status: .succeeded)
    } catch {
      fileOperationStatus = error.localizedDescription
      auditLog.record(toolName: "files.write", summary: error.localizedDescription, status: .failed)
    }
  }

  private func readFile(_ result: FileSearchResult) {
    do {
      let document = try FileReadService().read(url: result.url)
      readFileText = document.text
      auditLog.record(
        toolName: "files.read", summary: document.filename, status: .succeeded)
    } catch {
      readFileText = ""
      auditLog.record(toolName: "files.read", summary: error.localizedDescription, status: .failed)
    }
  }

  private func previewDelete(_ result: FileSearchResult) {
    do {
      let preview = try FileOperationService(rootDirectory: importsDirectory)
        .deletePreview(for: relativePath(for: result.url))
      pendingDeletePreview = preview
      fileOperationStatus = "Preview delete \(preview.filename) (\(preview.byteCount) bytes)"
      auditLog.record(
        toolName: "files.delete_with_preview", summary: preview.filename,
        status: .needsConfirmation)
    } catch {
      pendingDeletePreview = nil
      fileOperationStatus = error.localizedDescription
      auditLog.record(
        toolName: "files.delete_with_preview", summary: error.localizedDescription,
        status: .failed)
    }
  }

  private func confirmDelete() {
    guard let preview = pendingDeletePreview else { return }
    do {
      try FileOperationService(rootDirectory: importsDirectory).delete(preview)
      pendingDeletePreview = nil
      fileSearchReport = FileSearchReport(
        matches: fileSearchReport.matches.filter { $0.url != preview.url },
        skippedFiles: fileSearchReport.skippedFiles)
      fileOperationStatus = "Deleted \(preview.filename)"
      auditLog.record(
        toolName: "files.delete_with_preview", summary: preview.filename, status: .succeeded)
    } catch {
      fileOperationStatus = error.localizedDescription
      auditLog.record(
        toolName: "files.delete_with_preview", summary: error.localizedDescription,
        status: .failed)
    }
  }

  private func buildContextBundle() {
    do {
      let bundle = try ContextBundleService().build(
        title: fileSearchQuery.isEmpty ? "Imported Files" : fileSearchQuery,
        files: fileSearchReport.matches)
      contextBundleMarkdown = bundle.markdown
      auditLog.record(
        toolName: "files.context_bundle",
        summary: "\(fileSearchReport.matches.count) files, \(bundle.skippedFiles.count) skipped",
        status: .succeeded)
    } catch {
      contextBundleMarkdown = ""
      auditLog.record(
        toolName: "files.context_bundle", summary: error.localizedDescription, status: .failed)
    }
  }

  private func rebuildIndex() {
    do {
      localIndex = try LocalIndexService(rootDirectory: importsDirectory).rebuild()
      indexResults = []
      indexBundleMarkdown = ""
      auditLog.record(
        toolName: "index.rebuild",
        summary: "\(localIndex.chunks.count) chunks, \(localIndex.skippedFiles.count) skipped",
        status: .succeeded)
    } catch {
      localIndex = LocalIndex(chunks: [], skippedFiles: [])
      indexResults = []
      indexBundleMarkdown = ""
      auditLog.record(
        toolName: "index.rebuild", summary: error.localizedDescription, status: .failed)
    }
  }

  private func searchIndex() {
    do {
      indexResults = try localIndex.search(query: indexQuery)
      indexBundleMarkdown = ""
      auditLog.record(
        toolName: "index.search", summary: "\(indexResults.count) chunks", status: .succeeded)
    } catch {
      indexResults = []
      indexBundleMarkdown = ""
      auditLog.record(
        toolName: "index.search", summary: error.localizedDescription, status: .failed)
    }
  }

  private func exportIndexBundle() {
    indexBundleMarkdown = localIndex.exportContextBundle(
      title: indexQuery.isEmpty ? "Indexed Context" : indexQuery, chunks: indexResults)
    auditLog.record(
      toolName: "index.export_context_bundle",
      summary: "\(indexResults.count) chunks",
      status: .succeeded)
  }

  private func handleOCRImageImport(_ result: Result<[URL], Error>) {
    switch result {
    case .success(let urls):
      guard let url = urls.first else { return }
      let didStartAccess = url.startAccessingSecurityScopedResource()
      defer {
        if didStartAccess {
          url.stopAccessingSecurityScopedResource()
        }
      }

      do {
        let imageData = try Data(contentsOf: url)
        let result = try OCRService().recognizeText(in: imageData)
        ocrText = result.text
        auditLog.record(
          toolName: "vision.ocr_image",
          summary: "\(result.observations.count) text observations",
          status: .succeeded)
      } catch {
        ocrText = ""
        auditLog.record(
          toolName: "vision.ocr_image", summary: error.localizedDescription, status: .failed)
      }
    case .failure(let error):
      ocrText = ""
      auditLog.record(
        toolName: "vision.ocr_image", summary: error.localizedDescription, status: .failed)
    }
  }

  private func checkPhotoPermission() {
    let status = PhotoPermissionService().currentStatus()
    photoPermissionStatus = status.displayName
    auditLog.record(
      toolName: "photos.permission_status", summary: status.rawValue, status: .succeeded)
  }

  private func listPhotoAssets() {
    photoAssets = PhotoLibraryService().listAssets(limit: 20)
    photoClassifications = []
    auditLog.record(
      toolName: "photos.list_assets", summary: "\(photoAssets.count) assets", status: .succeeded)
  }

  private func findScreenshots() {
    photoAssets = PhotoLibraryService().findScreenshots(limit: 50)
    photoClassifications = []
    auditLog.record(
      toolName: "photos.find_screenshots", summary: "\(photoAssets.count) screenshots",
      status: .succeeded)
  }

  private func classifyPhotoCandidates() {
    photoClassifications = PhotoLibraryService().classifyCandidates(limit: 20)
    photoAssets = photoClassifications.map(\.asset)
    auditLog.record(
      toolName: "photos.classify_candidates",
      summary: "\(photoClassifications.count) assets",
      status: .succeeded)
  }

  private func checkContactPermission() {
    let status = ContactPermissionService().currentStatus()
    contactPermissionStatus = status.displayName
    auditLog.record(
      toolName: "contacts.permission_status", summary: status.rawValue, status: .succeeded)
  }

  private func searchContacts() {
    do {
      contactResults = try ContactLibraryService().search(contactQuery)
      auditLog.record(
        toolName: "contacts.search", summary: "\(contactResults.count) contacts",
        status: .succeeded)
    } catch {
      contactResults = []
      auditLog.record(
        toolName: "contacts.search", summary: error.localizedDescription, status: .failed)
    }
  }

  private func findDuplicateContacts() {
    do {
      contactResults = try ContactLibraryService().findDuplicateCandidates()
      auditLog.record(
        toolName: "contacts.find_duplicate_candidates",
        summary: "\(contactResults.count) candidates",
        status: .succeeded)
    } catch {
      contactResults = []
      auditLog.record(
        toolName: "contacts.find_duplicate_candidates", summary: error.localizedDescription,
        status: .failed)
    }
  }

  private func checkCalendarPermission() {
    let status = EventPermissionService().currentStatus(for: .calendar)
    calendarPermissionStatus = status.displayName
    auditLog.record(
      toolName: "calendar.permission_status", summary: status.rawValue, status: .succeeded)
  }

  private func checkReminderPermission() {
    let status = EventPermissionService().currentStatus(for: .reminders)
    reminderPermissionStatus = status.displayName
    auditLog.record(
      toolName: "reminders.permission_status", summary: status.rawValue, status: .succeeded)
  }

  private func searchCalendarEvents() {
    Task {
      do {
        let now = Date()
        calendarEvents = try await EventKitService().searchEvents(
          calendarQuery,
          from: now.addingTimeInterval(-30 * 24 * 60 * 60),
          to: now.addingTimeInterval(365 * 24 * 60 * 60))
        auditLog.record(
          toolName: "calendar.search_events", summary: "\(calendarEvents.count) events",
          status: .succeeded)
      } catch {
        calendarEvents = []
        auditLog.record(
          toolName: "calendar.search_events", summary: error.localizedDescription,
          status: .failed)
      }
    }
  }

  private func createCalendarEvent() {
    let startDate = Date().addingTimeInterval(60 * 60)
    let draft = CalendarEventDraft(
      title: calendarEventTitle,
      notes: "",
      startDate: startDate,
      endDate: startDate.addingTimeInterval(60 * 60))

    Task {
      do {
        let event = try await EventKitService().createEvent(draft)
        calendarEvents = [event]
        auditLog.record(
          toolName: "calendar.create_event", summary: event.title, status: .succeeded)
      } catch {
        auditLog.record(
          toolName: "calendar.create_event", summary: error.localizedDescription, status: .failed)
      }
    }
  }

  private func searchReminders() {
    Task {
      do {
        reminders = try await EventKitService().searchReminders(reminderQuery)
        auditLog.record(
          toolName: "reminders.search", summary: "\(reminders.count) reminders",
          status: .succeeded)
      } catch {
        reminders = []
        auditLog.record(
          toolName: "reminders.search", summary: error.localizedDescription, status: .failed)
      }
    }
  }

  private func createReminder() {
    Task {
      do {
        let reminder = try await EventKitService().createReminder(
          ReminderDraft(title: reminderTitle, notes: "", dueDate: nil))
        reminders = [reminder]
        auditLog.record(
          toolName: "reminders.create", summary: reminder.title, status: .succeeded)
      } catch {
        auditLog.record(
          toolName: "reminders.create", summary: error.localizedDescription, status: .failed)
      }
    }
  }

  private var importsDirectory: URL {
    URL.documentsDirectory.appending(path: "Imports", directoryHint: .isDirectory)
  }

  private func relativePath(for url: URL) throws -> String {
    let rootPath = importsDirectory.standardizedFileURL.path
    let path = url.standardizedFileURL.path
    guard path.hasPrefix(rootPath + "/") else {
      throw FileOperationError.pathEscapesRoot(url.lastPathComponent)
    }
    return String(path.dropFirst(rootPath.count + 1))
  }
}

private struct ChatBubble: View {
  let text: String
  let isUser: Bool

  var body: some View {
    Text(text)
      .padding(12)
      .frame(maxWidth: .infinity, alignment: isUser ? .trailing : .leading)
      .background(isUser ? Color.accentColor.opacity(0.18) : Color.secondary.opacity(0.12))
      .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
  }
}

private struct ToolSection: View {
  let registry: ToolRegistry

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Tools")
        .font(.headline)

      ForEach(registry.tools) { tool in
        HStack {
          VStack(alignment: .leading, spacing: 2) {
            Text(tool.name)
              .font(.subheadline.monospaced())
            Text(tool.appleFrameworks.joined(separator: ", "))
              .font(.caption)
              .foregroundStyle(.secondary)
          }
          Spacer()
          if tool.requiresPreview {
            Text("Preview")
              .font(.caption.weight(.semibold))
              .padding(.horizontal, 8)
              .padding(.vertical, 4)
              .background(Color.orange.opacity(0.18))
              .clipShape(Capsule())
          }
        }
        .padding(.vertical, 6)
      }
    }
  }
}

private struct FileImportSection: View {
  let importedFileName: String?
  let allowedSources: [AllowedFileSource]
  @Binding var fileWriteName: String
  @Binding var fileWriteText: String
  let fileOperationStatus: String
  @Binding var searchQuery: String
  let searchReport: FileSearchReport
  let readFileText: String
  let contextBundleMarkdown: String
  let pendingDeletePreview: FileDeletePreview?
  let onImportTapped: () -> Void
  let onSourcesTapped: () -> Void
  let onWriteTapped: () -> Void
  let onSearchTapped: () -> Void
  let onReadTapped: (FileSearchResult) -> Void
  let onDeletePreviewTapped: (FileSearchResult) -> Void
  let onConfirmDeleteTapped: () -> Void
  let onBundleTapped: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Files")
        .font(.headline)

      Text("Import a document from the Files app to grant access only to the item you pick.")
        .font(.subheadline)
        .foregroundStyle(.secondary)

      Button(action: onImportTapped) {
        Label(importedFileName ?? "Import File", systemImage: "doc.badge.plus")
      }
      .buttonStyle(.borderedProminent)

      Button(action: onSourcesTapped) {
        Label("Allowed Sources", systemImage: "folder")
      }
      .buttonStyle(.bordered)

      if let importedFileName {
        Text("Selected: \(importedFileName)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      ForEach(allowedSources) { source in
        Text("\(source.name): \(source.url.lastPathComponent)")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      TextField("New UTF-8 filename", text: $fileWriteName)
        .textFieldStyle(.roundedBorder)
      TextField("Text to write", text: $fileWriteText, axis: .vertical)
        .textFieldStyle(.roundedBorder)
        .lineLimit(1...4)
      Button("Write Text File", action: onWriteTapped)
        .buttonStyle(.bordered)
        .disabled(fileWriteName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)

      if !fileOperationStatus.isEmpty {
        Text(fileOperationStatus)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      HStack {
        TextField("Search imported files", text: $searchQuery)
          .textFieldStyle(.roundedBorder)
        Button("Search", action: onSearchTapped)
          .buttonStyle(.bordered)
          .disabled(searchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }

      ForEach(searchReport.matches) { result in
        HStack {
          Button(result.filename) {
            onReadTapped(result)
          }
          .font(.caption)

          Spacer()

          Button("Preview Delete", role: .destructive) {
            onDeletePreviewTapped(result)
          }
          .font(.caption)
        }
      }

      if let pendingDeletePreview {
        Text("Delete preview: \(pendingDeletePreview.filename)")
          .font(.caption)
          .foregroundStyle(.secondary)
        Button("Confirm Delete", role: .destructive, action: onConfirmDeleteTapped)
          .buttonStyle(.bordered)
      }

      if !searchReport.skippedFiles.isEmpty {
        Text("\(searchReport.skippedFiles.count) non-text file skipped")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      if !searchReport.matches.isEmpty {
        Button("Build Context Bundle", action: onBundleTapped)
          .buttonStyle(.bordered)
      }

      if !readFileText.isEmpty {
        Text(readFileText)
          .font(.caption.monospaced())
          .lineLimit(8)
          .padding(8)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color.secondary.opacity(0.08))
          .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
      }

      if !contextBundleMarkdown.isEmpty {
        Text(contextBundleMarkdown)
          .font(.caption.monospaced())
          .lineLimit(8)
          .padding(8)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color.secondary.opacity(0.08))
          .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
      }
    }
  }
}

private struct IndexSection: View {
  let index: LocalIndex
  @Binding var query: String
  let results: [IndexedChunk]
  let bundleMarkdown: String
  let onRebuildTapped: () -> Void
  let onSearchTapped: () -> Void
  let onExportTapped: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Local Index")
        .font(.headline)

      HStack {
        Button("Rebuild Index", action: onRebuildTapped)
          .buttonStyle(.bordered)
        Text("\(index.chunks.count) chunks")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      HStack {
        TextField("Search index chunks", text: $query)
          .textFieldStyle(.roundedBorder)
        Button("Search", action: onSearchTapped)
          .buttonStyle(.bordered)
          .disabled(query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }

      ForEach(results) { chunk in
        VStack(alignment: .leading, spacing: 3) {
          Text("\(chunk.filename) #\(chunk.number)")
            .font(.caption.weight(.semibold))
          Text(chunk.text)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(3)
        }
      }

      if !results.isEmpty {
        Button("Export Indexed Context", action: onExportTapped)
          .buttonStyle(.bordered)
      }

      if !bundleMarkdown.isEmpty {
        Text(bundleMarkdown)
          .font(.caption.monospaced())
          .lineLimit(8)
          .padding(8)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color.secondary.opacity(0.08))
          .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
      }

      if !index.skippedFiles.isEmpty {
        Text("\(index.skippedFiles.count) non-text file skipped")
          .font(.caption)
          .foregroundStyle(.secondary)
      }
    }
  }
}

private struct VisionSection: View {
  let ocrText: String
  let onOCRImageTapped: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Vision")
        .font(.headline)

      Button(action: onOCRImageTapped) {
        Label("OCR Image", systemImage: "text.viewfinder")
      }
      .buttonStyle(.bordered)

      if !ocrText.isEmpty {
        Text(ocrText)
          .font(.caption)
          .lineLimit(8)
          .padding(8)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color.secondary.opacity(0.08))
          .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
      }
    }
  }
}

private struct PhotosSection: View {
  let status: String
  let assets: [PhotoAssetSummary]
  let classifications: [PhotoClassificationResult]
  let onCheckTapped: () -> Void
  let onListTapped: () -> Void
  let onScreenshotsTapped: () -> Void
  let onClassifyTapped: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Photos")
        .font(.headline)

      HStack {
        Button(action: onCheckTapped) {
          Label("Check Permission", systemImage: "photo.on.rectangle")
        }
        .buttonStyle(.bordered)

        Text(status)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      HStack {
        Button("List Assets", action: onListTapped)
          .buttonStyle(.bordered)
        Button("Screenshots", action: onScreenshotsTapped)
          .buttonStyle(.bordered)
        Button("Classify", action: onClassifyTapped)
          .buttonStyle(.bordered)
      }

      ForEach(assets) { asset in
        VStack(alignment: .leading, spacing: 2) {
          Text(asset.id)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
          Text("\(asset.pixelWidth)x\(asset.pixelHeight)")
            .font(.caption)
            .foregroundStyle(.secondary)
        }
      }

      ForEach(classifications, id: \.asset.id) { result in
        if !result.labels.isEmpty {
          Text("\(result.asset.id): \(result.labels.map(\.rawValue).joined(separator: ", "))")
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(2)
        }
      }
    }
  }
}

private struct ContactsSection: View {
  let status: String
  @Binding var query: String
  let contacts: [ContactSummary]
  let onCheckTapped: () -> Void
  let onSearchTapped: () -> Void
  let onDuplicatesTapped: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Contacts")
        .font(.headline)

      HStack {
        Button(action: onCheckTapped) {
          Label("Check Permission", systemImage: "person.crop.circle")
        }
        .buttonStyle(.bordered)

        Text(status)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      TextField("Search contacts", text: $query)
        .textFieldStyle(.roundedBorder)

      HStack {
        Button("Search", action: onSearchTapped)
          .buttonStyle(.bordered)
        Button("Duplicates", action: onDuplicatesTapped)
          .buttonStyle(.bordered)
      }

      ForEach(contacts) { contact in
        VStack(alignment: .leading, spacing: 2) {
          Text(contact.displayName.isEmpty ? contact.organizationName : contact.displayName)
            .font(.caption.weight(.semibold))
            .lineLimit(1)
          Text((contact.emailAddresses + contact.phoneNumbers).joined(separator: " / "))
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
        }
      }
    }
  }
}

private struct EventKitSection: View {
  let calendarStatus: String
  let reminderStatus: String
  @Binding var calendarQuery: String
  @Binding var calendarEventTitle: String
  let calendarEvents: [CalendarEventSummary]
  @Binding var reminderQuery: String
  @Binding var reminderTitle: String
  let reminders: [ReminderSummary]
  let onCalendarTapped: () -> Void
  let onRemindersTapped: () -> Void
  let onCalendarSearchTapped: () -> Void
  let onCalendarCreateTapped: () -> Void
  let onReminderSearchTapped: () -> Void
  let onReminderCreateTapped: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Calendar")
        .font(.headline)

      HStack {
        Button(action: onCalendarTapped) {
          Label("Calendar", systemImage: "calendar")
        }
        .buttonStyle(.bordered)

        Text(calendarStatus)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      TextField("Calendar search", text: $calendarQuery)
        .textFieldStyle(.roundedBorder)
      TextField("Event title", text: $calendarEventTitle)
        .textFieldStyle(.roundedBorder)
      HStack {
        Button("Search Events", action: onCalendarSearchTapped)
          .buttonStyle(.bordered)
        Button("Create Event", action: onCalendarCreateTapped)
          .buttonStyle(.bordered)
      }

      ForEach(calendarEvents) { event in
        Text(event.title)
          .font(.caption)
          .lineLimit(1)
      }

      HStack {
        Button(action: onRemindersTapped) {
          Label("Reminders", systemImage: "checklist")
        }
        .buttonStyle(.bordered)

        Text(reminderStatus)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      TextField("Reminder search", text: $reminderQuery)
        .textFieldStyle(.roundedBorder)
      TextField("Reminder title", text: $reminderTitle)
        .textFieldStyle(.roundedBorder)
      HStack {
        Button("Search Reminders", action: onReminderSearchTapped)
          .buttonStyle(.bordered)
        Button("Create Reminder", action: onReminderCreateTapped)
          .buttonStyle(.bordered)
      }

      ForEach(reminders) { reminder in
        Text(reminder.title)
          .font(.caption)
          .lineLimit(1)
      }
    }
  }
}

private struct AuditSection: View {
  let entries: [AuditEntry]

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Audit")
        .font(.headline)

      if entries.isEmpty {
        Text("No tool calls yet.")
          .foregroundStyle(.secondary)
      } else {
        ForEach(entries) { entry in
          Text("\(entry.toolName): \(entry.summary)")
            .font(.caption)
        }
      }
    }
  }
}
