import SwiftUI
import JournalCore

struct EntryDetailView: View {
    let entry: Entry

    var body: some View {
        Form {
            Section {
                Text(entry.title ?? "Untitled session")
                    .font(.title3.bold())
                HStack {
                    Text(entry.sessionDate, format: .dateTime.weekday(.wide).day().month(.wide))
                    Spacer()
                    Text(entry.classType.displayName)
                    if let minutes = entry.durationMinutes {
                        Text("\(minutes) min")
                    }
                }
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            if !entry.techniques.isEmpty {
                Section("Techniques") {
                    ForEach(entry.techniques.indices, id: \.self) { index in
                        let technique = entry.techniques[index]
                        VStack(alignment: .leading) {
                            Text(technique.name).font(.body)
                            if let position = technique.position {
                                Text(position).font(.caption).foregroundStyle(.secondary)
                            }
                        }
                    }
                }
            }

            if let coachDetails = entry.coachDetails, !coachDetails.isEmpty {
                Section("Coach's details") { Text(coachDetails) }
            }
            if let whatWorked = entry.whatWorked, !whatWorked.isEmpty {
                Section("What worked") { Text(whatWorked) }
            }
            if let whatWentWrong = entry.whatWentWrong, !whatWentWrong.isEmpty {
                Section("What went wrong") { Text(whatWentWrong) }
            }
            if !entry.openQuestions.isEmpty {
                Section("Open questions") {
                    ForEach(entry.openQuestions, id: \.self) { Text($0) }
                }
            }

            Section("Raw note") {
                Text(entry.rawText)
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
        .navigationTitle("Entry")
        .inlineNavigationBarTitleIfAvailable()
    }
}
