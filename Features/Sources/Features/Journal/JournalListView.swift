import SwiftUI
import JournalCore

public struct JournalListView: View {
    @StateObject private var viewModel: JournalListViewModel
    private let extractionUseCase: any ExtractionUseCase
    private let entryUseCase: any EntryUseCase
    private let followUpQuestionsUseCase: any FollowUpQuestionsUseCase
    private let notificationScheduler: any NotificationScheduler

    public init(
        entryUseCase: any EntryUseCase,
        extractionUseCase: any ExtractionUseCase,
        followUpQuestionsUseCase: any FollowUpQuestionsUseCase,
        notificationScheduler: any NotificationScheduler
    ) {
        self.entryUseCase = entryUseCase
        self.extractionUseCase = extractionUseCase
        self.followUpQuestionsUseCase = followUpQuestionsUseCase
        self.notificationScheduler = notificationScheduler
        _viewModel = StateObject(wrappedValue: JournalListViewModel(entryUseCase: entryUseCase))
    }

    public var body: some View {
        NavigationStack {
            List {
                if !viewModel.pendingEntries.isEmpty {
                    Section("Not structured yet") {
                        ForEach(viewModel.pendingEntries) { entry in
                            NavigationLink(value: entry.id) {
                                PendingEntryRow(entry: entry)
                            }
                        }
                    }
                }

                Section {
                    ForEach(viewModel.structuredEntries) { entry in
                        NavigationLink(value: entry.id) {
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
            .navigationDestination(for: UUID.self) { id in
                if let entry = viewModel.entry(for: id) {
                    if entry.status == .pending {
                        FollowUpView(
                            entry: entry,
                            followUpUseCase: followUpQuestionsUseCase,
                            notificationScheduler: notificationScheduler,
                            extractionUseCase: extractionUseCase,
                            entryUseCase: entryUseCase,
                            onSaved: { Task { await viewModel.reload() } }
                        )
                    } else {
                        EntryDetailView(entry: entry)
                    }
                }
            }
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
        }
        .onAppear { Task { await viewModel.reload() } }
        .refreshable { await viewModel.reload() }
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
