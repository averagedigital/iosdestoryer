# iOS Agent

Native iPhone agent app scaffold built around official Apple permission domains. The app calls local tools from an in-app registry and records tool activity in an audit log.

## Current Increment

- Empty repository was scaffolded minimally.
- SwiftUI app shell: chat input, tool list, and audit section.
- `AgentCore` Swift package: tool registry and audit log.
- `files.pick_file` core import service: copies a user-picked file into the app container and keeps same-name imports instead of overwriting.
- `files.list_allowed_sources` shows the app-managed Imports directory only.
- `files.write`, `files.copy`, `files.move`, `files.delete_with_preview`, and `files.extract_text` operate only inside app-managed Imports.
- `files.read` UTF-8 reader for app-managed imported files.
- `files.search` lexical search over imported UTF-8 files, with skipped non-text files surfaced.
- `files.context_bundle` local Markdown bundle builder for matched imported files.
- `index.rebuild`, `index.search`, `index.get_chunks`, and `index.export_context_bundle` build a local chunk index from app-managed UTF-8 imports.
- `vision.ocr_image` OCR over user-picked image files through Apple's Vision framework.
- `photos.permission_status` inspectable PhotoKit authorization status without reading assets.
- `contacts.permission_status` inspectable Contacts authorization status without reading contacts.
- `calendar.permission_status` and `reminders.permission_status` inspectable EventKit authorization status without reading events or reminders.
- Tests cover the first contract: public Apple API tools only, destructive tools require preview, and audit events keep order.

## Verified Apple API Boundaries

- Files: `UIDocumentPickerViewController` gives user-mediated access to external files and folders. Security-scoped URLs must be accessed explicitly.
- Photos: PhotoKit supports permission status, limited-library access, asset queries, and `PHPhotoLibrary.performChanges` for user-authorized mutations.
- OCR: Vision text recognition is available through `VNRecognizeTextRequest` / `RecognizeTextRequest`.
- App Intents: App Intents expose this app's own actions to Shortcuts, Siri, Spotlight, widgets, and system experiences. They are not arbitrary third-party app control.

Sources checked:

- https://developer.apple.com/documentation/uikit/uidocumentpickerviewcontroller
- https://developer.apple.com/documentation/uikit/providing-access-to-directories
- https://developer.apple.com/documentation/Photos/PHPhotoLibrary
- https://developer.apple.com/documentation/photokit/requesting-changes-to-the-photo-library
- https://developer.apple.com/documentation/vision/recognizing-text-in-images
- https://developer.apple.com/documentation/appintents

## Architecture

- `iOSAgent/`: SwiftUI app target.
- `Sources/AgentCore/`: testable agent contracts and local tool metadata.
- `Tests/AgentCoreTests/`: narrow behavior tests.

Next feature should be `files.pick_file` plus app-container import/index stub, because it is the smallest useful permission-based workflow and does not require Photos/Contacts entitlements yet.
