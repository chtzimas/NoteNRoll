import Foundation

/// Everything a view model needs to do with journal entries: list them, and turn a
/// draft (or a failed extraction) into a saved entry. Wraps `EntryRepository` —
/// nothing in Presentation talks to the repository directly.
public protocol EntryUseCase: Sendable {
    func listEntries() async throws -> [Entry]

    /// Approves a draft (edited or not) as a structured entry. Updates the row at
    /// `existingEntryID` if given, otherwise inserts a new one.
    func approveDraft(
        _ draft: DraftExtraction,
        sessionDate: Date,
        classType: ClassType,
        rawText: String,
        existingEntryID: UUID?
    ) async throws -> Entry

    /// Keeps a note as a `pending` entry — used when extraction fails, so the raw
    /// text is never lost and the user can retry later from the Journal list.
    func savePending(
        sessionDate: Date,
        classType: ClassType,
        rawText: String,
        existingEntryID: UUID?
    ) async throws -> Entry
}
