import XCTest

@testable import AgentCore

final class AudioSpeechServiceTests: XCTestCase {
  func testRequestsInspectablePermissionsThroughProvider() async throws {
    let service = AudioSpeechService(provider: StubAudioSpeechProvider())

    let permissions = try await service.requestPermissions()

    XCTAssertTrue(permissions.microphoneGranted)
    XCTAssertEqual(permissions.speechStatus, .authorized)
  }

  func testStartsRecordingThroughProvider() async throws {
    let service = AudioSpeechService(provider: StubAudioSpeechProvider())

    let recording = try await service.record(
      AudioRecordDraft(fileName: "note.m4a", durationSeconds: 5, directory: URL.temporaryDirectory))

    XCTAssertEqual(recording.fileURL.lastPathComponent, "note.m4a")
    XCTAssertEqual(recording.durationSeconds, 5)
  }

  func testRejectsInvalidRecordingDuration() async {
    let service = AudioSpeechService(provider: StubAudioSpeechProvider())

    do {
      _ = try await service.record(
        AudioRecordDraft(fileName: "bad.m4a", durationSeconds: 0, directory: URL.temporaryDirectory)
      )
      XCTFail("Expected invalid duration")
    } catch {
      XCTAssertEqual(error as? AudioSpeechServiceError, .invalidDuration)
    }
  }

  func testRejectsBlankRecordingFileName() async {
    let service = AudioSpeechService(provider: StubAudioSpeechProvider())

    do {
      _ = try await service.record(
        AudioRecordDraft(fileName: " ", durationSeconds: 5, directory: URL.temporaryDirectory))
      XCTFail("Expected invalid file name")
    } catch {
      XCTAssertEqual(error as? AudioSpeechServiceError, .invalidFileName)
    }
  }

  func testTranscribesRecordingThroughProvider() async throws {
    let service = AudioSpeechService(provider: StubAudioSpeechProvider())
    let recording = AudioRecording(
      id: "audio-1",
      fileURL: URL(fileURLWithPath: "/tmp/audio-1.m4a"),
      durationSeconds: 5)

    let transcript = try await service.transcribe(recording)

    XCTAssertEqual(transcript.recordingID, "audio-1")
    XCTAssertEqual(transcript.text, "signed contract due friday")
  }
}

private struct StubAudioSpeechProvider: AudioSpeechProviding {
  func requestPermissions() async throws -> AudioSpeechPermissions {
    AudioSpeechPermissions(microphoneGranted: true, speechStatus: .authorized)
  }

  func record(_ draft: AudioRecordDraft) async throws -> AudioRecording {
    AudioRecording(
      id: draft.fileName,
      fileURL: draft.directory.appending(path: draft.fileName),
      durationSeconds: draft.durationSeconds)
  }

  func transcribe(_ recording: AudioRecording) async throws -> SpeechTranscript {
    SpeechTranscript(recordingID: recording.id, text: "signed contract due friday")
  }
}
