import Foundation
import Testing
import JournalCore
@testable import Features

@MainActor
@Suite
struct DraftReviewViewModelTests {
    private func makeViewModel(
        extractionUseCase: FakeExtractionUseCase = FakeExtractionUseCase(),
        entryUseCase: FakeEntryUseCase = FakeEntryUseCase(),
        existingEntryID: UUID? = nil
    ) -> DraftReviewViewModel {
        DraftReviewViewModel(
            sessionDate: Date(),
            classType: .gi,
            rawText: "Worked butterfly sweeps today.",
            existingEntryID: existingEntryID,
            extractionUseCase: extractionUseCase,
            entryUseCase: entryUseCase
        )
    }

    @Test
    func successfulExtractionPopulatesFieldsAndReviewingPhase() async throws {
        let extraction = FakeExtractionUseCase()
        extraction.result = .success(DraftExtraction(
            title: "Butterfly sweep",
            techniques: [Technique(name: "Butterfly sweep", type: .sweep)],
            openQuestions: ["Which grip?"]
        ))
        let viewModel = makeViewModel(extractionUseCase: extraction)

        await viewModel.runExtraction()

        #expect(viewModel.phase == .reviewing)
        #expect(viewModel.title == "Butterfly sweep")
        #expect(viewModel.techniques.count == 1)
        #expect(viewModel.openQuestions == ["Which grip?"])
    }

    @Test
    func failedExtractionSetsFailedPhaseAndErrorMessage() async throws {
        let extraction = FakeExtractionUseCase()
        extraction.result = .failure(ExtractionError.noToolCallReturned)
        let viewModel = makeViewModel(extractionUseCase: extraction)

        await viewModel.runExtraction()

        #expect(viewModel.phase == .failed)
        #expect(viewModel.errorMessage != nil)
    }

    @Test
    func saveApprovesEditedDraftThroughEntryUseCase() async throws {
        let entryUseCase = FakeEntryUseCase()
        let viewModel = makeViewModel(entryUseCase: entryUseCase)
        viewModel.title = "Edited title"

        let saved = await viewModel.save()

        #expect(saved != nil)
        #expect(entryUseCase.approvedDrafts.count == 1)
        #expect(entryUseCase.approvedDrafts.first?.title == "Edited title")
    }

    @Test
    func saveFailureReturnsNilAndSetsErrorMessage() async throws {
        let entryUseCase = FakeEntryUseCase()
        entryUseCase.approveResult = .failure(NSError(domain: "test", code: 1))
        let viewModel = makeViewModel(entryUseCase: entryUseCase)

        let saved = await viewModel.save()

        #expect(saved == nil)
        #expect(viewModel.errorMessage != nil)
    }

    @Test
    func saveAsPendingGoesThroughSavePending() async throws {
        let entryUseCase = FakeEntryUseCase()
        let viewModel = makeViewModel(entryUseCase: entryUseCase)

        let saved = await viewModel.saveAsPending()

        #expect(saved?.status == .pending)
        #expect(entryUseCase.pendingSaveCount == 1)
    }
}
