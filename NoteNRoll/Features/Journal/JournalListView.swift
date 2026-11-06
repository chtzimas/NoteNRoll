import SwiftUI
import JournalCore

struct JournalListView: View {
    @EnvironmentObject private var environment: AppEnvironment
    @State private var entries: [Entry] = []
    @State private var classTypeFilter: ClassType?
    @State private var searchText = ""
    @State private var loadError: String?

    private var filteredEntries: [Entry] {
        entries.filter { entry in
            let matchesClassType = classTypeFilter == nil || entry.classType == classTypeFilter
            let matchesSearch = searchText.isEmpty
                || (entry.title ?? "").localizedCaseInsensitiveContains(searchText)
                || entry.techniques.contains { $0.name.localizedCaseInsensitiveContains(searchText) }
            return matchesClassType && matchesSearch
        }
    }

    private var pendingEntries: [Entry] {
        filteredEntries.filter { $0.status == .pending }
    }

    private var structuredEntries: [Entry] {
        filteredEntries.filter { $0.status == .structured }
    }

    var body: some View {
        NavigationStack {
            List {
                if !pendingEntries.isEmpty {
                    Section("Not structured yet") {
                        ForEach(pendingEntries) { entry in
                            NavigationLink(value: entry.id) {
                                PendingEntryRow(entry: entry)
                            }
                        }
                    }
                }

                Section {
                    ForEach(structuredEntries) { entry in
                        NavigationLink(value: entry.id) {
                            EntryRow(entry: entry)
                        }
                    }
                }
            }
            .searchable(text: $searchText, prompt: "Search techniques, notes")
            .toolbar {
                ToolbarItem(placement: .principal) {
                    classTypeFilterPicker
                }
            }
            .navigationTitle("Journal")
            .navigationDestination(for: UUID.self) { id in
                if let entry = entries.first(where: { $0.id == id }) {
                    if entry.status == .pending {
                        DraftReviewView(
                            sessionDate: entry.sessionDate,
                            classType: entry.classType,
                            rawText: entry.rawText,
                            existingEntryID: entry.id
                        )
                    } else {
                        EntryDetailView(entry: entry)
                    }
                }
            }
            .overlay {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No sessions yet",
                        systemImage: "figure.martial.arts",
                        description: Text("Log your first class from the Log tab.")
                    )
                }
            }
            .alert("Couldn't load journal", isPresented: .constant(loadError != nil)) {
                Button("OK") { loadError = nil }
            } message: {
                Text(loadError ?? "")
            }
        }
        .task { await reload() }
        .refreshable { await reload() }
        .onReceive(NotificationCenter.default.publisher(for: .entriesDidChange)) { _ in
            Task { await reload() }
        }
    }

    private var classTypeFilterPicker: some View {
        Picker("Class type", selection: $classTypeFilter) {
            Text("All").tag(ClassType?.none)
            ForEach(ClassType.allCases, id: \.self) { type in
                Text(type.displayName).tag(ClassType?.some(type))
            }
        }
        .pickerStyle(.segmented)
    }

    private func reload() async {
        do {
            entries = try await environment.entryRepository.listAll()
        } catch {
            loadError = "\(error)"
        }
    }
}

private struct EntryRow: View {
    let entry: Entry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(entry.sessionDate, format: .dateTime.weekday(.abbreviated).day().month(.abbreviated))
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
                Text(entry.classType.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Text(entry.title ?? "Untitled session")
                .font(.headline)
            if !entry.techniques.isEmpty {
                TagRow(tags: entry.techniques.map(\.name))
            }
        }
        .padding(.vertical, 4)
    }
}

private struct PendingEntryRow: View {
    let entry: Entry

    var body: some View {
        HStack {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(.orange)
            VStack(alignment: .leading) {
                Text(entry.rawText)
                    .lineLimit(1)
                Text("Tap to structure")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct TagRow: View {
    let tags: [String]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack {
                ForEach(tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.secondary.opacity(0.15), in: Capsule())
                }
            }
        }
    }
}

extension ClassType {
    var displayName: String {
        switch self {
        case .gi: "Gi"
        case .noGi: "No-gi"
        case .openMat: "Open mat"
        case .other: "Other"
        }
    }
}

extension Notification.Name {
    static let entriesDidChange = Notification.Name("entriesDidChange")
}
