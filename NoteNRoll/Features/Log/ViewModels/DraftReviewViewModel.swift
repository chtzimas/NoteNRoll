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
    let rawText: String
    let existingEntryID: UUID?

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
        existingEntryID: UUID?,
        extractionUseCase: any ExtractionUseCase,
        entryUseCase: any EntryUseCase
    ) {
        self.sessionDate = sessionDate
        self.classType = classType
        self.rawText = rawText
        self.existingEntryID = existingEntryID
        self.extractionUseCase = extractionUseCase
        self.entryUseCase = entryUseCase
    }

    func runExtraction() async {
        phase = .extracting
        errorMessage = nil
        do {
            let draft = try await extractionUseCase.extract(rawText: rawText)
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
