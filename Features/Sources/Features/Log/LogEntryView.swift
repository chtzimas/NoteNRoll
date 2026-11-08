import SwiftUI
import JournalCore

public struct LogEntryView: View {
    private let extractionUseCase: any ExtractionUseCase
    private let entryUseCase: any EntryUseCase
    private let followUpQuestionsUseCase: any FollowUpQuestionsUseCase
    private let notificationScheduler: any NotificationScheduler

    @StateObject private var form: LogEntryViewModel
    @State private var pendingEntry: Entry?
    @State private var isSaving = false
    @State private var saveError: String?

    public init(
        extractionUseCase: any ExtractionUseCase,
        entryUseCase: any EntryUseCase,
        followUpQuestionsUseCase: any FollowUpQuestionsUseCase,
        notificationScheduler: any NotificationScheduler,
        speechTranscriber: any SpeechTranscriber
    ) {
        self.extractionUseCase = extractionUseCase
        self.entryUseCase = entryUseCase
        self.followUpQuestionsUseCase = followUpQuestionsUseCase
        self.notificationScheduler = notificationScheduler
        _form = StateObject(wrappedValue: LogEntryViewModel(speechTranscriber: speechTranscriber))
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $form.sessionDate, displayedComponents: .date)
                    Picker("Class type", selection: $form.classType) {
                        ForEach(ClassType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                Section("What happened") {
                    recordButton
                    TextEditor(text: $form.rawText)
                        .frame(minHeight: 160)
                }

                Section {
                    Button("Save") {
                        Task { await savePendingAndContinue() }
                    }
                    .disabled(!form.canSubmit || isSaving)
                }
            }
            .navigationTitle("Log")
            .alert("Couldn't save", isPresented: .constant(saveError != nil)) {
                Button("OK") { saveError = nil }
            } message: {
                Text(saveError ?? "")
            }
            .alert("Recording unavailable", isPresented: .constant(form.recordingError != nil)) {
                Button("OK") { form.recordingError = nil }
            } message: {
                Text(form.recordingError ?? "")
            }
            .sheet(item: $pendingEntry) { entry in
                NavigationStack {
                    FollowUpView(
                        entry: entry,
                        followUpUseCase: followUpQuestionsUseCase,
                        notificationScheduler: notificationScheduler,
                        extractionUseCase: extractionUseCase,
                        entryUseCase: entryUseCase,
                        onSaved: { form.reset() }
                    )
                }
            }
        }
    }

    private var recordButton: some View {
        Button {
            form.toggleRecording()
        } label: {
            Label(
                form.isRecording ? "Stop recording" : "Record",
                systemImage: form.isRecording ? "stop.circle.fill" : "mic.circle.fill"
            )
            .foregroundStyle(form.isRecording ? .red : .accentColor)
        }
    }

    /// Saves immediately as `pending` — capture stays instant and offline-safe —
    /// then opens the follow-up flow in the same session.
    private func savePendingAndContinue() async {
        isSaving = true
        defer { isSaving = false }
        do {
            pendingEntry = try await entryUseCase.savePending(
                sessionDate: form.sessionDate,
                classType: form.classType,
                rawText: form.rawText,
                existingEntryID: nil
            )
        } catch {
            saveError = String(describing: error)
        }
    }
}
