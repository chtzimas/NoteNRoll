import Foundation
import JournalCore

/// Constructed directly by the app target (no coordinator needed — no
/// navigation here), so both the class and its initializer are public.
@MainActor
public final class YouViewModel: ObservableObject {
    @Published var apiKeyInput = ""
    @Published private(set) var savedKeyPresent = false
    @Published var statusMessage: String?

    private let apiKeyUseCase: any APIKeyUseCase

    public init(apiKeyUseCase: any APIKeyUseCase) {
        self.apiKeyUseCase = apiKeyUseCase
    }

    func refreshKeyStatus() {
        savedKeyPresent = (try? apiKeyUseCase.hasSavedKey()) ?? false
    }

    func save() {
        do {
            try apiKeyUseCase.save(apiKey: apiKeyInput)
            apiKeyInput = ""
            statusMessage = "Saved."
            refreshKeyStatus()
        } catch {
            statusMessage = "Couldn't save the key: \(error)"
        }
    }

    func remove() {
        do {
            try apiKeyUseCase.removeKey()
            statusMessage = "Removed."
            refreshKeyStatus()
        } catch {
            statusMessage = "Couldn't remove the key: \(error)"
        }
    }
}
