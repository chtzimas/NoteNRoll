import SwiftUI
import JournalCore

/// Pure content: no `.sheet`, no use-case dependencies. `LogCoordinatorView`
/// presents the follow-up flow once `onEntrySaved` fires. Internal, not
/// public — only `LogCoordinatorView` (same module) constructs this.
struct LogEntryView: View {
    @ObservedObject private var viewModel: LogEntryViewModel
    private let onEntrySaved: (Entry) -> Void

    init(viewModel: LogEntryViewModel, onEntrySaved: @escaping (Entry) -> Void) {
        self.viewModel = viewModel
        self.onEntrySaved = onEntrySaved
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $viewModel.sessionDate, displayedComponents: .date)
                    Picker("Class type", selection: $viewModel.classType) {
                        ForEach(ClassType.allCases, id: \.self) { type in
                            Text(type.displayName).tag(type)
                        }
                    }
                }

                Section("What happened") {
                    recordButton
                    TextEditor(text: $viewModel.rawText)
                        .frame(minHeight: 160)
                }

                Section {
                    Button("Save") {
                        Task {
                            if let entry = await viewModel.savePendingAndReset() {
                                onEntrySaved(entry)
                            }
                        }
                    }
                    .disabled(!viewModel.canSubmit || viewModel.isSaving)
                }
            }
            .navigationTitle("Log")
            .alert("Couldn't save", isPresented: .constant(viewModel.saveError != nil)) {
                Button("OK") { viewModel.saveError = nil }
            } message: {
                Text(viewModel.saveError ?? "")
            }
            .alert("Recording unavailable", isPresented: .constant(viewModel.recordingError != nil)) {
                Button("OK") { viewModel.recordingError = nil }
            } message: {
                Text(viewModel.recordingError ?? "")
            }
        }
        .logScreenAppearance("\(Self.self)")
    }

    private var recordButton: some View {
        Button {
            viewModel.toggleRecording()
        } label: {
            Label(
                viewModel.isRecording ? "Stop recording" : "Record",
                systemImage: viewModel.isRecording ? "stop.circle.fill" : "mic.circle.fill"
            )
            .foregroundStyle(viewModel.isRecording ? .red : .accentColor)
        }
    }
}
