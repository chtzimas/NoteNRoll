import Testing
@testable import Features

@MainActor
@Suite
struct LogEntryViewModelTests {
    @Test
    func canSubmitIsFalseForBlankOrWhitespaceOnlyText() async throws {
        let viewModel = LogEntryViewModel()
        #expect(viewModel.canSubmit == false)

        viewModel.rawText = "   \n  "
        #expect(viewModel.canSubmit == false)

        viewModel.rawText = "Worked butterfly sweeps."
        #expect(viewModel.canSubmit == true)
    }

    @Test
    func resetClearsRawTextOnly() async throws {
        let viewModel = LogEntryViewModel()
        viewModel.rawText = "Some note"
        viewModel.classType = .noGi

        viewModel.reset()

        #expect(viewModel.rawText.isEmpty)
        #expect(viewModel.classType == .noGi)
    }
}
