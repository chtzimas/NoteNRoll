import Foundation
import JournalCore

@MainActor
final class DraftReviewViewModel: ObservableObject {
    enum Phase: Equatable {
        case extracting
        case reviewing
        case failed
    }

    let sessionDate: Date
    let classType: ClassType
    /// Stored verbatim as the entry's raw text — "the raw transcript is kept as
    /// the original," even when `extractionContext` below adds follow-up Q&A.
    let rawText: String
    /// What's actually sent to the extraction call. Defaults to `rawText`, but a
    /// follow-up flow passes `rawText` plus the answered questions, so extraction
    /// sees the clarifications without them polluting the stored raw note.
    let extractionContext: String
    let existingEntryID: UUID?
    /// When true, skips the extraction call entirely and opens straight into the
    /// (empty) editable form — keeps the app usable as a plain journal when
    /// Claude isn't reachable at all (no key, offline, rate-limited).
    let startsInManualMode: Bool

    @Published private(set) var phase: Phase = .extracting
    @Published var errorMessage: String?
    @Published var title = ""
    @Published var techniques: [Technique] = []
    @Published var coachDetails = ""
    @Published var whatWorked = ""
    @Published var whatWentWrong = ""
    @Published var openQuestions: [String] = []
    @Published var durationMinutesText = ""
    @Published private(set) var isSaving = false

    private let extractionUseCase: any ExtractionUseCase
    private let entryUseCase: any EntryUseCase

    init(
        sessionDate: Date,
        classType: ClassType,
        rawText: String,
        extractionContext: String? = nil,
        existingEntryID: UUID?,
        startsInManualMode: Bool = false,
        extractionUseCase: any ExtractionUseCase,
        entryUseCase: any EntryUseCase
    ) {
        self.sessionDate = sessionDate
        self.classType = classType
        self.rawText = rawText
        self.extractionContext = extractionContext ?? rawText
        self.existingEntryID = existingEntryID
        self.startsInManualMode = startsInManualMode
        self.extractionUseCase = extractionUseCase
        self.entryUseCase = entryUseCase
        if startsInManualMode {
            self.phase = .reviewing
        }
    }

    /// Lets the user skip Claude entirely and fill in the structured fields by
    /// hand, from the failure screen — same escape hatch as `startsInManualMode`,
    /// reachable after a failed attempt instead of before the first one.
    func enterManualMode() {
        errorMessage = nil
        phase = .reviewing
    }

    func runExtraction() async {
        phase = .extracting
        errorMessage = nil
        do {
            let draft = try await extractionUseCase.extract(rawText: extractionContext)
            apply(draft)
            phase = .reviewing
        } catch {
            errorMessage = String(describing: error)
            phase = .failed
        }
    }

    /// Saves the (possibly user-edited) draft as a structured entry. Returns the
    /// saved entry on success, or `nil` if saving failed — `errorMessage` is set
    /// either way the view can react to.
    @discardableResult
    func save() async -> Entry? {
        isSaving = true
        defer { isSaving = false }

        let draft = DraftExtraction(
            title: title,
            techniques: techniques,
            coachDetails: coachDetails,
            whatWorked: whatWorked,
            whatWentWrong: whatWentWrong,
            openQuestions: openQuestions,
            durationMinutes: Int(durationMinutesText)
        )

        do {
            return try await entryUseCase.approveDraft(
                draft,
                sessionDate: sessionDate,
                classType: classType,
                rawText: rawText,
                existingEntryID: existingEntryID
            )
        } catch {
            errorMessage = String(describing: error)
            return nil
        }
    }

    /// Keeps the raw text as a pending entry when extraction fails, so nothing the
    /// user typed is lost — they can retry structuring it later from the Journal list.
    @discardableResult
    func saveAsPending() async -> Entry? {
        do {
            return try await entryUseCase.savePending(
                sessionDate: sessionDate,
                classType: classType,
                rawText: rawText,
                existingEntryID: existingEntryID
            )
        } catch {
            errorMessage = String(describing: error)
            return nil
        }
    }

    private func apply(_ draft: DraftExtraction) {
        title = draft.title ?? ""
        techniques = draft.techniques
        coachDetails = draft.coachDetails ?? ""
        whatWorked = draft.whatWorked ?? ""
        whatWentWrong = draft.whatWentWrong ?? ""
        openQuestions = draft.openQuestions
        durationMinutesText = draft.durationMinutes.map(String.init) ?? ""
    }
}
