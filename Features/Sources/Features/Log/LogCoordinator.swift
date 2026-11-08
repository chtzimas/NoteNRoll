import SwiftUI
import JournalCore

/// Owns the Log tab's state: the composer's view model, whether the
/// follow-up sheet is presented, and navigation within that sheet. Same role
/// as `JournalCoordinator` for the Journal tab — constructs every view model
/// so `LogEntryView`/`FollowUpView`/`DraftReviewView` never have to.
@MainActor
public final class LogCoordinator: ObservableObject {
    let formViewModel: LogEntryViewModel
    @Published var presentedEntry: Entry?
    @Published var sheetPath: [LogRoute] = []

    private let entryUseCase: any EntryUseCase
    private let extractionUseCase: any ExtractionUseCase
    private let followUpQuestionsUseCase: any FollowUpQuestionsUseCase
    private let notificationScheduler: any NotificationScheduler

    public init(
        entryUseCase: any EntryUseCase,
        extractionUseCase: any ExtractionUseCase,
        followUpQuestionsUseCase: any FollowUpQuestionsUseCase,
        notificationScheduler: any NotificationScheduler,
        speechTranscriber: any SpeechTranscriber
    ) {
        self.entryUseCase = entryUseCase
        self.extractionUseCase = extractionUseCase
        self.followUpQuestionsUseCase = followUpQuestionsUseCase
        self.notificationScheduler = notificationScheduler
        self.formViewModel = LogEntryViewModel(speechTranscriber: speechTranscriber, entryUseCase: entryUseCase)
    }

    func entrySaved(_ entry: Entry) {
        presentedEntry = entry
        sheetPath = []
    }

    func dismissSheet() {
        presentedEntry = nil
        sheetPath = []
    }

    @ViewBuilder
    func followUpView(for entry: Entry) -> some View {
        FollowUpView(
            viewModel: FollowUpViewModel(
                entry: entry,
                followUpUseCase: followUpQuestionsUseCase,
                notificationScheduler: notificationScheduler
            ),
            onContinue: { [weak self] params in self?.sheetPath.append(.draftReview(params)) }
        )
    }

    @ViewBuilder
    func destination(for route: LogRoute) -> some View {
        switch route {
        case .draftReview(let params):
            DraftReviewView(
                viewModel: DraftReviewViewModel(
                    sessionDate: params.sessionDate,
                    classType: params.classType,
                    rawText: params.rawText,
                    extractionContext: params.extractionContext,
                    existingEntryID: params.existingEntryID,
                    startsInManualMode: params.startsInManualMode,
                    extractionUseCase: extractionUseCase,
                    entryUseCase: entryUseCase
                ),
                onSaved: { [weak self] in self?.dismissSheet() }
            )
        }
    }
}
