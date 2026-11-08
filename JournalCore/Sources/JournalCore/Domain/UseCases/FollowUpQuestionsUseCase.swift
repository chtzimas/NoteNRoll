public enum FollowUpQuestionsError: Error, Sendable, Equatable {
    case noToolCallReturned
    case invalidResponse(String)
}

/// The Debrief agent's first step: before structuring a note, ask Claude whether
/// anything in it is genuinely ambiguous enough to ask about. Returns an empty
/// array when the note is already clear — not every note needs a follow-up.
public protocol FollowUpQuestionsUseCase: Sendable {
    func generateQuestions(rawText: String) async throws -> [String]
}
