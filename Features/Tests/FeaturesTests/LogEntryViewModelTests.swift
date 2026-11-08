import Foundation
import Testing
@testable import Features

@MainActor
@Suite
struct LogEntryViewModelTests {
    private func makeViewModel(
        speechTranscriber: FakeSpeechTranscriber = FakeSpeechTranscriber(),
        entryUseCase: FakeEntryUseCase = FakeEntryUseCase()
    ) -> LogEntryViewModel {
        LogEntryViewModel(speechTranscriber: speechTranscriber, entryUseCase: entryUseCase)
    }

    @Test
    func canSubmitIsFalseForBlankOrWhitespaceOnlyText() async throws {
        let viewModel = makeViewModel()
        #expect(viewModel.canSubmit == false)

        viewModel.rawText = "   \n  "
        #expect(viewModel.canSubmit == false)

        viewModel.rawText = "Worked butterfly sweeps."
        #expect(viewModel.canSubmit == true)
    }

    @Test
    func resetClearsRawTextOnly() async throws {
        let viewModel = makeViewModel()
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
        let viewModel = makeViewModel(speechTranscriber: transcriber)

        viewModel.startRecording()
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(viewModel.rawText == "Worked butterfly sweeps.")
        #expect(viewModel.isRecording == false) // stream finished on its own
    }

    @Test
    func startRecordingSetsErrorWhenAuthorizationDenied() async throws {
        let transcriber = FakeSpeechTranscriber()
        transcriber.authorizationGranted = false
        let viewModel = makeViewModel(speechTranscriber: transcriber)

        viewModel.startRecording()
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(viewModel.recordingError != nil)
        #expect(viewModel.isRecording == false)
    }

    @Test
    func stopRecordingCallsThroughToTranscriber() async throws {
        let transcriber = FakeSpeechTranscriber()
        let viewModel = makeViewModel(speechTranscriber: transcriber)

        viewModel.stopRecording()

        #expect(transcriber.stopCallCount == 1)
        #expect(viewModel.isRecording == false)
    }

    @Test
    func savePendingAndResetSavesAndClearsRawTextOnSuccess() async throws {
        let entryUseCase = FakeEntryUseCase()
        let viewModel = makeViewModel(entryUseCase: entryUseCase)
        viewModel.rawText = "Worked takedowns."

        let saved = await viewModel.savePendingAndReset()

        #expect(saved?.status == .pending)
        #expect(entryUseCase.pendingSaveCount == 1)
        #expect(viewModel.rawText.isEmpty)
        #expect(viewModel.saveError == nil)
    }

    @Test
    func savePendingAndResetSurfacesErrorAndKeepsRawTextOnFailure() async throws {
        let entryUseCase = FakeEntryUseCase()
        entryUseCase.savePendingResult = .failure(NSError(domain: "test", code: 1))
        let viewModel = makeViewModel(entryUseCase: entryUseCase)
        viewModel.rawText = "Worked takedowns."

        let saved = await viewModel.savePendingAndReset()

        #expect(saved == nil)
        #expect(viewModel.saveError != nil)
        #expect(viewModel.rawText == "Worked takedowns.")
    }
}
