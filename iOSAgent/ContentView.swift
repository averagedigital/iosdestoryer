import SwiftUI
import UniformTypeIdentifiers

struct ContentView: View {
  private let registry = ToolRegistry.defaultRegistry()
  @State private var message = ""
  @State private var auditLog = AuditLog()
  @State private var isImportingFile = false
  @State private var isImportingOCRImage = false
  @State private var importedFileName: String?
  @State private var fileSearchQuery = ""
  @State private var fileSearchReport = FileSearchReport(matches: [], skippedFiles: [])
  @State private var contextBundleMarkdown = ""
  @State private var ocrText = ""
  @State private var photoPermissionStatus = "Not Checked"
  @State private var contactPermissionStatus = "Not Checked"
  @State private var calendarPermissionStatus = "Not Checked"
  @State private var reminderPermissionStatus = "Not Checked"

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
              searchQuery: $fileSearchQuery,
              searchReport: fileSearchReport,
              contextBundleMarkdown: contextBundleMarkdown,
              onImportTapped: { isImportingFile = true },
              onSearchTapped: searchImportedFiles,
              onBundleTapped: buildContextBundle)
            VisionSection(
              ocrText: ocrText,
              onOCRImageTapped: { isImportingOCRImage = true })
            PhotosSection(
              status: photoPermissionStatus,
              onCheckTapped: checkPhotoPermission)
            ContactsSection(
              status: contactPermissionStatus,
              onCheckTapped: checkContactPermission)
            EventKitSection(
              calendarStatus: calendarPermissionStatus,
              reminderStatus: reminderPermissionStatus,
              onCalendarTapped: checkCalendarPermission,
              onRemindersTapped: checkReminderPermission)
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

  private func searchImportedFiles() {
    do {
      let report = try FileSearchService(rootDirectory: importsDirectory).search(
        query: fileSearchQuery)
      fileSearchReport = report
      auditLog.record(
        toolName: "files.search", summary: "\(report.matches.count) matches",
        status: .succeeded)
    } catch {
      fileSearchReport = FileSearchReport(matches: [], skippedFiles: [])
      auditLog.record(
        toolName: "files.search", summary: error.localizedDescription, status: .failed)
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

  private func checkContactPermission() {
    let status = ContactPermissionService().currentStatus()
    contactPermissionStatus = status.displayName
    auditLog.record(
      toolName: "contacts.permission_status", summary: status.rawValue, status: .succeeded)
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

  private var importsDirectory: URL {
    URL.documentsDirectory.appending(path: "Imports", directoryHint: .isDirectory)
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
  @Binding var searchQuery: String
  let searchReport: FileSearchReport
  let contextBundleMarkdown: String
  let onImportTapped: () -> Void
  let onSearchTapped: () -> Void
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

      if let importedFileName {
        Text("Selected: \(importedFileName)")
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
        Text(result.filename)
          .font(.caption)
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
  let onCheckTapped: () -> Void

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
    }
  }
}

private struct ContactsSection: View {
  let status: String
  let onCheckTapped: () -> Void

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
    }
  }
}

private struct EventKitSection: View {
  let calendarStatus: String
  let reminderStatus: String
  let onCalendarTapped: () -> Void
  let onRemindersTapped: () -> Void

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

      HStack {
        Button(action: onRemindersTapped) {
          Label("Reminders", systemImage: "checklist")
        }
        .buttonStyle(.bordered)

        Text(reminderStatus)
          .font(.caption)
          .foregroundStyle(.secondary)
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
