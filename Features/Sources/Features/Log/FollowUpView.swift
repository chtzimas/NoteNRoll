import SwiftUI
import JournalCore

/// Shown right after a pending entry is saved (from the Log tab) or whenever the
/// user opens a pending entry later from the Journal list — same view either way.
struct FollowUpView: View {
    @StateObject private var viewModel: FollowUpViewModel
    private let extractionUseCase: any ExtractionUseCase
    private let entryUseCase: any EntryUseCase
    private let onSaved: () -> Void

    init(
        entry: Entry,
        followUpUseCase: any FollowUpQuestionsUseCase,
        notificationScheduler: any NotificationScheduler,
        extractionUseCase: any ExtractionUseCase,
        entryUseCase: any EntryUseCase,
        onSaved: @escaping () -> Void = {}
    ) {
        _viewModel = StateObject(wrappedValue: FollowUpViewModel(
            entry: entry,
            followUpUseCase: followUpUseCase,
            notificationScheduler: notificationScheduler
        ))
        self.extractionUseCase = extractionUseCase
        self.entryUseCase = entryUseCase
        self.onSaved = onSaved
    }

    var body: some View {
        Group {
            switch viewModel.phase {
            case .loadingQuestions:
                ProgressView("Checking for follow-ups…")
            case .failed:
                failedView
            case .noQuestionsNeeded:
                draftReview(extractionContext: viewModel.entry.rawText)
            case .answering:
                answeringForm
            }
        }
        .navigationTitle("Debrief")
        .inlineNavigationBarTitleIfAvailable()
        .task { await viewModel.loadQuestions() }
        .logScreenAppearance("\(Self.self)")
    }

    /// This entry is already saved regardless — nothing here should be a dead
    /// end. Whatever the cause (no API key, offline, rate-limited), the raw
    /// note stays visible and the user can always continue by hand.
    private var failedView: some View {
        Form {
            Section("Your note") {
                Text(viewModel.entry.rawText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section {
                Text(viewModel.errorMessage ?? "Couldn't reach Claude.")
                    .foregroundStyle(.secondary)
                Button("Try again") { Task { await viewModel.loadQuestions() } }
                NavigationLink {
                    draftReview(extractionContext: viewModel.entry.rawText, startsInManualMode: true)
                } label: {
                    Text("Continue without AI")
                }
                .simultaneousGesture(TapGesture().onEnded { viewModel.markHandled() })
            } header: {
                Text("Couldn't check for follow-ups")
            }
        }
    }

    private var answeringForm: some View {
        Form {
            Section("Your note") {
                Text(viewModel.entry.rawText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            ForEach(viewModel.questions.indices, id: \.self) { index in
                Section(viewModel.questions[index]) {
                    TextField("Your answer", text: $viewModel.answers[index], axis: .vertical)
                }
            }

            Section {
                NavigationLink {
                    draftReview(extractionContext: viewModel.extractionContext)
                } label: {
                    Text("Continue")
                }
                .simultaneousGesture(TapGesture().onEnded { viewModel.markHandled() })
            }
        }
    }

    private func draftReview(extractionContext: String, startsInManualMode: Bool = false) -> some View {
        DraftReviewView(
            sessionDate: viewModel.entry.sessionDate,
            classType: viewModel.entry.classType,
            rawText: viewModel.entry.rawText,
            extractionContext: extractionContext,
            existingEntryID: viewModel.entry.id,
            startsInManualMode: startsInManualMode,
            extractionUseCase: extractionUseCase,
            entryUseCase: entryUseCase,
            onSaved: onSaved
        )
    }
}
