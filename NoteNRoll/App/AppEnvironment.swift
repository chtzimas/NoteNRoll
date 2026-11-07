import Foundation
import JournalCore

/// Composition root. The one place concrete `JournalCore` Data types (GRDB, Keychain,
/// `DirectClaudeClient`) get wired together and handed to use cases — everything
/// above this, views and view models alike, depends only on the use-case protocols.
@MainActor
final class AppEnvironment: ObservableObject {
    let entryUseCase: any EntryUseCase
    let extractionUseCase: any ExtractionUseCase
    let apiKeyUseCase: any APIKeyUseCase

    init() {
        let database: AppDatabase
        do {
            database = try AppDatabase.onDisk(at: Self.databaseURL())
        } catch {
            fatalError("Failed to open the journal database: \(error)")
        }

        let apiKeyStore = KeychainStore()
        let repository = GRDBEntryRepository(database: database)
        let llmClient = DirectClaudeClient(apiKeyStore: apiKeyStore)

        self.entryUseCase = DefaultEntryUseCase(repository: repository)
        self.extractionUseCase = DefaultExtractionUseCase(llmClient: llmClient)
        self.apiKeyUseCase = DefaultAPIKeyUseCase(store: apiKeyStore)
    }

    private static func databaseURL() -> URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("journal.sqlite")
    }
}
