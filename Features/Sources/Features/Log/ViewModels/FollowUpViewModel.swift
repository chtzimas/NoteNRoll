import Foundation
import JournalCore

/// The Debrief agent's first step, in UI form: before the user sees a draft, ask
/// whether the note leaves anything worth clarifying. Works the same whether this
/// is entered right after recording or later from a pending entry in the Journal
/// list — the entry is already safely saved either way.
@MainActor
final class FollowUpViewModel: ObservableObject {
    enum Phase: Equatable {
        case loadingQuestions
        case answering
        case noQuestionsNeeded
        case failed
    }

    let entry: Entry

    @Published private(set) var phase: Phase = .loadingQuestions
    @Published private(set) var questions: [String] = []
    @Published var answers: [String] = []
    @Published var errorMessage: String?

    private let followUpUseCase: any FollowUpQuestionsUseCase
    private let notificationScheduler: any NotificationScheduler

    init(
        entry: Entry,
        followUpUseCase: any FollowUpQuestionsUseCase,
        notificationScheduler: any NotificationScheduler
    ) {
        self.entry = entry
        self.followUpUseCase = followUpUseCase
        self.notificationScheduler = notificationScheduler
    }

    func loadQuestions() async {
        phase = .loadingQuestions
        errorMessage = nil
        do {
            let result = try await followUpUseCase.generateQuestions(rawText: entry.rawText)
            questions = result
            answers = Array(repeating: "", count: result.count)

            if result.isEmpty {
                phase = .noQuestionsNeeded
            } else {
                phase = .answering
                // Best-effort: if the user leaves before answering, a reminder
                // still reaches them. Not blocking on this — a note is fully
                // usable without it.
                try? await notificationScheduler.scheduleFollowUpNotification(
                    entryID: entry.id,
                    questionCount: result.count
                )
            }
        } catch {
            // Most likely offline right after class — the entry is already saved
            // as pending, so nothing is lost; they can retry from the Journal tab.
            errorMessage = String(describing: error)
            phase = .failed
        }
    }

    /// `entry.rawText` enriched with the answered questions, for the extraction
    /// call only — `entry.rawText` itself stays untouched as the stored original.
    var extractionContext: String {
        let answered = zip(questions, answers)
            .filter { !$1.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty }
            .map { "Q: \($0)\nA: \($1)" }

        guard !answered.isEmpty else { return entry.rawText }
        return entry.rawText + "\n\n" + answered.joined(separator: "\n")
    }

    /// Called once the user moves on to the draft, answered or not, so a reminder
    /// that already did its job doesn't fire anyway.
    func markHandled() {
        notificationScheduler.cancelFollowUpNotification(entryID: entry.id)
    }
}
