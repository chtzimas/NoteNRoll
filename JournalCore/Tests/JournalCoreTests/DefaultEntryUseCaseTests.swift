import Foundation
import Testing
@testable import JournalCore

private actor FakeEntryRepository: EntryRepository {
    private(set) var insertedEntries: [Entry] = []
    private(set) var updatedEntries: [Entry] = []

    func insert(_ entry: Entry) async throws {
        insertedEntries.append(entry)
    }

    func update(_ entry: Entry) async throws {
        updatedEntries.append(entry)
    }

    func fetch(id: UUID) async throws -> Entry? {
        (insertedEntries + updatedEntries).first { $0.id == id }
    }

    func listAll(mostRecentFirst: Bool) async throws -> [Entry] {
        insertedEntries
    }
}

@Suite
struct DefaultEntryUseCaseTests {
    @Test
    func approveDraftInsertsNewStructuredEntryAndTrimsEmptyFields() async throws {
        let repository = FakeEntryRepository()
        let useCase = DefaultEntryUseCase(repository: repository)
        let draft = DraftExtraction(
            title: "Butterfly sweep",
            techniques: [
                Technique(name: "Butterfly sweep", type: .sweep),
                Technique(name: "", type: .other), // should be dropped
            ],
            coachDetails: "",
            openQuestions: ["Which grip?", ""]
        )

        let entry = try await useCase.approveDraft(
            draft,
            sessionDate: Date(),
            classType: .gi,
            rawText: "raw note",
            existingEntryID: nil
        )

        #expect(entry.status == .structured)
        #expect(entry.title == "Butterfly sweep")
        #expect(entry.techniques.count == 1)
        #expect(entry.coachDetails == nil)
        #expect(entry.openQuestions == ["Which grip?"])

        let inserted = await repository.insertedEntries
        let updated = await repository.updatedEntries
        #expect(inserted.count == 1)
        #expect(updated.isEmpty)
    }

    @Test
    func approveDraftWithExistingIDUpdatesRatherThanInserts() async throws {
        let repository = FakeEntryRepository()
        let useCase = DefaultEntryUseCase(repository: repository)
        let existingID = UUID()

        _ = try await useCase.approveDraft(
            DraftExtraction(title: "Title"),
            sessionDate: Date(),
            classType: .noGi,
            rawText: "raw note",
            existingEntryID: existingID
        )

        let inserted = await repository.insertedEntries
        let updated = await repository.updatedEntries
        #expect(inserted.isEmpty)
        #expect(updated.count == 1)
        #expect(updated.first?.id == existingID)
    }

    @Test
    func savePendingKeepsRawTextAndPendingStatus() async throws {
        let repository = FakeEntryRepository()
        let useCase = DefaultEntryUseCase(repository: repository)

        let entry = try await useCase.savePending(
            sessionDate: Date(),
            classType: .openMat,
            rawText: "Worked on takedowns",
            existingEntryID: nil
        )

        #expect(entry.status == .pending)
        #expect(entry.rawText == "Worked on takedowns")
        #expect(entry.title == nil)
    }
}
