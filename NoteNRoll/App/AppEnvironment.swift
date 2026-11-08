import Foundation
import JournalCore
import Features

/// Composition root. The one place concrete `JournalCore` Data types (GRDB, Keychain,
/// `DirectClaudeClient`) get wired together, handed to use cases, and those use cases
/// handed to coordinators — the only things downstream of here (coordinators, view
/// models, views) ever see are use-case protocols, and only coordinators see those.
/// Views never construct a view model or a use case; they receive one already built.
@MainActor
final class AppEnvironment: ObservableObject {
    let journalCoordinator: JournalCoordinator
    let logCoordinator: LogCoordinator
    let youViewModel: YouViewModel

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

        let entryUseCase = DefaultEntryUseCase(repository: repository)
        let extractionUseCase = DefaultExtractionUseCase(llmClient: llmClient)
        let followUpQuestionsUseCase = DefaultFollowUpQuestionsUseCase(llmClient: llmClient)
        let apiKeyUseCase = DefaultAPIKeyUseCase(store: apiKeyStore)
        let notificationScheduler = UserNotificationScheduler()
        let speechTranscriber = SpeechKitTranscriber()

        self.journalCoordinator = JournalCoordinator(
            entryUseCase: entryUseCase,
            extractionUseCase: extractionUseCase,
            followUpQuestionsUseCase: followUpQuestionsUseCase,
            notificationScheduler: notificationScheduler
        )
        self.logCoordinator = LogCoordinator(
            entryUseCase: entryUseCase,
            extractionUseCase: extractionUseCase,
            followUpQuestionsUseCase: followUpQuestionsUseCase,
            notificationScheduler: notificationScheduler,
            speechTranscriber: speechTranscriber
        )
        self.youViewModel = YouViewModel(apiKeyUseCase: apiKeyUseCase)
    }

    private static func databaseURL() -> URL {
        let directory = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        return directory.appendingPathComponent("journal.sqlite")
    }
}
