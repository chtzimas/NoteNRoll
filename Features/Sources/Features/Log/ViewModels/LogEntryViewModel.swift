import Foundation
import JournalCore

/// Owns just the composer's form state. No use-case dependency — it doesn't perform
/// any operation itself, only captures input that `DraftReviewViewModel` acts on
/// once the user taps "Structure it".
@MainActor
final class LogEntryViewModel: ObservableObject {
    @Published var sessionDate = Date()
    @Published var classType: ClassType = .gi
    @Published var rawText = ""

    var canSubmit: Bool {
        !rawText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    func reset() {
        rawText = ""
    }
}
