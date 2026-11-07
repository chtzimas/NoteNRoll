import SwiftUI
import JournalCore

public struct LogEntryView: View {
    private let extractionUseCase: any ExtractionUseCase
    private let entryUseCase: any EntryUseCase

    @StateObject private var form = LogEntryViewModel()
    @State private var isPresentingDraft = false

    public init(extractionUseCase: any ExtractionUseCase, entryUseCase: any EntryUseCase) {
        self.extractionUseCase = extractionUseCase
        self.entryUseCase = entryUseCase
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
                    TextEditor(text: $form.rawText)
                        .frame(minHeight: 160)
                }

                Section {
                    Button("Structure it") {
                        isPresentingDraft = true
                    }
                    .disabled(!form.canSubmit)
                }
            }
            .navigationTitle("Log")
            .sheet(isPresented: $isPresentingDraft) {
                NavigationStack {
                    DraftReviewView(
                        sessionDate: form.sessionDate,
                        classType: form.classType,
                        rawText: form.rawText,
                        existingEntryID: nil,
                        extractionUseCase: extractionUseCase,
                        entryUseCase: entryUseCase,
                        onSaved: { form.reset() }
                    )
                }
            }
        }
    }
}
