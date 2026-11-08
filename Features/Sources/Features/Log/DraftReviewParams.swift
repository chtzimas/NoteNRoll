import Foundation
import JournalCore

/// Everything `DraftReviewViewModel` needs, carried as a plain `Hashable` value
/// so it can travel through navigation state without the view that triggers it
/// needing to construct the view model (or know its use-case dependencies)
/// itself — only the owning coordinator turns this into a `DraftReviewViewModel`.
struct DraftReviewParams: Hashable {
    let sessionDate: Date
    let classType: ClassType
    let rawText: String
    let extractionContext: String?
    let existingEntryID: UUID?
    let startsInManualMode: Bool
}
