import Foundation
import JournalCore

/// Composition root. The one place the app wires concrete `JournalCore` types
/// together; feature views only ever see `EntryRepository` and `ExtractionService`.
@MainActor
final class AppEnvironment: ObservableObject {
    let entryRepository: EntryRepository
    let extractionService: ExtractionService
    let keychainStore: KeychainStore

    init() {
        let database: AppDatabase
        do {
            database = try AppDatabase.onDisk(at: Self.databaseURL())
        } catch {
            fatalError("Failed to open the journal database: \(error)")
        }

        let keychainStore = KeychainStore()
        let client = DirectClaudeClient(apiKeyProvider: { try keychainStore.requireAPIKey() })

        self.entryRepository = EntryRepository(database: database)
        self.extractionService = ExtractionService(llmClient: client)
        self.keychainStore = keychainStore
    }

    private static func databaseURL() -> URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("journal.sqlite")
    }
}
