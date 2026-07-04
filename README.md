# iOS Agent

Native iPhone agent app scaffold built around official Apple permission domains. The app calls local tools from an in-app registry and records tool activity in an audit log.

## Current Increment

- Empty repository was scaffolded minimally.
- SwiftUI app shell: chat input, tool list, and audit section.
- `AgentCore` Swift package: tool registry and audit log.
- `files.pick_file` core import service: copies a user-picked file into the app container and keeps same-name imports instead of overwriting.
- `files.pick_folder` copies a user-picked folder into the app container with nested files preserved for local search/indexing.
- `files.list_allowed_sources` shows the app-managed Imports directory only.
- `files.write`, `files.copy`, `files.move`, `files.delete_with_preview`, and `files.extract_text` operate only inside app-managed Imports.
- `files.read` UTF-8 reader for app-managed imported files.
- `files.search` lexical search over imported UTF-8 files, with skipped non-text files surfaced.
- `files.context_bundle` local Markdown bundle builder for matched imported files.
- `index.rebuild`, `index.search`, `index.get_chunks`, and `index.export_context_bundle` build a local chunk index from app-managed UTF-8 imports.
- `vision.ocr_image` OCR over user-picked image files through Apple's Vision framework.
- `camera.take_photo`, `camera.scan_document`, and `vision.detect_barcodes_if_easy` use foreground UIKit/VisionKit/Vision flows only.
- `photos.permission_status` inspectable PhotoKit authorization status without reading assets.
- `photos.list_assets`, `photos.find_screenshots`, `photos.find_documents`, `photos.classify_candidates`, `photos.create_album`, `photos.add_to_album`, `photos.favorite`, `photos.remove_from_album_with_preview`, `photos.hide_with_preview`, and `photos.delete_with_preview` use PhotoKit after Photos authorization.
- `contacts.permission_status`, `contacts.search`, `contacts.create`, `contacts.update_with_preview`, `contacts.delete_with_preview`, `contacts.find_duplicate_candidates`, and `contacts.merge_preview` use Contacts after explicit authorization.
- `calendar.permission_status`, `calendar.search_events`, `calendar.create_event`, `calendar.update_event_with_preview`, `calendar.delete_event_with_preview`, `reminders.permission_status`, `reminders.search`, `reminders.create`, `reminders.update_with_preview`, and `reminders.complete` use EventKit after explicit authorization.
- `notify.schedule` and `notify.cancel` use UserNotifications after explicit permission.
- `share.import_text`, `share.import_url`, `share.import_file`, `share.import_image`, and `share.list_inbox` model Share Extension ingestion into an app-owned inbox. The extension target still needs App Group wiring before other apps can send content into it.
- `app.open_url` and `app.open_deeplink` use `UIApplication.open` for explicit user-visible navigation only.
- `app_intents.list_supported_actions` and `app_intents.invoke_own_action` expose this app's own supported action list; `OpenAgentWorkspaceIntent` registers an App Shortcut for opening the workspace.
- `audio.record` and `speech.transcribe` use AVFoundation and Speech after explicit user action and permission; transcription requires on-device recognition.
- Tests cover the first contract: public Apple API tools only, destructive tools require preview, and audit events keep order.

## Verified Apple API Boundaries

- Files: `UIDocumentPickerViewController` gives user-mediated access to external files and folders. Security-scoped URLs must be accessed explicitly.
- Photos: PhotoKit supports permission status, limited-library access, asset queries, and `PHPhotoLibrary.performChanges` for user-authorized mutations.
- Contacts: `CNContactStore` reads and saves contacts, and `CNSaveRequest` batches contact changes; contact notes are not used because `CNContactNoteKey` requires an entitlement.
- Calendar/reminders: EventKit `EKEventStore` searches events/reminders, saves requested items, and locates reminders by identifier before completion.
- Notifications: UserNotifications schedules and cancels local notification requests after user permission.
- Share: Share Extension ingestion is the supported path for content from other apps; the app reads only its own inbox, not third-party app containers.
- URLs/deeplinks: `UIApplication.open` can open explicit URLs; the app does not depend on private schemes or claim third-party app control.
- OCR: Vision text recognition is available through `VNRecognizeTextRequest` / `RecognizeTextRequest`.
- Camera/scanning: `UIImagePickerController` and `VNDocumentCameraViewController` present foreground camera UI; if unsupported, the app reports that explicitly.
- Barcodes: Vision barcode detection returns structured payload/symbology/confidence results for selected images.
- App Intents: App Intents expose this app's own actions to Shortcuts, Siri, Spotlight, widgets, and system experiences. They are not arbitrary third-party app control.
- Speech/audio: AVFoundation records only after a visible app action and microphone permission; Speech transcription requires explicit speech permission and on-device recognition.

Sources checked:

- https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller
- https://developer.apple.com/documentation/uikit/providing-access-to-directories
- https://developer.apple.com/documentation/Photos/PHPhotoLibrary
- https://developer.apple.com/documentation/photokit/requesting-changes-to-the-photo-library
- https://developer.apple.com/documentation/photos/phassetchangerequest
- https://developer.apple.com/documentation/photos/phassetcollectionchangerequest
- https://developer.apple.com/documentation/contacts/cncontactstore
- https://developer.apple.com/documentation/contacts/cnsaverequest
- https://developer.apple.com/documentation/eventkit/ekeventstore/calendaritem%28withidentifier%3A%29
- https://developer.apple.com/documentation/eventkit/creating-events-and-reminders
- https://developer.apple.com/documentation/usernotifications/unusernotificationcenter
- https://developer.apple.com/documentation/usernotifications/untimeintervalnotificationtrigger
- https://developer.apple.com/app-extensions/
- https://developer.apple.com/documentation/uikit/uiapplication/open(_:options:completionhandler:)
- https://developer.apple.com/documentation/vision/recognizing-text-in-images
- https://developer.apple.com/documentation/uikit/uiimagepickercontroller/sourcetype-swift.enum/camera
- https://developer.apple.com/documentation/visionkit/vndocumentcameraviewcontroller
- https://developer.apple.com/documentation/vision/detectbarcodesrequest
- https://developer.apple.com/documentation/appintents
- https://developer.apple.com/documentation/avfaudio/avaudiorecorder
- https://developer.apple.com/documentation/speech/sfspeechrecognizer

## Architecture

- `iOSAgent/`: SwiftUI app target.
- `Sources/AgentCore/`: testable agent contracts and local tool metadata.
- `Tests/AgentCoreTests/`: narrow behavior tests.

Next feature should be the real Share Extension target/App Group wiring; the current share inbox core already models the app-owned ingestion behavior.
