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

    func extract(rawText: String) async throws -> DraftExtraction {
        switch result {
        case .success(let draft): return draft
        case .failure(let error): throw error
        }
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
