import Foundation
import Testing
@testable import JournalCore

@Suite
struct EntryRepositoryTests {
    private func makeRepository() throws -> EntryRepository {
        let database = try AppDatabase.inMemory()
        return EntryRepository(database: database)
    }

    private func samplePendingEntry(sessionDate: Date = Date()) -> Entry {
        Entry(
            sessionDate: sessionDate,
            classType: .gi,
            rawText: "Worked butterfly sweeps, coach said lift with the hook not the arms.",
            status: .pending
        )
    }

    @Test
    func insertAndFetchPreservesRawText() async throws {
        let repository = try makeRepository()
        let entry = samplePendingEntry()

        try await repository.insert(entry)
        let fetched = try await repository.fetch(id: entry.id)

        #expect(fetched?.rawText == entry.rawText)
        #expect(fetched?.status == .pending)
    }

    @Test
    func updateToStructuredPreservesRawTextAndBumpsUpdatedAt() async throws {
        let repository = try makeRepository()
        var entry = samplePendingEntry()
        try await repository.insert(entry)

        let originalUpdatedAt = entry.updatedAt
        entry.status = .structured
        entry.title = "Butterfly sweep: elevate with the hook"
        entry.techniques = [Technique(name: "Butterfly sweep", position: "Butterfly guard", type: .sweep)]
        try await repository.update(entry)

        let fetched = try await repository.fetch(id: entry.id)
        #expect(fetched?.status == .structured)
        #expect(fetched?.title == "Butterfly sweep: elevate with the hook")
        #expect(fetched?.techniques == entry.techniques)
        #expect(fetched?.rawText == entry.rawText)
        #expect((fetched?.updatedAt ?? .distantPast) > originalUpdatedAt)
    }

    @Test
    func listAllOrdersByMostRecentSessionFirst() async throws {
        let repository = try makeRepository()
        let older = samplePendingEntry(sessionDate: Date(timeIntervalSince1970: 1_000))
        let newer = samplePendingEntry(sessionDate: Date(timeIntervalSince1970: 2_000))

        try await repository.insert(older)
        try await repository.insert(newer)

        let entries = try await repository.listAll()
        #expect(entries.map(\.id) == [newer.id, older.id])
    }

    @Test
    func fetchMissingEntryReturnsNil() async throws {
        let repository = try makeRepository()
        let fetched = try await repository.fetch(id: UUID())
        #expect(fetched == nil)
    }
}
