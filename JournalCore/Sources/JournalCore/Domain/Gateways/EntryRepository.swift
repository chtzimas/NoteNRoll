import Foundation

/// Persistence gateway for `Entry` rows. A narrow, storage-agnostic contract —
/// `GRDBEntryRepository` is the only implementation today, but nothing above this
/// protocol (use cases, view models) knows that, or could tell the difference from
/// an in-memory fake in a test.
public protocol EntryRepository: Sendable {
    func insert(_ entry: Entry) async throws
    func update(_ entry: Entry) async throws
    func fetch(id: UUID) async throws -> Entry?
    func listAll(mostRecentFirst: Bool) async throws -> [Entry]
}

extension EntryRepository {
    public func listAll() async throws -> [Entry] {
        try await listAll(mostRecentFirst: true)
    }
}
