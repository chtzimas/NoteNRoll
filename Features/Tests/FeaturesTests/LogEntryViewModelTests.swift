import Testing
@testable import Features

@MainActor
@Suite
struct LogEntryViewModelTests {
    @Test
    func canSubmitIsFalseForBlankOrWhitespaceOnlyText() async throws {
        let viewModel = LogEntryViewModel(speechTranscriber: FakeSpeechTranscriber())
        #expect(viewModel.canSubmit == false)

        viewModel.rawText = "   \n  "
        #expect(viewModel.canSubmit == false)

        viewModel.rawText = "Worked butterfly sweeps."
        #expect(viewModel.canSubmit == true)
    }

    @Test
    func resetClearsRawTextOnly() async throws {
        let viewModel = LogEntryViewModel(speechTranscriber: FakeSpeechTranscriber())
        viewModel.rawText = "Some note"
        viewModel.classType = .noGi

        viewModel.reset()

        #expect(viewModel.rawText.isEmpty)
        #expect(viewModel.classType == .noGi)
    }

    @Test
    func startRecordingFillsRawTextFromTranscriptStream() async throws {
        let transcriber = FakeSpeechTranscriber()
        transcriber.transcripts = ["Worked", "Worked butterfly", "Worked butterfly sweeps."]
        let viewModel = LogEntryViewModel(speechTranscriber: transcriber)

        viewModel.startRecording()
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(viewModel.rawText == "Worked butterfly sweeps.")
        #expect(viewModel.isRecording == false) // stream finished on its own
    }

    @Test
    func startRecordingSetsErrorWhenAuthorizationDenied() async throws {
        let transcriber = FakeSpeechTranscriber()
        transcriber.authorizationGranted = false
        let viewModel = LogEntryViewModel(speechTranscriber: transcriber)

        viewModel.startRecording()
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(viewModel.recordingError != nil)
        #expect(viewModel.isRecording == false)
    }

    @Test
    func stopRecordingCallsThroughToTranscriber() async throws {
        let transcriber = FakeSpeechTranscriber()
        let viewModel = LogEntryViewModel(speechTranscriber: transcriber)

        viewModel.stopRecording()

        #expect(transcriber.stopCallCount == 1)
        #expect(viewModel.isRecording == false)
    }
}
