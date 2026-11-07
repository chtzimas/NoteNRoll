import GRDB

// `Entry` and its enums are defined without any storage-framework import in
// Models/Entry.swift; this file is the only place that ties them to GRDB, so the
// model stays framework-agnostic.

extension ClassType: DatabaseValueConvertible {}
extension EntryStatus: DatabaseValueConvertible {}
extension TechniqueType: DatabaseValueConvertible {}

extension Entry: TableRecord {
    public static let databaseTableName = "entry"
}

extension Entry: FetchableRecord, PersistableRecord {}
