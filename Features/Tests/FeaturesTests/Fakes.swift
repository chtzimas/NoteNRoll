import Foundation
import JournalCore

final class FakeEntryUseCase: EntryUseCase, @unchecked Sendable {
    var entriesToReturn: [Entry] = []
    var listEntriesError: Error?

    private(set) var approvedDrafts: [DraftExtraction] = []
    private(set) var pendingSaveCount = 0
    var approveResult: Result<Entry, Error>?
    var savePendingResult: Result<Entry, Error>?

    func listEntries() async throws -> [Entry] {
        if let listEntriesError { throw listEntriesError }
        return entriesToReturn
    }

    func approveDraft(
        _ draft: DraftExtraction,
        sessionDate: Date,
        classType: ClassType,
        rawText: String,
        existingEntryID: UUID?
    ) async throws -> Entry {
        approvedDrafts.append(draft)
        switch approveResult {
        case .success(let entry): return entry
        case .failure(let error): throw error
        case nil:
            return Entry(
                id: existingEntryID ?? UUID(),
                sessionDate: sessionDate,
                classType: classType,
                rawText: rawText,
                status: .structured,
                title: draft.title
            )
        }
    }

    func savePending(
        sessionDate: Date,
        classType: ClassType,
        rawText: String,
        existingEntryID: UUID?
    ) async throws -> Entry {
        pendingSaveCount += 1
        switch savePendingResult {
        case .success(let entry): return entry
        case .failure(let error): throw error
        case nil:
            return Entry(
                id: existingEntryID ?? UUID(),
                sessionDate: sessionDate,
                classType: classType,
                rawText: rawText,
                status: .pending
            )
        }
    }
}

final class FakeExtractionUseCase: ExtractionUseCase, @unchecked Sendable {
    var result: Result<DraftExtraction, Error> = .success(DraftExtraction())
    private(set) var receivedRawText: String?

    func extract(rawText: String) async throws -> DraftExtraction {
        receivedRawText = rawText
        switch result {
        case .success(let draft): return draft
        case .failure(let error): throw error
        }
    }
}

final class FakeFollowUpQuestionsUseCase: FollowUpQuestionsUseCase, @unchecked Sendable {
    var result: Result<[String], Error> = .success([])

    func generateQuestions(rawText: String) async throws -> [String] {
        switch result {
        case .success(let questions): return questions
        case .failure(let error): throw error
        }
    }
}

final class FakeNotificationScheduler: NotificationScheduler, @unchecked Sendable {
    private(set) var scheduledEntryIDs: [UUID] = []
    private(set) var canceledEntryIDs: [UUID] = []
    var authorizationGranted = true

    func requestAuthorization() async -> Bool { authorizationGranted }

    func scheduleFollowUpNotification(entryID: UUID, questionCount: Int) async throws {
        scheduledEntryIDs.append(entryID)
    }

    func cancelFollowUpNotification(entryID: UUID) {
        canceledEntryIDs.append(entryID)
    }
}

final class FakeSpeechTranscriber: SpeechTranscriber, @unchecked Sendable {
    var authorizationGranted = true
    var transcripts: [String] = []
    var streamError: Error?
    private(set) var stopCallCount = 0

    func requestAuthorization() async -> Bool { authorizationGranted }

    func startTranscribing() async throws -> AsyncThrowingStream<String, Error> {
        let transcripts = transcripts
        let streamError = streamError
        return AsyncThrowingStream { continuation in
            for transcript in transcripts {
                continuation.yield(transcript)
            }
            if let streamError {
                continuation.finish(throwing: streamError)
            } else {
                continuation.finish()
            }
        }
    }

    func stopTranscribing() {
        stopCallCount += 1
    }
}

final class FakeAPIKeyUseCase: APIKeyUseCase, @unchecked Sendable {
    var savedKey: String?
    var throwOnSave = false
    var throwOnRemove = false

    func hasSavedKey() throws -> Bool {
        savedKey?.isEmpty == false
    }

    func save(apiKey: String) throws {
        if throwOnSave { throw NSError(domain: "test", code: 1) }
        savedKey = apiKey
    }

    func removeKey() throws {
        if throwOnRemove { throw NSError(domain: "test", code: 2) }
        savedKey = nil
    }
}
