import Foundation
import JournalCore

@MainActor
final class JournalListViewModel: ObservableObject {
    @Published private(set) var entries: [Entry] = []
    @Published var classTypeFilter: ClassType?
    @Published var searchText = ""
    @Published var loadError: String?

    private let entryUseCase: any EntryUseCase

    init(entryUseCase: any EntryUseCase) {
        self.entryUseCase = entryUseCase
    }

    var filteredEntries: [Entry] {
        entries.filter { entry in
            let matchesClassType = classTypeFilter == nil || entry.classType == classTypeFilter
            let matchesSearch = searchText.isEmpty
                || (entry.title ?? "").localizedCaseInsensitiveContains(searchText)
                || entry.techniques.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
            return matchesClassType && matchesSearch
        }
    }

    var pendingEntries: [Entry] { filteredEntries.filter { $0.status == .pending } }
    var structuredEntries: [Entry] { filteredEntries.filter { $0.status == .structured } }

    func reload() async {
        do {
            entries = try await entryUseCase.listEntries()
            loadError = nil
        } catch {
            loadError = "\(error)"
        }
    }
}
