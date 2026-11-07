public enum ExtractionError: Error, Sendable, Equatable {
    /// The model replied without the forced tool call — shouldn't happen with
    /// `tool_choice` set, but a malformed/unexpected response is still possible.
    case noToolCallReturned
    case invalidDraft(String)
}

/// Turns raw note text into a `DraftExtraction` via Claude. The only business logic
/// here is "what we ask the model for and how we validate what comes back" — no
/// storage, no UI. View models depend on this, never on `LLMClient` directly.
public protocol ExtractionUseCase: Sendable {
    func extract(rawText: String) async throws -> DraftExtraction
}
