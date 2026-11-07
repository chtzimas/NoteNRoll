import Foundation

public struct DefaultEntryUseCase: EntryUseCase {
    private let repository: any EntryRepository

    public init(repository: any EntryRepository) {
        self.repository = repository
    }

    public func listEntries() async throws -> [Entry] {
        try await repository.listAll()
    }

    public func approveDraft(
        _ draft: DraftExtraction,
        sessionDate: Date,
        classType: ClassType,
        rawText: String,
        existingEntryID: UUID?
    ) async throws -> Entry {
        let entry = Entry(
            id: existingEntryID ?? UUID(),
            sessionDate: sessionDate,
            classType: classType,
            rawText: rawText,
            status: .structured,
            title: (draft.title?.isEmpty == false) ? draft.title : nil,
            techniques: draft.techniques.filter { !$0.name.isEmpty },
            coachDetails: (draft.coachDetails?.isEmpty == false) ? draft.coachDetails : nil,
            whatWorked: (draft.whatWorked?.isEmpty == false) ? draft.whatWorked : nil,
            whatWentWrong: (draft.whatWentWrong?.isEmpty == false) ? draft.whatWentWrong : nil,
            openQuestions: draft.openQuestions.filter { !$0.isEmpty },
            durationMinutes: draft.durationMinutes
        )
        try await save(entry, isUpdate: existingEntryID != nil)
        return entry
    }

    public func savePending(
        sessionDate: Date,
        classType: ClassType,
        rawText: String,
        existingEntryID: UUID?
    ) async throws -> Entry {
        let entry = Entry(
            id: existingEntryID ?? UUID(),
            sessionDate: sessionDate,
            classType: classType,
            rawText: rawText,
            status: .pending
        )
        try await save(entry, isUpdate: existingEntryID != nil)
        return entry
    }

    private func save(_ entry: Entry, isUpdate: Bool) async throws {
        if isUpdate {
            try await repository.update(entry)
        } else {
            try await repository.insert(entry)
        }
    }
}
