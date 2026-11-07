import SwiftUI
import JournalCore

/// Mostly a placeholder for now — belt/stripes, curriculum, import and export all
/// arrive with later milestones. The API key field is real: extraction needs
/// somewhere for the user to enter it, and Settings is where the brief puts it.
public struct YouView: View {
    @StateObject private var viewModel: YouViewModel

    public init(apiKeyUseCase: any APIKeyUseCase) {
        _viewModel = StateObject(wrappedValue: YouViewModel(apiKeyUseCase: apiKeyUseCase))
    }

    public var body: some View {
        NavigationStack {
            Form {
                Section("Training profile") {
                    LabeledContent("Belt", value: "Coming soon")
                    LabeledContent("Goals", value: "Coming soon")
                }

                Section("My curriculum") {
                    Text("Coming soon — Insights will check your entries against this list.")
                        .foregroundStyle(.secondary)
                }

                Section {
                    SecureField("Claude API key", text: $viewModel.apiKeyInput)
                        .textContentType(.password)
                    Button("Save to Keychain") { viewModel.save() }
                        .disabled(viewModel.apiKeyInput.isEmpty)
                    if viewModel.savedKeyPresent {
                        Button("Remove key", role: .destructive) { viewModel.remove() }
                    }
                } header: {
                    Text("Claude API key")
                } footer: {
                    Text(viewModel.savedKeyPresent ? "A key is saved in the Keychain." : "No key saved yet — Log and extraction need one.")
                }

                Section("Import notes") {
                    Text("Coming soon — paste, files, Apple Notes.")
                        .foregroundStyle(.secondary)
                }
                Section("Export journal") {
                    Text("Coming soon — Markdown, JSON.")
                        .foregroundStyle(.secondary)
                }

                Text("Your journal stays on this iPhone. No account needed.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .navigationTitle("You")
            .onAppear { viewModel.refreshKeyStatus() }
            .alert("API key", isPresented: .constant(viewModel.statusMessage != nil)) {
                Button("OK") { viewModel.statusMessage = nil }
            } message: {
                Text(viewModel.statusMessage ?? "")
            }
        }
    }
}
