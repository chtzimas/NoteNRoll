import SwiftUI
import JournalCore

/// Shows a raw note, runs extraction, and lets the user edit and approve the
/// resulting draft before anything is saved. Used both right after typing a note
/// (`existingEntryID == nil`) and when retrying a pending entry from the Journal
/// list (`existingEntryID` set, so saving updates that row instead of inserting).
struct DraftReviewView: View {
    @Environment(\.dismiss) private var dismiss
    @StateObject private var viewModel: DraftReviewViewModel
    private let onSaved: () -> Void

    init(viewModel: DraftReviewViewModel, onSaved: @escaping () -> Void = {}) {
        _viewModel = StateObject(wrappedValue: viewModel)
        self.onSaved = onSaved
    }

    var body: some View {
        Group {
            switch viewModel.phase {
            case .extracting:
                ProgressView("Structuring your note…")
            case .failed:
                failedView
            case .reviewing:
                reviewForm
            }
        }
        .navigationTitle("Review")
        .inlineNavigationBarTitleIfAvailable()
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            if viewModel.phase == .reviewing {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save entry") { Task { await save { await viewModel.save() } } }
                        .disabled(viewModel.isSaving)
                }
            }
        }
        .task {
            if !viewModel.startsInManualMode {
                await viewModel.runExtraction()
            }
        }
        .logScreenAppearance("\(Self.self)")
    }

    private var failedView: some View {
        ContentUnavailableView {
            Label("Couldn't structure this note", systemImage: "exclamationmark.triangle")
        } description: {
            Text(viewModel.errorMessage ?? "Something went wrong talking to Claude.")
        } actions: {
            Button("Enter manually") { viewModel.enterManualMode() }
            Button("Save as-is, structure later") { Task { await save { await viewModel.saveAsPending() } } }
            Button("Try again") { Task { await viewModel.runExtraction() } }
        }
    }

    private var reviewForm: some View {
        Form {
            Section("Raw note") {
                Text(viewModel.rawText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Title") {
                TextField("Title", text: $viewModel.title)
            }

            Section("Techniques") {
                ForEach(viewModel.techniques.indices, id: \.self) { index in
                    TechniqueRow(technique: $viewModel.techniques[index])
                }
                .onDelete { viewModel.techniques.remove(atOffsets: $0) }
                Button("Add technique") {
                    viewModel.techniques.append(Technique(name: "", type: .other))
                }
            }

            Section("Coach's details") {
                TextField("What the coach said", text: $viewModel.coachDetails, axis: .vertical)
            }
            Section("What worked") {
                TextField("What worked", text: $viewModel.whatWorked, axis: .vertical)
            }
            Section("What went wrong") {
                TextField("What went wrong", text: $viewModel.whatWentWrong, axis: .vertical)
            }

            Section("Open questions") {
                ForEach(viewModel.openQuestions.indices, id: \.self) { index in
                    TextField("Question", text: $viewModel.openQuestions[index])
                }
                .onDelete { viewModel.openQuestions.remove(atOffsets: $0) }
                Button("Add question") { viewModel.openQuestions.append("") }
            }

            Section("Duration") {
                TextField("Minutes", text: $viewModel.durationMinutesText)
                    .numberPadKeyboardIfAvailable()
            }
        }
    }

    /// Runs a save operation on the view model and, only on success, notifies the
    /// caller and dismisses — on failure the view model's `errorMessage` is left
    /// for the view to show instead.
    private func save(_ operation: () async -> Entry?) async {
        guard await operation() != nil else { return }
        onSaved()
        dismiss()
    }
}

private struct TechniqueRow: View {
    @Binding var technique: Technique

    var body: some View {
        VStack(alignment: .leading) {
            TextField("Name", text: $technique.name)
            TextField("Position (optional)", text: Binding(
                get: { technique.position ?? "" },
                set: { technique.position = $0.isEmpty ? nil : $0 }
            ))
            .font(.footnote)
            Picker("Type", selection: $technique.type) {
                ForEach(TechniqueType.allCases, id: \.self) { type in
                    Text(type.rawValue).tag(type)
                }
            }
            .font(.footnote)
        }
    }
}
