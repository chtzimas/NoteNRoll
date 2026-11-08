import Foundation
import Testing
import JournalCore
@testable import Features

@MainActor
@Suite
struct LogCoordinatorTests {
    private func makeCoordinator() -> LogCoordinator {
        LogCoordinator(
            entryUseCase: FakeEntryUseCase(),
            extractionUseCase: FakeExtractionUseCase(),
            followUpQuestionsUseCase: FakeFollowUpQuestionsUseCase(),
            notificationScheduler: FakeNotificationScheduler(),
            speechTranscriber: FakeSpeechTranscriber()
        )
    }

    @Test
    func startsWithNoPresentedEntry() {
        let coordinator = makeCoordinator()
        #expect(coordinator.presentedEntry == nil)
        #expect(coordinator.sheetPath.isEmpty)
    }

    @Test
    func entrySavedPresentsItAndResetsSheetPath() {
        let coordinator = makeCoordinator()
        let entry = Entry(sessionDate: Date(), classType: .gi, rawText: "raw", status: .pending)
        coordinator.sheetPath = [.draftReview(
            DraftReviewParams(sessionDate: Date(), classType: .gi, rawText: "x", extractionContext: nil, existingEntryID: nil, startsInManualMode: false)
        )]

        coordinator.entrySaved(entry)

        #expect(coordinator.presentedEntry == entry)
        #expect(coordinator.sheetPath.isEmpty)
    }

    @Test
    func dismissSheetClearsPresentedEntryAndSheetPath() {
        let coordinator = makeCoordinator()
        let entry = Entry(sessionDate: Date(), classType: .gi, rawText: "raw", status: .pending)
        coordinator.entrySaved(entry)

        coordinator.dismissSheet()

        #expect(coordinator.presentedEntry == nil)
        #expect(coordinator.sheetPath.isEmpty)
    }
}
