import SwiftUI
import JournalCore

/// Owns the Journal tab's navigation state and is the only thing that
/// constructs its screens' view models — `JournalListView`, `FollowUpView`,
/// `DraftReviewView` and `EntryDetailView` never see a use-case protocol or
/// build their own view model; they only receive one already made.
@MainActor
public final class JournalCoordinator: ObservableObject {
    @Published var path: [JournalRoute] = []
    let listViewModel: JournalListViewModel

    private let entryUseCase: any EntryUseCase
    private let extractionUseCase: any ExtractionUseCase
    private let followUpQuestionsUseCase: any FollowUpQuestionsUseCase
    private let notificationScheduler: any NotificationScheduler

    public init(
        entryUseCase: any EntryUseCase,
        extractionUseCase: any ExtractionUseCase,
        followUpQuestionsUseCase: any FollowUpQuestionsUseCase,
        notificationScheduler: any NotificationScheduler
    ) {
        self.entryUseCase = entryUseCase
        self.extractionUseCase = extractionUseCase
        self.followUpQuestionsUseCase = followUpQuestionsUseCase
        self.notificationScheduler = notificationScheduler
        self.listViewModel = JournalListViewModel(entryUseCase: entryUseCase)
    }

    @ViewBuilder
    func destination(for route: JournalRoute) -> some View {
        switch route {
        case .followUp(let entry):
            FollowUpView(
                viewModel: FollowUpViewModel(
                    entry: entry,
                    followUpUseCase: followUpQuestionsUseCase,
                    notificationScheduler: notificationScheduler
                ),
                onContinue: { [weak self] params in self?.path.append(.draftReview(params)) }
            )
        case .entryDetail(let entry):
            EntryDetailView(entry: entry)
        case .draftReview(let params):
            DraftReviewView(
                viewModel: makeDraftReviewViewModel(params),
                onSaved: { [weak self] in self?.handleSaved() }
            )
        }
    }

    private func makeDraftReviewViewModel(_ params: DraftReviewParams) -> DraftReviewViewModel {
        DraftReviewViewModel(
            sessionDate: params.sessionDate,
            classType: params.classType,
            rawText: params.rawText,
            extractionContext: params.extractionContext,
            existingEntryID: params.existingEntryID,
            startsInManualMode: params.startsInManualMode,
            extractionUseCase: extractionUseCase,
            entryUseCase: entryUseCase
        )
    }

    /// Entries this deep (`list -> followUp -> draftReview`) are saved — pop
    /// all the way back to the list and show the freshly structured entry.
    func handleSaved() {
        path.removeAll()
        Task { await listViewModel.reload() }
    }
}
