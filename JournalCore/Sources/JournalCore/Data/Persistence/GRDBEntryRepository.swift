import Foundation
import GRDB

/// GRDB-backed `EntryRepository`. The only place in the app that constructs a GRDB
/// query — nothing above the `EntryRepository` protocol is allowed to know that.
public struct GRDBEntryRepository: EntryRepository {
    private let database: AppDatabase

    public init(database: AppDatabase) {
        self.database = database
    }

    public func insert(_ entry: Entry) async throws {
        try await database.dbWriter.write { db in
            try entry.insert(db)
        }
    }

    /// Replaces a pending entry's content and marks it structured. Stamps
    /// `updatedAt`; callers don't set it themselves.
    public func update(_ entry: Entry) async throws {
        var mutableEntry = entry
        mutableEntry.updatedAt = Date()
        let updated = mutableEntry
        try await database.dbWriter.write { db in
            try updated.update(db)
        }
    }

    public func fetch(id: UUID) async throws -> Entry? {
        try await database.dbWriter.read { db in
            try Entry.fetchOne(db, key: id)
        }
    }

    public func listAll(mostRecentFirst: Bool = true) async throws -> [Entry] {
        try await database.dbWriter.read { db in
            let order = mostRecentFirst ? Column("sessionDate").desc : Column("sessionDate").asc
            return try Entry.order(order).fetchAll(db)
        }
    }
}
