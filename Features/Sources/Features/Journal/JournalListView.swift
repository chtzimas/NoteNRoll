import SwiftUI
import JournalCore

/// Pure content: no `NavigationStack`, no `.navigationDestination` — those are
/// `JournalCoordinatorView`'s job, since building a destination requires use-case
/// dependencies this view never sees. Row taps push a `JournalRoute` directly
/// via `NavigationLink(value:)`, resolved by whatever ancestor stack owns it.
/// Internal, not public: only `JournalCoordinatorView` (same module) constructs this.
struct JournalListView: View {
    @ObservedObject private var viewModel: JournalListViewModel

    init(viewModel: JournalListViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        List {
            if !viewModel.pendingEntries.isEmpty {
                Section("Not structured yet") {
                    ForEach(viewModel.pendingEntries) { entry in
                        NavigationLink(value: JournalRoute.followUp(entry)) {
                            PendingEntryRow(entry: entry)
                        }
                    }
                }
            }

            Section {
                ForEach(viewModel.structuredEntries) { entry in
                    NavigationLink(value: JournalRoute.entryDetail(entry)) {
                        EntryRow(entry: entry)
                    }
                }
            }
        }
        .searchable(text: $viewModel.searchText, prompt: "Search techniques, notes")
        .toolbar {
            ToolbarItem(placement: .principal) {
                classTypeFilterPicker
            }
        }
        .navigationTitle("Journal")
        .overlay {
            if viewModel.entries.isEmpty {
                ContentUnavailableView(
                    "No sessions yet",
                    systemImage: "figure.martial.arts",
                    description: Text("Log your first class from the Log tab.")
                )
            }
        }
        .alert("Couldn't load journal", isPresented: .constant(viewModel.loadError != nil)) {
            Button("OK") { viewModel.loadError = nil }
        } message: {
            Text(viewModel.loadError ?? "")
        }
        .onAppear { Task { await viewModel.reload() } }
        .refreshable { await viewModel.reload() }
        .logScreenAppearance("\(Self.self)")
    }

    private var classTypeFilterPicker: some View {
        Picker("Class type", selection: $viewModel.classTypeFilter) {
            Text("All").tag(ClassType?.none)
            ForEach(ClassType.allCases, id: \.self) { type in
                Text(type.displayName).tag(ClassType?.some(type))
            }
        }
        .pickerStyle(.segmented)
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
