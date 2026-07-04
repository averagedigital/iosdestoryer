# iOS Agent

Native iPhone agent app scaffold built around official Apple permission domains. The app calls local tools from an in-app registry and records tool activity in an audit log.

## Current Increment

- Empty repository was scaffolded minimally.
- SwiftUI app shell: chat input, tool list, and audit section.
- The app uses separate SwiftUI tabs for Chat, Sources/Permissions, Index, Audit, and Settings/Privacy.
- Chat keeps a session transcript and shows app-local tool call cards for routed requests.
- Chat input routes obvious local requests to existing app-local tools and records the selected tool call in the audit log.
- `AgentCore` Swift package: tool registry and audit log.
- `files.pick_file` core import service: copies a user-picked file into the app container and keeps same-name imports instead of overwriting.
- `files.pick_folder` copies a user-picked folder into the app container with nested files preserved for local search/indexing.
- `files.list_allowed_sources` shows the app-managed Imports directory only.
- `files.write`, `files.copy`, `files.move`, `files.delete_with_preview`, and `files.extract_text` operate only inside app-managed Imports.
- `files.read` UTF-8 reader for app-managed imported files.
- `files.search` lexical search over imported UTF-8 files, with skipped non-text files surfaced.
- `files.context_bundle` local Markdown bundle builder for matched imported files.
- `index.add_source`, `index.rebuild`, `index.search`, `index.get_chunks`, and `index.export_context_bundle` build a local chunk index from app-managed UTF-8 imports.
- `vision.ocr_image` OCR over image data through Apple's Vision framework.
- `vision.ocr_pdf_or_file_image` OCR over user-picked image/PDF files; PDFs render locally through PDFKit before Vision OCR.
- `camera.permission_status`, `camera.permission`, `camera.take_photo`, `camera.scan_document`, and `vision.detect_barcodes_if_easy` use foreground AVFoundation/UIKit/VisionKit/Vision flows only.
- `photos.permission_status` inspects and explicitly requests PhotoKit authorization without reading assets.
- `photos.list_assets`, `photos.find_screenshots`, `photos.find_documents`, `photos.classify_candidates`, `photos.create_album`, `photos.add_to_album`, `photos.favorite`, `photos.remove_from_album_with_preview`, `photos.hide_with_preview`, and `photos.delete_with_preview` use PhotoKit after Photos authorization.
- Photo destructive tools require a preview first, then a separate Confirm action applies the stored preview through PhotoKit change requests.
- `contacts.permission_status` inspects and explicitly requests Contacts authorization.
- `contacts.search`, `contacts.create`, `contacts.update_with_preview`, `contacts.delete_with_preview`, `contacts.find_duplicate_candidates`, and `contacts.merge_preview` use Contacts after explicit authorization.
- Contact update/delete tools require a preview first, then a separate Confirm action applies the stored preview through Contacts save requests.
- Contact merge requires a preview first, then Confirm updates the primary contact and removes duplicate contacts in a Contacts save request.
- `calendar.permission_status` and `reminders.permission_status` inspect and explicitly request EventKit authorization.
- `calendar.search_events`, `calendar.create_event`, `calendar.update_event_with_preview`, `calendar.delete_event_with_preview`, `reminders.search`, `reminders.create`, `reminders.update_with_preview`, and `reminders.complete` use EventKit after explicit authorization.
- Calendar event update/delete and reminder update tools require a preview first, then a separate Confirm action applies the stored preview through EventKit save/remove requests.
- `notify.permission_status`, `notify.permission`, `notify.schedule`, and `notify.cancel` use UserNotifications with explicit permission before scheduling.
- `AgentShareExtension` receives shared text, URLs, images, and files through the iOS share sheet, then writes them into the shared App Group inbox for `share.list_inbox`.
- Shared inbox items can be imported into app-managed Files and the local index from the Sources UI.
- `app.open_url` and `app.open_deeplink` use `UIApplication.open` for explicit user-visible navigation only.
- `app_intents.list_supported_actions` and `app_intents.invoke_own_action` expose this app's own supported action list; `OpenAgentWorkspaceIntent` registers an App Shortcut for opening the workspace.
- `shortcuts.run_user_configured_shortcut` opens a named user-created Shortcut through the official Shortcuts URL scheme; it does not control arbitrary third-party apps.
- `audio.permission_status`, `audio.permission`, `audio.record`, and `speech.transcribe` use AVFoundation and Speech after explicit user action and permission; transcription requires on-device recognition.
- `local_model.classify_if_available` uses NaturalLanguage on device; `local_model.summarize_if_available` and `local_model.embed_if_available` return explicit unavailable results until a local Core ML/Foundation Models-backed model is bundled.
- Tests cover the first contract: public Apple API tools only, destructive tools require preview, and audit events keep order.

## Verified Apple API Boundaries

- Files: `UIDocumentPickerViewController` gives user-mediated access to external files and folders. Security-scoped URLs must be accessed explicitly.
- Photos: PhotoKit supports permission status, limited-library access, asset queries, and `PHPhotoLibrary.performChanges` for user-authorized mutations.
- Contacts: `CNContactStore` reads and saves contacts, and `CNSaveRequest` batches contact changes; contact notes are not used because `CNContactNoteKey` requires an entitlement.
- Calendar/reminders: EventKit `EKEventStore` searches events/reminders, saves requested items, and locates reminders by identifier before completion.
- Notifications: UserNotifications schedules and cancels local notification requests after user permission.
- Share: Share Extension ingestion is the supported path for content from other apps; the app reads only its own inbox, not third-party app containers.
- URLs/deeplinks: `UIApplication.open` can open explicit URLs; the app does not depend on private schemes or claim third-party app control.
- OCR: Vision text recognition is available through `VNRecognizeTextRequest` / `RecognizeTextRequest`; selected PDFs are rendered locally with PDFKit before OCR.
- Camera/scanning: `UIImagePickerController` and `VNDocumentCameraViewController` present foreground camera UI; if unsupported, the app reports that explicitly.
- Barcodes: Vision barcode detection returns structured payload/symbology/confidence results for selected images.
- App Intents: App Intents expose this app's own actions to Shortcuts, Siri, Spotlight, widgets, and system experiences. They are not arbitrary third-party app control.
- Shortcuts URL scheme: `shortcuts://run-shortcut` can run a named shortcut from the user's Shortcuts collection.
- Speech/audio: AVFoundation records only after a visible app action and microphone permission; Speech transcription requires explicit speech permission and on-device recognition.
- Local models: NaturalLanguage can classify text locally; Core ML requires a bundled/downloaded model; Foundation Models access is availability-gated and must not imply remote private-data export.

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
- https://developer.apple.com/documentation/pdfkit/pdfpage
- https://developer.apple.com/documentation/pdfkit/pdfpage/draw%28with%3A%29
- https://developer.apple.com/documentation/uniformtypeidentifiers/uttype-swift.struct
- https://developer.apple.com/documentation/uikit/uiimagepickercontroller/sourcetype-swift.enum/camera
- https://developer.apple.com/documentation/visionkit/vndocumentcameraviewcontroller
- https://developer.apple.com/documentation/vision/detectbarcodesrequest
- https://developer.apple.com/documentation/appintents
- https://support.apple.com/guide/shortcuts/run-a-shortcut-from-a-url-apd624386f42/ios
- https://developer.apple.com/documentation/avfaudio/avaudiorecorder
- https://developer.apple.com/documentation/speech/sfspeechrecognizer
- https://developer.apple.com/documentation/naturallanguage/nllanguagerecognizer
- https://developer.apple.com/documentation/coreml/
- https://developer.apple.com/documentation/foundationmodels

## Architecture

- `iOSAgent/`: SwiftUI app target.
- `Sources/AgentCore/`: testable agent contracts and local tool metadata.
- `Tests/AgentCoreTests/`: narrow behavior tests.

## Validation Gaps

- Real-device permission prompts and limited-access behavior still need manual validation for Photos, Contacts, Calendar, Reminders, Camera, Microphone, Speech, and Notifications.
- Share Extension ingestion must be checked from the iOS share sheet on a simulator/device.
- App Intents and user-configured Shortcut execution must be checked from Shortcuts/Siri surfaces.

Next feature should fill only the remaining verified validation gaps.

## Objective Matrix

| Objective area | Status | Evidence / gap |
| --- | --- | --- |
| Native iOS app, public Apple APIs only | Implemented | SwiftUI app target, AgentCore package, no private API or GUI automation claim. |
| Chat-like agent UI | Implemented | Chat tab has transcript, input, routed tool cards, and audit-backed statuses. |
| Separate app screens | Implemented | Tabs: Chat, Sources, Index, Audit, Settings. |
| Tool registry | Implemented | `ToolRegistry.defaultRegistry()` lists app-local tools by permission domain. |
| Audit log | Implemented | Tool calls record ordered status entries and are shown in Audit. |
| Files and local index | Implemented | Imports, app-managed file ops, text extraction, lexical index/search, context bundle. |
| OCR, camera, barcode | Implemented with simulator limits | Image/PDF OCR, foreground camera/scanner UI, barcode detection; hardware camera needs device validation. |
| Photos | Implemented with manual validation gap | Permission status/request, listing, candidates, albums, favorite, previewed remove/hide/delete. |
| Contacts | Implemented with manual validation gap | Permission status/request, search/create, previewed update/delete/merge. |
| Calendar and reminders | Implemented with manual validation gap | Permission status/request, search/create, previewed update/delete, reminder completion. |
| Share Extension | Implemented with manual validation gap | Extension imports text, URL, file, image into App Group inbox; share sheet path still needs manual smoke. |
| Notifications | Implemented with manual validation gap | Permission request, schedule, cancel. |
| URLs, App Intents, Shortcuts | Implemented with manual validation gap | Explicit URL/deeplink open, own App Intent, user-configured Shortcut URL. |
| Audio and speech | Implemented with manual validation gap | Visible in-app recording and on-device speech transcription after permission. |
| Local models | Partial by design | NaturalLanguage classification works; summarize/embed return explicit unavailable until a model is bundled. |
| Remote private-data boundary | Implemented | No remote model integration is present; local-only behavior by default. |
| Simulator smoke | Passed | Build, install, launch, and screenshot passed on iPhone 17 / iOS 26.5 simulator. |

## Last Simulator Smoke

- `xcodebuild -project iOSAgent.xcodeproj -scheme iOSAgent -destination 'id=30E8D997-708D-4051-AF90-4A7D90310F5B' -derivedDataPath /tmp/iosagent-dd build` passed on iPhone 17 / iOS 26.5 simulator.
- `xcrun simctl install .../iOSAgent.app`, `xcrun simctl launch ... com.averagedigital.iosagent`, and `xcrun simctl io ... screenshot /tmp/iosagent-chat.png` passed.
