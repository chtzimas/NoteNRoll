import Foundation
import GRDB

/// Owns the migrator and the underlying GRDB connection. Every write and read in the
/// app goes through here — repositories hold one of these rather than talking to
/// `DatabaseQueue`/`DatabasePool` directly.
public struct AppDatabase: Sendable {
    public let dbWriter: any DatabaseWriter

    public init(_ dbWriter: any DatabaseWriter) throws {
        self.dbWriter = dbWriter
        try Self.migrator.migrate(dbWriter)
    }

    public static func inMemory() throws -> AppDatabase {
        try AppDatabase(DatabaseQueue())
    }

    public static func onDisk(at url: URL) throws -> AppDatabase {
        try AppDatabase(DatabaseQueue(path: url.path))
    }

    private static var migrator: DatabaseMigrator {
        var migrator = DatabaseMigrator()

        migrator.registerMigration("createEntry") { db in
            try db.create(table: Entry.databaseTableName) { t in
                t.column("id", .blob).primaryKey()
                t.column("sessionDate", .datetime).notNull()
                t.column("classType", .text).notNull()
                t.column("rawText", .text).notNull()
                t.column("status", .text).notNull()
                t.column("title", .text)
                t.column("techniques", .text).notNull()
                t.column("coachDetails", .text)
                t.column("whatWorked", .text)
                t.column("whatWentWrong", .text)
                t.column("openQuestions", .text).notNull()
                t.column("durationMinutes", .integer)
                t.column("createdAt", .datetime).notNull()
                t.column("updatedAt", .datetime).notNull()
            }
        }

        return migrator
    }
}
