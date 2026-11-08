import SwiftUI
import JournalCore

/// Shown right after a pending entry is saved (from the Log tab) or whenever the
/// user opens a pending entry later from the Journal list — same view either way.
/// Purely declarative: it never constructs `DraftReviewView` or its view model
/// itself, since this view is hosted by two different navigation stacks (Journal's
/// own, and the Log tab's sheet) that need the result wrapped differently. It only
/// reports what happened via `onContinue`; the owning coordinator decides what to
/// push.
struct FollowUpView: View {
    @StateObject private var viewModel: FollowUpViewModel
    private let onContinue: (DraftReviewParams) -> Void

    init(viewModel: FollowUpViewModel, onContinue: @escaping (DraftReviewParams) -> Void) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onContinue = onContinue
    }

    var body: some View {
        Group {
            switch viewModel.phase {
            case .loadingQuestions, .noQuestionsNeeded:
                ProgressView("Checking for follow-ups…")
            case .failed:
                failedView
            case .answering:
                answeringForm
            }
        }
        .navigationTitle("Debrief")
        .inlineNavigationBarTitleIfAvailable()
        .task {
            await viewModel.loadQuestions()
            if viewModel.phase == .noQuestionsNeeded {
                onContinue(viewModel.draftReviewParams())
            }
        }
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
                Button("Continue without AI") {
                    viewModel.markHandled()
                    onContinue(viewModel.draftReviewParams(startsInManualMode: true))
                }
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
                Button("Continue") {
                    viewModel.markHandled()
                    onContinue(viewModel.draftReviewParams())
                }
            }
        }
    }
}
