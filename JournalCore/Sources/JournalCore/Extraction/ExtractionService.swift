import Foundation

public enum ExtractionError: Error, Sendable, Equatable {
    /// The model replied without the forced tool call — shouldn't happen with
    /// `tool_choice` set, but a malformed/unexpected response is still possible.
    case noToolCallReturned
    case invalidDraft(String)
}

/// Turns raw note text into a `DraftExtraction` via one forced tool call. Doesn't
/// touch storage or the UI — callers decide what to do with the draft (show it for
/// review, discard it, retry).
public struct ExtractionService: Sendable {
    private let llmClient: any LLMClient
    private let model: String
    private let maxTokens: Int

    public init(
        llmClient: any LLMClient,
        model: String = AppConfig.defaultExtractionModel,
        maxTokens: Int = 1024
    ) {
        self.llmClient = llmClient
        self.model = model
        self.maxTokens = maxTokens
    }

    public func extract(rawText: String) async throws -> DraftExtraction {
        let request = MessageRequest(
            model: model,
            maxTokens: maxTokens,
            system: ExtractionPrompt.system,
            messages: [.user(rawText)],
            tools: [ExtractionSchema.tool],
            toolChoice: .tool(named: ExtractionSchema.toolName)
        )

        let response = try await llmClient.send(request)

        guard let input = response.toolUseInput(named: ExtractionSchema.toolName) else {
            throw ExtractionError.noToolCallReturned
        }

        do {
            return try input.decoded(as: DraftExtraction.self)
        } catch {
            throw ExtractionError.invalidDraft(String(describing: error))
        }
    }
}
