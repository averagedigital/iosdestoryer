import SwiftUI
import UIKit
import UniformTypeIdentifiers
import VisionKit

struct ContentView: View {
  private let registry = ToolRegistry.defaultRegistry()
  private let commandRouter = AgentCommandRouter()
  @State private var message = ""
  @State private var auditLog = AuditLog()
  @State private var isImportingFile = false
  @State private var isImportingFolder = false
  @State private var isImportingOCRImage = false
  @State private var isImportingBarcodeImage = false
  @State private var isTakingPhoto = false
  @State private var isScanningDocument = false
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
  @State private var sharedInboxItems: [SharedInboxItem] = []
  @State private var shareInboxStatus = ""
  @State private var localIndex = LocalIndex(chunks: [], skippedFiles: [])
  @State private var indexQuery = ""
  @State private var indexResults: [IndexedChunk] = []
  @State private var indexBundleMarkdown = ""
  @State private var ocrText = ""
  @State private var barcodeText = ""
  @State private var cameraStatus = ""
  @State private var photoPermissionStatus = "Not Checked"
  @State private var photoAlbumTitle = "Agent Docs"
  @State private var photoAssets: [PhotoAssetSummary] = []
  @State private var photoClassifications: [PhotoClassificationResult] = []
  @State private var photoPreview = ""
  @State private var pendingPhotoPreview: PhotoChangePreview?
  @State private var contactPermissionStatus = "Not Checked"
  @State private var contactQuery = ""
  @State private var contactGivenName = "New"
  @State private var contactFamilyName = "Contact"
  @State private var contactEmail = ""
  @State private var contactPhone = ""
  @State private var contactResults: [ContactSummary] = []
  @State private var contactPreview: String = ""
  @State private var pendingContactPreview: ContactChangePreview?
  @State private var calendarPermissionStatus = "Not Checked"
  @State private var reminderPermissionStatus = "Not Checked"
  @State private var calendarQuery = ""
  @State private var calendarEventTitle = "New event"
  @State private var calendarEvents: [CalendarEventSummary] = []
  @State private var reminderQuery = ""
  @State private var reminderTitle = "New reminder"
  @State private var reminders: [ReminderSummary] = []
  @State private var eventKitPreview = ""
  @State private var pendingEventKitPreview: EventKitChangePreview?
  @State private var notificationPermissionStatus = "Not Checked"
  @State private var notificationTitle = "Reminder"
  @State private var notificationBody = "Review the item"
  @State private var notificationDelaySeconds = 60.0
  @State private var scheduledNotificationID = ""
  @State private var appURLString = "https://example.com"
  @State private var appDeepLinkString = "shortcuts://"
  @State private var appOpenStatus = ""
  @State private var supportedAppActions: [SupportedAppAction] = []
  @State private var appIntentStatus = ""
  @State private var audioPermissionStatus = "Not Checked"
  @State private var audioRecordSeconds = 5.0
  @State private var latestRecording: AudioRecording?
  @State private var speechTranscript = ""
  @State private var localModelText = "water supply contract"
  @State private var localModelStatus = ""
  @State private var localModelClassification: LocalModelClassification?

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
              onFolderImportTapped: { isImportingFolder = true },
              onSourcesTapped: listAllowedSources,
              onWriteTapped: writeTextFile,
              onSearchTapped: searchImportedFiles,
              onReadTapped: readFile,
              onDeletePreviewTapped: previewDelete,
              onConfirmDeleteTapped: confirmDelete,
              onBundleTapped: buildContextBundle)
            ShareInboxSection(
              items: sharedInboxItems,
              status: shareInboxStatus,
              onRefreshTapped: refreshShareInbox,
              onImportTapped: importSharedInboxItem)
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
              barcodeText: barcodeText,
              cameraStatus: cameraStatus,
              onOCRImageTapped: { isImportingOCRImage = true },
              onBarcodeImageTapped: { isImportingBarcodeImage = true },
              onTakePhotoTapped: takePhoto,
              onScanDocumentTapped: scanDocument)
            PhotosSection(
              status: photoPermissionStatus,
              albumTitle: $photoAlbumTitle,
              assets: photoAssets,
              classifications: photoClassifications,
              preview: photoPreview,
              hasPendingPreview: pendingPhotoPreview != nil,
              onCheckTapped: checkPhotoPermission,
              onListTapped: listPhotoAssets,
              onScreenshotsTapped: findScreenshots,
              onClassifyTapped: classifyPhotoCandidates,
              onCreateAlbumTapped: createPhotoAlbum,
              onAddToAlbumTapped: addFirstPhotoToAlbum,
              onFavoriteTapped: favoriteFirstPhoto,
              onRemovePreviewTapped: previewPhotoRemoveFromAlbum,
              onHidePreviewTapped: previewPhotoHide,
              onDeletePreviewTapped: previewPhotoDelete,
              onConfirmPreviewTapped: confirmPhotoPreview)
            ContactsSection(
              status: contactPermissionStatus,
              query: $contactQuery,
              givenName: $contactGivenName,
              familyName: $contactFamilyName,
              email: $contactEmail,
              phone: $contactPhone,
              contacts: contactResults,
              preview: contactPreview,
              hasPendingPreview: pendingContactPreview != nil,
              onCheckTapped: checkContactPermission,
              onSearchTapped: searchContacts,
              onDuplicatesTapped: findDuplicateContacts,
              onCreateTapped: createContact,
              onUpdatePreviewTapped: previewContactUpdate,
              onDeletePreviewTapped: previewContactDelete,
              onMergePreviewTapped: previewContactMerge,
              onConfirmPreviewTapped: confirmContactPreview)
            EventKitSection(
              calendarStatus: calendarPermissionStatus,
              reminderStatus: reminderPermissionStatus,
              calendarQuery: $calendarQuery,
              calendarEventTitle: $calendarEventTitle,
              calendarEvents: calendarEvents,
              reminderQuery: $reminderQuery,
              reminderTitle: $reminderTitle,
              reminders: reminders,
              preview: eventKitPreview,
              hasPendingPreview: pendingEventKitPreview != nil,
              onCalendarTapped: checkCalendarPermission,
              onRemindersTapped: checkReminderPermission,
              onCalendarSearchTapped: searchCalendarEvents,
              onCalendarCreateTapped: createCalendarEvent,
              onReminderSearchTapped: searchReminders,
              onReminderCreateTapped: createReminder,
              onCalendarUpdatePreviewTapped: previewCalendarEventUpdate,
              onCalendarDeletePreviewTapped: previewCalendarEventDelete,
              onReminderUpdatePreviewTapped: previewReminderUpdate,
              onReminderCompleteTapped: completeReminder,
              onConfirmPreviewTapped: confirmEventKitPreview)
            NotificationSection(
              status: notificationPermissionStatus,
              title: $notificationTitle,
              notificationBody: $notificationBody,
              delaySeconds: $notificationDelaySeconds,
              scheduledID: scheduledNotificationID,
              onPermissionTapped: requestNotificationPermission,
              onScheduleTapped: scheduleNotification,
              onCancelTapped: cancelNotification)
            AppURLSection(
              urlString: $appURLString,
              deepLinkString: $appDeepLinkString,
              status: appOpenStatus,
              onOpenURLTapped: openAppURL,
              onOpenDeepLinkTapped: openAppDeepLink)
            AppIntentSection(
              actions: supportedAppActions,
              status: appIntentStatus,
              onListTapped: listSupportedAppActions,
              onInvokeTapped: invokeFirstAppAction)
            AudioSpeechSection(
              permissionStatus: audioPermissionStatus,
              durationSeconds: $audioRecordSeconds,
              recording: latestRecording,
              transcript: speechTranscript,
              onPermissionTapped: requestAudioSpeechPermissions,
              onRecordTapped: recordAudio,
              onTranscribeTapped: transcribeLatestRecording)
            LocalModelSection(
              text: $localModelText,
              status: localModelStatus,
              classification: localModelClassification,
              onAvailabilityTapped: checkLocalModelAvailability,
              onClassifyTapped: classifyLocalText,
              onSummarizeTapped: summarizeLocalText,
              onEmbedTapped: embedLocalText)
            ToolSection(registry: registry)
            AuditSection(entries: auditLog.entries)
          }
          .padding()
        }

        HStack(spacing: 10) {
          TextField("Message", text: $message, axis: .vertical)
            .textFieldStyle(.roundedBorder)
            .lineLimit(1...4)

          Button("Send", action: sendMessage)
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
        isPresented: $isImportingFolder,
        allowedContentTypes: [.folder],
        allowsMultipleSelection: false,
        onCompletion: handleFolderImport
      )
      .fileImporter(
        isPresented: $isImportingOCRImage,
        allowedContentTypes: [.image, .pdf],
        allowsMultipleSelection: false,
        onCompletion: handleOCRImageImport
      )
      .fileImporter(
        isPresented: $isImportingBarcodeImage,
        allowedContentTypes: [.image],
        allowsMultipleSelection: false,
        onCompletion: handleBarcodeImageImport
      )
      .sheet(isPresented: $isTakingPhoto) {
        ImageCaptureView { imageData in
          handleCameraPhoto(imageData)
        }
      }
      .sheet(isPresented: $isScanningDocument) {
        DocumentScannerView { pages in
          handleDocumentScan(pages)
        }
      }
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

  private func handleFolderImport(_ result: Result<[URL], Error>) {
    switch result {
    case .success(let urls):
      guard let url = urls.first else { return }
      do {
        let imported = try FileImportService(importsDirectory: importsDirectory)
          .importPickedFolder(from: url)
        importedFileName = imported.originalFolderName
        fileOperationStatus =
          "\(imported.importedFiles.count) files imported, \(imported.skippedFiles.count) skipped"
        auditLog.record(
          toolName: "files.pick_folder", summary: fileOperationStatus, status: .succeeded)
      } catch {
        fileOperationStatus = error.localizedDescription
        auditLog.record(
          toolName: "files.pick_folder", summary: error.localizedDescription, status: .failed)
      }
    case .failure(let error):
      fileOperationStatus = error.localizedDescription
      auditLog.record(
        toolName: "files.pick_folder", summary: error.localizedDescription, status: .failed)
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

  private func refreshShareInbox() {
    do {
      let inboxDirectory = try ShareInboxService.appGroupInboxDirectory()
      sharedInboxItems = try ShareInboxService(inboxDirectory: inboxDirectory).listItems()
      shareInboxStatus = "\(sharedInboxItems.count) item(s)"
      auditLog.record(
        toolName: "share.list_inbox", summary: shareInboxStatus, status: .succeeded)
    } catch {
      shareInboxStatus = error.localizedDescription
      auditLog.record(toolName: "share.list_inbox", summary: shareInboxStatus, status: .failed)
    }
  }

  private func importSharedInboxItem(_ item: SharedInboxItem) {
    do {
      let imported = try FileImportService(importsDirectory: importsDirectory)
        .importPickedFile(from: item.url)
      localIndex = try LocalIndexService(rootDirectory: importsDirectory).rebuild()
      indexResults = []
      indexBundleMarkdown = ""
      importedFileName = imported.originalFilename
      shareInboxStatus = "Imported \(imported.originalFilename); \(localIndex.chunks.count) chunks"
      auditLog.record(
        toolName: "share.import_\(item.kind.rawValue)",
        summary: shareInboxStatus,
        status: .succeeded)
    } catch {
      shareInboxStatus = error.localizedDescription
      auditLog.record(
        toolName: "share.import_\(item.kind.rawValue)",
        summary: error.localizedDescription,
        status: .failed)
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

  private func sendMessage() {
    let text = message.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !text.isEmpty else { return }

    auditLog.record(toolName: "agent.chat", summary: text, status: .succeeded)
    if let route = commandRouter.route(text) {
      runAgentRoute(route, message: text)
    } else {
      auditLog.record(
        toolName: "agent.route", summary: "No local tool matched.", status: .failed)
    }
    message = ""
  }

  private func runAgentRoute(_ route: AgentCommandRoute, message: String) {
    switch route.toolName {
    case "index.search":
      indexQuery = message
      searchIndex()
    case "index.export_context_bundle":
      exportIndexBundle()
    case "reminders.create":
      reminderTitle = message
      createReminder()
    case "contacts.create":
      contactGivenName = message
      createContact()
    case "camera.scan_document":
      scanDocument()
    case "photos.classify_candidates":
      classifyPhotoCandidates()
    default:
      auditLog.record(
        toolName: route.toolName, summary: "Route not wired.", status: .failed)
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
        let result = try OCRService().recognizeText(inFileAt: url)
        ocrText = result.text
        auditLog.record(
          toolName: "vision.ocr_pdf_or_file_image",
          summary: "\(result.observations.count) text observations",
          status: .succeeded)
      } catch {
        ocrText = ""
        auditLog.record(
          toolName: "vision.ocr_pdf_or_file_image", summary: error.localizedDescription,
          status: .failed)
      }
    case .failure(let error):
      ocrText = ""
      auditLog.record(
        toolName: "vision.ocr_pdf_or_file_image", summary: error.localizedDescription,
        status: .failed)
    }
  }

  private func handleBarcodeImageImport(_ result: Result<[URL], Error>) {
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
        let result = try OCRService().detectBarcodes(in: imageData)
        barcodeText = result.barcodes.map(\.payload).joined(separator: "\n")
        auditLog.record(
          toolName: "vision.detect_barcodes_if_easy",
          summary: "\(result.barcodes.count) barcodes",
          status: .succeeded)
      } catch {
        barcodeText = ""
        auditLog.record(
          toolName: "vision.detect_barcodes_if_easy", summary: error.localizedDescription,
          status: .failed)
      }
    case .failure(let error):
      barcodeText = ""
      auditLog.record(
        toolName: "vision.detect_barcodes_if_easy", summary: error.localizedDescription,
        status: .failed)
    }
  }

  private func takePhoto() {
    guard UIImagePickerController.isSourceTypeAvailable(.camera) else {
      cameraStatus = "Camera unavailable"
      auditLog.record(toolName: "camera.take_photo", summary: cameraStatus, status: .failed)
      return
    }
    isTakingPhoto = true
  }

  private func scanDocument() {
    guard VNDocumentCameraViewController.isSupported else {
      cameraStatus = "Document scanner unavailable"
      auditLog.record(toolName: "camera.scan_document", summary: cameraStatus, status: .failed)
      return
    }
    isScanningDocument = true
  }

  private func handleCameraPhoto(_ imageData: Data?) {
    isTakingPhoto = false
    guard let imageData else { return }

    do {
      let fileName = "camera-\(Int(Date().timeIntervalSince1970)).jpg"
      let capture = try CameraCaptureService(directory: cameraDirectory)
        .savePhoto(imageData, fileName: fileName)
      cameraStatus = capture.fileURL.lastPathComponent
      auditLog.record(toolName: "camera.take_photo", summary: cameraStatus, status: .succeeded)
    } catch {
      cameraStatus = error.localizedDescription
      auditLog.record(toolName: "camera.take_photo", summary: cameraStatus, status: .failed)
    }
  }

  private func handleDocumentScan(_ result: Result<[Data], Error>?) {
    isScanningDocument = false
    guard let result else { return }

    do {
      let pages = try result.get()
      let basename = "scan-\(Int(Date().timeIntervalSince1970))"
      let capture = try CameraCaptureService(directory: cameraDirectory)
        .saveScannedDocument(pages, basename: basename)
      cameraStatus = "\(capture.pageCount) page(s)"
      auditLog.record(toolName: "camera.scan_document", summary: cameraStatus, status: .succeeded)
    } catch {
      cameraStatus = error.localizedDescription
      auditLog.record(toolName: "camera.scan_document", summary: cameraStatus, status: .failed)
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
    photoPreview = ""
    pendingPhotoPreview = nil
    auditLog.record(
      toolName: "photos.list_assets", summary: "\(photoAssets.count) assets", status: .succeeded)
  }

  private func findScreenshots() {
    photoAssets = PhotoLibraryService().findScreenshots(limit: 50)
    photoClassifications = []
    photoPreview = ""
    pendingPhotoPreview = nil
    auditLog.record(
      toolName: "photos.find_screenshots", summary: "\(photoAssets.count) screenshots",
      status: .succeeded)
  }

  private func classifyPhotoCandidates() {
    photoClassifications = PhotoLibraryService().classifyCandidates(limit: 20)
    photoAssets = photoClassifications.map(\.asset)
    photoPreview = ""
    pendingPhotoPreview = nil
    auditLog.record(
      toolName: "photos.classify_candidates",
      summary: "\(photoClassifications.count) assets",
      status: .succeeded)
  }

  private func createPhotoAlbum() {
    Task {
      do {
        let album = try await PhotoLibraryService().createAlbum(title: photoAlbumTitle)
        photoPreview = ""
        pendingPhotoPreview = nil
        auditLog.record(toolName: "photos.create_album", summary: album.title, status: .succeeded)
      } catch {
        auditLog.record(
          toolName: "photos.create_album", summary: error.localizedDescription, status: .failed)
      }
    }
  }

  private func addFirstPhotoToAlbum() {
    guard let asset = photoAssets.first else { return }
    Task {
      do {
        let result = try await PhotoLibraryService().addToAlbum(
          assetIDs: [asset.id], albumTitle: photoAlbumTitle)
        photoPreview = ""
        pendingPhotoPreview = nil
        auditLog.record(
          toolName: "photos.add_to_album", summary: "\(result.assetIDs.count) assets",
          status: .succeeded)
      } catch {
        auditLog.record(
          toolName: "photos.add_to_album", summary: error.localizedDescription, status: .failed)
      }
    }
  }

  private func favoriteFirstPhoto() {
    guard let asset = photoAssets.first else { return }
    Task {
      do {
        let favorite = try await PhotoLibraryService().favorite(assetID: asset.id)
        photoAssets = [favorite] + Array(photoAssets.dropFirst())
        photoPreview = ""
        pendingPhotoPreview = nil
        auditLog.record(toolName: "photos.favorite", summary: favorite.id, status: .succeeded)
      } catch {
        auditLog.record(
          toolName: "photos.favorite", summary: error.localizedDescription, status: .failed)
      }
    }
  }

  private func previewPhotoRemoveFromAlbum() {
    let preview = PhotoLibraryService().removeFromAlbumPreview(
      assetIDs: selectedPhotoIDs, albumTitle: photoAlbumTitle)
    pendingPhotoPreview = preview
    photoPreview = preview.summary
    auditLog.record(
      toolName: "photos.remove_from_album_with_preview", summary: preview.summary,
      status: .needsConfirmation)
  }

  private func previewPhotoHide() {
    let preview = PhotoLibraryService().hidePreview(assetIDs: selectedPhotoIDs)
    pendingPhotoPreview = preview
    photoPreview = preview.summary
    auditLog.record(
      toolName: "photos.hide_with_preview", summary: preview.summary,
      status: .needsConfirmation)
  }

  private func previewPhotoDelete() {
    let preview = PhotoLibraryService().deletePreview(assetIDs: selectedPhotoIDs)
    pendingPhotoPreview = preview
    photoPreview = preview.summary
    auditLog.record(
      toolName: "photos.delete_with_preview", summary: preview.summary,
      status: .needsConfirmation)
  }

  private func confirmPhotoPreview() {
    guard let preview = pendingPhotoPreview else { return }
    Task {
      do {
        let applied = try await PhotoLibraryService().apply(preview)
        pendingPhotoPreview = nil
        photoPreview = "Confirmed: \(applied.summary)"
        if applied.action == .delete {
          let ids = Set(applied.assetIDs)
          photoAssets.removeAll { ids.contains($0.id) }
        }
        auditLog.record(
          toolName: photoToolName(for: applied.action), summary: applied.summary,
          status: .succeeded)
      } catch {
        auditLog.record(
          toolName: photoToolName(for: preview.action), summary: error.localizedDescription,
          status: .failed)
      }
    }
  }

  private func photoToolName(for action: PhotoChangeAction) -> String {
    switch action {
    case .removeFromAlbum:
      "photos.remove_from_album_with_preview"
    case .hide:
      "photos.hide_with_preview"
    case .delete:
      "photos.delete_with_preview"
    }
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
      contactPreview = ""
      pendingContactPreview = nil
      auditLog.record(
        toolName: "contacts.search", summary: "\(contactResults.count) contacts",
        status: .succeeded)
    } catch {
      contactResults = []
      contactPreview = ""
      pendingContactPreview = nil
      auditLog.record(
        toolName: "contacts.search", summary: error.localizedDescription, status: .failed)
    }
  }

  private func findDuplicateContacts() {
    do {
      contactResults = try ContactLibraryService().findDuplicateCandidates()
      contactPreview = ""
      pendingContactPreview = nil
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

  private func createContact() {
    do {
      let contact = try ContactLibraryService().create(contactDraft)
      contactResults = [contact]
      contactPreview = ""
      pendingContactPreview = nil
      auditLog.record(
        toolName: "contacts.create", summary: contact.displayLabel, status: .succeeded)
    } catch {
      auditLog.record(
        toolName: "contacts.create", summary: error.localizedDescription, status: .failed)
    }
  }

  private func previewContactUpdate() {
    guard let contact = contactResults.first else { return }
    let preview = ContactLibraryService().updatePreview(contact: contact, draft: contactDraft)
    pendingContactPreview = preview
    contactPreview = preview.summary
    auditLog.record(
      toolName: "contacts.update_with_preview", summary: preview.summary,
      status: .needsConfirmation)
  }

  private func previewContactDelete() {
    guard let contact = contactResults.first else { return }
    let preview = ContactLibraryService().deletePreview(contact: contact)
    pendingContactPreview = preview
    contactPreview = preview.summary
    auditLog.record(
      toolName: "contacts.delete_with_preview", summary: preview.summary,
      status: .needsConfirmation)
  }

  private func previewContactMerge() {
    let preview = ContactLibraryService().mergePreview(contacts: contactResults)
    guard let contact = preview.mergedContact else { return }
    pendingContactPreview = nil
    contactPreview =
      "Merge \(preview.duplicateContactIDs.count) into \(contact.displayLabel)"
    auditLog.record(
      toolName: "contacts.merge_preview", summary: contactPreview, status: .needsConfirmation)
  }

  private func confirmContactPreview() {
    guard let preview = pendingContactPreview else { return }
    do {
      let updated = try ContactLibraryService().apply(preview)
      pendingContactPreview = nil
      contactPreview = "Confirmed: \(preview.summary)"
      switch preview.action {
      case .update:
        if let updated {
          contactResults = contactResults.map { $0.id == updated.id ? updated : $0 }
        }
      case .delete:
        contactResults.removeAll { $0.id == preview.contactID }
      }
      auditLog.record(
        toolName: contactToolName(for: preview.action), summary: preview.summary,
        status: .succeeded)
    } catch {
      auditLog.record(
        toolName: contactToolName(for: preview.action), summary: error.localizedDescription,
        status: .failed)
    }
  }

  private func contactToolName(for action: ContactChangeAction) -> String {
    switch action {
    case .update:
      "contacts.update_with_preview"
    case .delete:
      "contacts.delete_with_preview"
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
        eventKitPreview = ""
        pendingEventKitPreview = nil
        auditLog.record(
          toolName: "calendar.search_events", summary: "\(calendarEvents.count) events",
          status: .succeeded)
      } catch {
        calendarEvents = []
        eventKitPreview = ""
        pendingEventKitPreview = nil
        auditLog.record(
          toolName: "calendar.search_events", summary: error.localizedDescription,
          status: .failed)
      }
    }
  }

  private func createCalendarEvent() {
    Task {
      do {
        let event = try await EventKitService().createEvent(calendarEventDraft)
        calendarEvents = [event]
        eventKitPreview = ""
        pendingEventKitPreview = nil
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
        eventKitPreview = ""
        pendingEventKitPreview = nil
        auditLog.record(
          toolName: "reminders.search", summary: "\(reminders.count) reminders",
          status: .succeeded)
      } catch {
        reminders = []
        eventKitPreview = ""
        pendingEventKitPreview = nil
        auditLog.record(
          toolName: "reminders.search", summary: error.localizedDescription, status: .failed)
      }
    }
  }

  private func createReminder() {
    Task {
      do {
        let reminder = try await EventKitService().createReminder(reminderDraft)
        reminders = [reminder]
        eventKitPreview = ""
        pendingEventKitPreview = nil
        auditLog.record(
          toolName: "reminders.create", summary: reminder.title, status: .succeeded)
      } catch {
        auditLog.record(
          toolName: "reminders.create", summary: error.localizedDescription, status: .failed)
      }
    }
  }

  private func previewCalendarEventUpdate() {
    guard let event = calendarEvents.first else { return }
    let preview = EventKitService().updateEventPreview(event: event, draft: calendarEventDraft)
    pendingEventKitPreview = preview
    eventKitPreview = preview.summary
    auditLog.record(
      toolName: "calendar.update_event_with_preview", summary: preview.summary,
      status: .needsConfirmation)
  }

  private func previewCalendarEventDelete() {
    guard let event = calendarEvents.first else { return }
    let preview = EventKitService().deleteEventPreview(event: event)
    pendingEventKitPreview = preview
    eventKitPreview = preview.summary
    auditLog.record(
      toolName: "calendar.delete_event_with_preview", summary: preview.summary,
      status: .needsConfirmation)
  }

  private func previewReminderUpdate() {
    guard let reminder = reminders.first else { return }
    let preview = EventKitService().updateReminderPreview(reminder: reminder, draft: reminderDraft)
    pendingEventKitPreview = preview
    eventKitPreview = preview.summary
    auditLog.record(
      toolName: "reminders.update_with_preview", summary: preview.summary,
      status: .needsConfirmation)
  }

  private func completeReminder() {
    guard let reminder = reminders.first else { return }
    Task {
      do {
        let completed = try await EventKitService().completeReminder(id: reminder.id)
        reminders = [completed]
        eventKitPreview = ""
        pendingEventKitPreview = nil
        auditLog.record(
          toolName: "reminders.complete", summary: completed.title, status: .succeeded)
      } catch {
        auditLog.record(
          toolName: "reminders.complete", summary: error.localizedDescription, status: .failed)
      }
    }
  }

  private func confirmEventKitPreview() {
    guard let preview = pendingEventKitPreview else { return }
    Task {
      do {
        let result = try await EventKitService().apply(preview)
        pendingEventKitPreview = nil
        eventKitPreview = "Confirmed: \(preview.summary)"
        switch result {
        case .event(let event):
          calendarEvents = calendarEvents.map { $0.id == event.id ? event : $0 }
        case .reminder(let reminder):
          reminders = reminders.map { $0.id == reminder.id ? reminder : $0 }
        case .deleted(let id):
          calendarEvents.removeAll { $0.id == id }
        }
        auditLog.record(
          toolName: eventKitToolName(for: preview.action), summary: preview.summary,
          status: .succeeded)
      } catch {
        auditLog.record(
          toolName: eventKitToolName(for: preview.action), summary: error.localizedDescription,
          status: .failed)
      }
    }
  }

  private func eventKitToolName(for action: EventKitChangeAction) -> String {
    switch action {
    case .updateEvent:
      "calendar.update_event_with_preview"
    case .deleteEvent:
      "calendar.delete_event_with_preview"
    case .updateReminder:
      "reminders.update_with_preview"
    }
  }

  private func requestNotificationPermission() {
    Task {
      do {
        let granted = try await NotificationService().requestPermission()
        notificationPermissionStatus = granted ? "Granted" : "Denied"
        auditLog.record(
          toolName: "notify.permission", summary: notificationPermissionStatus,
          status: granted ? .succeeded : .failed)
      } catch {
        notificationPermissionStatus = "Failed"
        auditLog.record(
          toolName: "notify.permission", summary: error.localizedDescription, status: .failed)
      }
    }
  }

  private func scheduleNotification() {
    let id = UUID().uuidString
    let draft = NotificationDraft(
      id: id,
      title: notificationTitle,
      body: notificationBody,
      delaySeconds: notificationDelaySeconds)
    Task {
      do {
        let scheduled = try await NotificationService().schedule(draft)
        scheduledNotificationID = scheduled.id
        auditLog.record(
          toolName: "notify.schedule", summary: scheduled.title, status: .succeeded)
      } catch {
        auditLog.record(
          toolName: "notify.schedule", summary: error.localizedDescription, status: .failed)
      }
    }
  }

  private func cancelNotification() {
    guard !scheduledNotificationID.isEmpty else { return }
    NotificationService().cancel(id: scheduledNotificationID)
    auditLog.record(
      toolName: "notify.cancel", summary: scheduledNotificationID, status: .succeeded)
    scheduledNotificationID = ""
  }

  private func openAppURL() {
    guard let url = URL(string: appURLString) else {
      appOpenStatus = "Invalid URL"
      auditLog.record(toolName: "app.open_url", summary: appOpenStatus, status: .failed)
      return
    }

    Task {
      do {
        let opened = try await AppURLService().openURL(url)
        appOpenStatus = opened.url.absoluteString
        auditLog.record(toolName: "app.open_url", summary: appOpenStatus, status: .succeeded)
      } catch {
        appOpenStatus = error.localizedDescription
        auditLog.record(toolName: "app.open_url", summary: appOpenStatus, status: .failed)
      }
    }
  }

  private func openAppDeepLink() {
    guard let url = URL(string: appDeepLinkString) else {
      appOpenStatus = "Invalid deeplink"
      auditLog.record(toolName: "app.open_deeplink", summary: appOpenStatus, status: .failed)
      return
    }

    Task {
      do {
        let opened = try await AppURLService().openDeepLink(url)
        appOpenStatus = opened.url.absoluteString
        auditLog.record(
          toolName: "app.open_deeplink", summary: appOpenStatus, status: .succeeded)
      } catch {
        appOpenStatus = error.localizedDescription
        auditLog.record(toolName: "app.open_deeplink", summary: appOpenStatus, status: .failed)
      }
    }
  }

  private func listSupportedAppActions() {
    supportedAppActions = AppIntentService().listSupportedActions()
    appIntentStatus = "\(supportedAppActions.count) action(s)"
    auditLog.record(
      toolName: "app_intents.list_supported_actions", summary: appIntentStatus,
      status: .succeeded)
  }

  private func invokeFirstAppAction() {
    guard let action = supportedAppActions.first else {
      appIntentStatus = "No action selected"
      auditLog.record(
        toolName: "app_intents.invoke_own_action", summary: appIntentStatus, status: .failed)
      return
    }

    do {
      let invoked = try AppIntentService().invokeOwnAction(id: action.id)
      appIntentStatus = invoked.action.title
      auditLog.record(
        toolName: "app_intents.invoke_own_action", summary: appIntentStatus, status: .succeeded)
    } catch {
      appIntentStatus = error.localizedDescription
      auditLog.record(
        toolName: "app_intents.invoke_own_action", summary: appIntentStatus, status: .failed)
    }
  }

  private func requestAudioSpeechPermissions() {
    Task {
      do {
        let permissions = try await AudioSpeechService().requestPermissions()
        audioPermissionStatus =
          permissions.microphoneGranted
          ? "Microphone granted, speech \(permissions.speechStatus.rawValue)"
          : "Microphone denied, speech \(permissions.speechStatus.rawValue)"
        auditLog.record(
          toolName: "audio.permission_status", summary: audioPermissionStatus,
          status: permissions.microphoneGranted && permissions.speechStatus == .authorized
            ? .succeeded : .failed)
      } catch {
        audioPermissionStatus = error.localizedDescription
        auditLog.record(
          toolName: "audio.permission_status", summary: audioPermissionStatus, status: .failed)
      }
    }
  }

  private func recordAudio() {
    let fileName = "agent-recording-\(Int(Date().timeIntervalSince1970)).m4a"
    let draft = AudioRecordDraft(
      fileName: fileName,
      durationSeconds: audioRecordSeconds,
      directory: audioDirectory)

    Task {
      do {
        let recording = try await AudioSpeechService().record(draft)
        latestRecording = recording
        speechTranscript = ""
        auditLog.record(toolName: "audio.record", summary: fileName, status: .succeeded)
      } catch {
        auditLog.record(
          toolName: "audio.record", summary: error.localizedDescription, status: .failed)
      }
    }
  }

  private func transcribeLatestRecording() {
    guard let latestRecording else { return }

    Task {
      do {
        let transcript = try await AudioSpeechService().transcribe(latestRecording)
        speechTranscript = transcript.text
        auditLog.record(
          toolName: "speech.transcribe", summary: transcript.text, status: .succeeded)
      } catch {
        auditLog.record(
          toolName: "speech.transcribe", summary: error.localizedDescription, status: .failed)
      }
    }
  }

  private func checkLocalModelAvailability() {
    let availability = LocalModelService().availability()
    localModelStatus =
      "classify: \(availability.classify.isAvailable ? "available" : "unavailable"); summarize/embed: unavailable"
    auditLog.record(
      toolName: "local_model.availability", summary: localModelStatus, status: .succeeded)
  }

  private func classifyLocalText() {
    do {
      let result = try LocalModelService().classify(localModelText)
      localModelClassification = result
      localModelStatus = "\(result.label) \(Int(result.confidence * 100))%"
      auditLog.record(
        toolName: "local_model.classify_if_available", summary: localModelStatus,
        status: .succeeded)
    } catch {
      localModelStatus = error.localizedDescription
      auditLog.record(
        toolName: "local_model.classify_if_available", summary: localModelStatus,
        status: .failed)
    }
  }

  private func summarizeLocalText() {
    do {
      localModelStatus = try LocalModelService().summarize(localModelText)
      auditLog.record(
        toolName: "local_model.summarize_if_available", summary: localModelStatus,
        status: .succeeded)
    } catch {
      localModelStatus = error.localizedDescription
      auditLog.record(
        toolName: "local_model.summarize_if_available", summary: localModelStatus,
        status: .failed)
    }
  }

  private func embedLocalText() {
    do {
      let embedding = try LocalModelService().embed(localModelText)
      localModelStatus = "\(embedding.count) dimensions"
      auditLog.record(
        toolName: "local_model.embed_if_available", summary: localModelStatus,
        status: .succeeded)
    } catch {
      localModelStatus = error.localizedDescription
      auditLog.record(
        toolName: "local_model.embed_if_available", summary: localModelStatus, status: .failed)
    }
  }

  private var importsDirectory: URL {
    URL.documentsDirectory.appending(path: "Imports", directoryHint: .isDirectory)
  }

  private var audioDirectory: URL {
    URL.documentsDirectory.appending(path: "Recordings", directoryHint: .isDirectory)
  }

  private var cameraDirectory: URL {
    URL.documentsDirectory.appending(path: "Camera", directoryHint: .isDirectory)
  }

  private var contactDraft: ContactDraft {
    ContactDraft(
      givenName: contactGivenName,
      familyName: contactFamilyName,
      organizationName: "",
      phoneNumber: contactPhone,
      emailAddress: contactEmail)
  }

  private var selectedPhotoIDs: [String] {
    photoAssets.prefix(10).map(\.id)
  }

  private var calendarEventDraft: CalendarEventDraft {
    let startDate = Date().addingTimeInterval(60 * 60)
    return CalendarEventDraft(
      title: calendarEventTitle,
      notes: "",
      startDate: startDate,
      endDate: startDate.addingTimeInterval(60 * 60))
  }

  private var reminderDraft: ReminderDraft {
    ReminderDraft(title: reminderTitle, notes: "", dueDate: nil)
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

private struct ShareInboxSection: View {
  let items: [SharedInboxItem]
  let status: String
  let onRefreshTapped: () -> Void
  let onImportTapped: (SharedInboxItem) -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Share Inbox")
        .font(.headline)

      Text("Local App Group inbox")
        .font(.caption)
        .foregroundStyle(.secondary)

      Text("Shared items stay in the app group until you import them into Files.")
        .font(.caption)
        .foregroundStyle(.secondary)

      Button(action: onRefreshTapped) {
        Label("Refresh Shared Items", systemImage: "square.and.arrow.down")
      }
      .buttonStyle(.bordered)

      if !status.isEmpty {
        Text(status)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      if items.isEmpty {
        Text("No shared items yet.")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      ForEach(items) { item in
        HStack {
          VStack(alignment: .leading, spacing: 2) {
            Text(item.kind.rawValue)
              .font(.caption.monospaced())
            Text(item.url.lastPathComponent)
              .lineLimit(1)
          }

          Spacer()

          Button(action: { onImportTapped(item) }) {
            Label("Import to Files", systemImage: "tray.and.arrow.down")
          }
          .buttonStyle(.bordered)
          .font(.caption)
        }
        .font(.caption)
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
  let onFolderImportTapped: () -> Void
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

      Text("Files are copied into this app and stay local.")
        .font(.caption)
        .foregroundStyle(.secondary)

      HStack {
        Button(action: onImportTapped) {
          Label(importedFileName ?? "Import File", systemImage: "doc.badge.plus")
        }
        .buttonStyle(.borderedProminent)

        Button(action: onFolderImportTapped) {
          Label("Import Folder", systemImage: "folder.badge.plus")
        }
        .buttonStyle(.bordered)
      }

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

      if index.chunks.isEmpty {
        Text("No indexed text yet. Import files, then rebuild the index.")
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
  let barcodeText: String
  let cameraStatus: String
  let onOCRImageTapped: () -> Void
  let onBarcodeImageTapped: () -> Void
  let onTakePhotoTapped: () -> Void
  let onScanDocumentTapped: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Vision")
        .font(.headline)

      HStack {
        Button(action: onOCRImageTapped) {
          Label("OCR", systemImage: "text.viewfinder")
        }
        .buttonStyle(.bordered)

        Button(action: onBarcodeImageTapped) {
          Label("Barcode", systemImage: "barcode.viewfinder")
        }
        .buttonStyle(.bordered)
      }

      HStack {
        Button(action: onTakePhotoTapped) {
          Label("Photo", systemImage: "camera")
        }
        .buttonStyle(.bordered)

        Button(action: onScanDocumentTapped) {
          Label("Scan", systemImage: "doc.viewfinder")
        }
        .buttonStyle(.bordered)
      }

      if !cameraStatus.isEmpty {
        Text(cameraStatus)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      if !ocrText.isEmpty {
        Text(ocrText)
          .font(.caption)
          .lineLimit(8)
          .padding(8)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color.secondary.opacity(0.08))
          .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
      }

      if !barcodeText.isEmpty {
        Text(barcodeText)
          .font(.caption.monospaced())
          .lineLimit(4)
          .padding(8)
          .frame(maxWidth: .infinity, alignment: .leading)
          .background(Color.secondary.opacity(0.08))
          .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
      }
    }
  }
}

private struct ImageCaptureView: UIViewControllerRepresentable {
  let completion: (Data?) -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(completion: completion)
  }

  func makeUIViewController(context: Context) -> UIImagePickerController {
    let picker = UIImagePickerController()
    picker.sourceType = .camera
    picker.delegate = context.coordinator
    return picker
  }

  func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}

  final class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate
  {
    private let completion: (Data?) -> Void

    init(completion: @escaping (Data?) -> Void) {
      self.completion = completion
    }

    func imagePickerController(
      _ picker: UIImagePickerController,
      didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey: Any]
    ) {
      completion((info[.originalImage] as? UIImage)?.jpegData(compressionQuality: 0.9))
    }

    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
      completion(nil)
    }
  }
}

private struct DocumentScannerView: UIViewControllerRepresentable {
  let completion: (Result<[Data], Error>?) -> Void

  func makeCoordinator() -> Coordinator {
    Coordinator(completion: completion)
  }

  func makeUIViewController(context: Context) -> VNDocumentCameraViewController {
    let scanner = VNDocumentCameraViewController()
    scanner.delegate = context.coordinator
    return scanner
  }

  func updateUIViewController(_ uiViewController: VNDocumentCameraViewController, context: Context)
  {}

  final class Coordinator: NSObject, VNDocumentCameraViewControllerDelegate {
    private let completion: (Result<[Data], Error>?) -> Void

    init(completion: @escaping (Result<[Data], Error>?) -> Void) {
      self.completion = completion
    }

    func documentCameraViewController(
      _ controller: VNDocumentCameraViewController,
      didFinishWith scan: VNDocumentCameraScan
    ) {
      let pages = (0..<scan.pageCount).compactMap {
        scan.imageOfPage(at: $0).jpegData(compressionQuality: 0.9)
      }
      completion(.success(pages))
    }

    func documentCameraViewControllerDidCancel(_ controller: VNDocumentCameraViewController) {
      completion(nil)
    }

    func documentCameraViewController(
      _ controller: VNDocumentCameraViewController,
      didFailWithError error: Error
    ) {
      completion(.failure(error))
    }
  }
}

private struct PhotosSection: View {
  let status: String
  @Binding var albumTitle: String
  let assets: [PhotoAssetSummary]
  let classifications: [PhotoClassificationResult]
  let preview: String
  let hasPendingPreview: Bool
  let onCheckTapped: () -> Void
  let onListTapped: () -> Void
  let onScreenshotsTapped: () -> Void
  let onClassifyTapped: () -> Void
  let onCreateAlbumTapped: () -> Void
  let onAddToAlbumTapped: () -> Void
  let onFavoriteTapped: () -> Void
  let onRemovePreviewTapped: () -> Void
  let onHidePreviewTapped: () -> Void
  let onDeletePreviewTapped: () -> Void
  let onConfirmPreviewTapped: () -> Void

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

      TextField("Album title", text: $albumTitle)
        .textFieldStyle(.roundedBorder)

      HStack {
        Button("Album", action: onCreateAlbumTapped)
          .buttonStyle(.bordered)
        Button("Add", action: onAddToAlbumTapped)
          .buttonStyle(.bordered)
        Button("Favorite", action: onFavoriteTapped)
          .buttonStyle(.bordered)
      }

      HStack {
        Button("Remove", action: onRemovePreviewTapped)
          .buttonStyle(.bordered)
        Button("Hide", action: onHidePreviewTapped)
          .buttonStyle(.bordered)
        Button("Delete", action: onDeletePreviewTapped)
          .buttonStyle(.bordered)
      }

      if !preview.isEmpty {
        Text(preview)
          .font(.caption)
          .foregroundStyle(.secondary)
        if hasPendingPreview {
          Button("Confirm", role: .destructive, action: onConfirmPreviewTapped)
            .buttonStyle(.borderedProminent)
        }
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
  @Binding var givenName: String
  @Binding var familyName: String
  @Binding var email: String
  @Binding var phone: String
  let contacts: [ContactSummary]
  let preview: String
  let hasPendingPreview: Bool
  let onCheckTapped: () -> Void
  let onSearchTapped: () -> Void
  let onDuplicatesTapped: () -> Void
  let onCreateTapped: () -> Void
  let onUpdatePreviewTapped: () -> Void
  let onDeletePreviewTapped: () -> Void
  let onMergePreviewTapped: () -> Void
  let onConfirmPreviewTapped: () -> Void

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

      TextField("Given name", text: $givenName)
        .textFieldStyle(.roundedBorder)
      TextField("Family name", text: $familyName)
        .textFieldStyle(.roundedBorder)
      TextField("Email", text: $email)
        .textFieldStyle(.roundedBorder)
      TextField("Phone", text: $phone)
        .textFieldStyle(.roundedBorder)

      HStack {
        Button("Create", action: onCreateTapped)
          .buttonStyle(.bordered)
        Button("Update", action: onUpdatePreviewTapped)
          .buttonStyle(.bordered)
        Button("Delete", action: onDeletePreviewTapped)
          .buttonStyle(.bordered)
      }

      Button("Merge", action: onMergePreviewTapped)
        .buttonStyle(.bordered)

      if !preview.isEmpty {
        Text(preview)
          .font(.caption)
          .foregroundStyle(.secondary)
        if hasPendingPreview {
          Button("Confirm", role: .destructive, action: onConfirmPreviewTapped)
            .buttonStyle(.borderedProminent)
        }
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
  let preview: String
  let hasPendingPreview: Bool
  let onCalendarTapped: () -> Void
  let onRemindersTapped: () -> Void
  let onCalendarSearchTapped: () -> Void
  let onCalendarCreateTapped: () -> Void
  let onReminderSearchTapped: () -> Void
  let onReminderCreateTapped: () -> Void
  let onCalendarUpdatePreviewTapped: () -> Void
  let onCalendarDeletePreviewTapped: () -> Void
  let onReminderUpdatePreviewTapped: () -> Void
  let onReminderCompleteTapped: () -> Void
  let onConfirmPreviewTapped: () -> Void

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
      HStack {
        Button("Update", action: onCalendarUpdatePreviewTapped)
          .buttonStyle(.bordered)
        Button("Delete", action: onCalendarDeletePreviewTapped)
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
      HStack {
        Button("Update", action: onReminderUpdatePreviewTapped)
          .buttonStyle(.bordered)
        Button("Complete", action: onReminderCompleteTapped)
          .buttonStyle(.bordered)
      }

      if !preview.isEmpty {
        Text(preview)
          .font(.caption)
          .foregroundStyle(.secondary)
        if hasPendingPreview {
          Button("Confirm", role: .destructive, action: onConfirmPreviewTapped)
            .buttonStyle(.borderedProminent)
        }
      }

      ForEach(reminders) { reminder in
        Text(reminder.isCompleted ? "\(reminder.title) - done" : reminder.title)
          .font(.caption)
          .lineLimit(1)
      }
    }
  }
}

private struct NotificationSection: View {
  let status: String
  @Binding var title: String
  @Binding var notificationBody: String
  @Binding var delaySeconds: Double
  let scheduledID: String
  let onPermissionTapped: () -> Void
  let onScheduleTapped: () -> Void
  let onCancelTapped: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Notifications")
        .font(.headline)

      HStack {
        Button("Permission", action: onPermissionTapped)
          .buttonStyle(.bordered)
        Text(status)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      TextField("Title", text: $title)
        .textFieldStyle(.roundedBorder)
      TextField("Body", text: $notificationBody)
        .textFieldStyle(.roundedBorder)
      Stepper("Delay \(Int(delaySeconds))s", value: $delaySeconds, in: 5...3600, step: 5)

      HStack {
        Button("Schedule", action: onScheduleTapped)
          .buttonStyle(.bordered)
        Button("Cancel", action: onCancelTapped)
          .buttonStyle(.bordered)
          .disabled(scheduledID.isEmpty)
      }

      if !scheduledID.isEmpty {
        Text(scheduledID)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }
    }
  }
}

private struct AppURLSection: View {
  @Binding var urlString: String
  @Binding var deepLinkString: String
  let status: String
  let onOpenURLTapped: () -> Void
  let onOpenDeepLinkTapped: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("URLs")
        .font(.headline)

      TextField("https://example.com", text: $urlString)
        .textFieldStyle(.roundedBorder)
      Button("Open URL", action: onOpenURLTapped)
        .buttonStyle(.bordered)

      TextField("app://path", text: $deepLinkString)
        .textFieldStyle(.roundedBorder)
      Button("Open Deeplink", action: onOpenDeepLinkTapped)
        .buttonStyle(.bordered)

      if !status.isEmpty {
        Text(status)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(2)
      }
    }
  }
}

private struct AppIntentSection: View {
  let actions: [SupportedAppAction]
  let status: String
  let onListTapped: () -> Void
  let onInvokeTapped: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("App Intents")
        .font(.headline)

      HStack {
        Button("List Actions", action: onListTapped)
          .buttonStyle(.bordered)
        Button("Invoke First", action: onInvokeTapped)
          .buttonStyle(.bordered)
          .disabled(actions.isEmpty)
      }

      if !status.isEmpty {
        Text(status)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      ForEach(actions) { action in
        VStack(alignment: .leading, spacing: 2) {
          Text(action.title)
          Text(action.summary)
            .foregroundStyle(.secondary)
        }
        .font(.caption)
      }
    }
  }
}

private struct AudioSpeechSection: View {
  let permissionStatus: String
  @Binding var durationSeconds: Double
  let recording: AudioRecording?
  let transcript: String
  let onPermissionTapped: () -> Void
  let onRecordTapped: () -> Void
  let onTranscribeTapped: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Audio & Speech")
        .font(.headline)

      HStack {
        Button("Permission", action: onPermissionTapped)
          .buttonStyle(.bordered)
        Text(permissionStatus)
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      Stepper("Record \(Int(durationSeconds))s", value: $durationSeconds, in: 3...60, step: 1)

      HStack {
        Button("Record", action: onRecordTapped)
          .buttonStyle(.bordered)
        Button("Transcribe", action: onTranscribeTapped)
          .buttonStyle(.bordered)
          .disabled(recording == nil)
      }

      if let recording {
        Text(recording.fileURL.lastPathComponent)
          .font(.caption)
          .foregroundStyle(.secondary)
          .lineLimit(1)
      }

      if !transcript.isEmpty {
        Text(transcript)
          .font(.caption)
          .lineLimit(3)
      }
    }
  }
}

private struct LocalModelSection: View {
  @Binding var text: String
  let status: String
  let classification: LocalModelClassification?
  let onAvailabilityTapped: () -> Void
  let onClassifyTapped: () -> Void
  let onSummarizeTapped: () -> Void
  let onEmbedTapped: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      Text("Local Models")
        .font(.headline)

      Text("Runs only on device. Summarize/embed stay unavailable until a local model is bundled.")
        .font(.caption)
        .foregroundStyle(.secondary)

      TextField("Text", text: $text, axis: .vertical)
        .textFieldStyle(.roundedBorder)
        .lineLimit(2...4)

      HStack {
        Button("Availability", action: onAvailabilityTapped)
          .buttonStyle(.bordered)
        Button("Classify", action: onClassifyTapped)
          .buttonStyle(.bordered)
        Button("Summarize", action: onSummarizeTapped)
          .buttonStyle(.bordered)
        Button("Embed", action: onEmbedTapped)
          .buttonStyle(.bordered)
      }

      if let classification {
        Text("\(classification.label) \(Int(classification.confidence * 100))%")
          .font(.caption)
          .foregroundStyle(.secondary)
      }

      if !status.isEmpty {
        Text(status)
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
