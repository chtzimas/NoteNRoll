public struct DefaultFollowUpQuestionsUseCase: FollowUpQuestionsUseCase {
    private let llmClient: any LLMClient
    private let model: String
    private let maxTokens: Int

    public init(
        llmClient: any LLMClient,
        model: String = AppConfig.defaultExtractionModel,
        maxTokens: Int = 512
    ) {
        self.llmClient = llmClient
        self.model = model
        self.maxTokens = maxTokens
    }

    public func generateQuestions(rawText: String) async throws -> [String] {
        let request = MessageRequest(
            model: model,
            maxTokens: maxTokens,
            system: FollowUpPrompt.system,
            messages: [.user(rawText)],
            tools: [FollowUpSchema.tool],
            toolChoice: .tool(named: FollowUpSchema.toolName)
        )

        let response = try await llmClient.send(request)

        guard let input = response.toolUseInput(named: FollowUpSchema.toolName) else {
            throw FollowUpQuestionsError.noToolCallReturned
        }

        do {
            let proposed = try input.decoded(as: ProposedFollowUpQuestions.self)
            return Array(proposed.questions.prefix(3))
        } catch {
            throw FollowUpQuestionsError.invalidResponse(String(describing: error))
        }
    }
}
