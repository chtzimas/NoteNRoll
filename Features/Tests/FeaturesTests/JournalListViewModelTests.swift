import Foundation
import Testing
import JournalCore
@testable import Features

@MainActor
@Suite
struct JournalListViewModelTests {
    private func makeEntry(
        title: String? = "Title",
        classType: ClassType = .gi,
        status: EntryStatus = .structured,
        technique: String = "Armbar"
    ) -> Entry {
        Entry(
            sessionDate: Date(),
            classType: classType,
            rawText: "raw",
            status: status,
            title: title,
            techniques: [Technique(name: technique, type: .submission)]
        )
    }

    @Test
    func reloadPopulatesEntriesFromUseCase() async throws {
        let useCase = FakeEntryUseCase()
        useCase.entriesToReturn = [makeEntry(), makeEntry()]
        let viewModel = JournalListViewModel(entryUseCase: useCase)

        await viewModel.reload()

        #expect(viewModel.entries.count == 2)
        #expect(viewModel.loadError == nil)
    }

    @Test
    func reloadFailureSetsLoadError() async throws {
        let useCase = FakeEntryUseCase()
        useCase.listEntriesError = NSError(domain: "test", code: 1)
        let viewModel = JournalListViewModel(entryUseCase: useCase)

        await viewModel.reload()

        #expect(viewModel.entries.isEmpty)
        #expect(viewModel.loadError != nil)
    }

    @Test
    func pendingAndStructuredEntriesAreSeparated() async throws {
        let useCase = FakeEntryUseCase()
        useCase.entriesToReturn = [
            makeEntry(status: .pending),
            makeEntry(status: .structured),
        ]
        let viewModel = JournalListViewModel(entryUseCase: useCase)
        await viewModel.reload()

        #expect(viewModel.pendingEntries.count == 1)
        #expect(viewModel.structuredEntries.count == 1)
    }

    @Test
    func classTypeFilterNarrowsResults() async throws {
        let useCase = FakeEntryUseCase()
        useCase.entriesToReturn = [
            makeEntry(classType: .gi),
            makeEntry(classType: .noGi),
        ]
        let viewModel = JournalListViewModel(entryUseCase: useCase)
        await viewModel.reload()
        viewModel.classTypeFilter = .noGi

        #expect(viewModel.filteredEntries.count == 1)
        #expect(viewModel.filteredEntries.first?.classType == .noGi)
    }

    @Test
    func searchTextMatchesTitleOrTechniqueName() async throws {
        let useCase = FakeEntryUseCase()
        useCase.entriesToReturn = [
            makeEntry(title: "Butterfly sweep", technique: "Butterfly sweep"),
            makeEntry(title: "Arm drag", technique: "Arm drag"),
        ]
        let viewModel = JournalListViewModel(entryUseCase: useCase)
        await viewModel.reload()
        viewModel.searchText = "butterfly"

        #expect(viewModel.filteredEntries.count == 1)
        #expect(viewModel.filteredEntries.first?.title == "Butterfly sweep")
    }

    @Test
    func entryForIDLooksUpLoadedEntry() async throws {
        let useCase = FakeEntryUseCase()
        let entry = makeEntry()
        useCase.entriesToReturn = [entry]
        let viewModel = JournalListViewModel(entryUseCase: useCase)
        await viewModel.reload()

        #expect(viewModel.entry(for: entry.id)?.id == entry.id)
        #expect(viewModel.entry(for: UUID()) == nil)
    }
}
