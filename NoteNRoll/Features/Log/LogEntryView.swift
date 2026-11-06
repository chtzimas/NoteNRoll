import SwiftUI
import JournalCore

struct LogEntryView: View {
    @State private var sessionDate = Date()
    @State private var classType: ClassType = .gi
    @State private var rawText = ""
    @State private var isPresentingDraft = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $sessionDate, displayedComponents: .date)
                    Picker("Class type", selection: $classType) {
                        ForEach(ClassType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                Section("What happened") {
                    TextEditor(text: $rawText)
                        .frame(minHeight: 160)
                }

                Section {
                    Button("Structure it") {
                        isPresentingDraft = true
                    }
                    .disabled(rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
            .navigationTitle("Log")
            .sheet(isPresented: $isPresentingDraft) {
                NavigationStack {
                    DraftReviewView(
                        sessionDate: sessionDate,
                        classType: classType,
                        rawText: rawText,
                        existingEntryID: nil,
                        onSaved: { rawText = "" }
                    )
                }
            }
        }
    }
}

#Preview {
    LogEntryView()
        .environmentObject(AppEnvironment())
}
