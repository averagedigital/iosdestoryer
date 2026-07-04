import Foundation

#if os(iOS) && canImport(AVFoundation) && canImport(Speech)
  import AVFoundation
  import Speech
#endif

public struct AudioSpeechService {
  private let provider: any AudioSpeechProviding

  public init(provider: any AudioSpeechProviding = SystemAudioSpeechProvider()) {
    self.provider = provider
  }

  public func requestPermissions() async throws -> AudioSpeechPermissions {
    try await provider.requestPermissions()
  }

  public func record(_ draft: AudioRecordDraft) async throws -> AudioRecording {
    guard draft.durationSeconds > 0 else {
      throw AudioSpeechServiceError.invalidDuration
    }
    guard !draft.fileName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
      throw AudioSpeechServiceError.invalidFileName
    }
    return try await provider.record(draft)
  }

  public func transcribe(_ recording: AudioRecording) async throws -> SpeechTranscript {
    try await provider.transcribe(recording)
  }
}

public protocol AudioSpeechProviding {
  func requestPermissions() async throws -> AudioSpeechPermissions
  func record(_ draft: AudioRecordDraft) async throws -> AudioRecording
  func transcribe(_ recording: AudioRecording) async throws -> SpeechTranscript
}

public struct AudioSpeechPermissions: Equatable, Sendable {
  public let microphoneGranted: Bool
  public let speechStatus: SpeechPermissionStatus

  public init(microphoneGranted: Bool, speechStatus: SpeechPermissionStatus) {
    self.microphoneGranted = microphoneGranted
    self.speechStatus = speechStatus
  }
}

public enum SpeechPermissionStatus: String, Equatable, Sendable {
  case notDetermined
  case denied
  case restricted
  case authorized
  case unavailable
}

public struct AudioRecordDraft: Equatable, Sendable {
  public let fileName: String
  public let durationSeconds: TimeInterval
  public let directory: URL

  public init(fileName: String, durationSeconds: TimeInterval, directory: URL) {
    self.fileName = fileName
    self.durationSeconds = durationSeconds
    self.directory = directory
  }
}

public struct AudioRecording: Equatable, Identifiable, Sendable {
  public let id: String
  public let fileURL: URL
  public let durationSeconds: TimeInterval

  public init(id: String, fileURL: URL, durationSeconds: TimeInterval) {
    self.id = id
    self.fileURL = fileURL
    self.durationSeconds = durationSeconds
  }
}

public struct SpeechTranscript: Equatable, Sendable {
  public let recordingID: String
  public let text: String

  public init(recordingID: String, text: String) {
    self.recordingID = recordingID
    self.text = text
  }
}

public enum AudioSpeechServiceError: Error, Equatable {
  case invalidDuration
  case invalidFileName
  case unsupportedPlatform
  case microphoneDenied
  case speechDenied(SpeechPermissionStatus)
  case recordingFailed
  case speechRecognizerUnavailable
  case onDeviceRecognitionUnavailable
  case emptyTranscript
}

#if os(iOS) && canImport(AVFoundation) && canImport(Speech)
  public final class SystemAudioSpeechProvider: AudioSpeechProviding {
    private var recorder: AVAudioRecorder?

    public init() {}

    public func requestPermissions() async throws -> AudioSpeechPermissions {
      let microphoneGranted = await requestMicrophonePermission()
      let speechStatus = await requestSpeechPermission()
      return AudioSpeechPermissions(
        microphoneGranted: microphoneGranted, speechStatus: speechStatus)
    }

    public func record(_ draft: AudioRecordDraft) async throws -> AudioRecording {
      let permissions = try await requestPermissions()
      guard permissions.microphoneGranted else {
        throw AudioSpeechServiceError.microphoneDenied
      }

      try FileManager.default.createDirectory(
        at: draft.directory,
        withIntermediateDirectories: true)
      let fileURL = draft.directory.appending(path: draft.fileName)
      let settings: [String: Any] = [
        AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
        AVSampleRateKey: 12_000,
        AVNumberOfChannelsKey: 1,
        AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue,
      ]

      let session = AVAudioSession.sharedInstance()
      try session.setCategory(.playAndRecord, mode: .spokenAudio)
      try session.setActive(true)

      let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
      guard recorder.record(forDuration: draft.durationSeconds) else {
        throw AudioSpeechServiceError.recordingFailed
      }
      self.recorder = recorder

      return AudioRecording(
        id: fileURL.lastPathComponent,
        fileURL: fileURL,
        durationSeconds: draft.durationSeconds)
    }

    public func transcribe(_ recording: AudioRecording) async throws -> SpeechTranscript {
      guard let recognizer = SFSpeechRecognizer(), recognizer.isAvailable else {
        throw AudioSpeechServiceError.speechRecognizerUnavailable
      }
      guard recognizer.supportsOnDeviceRecognition else {
        throw AudioSpeechServiceError.onDeviceRecognitionUnavailable
      }

      let status = await requestSpeechPermission()
      guard status == .authorized else {
        throw AudioSpeechServiceError.speechDenied(status)
      }

      let request = SFSpeechURLRecognitionRequest(url: recording.fileURL)
      request.requiresOnDeviceRecognition = true

      let text: String = try await withCheckedThrowingContinuation {
        (continuation: CheckedContinuation<String, any Error>) in
        var resumed = false
        recognizer.recognitionTask(with: request) { result, error in
          if let error, !resumed {
            resumed = true
            continuation.resume(throwing: error)
            return
          }

          guard let result, result.isFinal, !resumed else { return }
          resumed = true
          continuation.resume(returning: result.bestTranscription.formattedString)
        }
      }

      guard !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
        throw AudioSpeechServiceError.emptyTranscript
      }
      return SpeechTranscript(recordingID: recording.id, text: text)
    }

    private func requestMicrophonePermission() async -> Bool {
      await withCheckedContinuation { continuation in
        AVAudioApplication.requestRecordPermission { granted in
          continuation.resume(returning: granted)
        }
      }
    }

    private func requestSpeechPermission() async -> SpeechPermissionStatus {
      await withCheckedContinuation { continuation in
        SFSpeechRecognizer.requestAuthorization { status in
          continuation.resume(returning: SpeechPermissionStatus(status))
        }
      }
    }
  }

  extension SpeechPermissionStatus {
    fileprivate init(_ status: SFSpeechRecognizerAuthorizationStatus) {
      switch status {
      case .notDetermined:
        self = .notDetermined
      case .denied:
        self = .denied
      case .restricted:
        self = .restricted
      case .authorized:
        self = .authorized
      @unknown default:
        self = .unavailable
      }
    }
  }
#else
  public struct SystemAudioSpeechProvider: AudioSpeechProviding {
    public init() {}

    public func requestPermissions() async throws -> AudioSpeechPermissions {
      AudioSpeechPermissions(microphoneGranted: false, speechStatus: .unavailable)
    }

    public func record(_ draft: AudioRecordDraft) async throws -> AudioRecording {
      throw AudioSpeechServiceError.unsupportedPlatform
    }

    public func transcribe(_ recording: AudioRecording) async throws -> SpeechTranscript {
      throw AudioSpeechServiceError.unsupportedPlatform
    }
  }
#endif
