import Foundation
import Testing
import JournalCore
@testable import Features

@MainActor
@Suite
struct JournalCoordinatorTests {
    private func makeCoordinator(entryUseCase: FakeEntryUseCase = FakeEntryUseCase()) -> JournalCoordinator {
        JournalCoordinator(
            entryUseCase: entryUseCase,
            extractionUseCase: FakeExtractionUseCase(),
            followUpQuestionsUseCase: FakeFollowUpQuestionsUseCase(),
            notificationScheduler: FakeNotificationScheduler()
        )
    }

    @Test
    func pathStartsEmpty() {
        let coordinator = makeCoordinator()
        #expect(coordinator.path.isEmpty)
    }

    @Test
    func handleSavedClearsPathAndReloadsTheList() async throws {
        let entryUseCase = FakeEntryUseCase()
        let entry = Entry(sessionDate: Date(), classType: .gi, rawText: "raw", status: .structured)
        entryUseCase.entriesToReturn = [entry]
        let coordinator = makeCoordinator(entryUseCase: entryUseCase)
        coordinator.path = [.entryDetail(entry)]

        coordinator.handleSaved()
        try await Task.sleep(nanoseconds: 50_000_000)

        #expect(coordinator.path.isEmpty)
        #expect(coordinator.listViewModel.entries == [entry])
    }
}
