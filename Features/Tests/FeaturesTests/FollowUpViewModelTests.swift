import Foundation
import Testing
import JournalCore
@testable import Features

@MainActor
@Suite
struct FollowUpViewModelTests {
    private func makeEntry(rawText: String = "Worked butterfly sweeps today.") -> Entry {
        Entry(sessionDate: Date(), classType: .gi, rawText: rawText, status: .pending)
    }

    @Test
    func loadQuestionsWithResultsEntersAnsweringPhaseAndSchedulesNotification() async throws {
        let followUp = FakeFollowUpQuestionsUseCase()
        followUp.result = .success(["Which grip?", "Which side?"])
        let scheduler = FakeNotificationScheduler()
        let entry = makeEntry()
        let viewModel = FollowUpViewModel(entry: entry, followUpUseCase: followUp, notificationScheduler: scheduler)

        await viewModel.loadQuestions()

        #expect(viewModel.phase == .answering)
        #expect(viewModel.questions == ["Which grip?", "Which side?"])
        #expect(viewModel.answers == ["", ""])
        #expect(scheduler.scheduledEntryIDs == [entry.id])
    }

    @Test
    func loadQuestionsWithNoneEntersNoQuestionsNeededAndDoesNotSchedule() async throws {
        let followUp = FakeFollowUpQuestionsUseCase()
        followUp.result = .success([])
        let scheduler = FakeNotificationScheduler()
        let viewModel = FollowUpViewModel(entry: makeEntry(), followUpUseCase: followUp, notificationScheduler: scheduler)

        await viewModel.loadQuestions()

        #expect(viewModel.phase == .noQuestionsNeeded)
        #expect(scheduler.scheduledEntryIDs.isEmpty)
    }

    @Test
    func loadQuestionsFailureEntersFailedPhase() async throws {
        let followUp = FakeFollowUpQuestionsUseCase()
        followUp.result = .failure(FollowUpQuestionsError.noToolCallReturned)
        let viewModel = FollowUpViewModel(
            entry: makeEntry(),
            followUpUseCase: followUp,
            notificationScheduler: FakeNotificationScheduler()
        )

        await viewModel.loadQuestions()

        #expect(viewModel.phase == .failed)
        #expect(viewModel.errorMessage != nil)
    }

    @Test
    func extractionContextCombinesRawTextWithAnsweredQuestionsOnly() async throws {
        let followUp = FakeFollowUpQuestionsUseCase()
        followUp.result = .success(["Which grip?", "Which side?"])
        let entry = makeEntry()
        let viewModel = FollowUpViewModel(
            entry: entry,
            followUpUseCase: followUp,
            notificationScheduler: FakeNotificationScheduler()
        )
        await viewModel.loadQuestions()

        viewModel.answers = ["Collar grip", ""] // second question left unanswered

        let context = viewModel.extractionContext
        #expect(context.hasPrefix(entry.rawText))
        #expect(context.contains("Q: Which grip?\nA: Collar grip"))
        #expect(!context.contains("Which side?"))
    }

    @Test
    func extractionContextFallsBackToRawTextWhenNothingAnswered() async throws {
        let followUp = FakeFollowUpQuestionsUseCase()
        followUp.result = .success(["Which grip?"])
        let entry = makeEntry()
        let viewModel = FollowUpViewModel(
            entry: entry,
            followUpUseCase: followUp,
            notificationScheduler: FakeNotificationScheduler()
        )
        await viewModel.loadQuestions()

        #expect(viewModel.extractionContext == entry.rawText)
    }

    @Test
    func markHandledCancelsTheScheduledNotification() async throws {
        let scheduler = FakeNotificationScheduler()
        let entry = makeEntry()
        let viewModel = FollowUpViewModel(
            entry: entry,
            followUpUseCase: FakeFollowUpQuestionsUseCase(),
            notificationScheduler: scheduler
        )

        viewModel.markHandled()

        #expect(scheduler.canceledEntryIDs == [entry.id])
    }
}
