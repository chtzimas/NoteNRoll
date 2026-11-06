import SwiftUI
import JournalCore

/// Shows a raw note, runs extraction, and lets the user edit and approve the
/// resulting draft before anything is saved. Used both right after typing a note
/// (`existingEntryID == nil`) and when retrying a pending entry from the Journal
/// list (`existingEntryID` set, so saving updates that row instead of inserting).
struct DraftReviewView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @Environment(\.dismiss) private var dismiss

    let sessionDate: Date
    let classType: ClassType
    let rawText: String
    let existingEntryID: UUID?
    var onSaved: () -> Void = {}

    @State private var phase: Phase = .extracting
    @State private var errorMessage: String?

    @State private var title = ""
    @State private var techniques: [Technique] = []
    @State private var coachDetails = ""
    @State private var whatWorked = ""
    @State private var whatWentWrong = ""
    @State private var openQuestions: [String] = []
    @State private var durationMinutesText = ""
    @State private var isSaving = false

    private enum Phase: Equatable {
        case extracting
        case reviewing
        case failed
    }

    var body: some View {
        Group {
            switch phase {
            case .extracting:
                ProgressView("Structuring your note…")
            case .failed:
                failedView
            case .reviewing:
                reviewForm
            }
        }
        .navigationTitle("Review")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Cancel") { dismiss() }
            }
            if phase == .reviewing {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save entry") { Task { await save() } }
                        .disabled(isSaving)
                }
            }
        }
        .task { await runExtraction() }
    }

    private var failedView: some View {
        ContentUnavailableView {
            Label("Couldn't structure this note", systemImage: "exclamationmark.triangle")
        } description: {
            Text(errorMessage ?? "Something went wrong talking to Claude.")
        } actions: {
            Button("Save as-is, structure later") { Task { await saveAsPending() } }
            Button("Try again") { Task { await runExtraction() } }
        }
    }

    private var reviewForm: some View {
        Form {
            Section("Raw note") {
                Text(rawText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("Title") {
                TextField("Title", text: $title)
            }

            Section("Techniques") {
                ForEach(techniques.indices, id: \.self) { index in
                    TechniqueRow(technique: $techniques[index])
                }
                .onDelete { techniques.remove(atOffsets: $0) }
                Button("Add technique") {
                    techniques.append(Technique(name: "", type: .other))
                }
            }

            Section("Coach's details") {
                TextField("What the coach said", text: $coachDetails, axis: .vertical)
            }
            Section("What worked") {
                TextField("What worked", text: $whatWorked, axis: .vertical)
            }
            Section("What went wrong") {
                TextField("What went wrong", text: $whatWentWrong, axis: .vertical)
            }

            Section("Open questions") {
                ForEach($openQuestions.indices, id: \.self) { index in
                    TextField("Question", text: $openQuestions[index])
                }
                .onDelete { openQuestions.remove(atOffsets: $0) }
                Button("Add question") { openQuestions.append("") }
            }

            Section("Duration") {
                TextField("Minutes", text: $durationMinutesText)
                    .keyboardType(.numberPad)
            }
        }
    }

    private func runExtraction() async {
        phase = .extracting
        errorMessage = nil
        do {
            let draft = try await environment.extractionService.extract(rawText: rawText)
            apply(draft)
            phase = .reviewing
        } catch {
            errorMessage = String(describing: error)
            phase = .failed
        }
    }

    private func apply(_ draft: DraftExtraction) {
        title = draft.title ?? ""
        techniques = draft.techniques
        coachDetails = draft.coachDetails ?? ""
        whatWorked = draft.whatWorked ?? ""
        whatWentWrong = draft.whatWentWrong ?? ""
        openQuestions = draft.openQuestions
        durationMinutesText = draft.durationMinutes.map(String.init) ?? ""
    }

    private func save() async {
        isSaving = true
        defer { isSaving = false }

        let entry = Entry(
            id: existingEntryID ?? UUID(),
            sessionDate: sessionDate,
            classType: classType,
            rawText: rawText,
            status: .structured,
            title: title.isEmpty ? nil : title,
            techniques: techniques.filter { !$0.name.isEmpty },
            coachDetails: coachDetails.isEmpty ? nil : coachDetails,
            whatWorked: whatWorked.isEmpty ? nil : whatWorked,
            whatWentWrong: whatWentWrong.isEmpty ? nil : whatWentWrong,
            openQuestions: openQuestions.filter { !$0.isEmpty },
            durationMinutes: Int(durationMinutesText)
        )

        do {
            if existingEntryID != nil {
                try await environment.entryRepository.update(entry)
            } else {
                try await environment.entryRepository.insert(entry)
            }
            NotificationCenter.default.post(name: .entriesDidChange, object: nil)
            onSaved()
            dismiss()
        } catch {
            errorMessage = String(describing: error)
        }
    }

    /// Keeps the raw text as a pending entry when extraction fails, so nothing the
    /// user typed is lost — they can retry structuring it later from the Journal list.
    private func saveAsPending() async {
        let entry = Entry(
            id: existingEntryID ?? UUID(),
            sessionDate: sessionDate,
            classType: classType,
            rawText: rawText,
            status: .pending
        )
        do {
            if existingEntryID != nil {
                try await environment.entryRepository.update(entry)
            } else {
                try await environment.entryRepository.insert(entry)
            }
            NotificationCenter.default.post(name: .entriesDidChange, object: nil)
            onSaved()
            dismiss()
        } catch {
            errorMessage = String(describing: error)
        }
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
