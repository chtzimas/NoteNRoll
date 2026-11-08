public enum TranscriptionError: Error, Sendable, Equatable {
    case authorizationDenied
    case recognizerUnavailable
    case audioEngineFailure(String)
}

/// On-device speech-to-text. Yields the full transcript so far on every partial
/// result (not a delta), matching how `SFSpeechRecognizer` itself reports
/// progress — callers just display the latest value.
public protocol SpeechTranscriber: Sendable {
    func requestAuthorization() async -> Bool
    func startTranscribing() async throws -> AsyncThrowingStream<String, Error>
    func stopTranscribing()
}
