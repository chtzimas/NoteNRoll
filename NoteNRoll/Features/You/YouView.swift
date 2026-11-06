import SwiftUI
import JournalCore

/// Mostly a placeholder for now — belt/stripes, curriculum, import and export all
/// arrive with later milestones. The API key field is real: extraction needs
/// somewhere for the user to enter it, and Settings is where the brief puts it.
struct YouView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var apiKeyInput = ""
    @State private var savedKeyPresent = false
    @State private var statusMessage: String?

    var body: some View {
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
                    SecureField("Claude API key", text: $apiKeyInput)
                        .textContentType(.password)
                    Button("Save to Keychain") { save() }
                        .disabled(apiKeyInput.isEmpty)
                    if savedKeyPresent {
                        Button("Remove key", role: .destructive) { remove() }
                    }
                } header: {
                    Text("Claude API key")
                } footer: {
                    Text(savedKeyPresent ? "A key is saved in the Keychain." : "No key saved yet — Log and extraction need one.")
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
            .task { refreshKeyStatus() }
            .alert("API key", isPresented: .constant(statusMessage != nil)) {
                Button("OK") { statusMessage = nil }
            } message: {
                Text(statusMessage ?? "")
            }
        }
    }

    private func refreshKeyStatus() {
        savedKeyPresent = (try? environment.keychainStore.loadAPIKey())?.isEmpty == false
    }

    private func save() {
        do {
            try environment.keychainStore.save(apiKey: apiKeyInput)
            apiKeyInput = ""
            statusMessage = "Saved."
            refreshKeyStatus()
        } catch {
            statusMessage = "Couldn't save the key: \(error)"
        }
    }

    private func remove() {
        do {
            try environment.keychainStore.deleteAPIKey()
            statusMessage = "Removed."
            refreshKeyStatus()
        } catch {
            statusMessage = "Couldn't remove the key: \(error)"
        }
    }
}

#Preview {
    YouView()
        .environmentObject(AppEnvironment())
}
