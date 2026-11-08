import Foundation
import JournalCore

/// Owns the composer's form state, including voice capture. Recording and
/// transcription happen on-device — nothing here needs Claude or the network,
/// matching "capture is offline and instant."
@MainActor
final class LogEntryViewModel: ObservableObject {
    @Published var sessionDate = Date()
    @Published var classType: ClassType = .gi
    @Published var rawText = ""
    @Published private(set) var isRecording = false
    @Published var recordingError: String?
    @Published private(set) var isSaving = false
    @Published var saveError: String?

    private let speechTranscriber: any SpeechTranscriber
    private let entryUseCase: any EntryUseCase
    private var transcriptionTask: Task<Void, Never>?

    init(speechTranscriber: any SpeechTranscriber, entryUseCase: any EntryUseCase) {
        self.speechTranscriber = speechTranscriber
        self.entryUseCase = entryUseCase
    }

    var canSubmit: Bool {
        !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func toggleRecording() {
        if isRecording {
            stopRecording()
        } else {
            startRecording()
        }
    }

    func startRecording() {
        guard !isRecording else { return }
        recordingError = nil

        transcriptionTask = Task { [weak self] in
            guard let self else { return }
            guard await speechTranscriber.requestAuthorization() else {
                recordingError = "Microphone and speech recognition access are needed to record."
                return
            }

            do {
                isRecording = true
                let stream = try await speechTranscriber.startTranscribing()
                for try await transcript in stream {
                    rawText = transcript
                }
            } catch {
                recordingError = String(describing: error)
            }
            isRecording = false
        }
    }

    func stopRecording() {
        speechTranscriber.stopTranscribing()
        transcriptionTask?.cancel()
        transcriptionTask = nil
        isRecording = false
    }

    /// Saves immediately as `pending` — capture stays instant and offline-safe
    /// — and clears the form on success. Returns the saved entry so the caller
    /// (its coordinator) can present the follow-up flow for it.
    @discardableResult
    func savePendingAndReset() async -> Entry? {
        isSaving = true
        defer { isSaving = false }
        do {
            let entry = try await entryUseCase.savePending(
                sessionDate: sessionDate,
                classType: classType,
                rawText: rawText,
                existingEntryID: nil
            )
            reset()
            return entry
        } catch {
            saveError = String(describing: error)
            return nil
        }
    }

    func reset() {
        rawText = ""
    }
}
