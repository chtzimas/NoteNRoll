import Foundation
import Testing
@testable import JournalCore

private struct MockLLMClient: LLMClient {
    var response: MessageResponse
    func send(_ request: MessageRequest) async throws -> MessageResponse { response }
}

@Suite
struct DefaultExtractionUseCaseTests {
    private func response(content: [ContentBlock]) -> MessageResponse {
        MessageResponse(
            id: "msg_1",
            model: AppConfig.defaultExtractionModel,
            role: .assistant,
            content: content,
            stopReason: "tool_use",
            usage: nil
        )
    }

    @Test
    func extractsDraftFromForcedToolCall() async throws {
        let input = JSONValue.object([
            "title": .string("Butterfly sweep"),
            "techniques": .array([]),
            "openQuestions": .array([]),
        ])
        let client = MockLLMClient(
            response: response(content: [.toolUse(id: "t1", name: ExtractionSchema.toolName, input: input)])
        )
        let service = DefaultExtractionUseCase(llmClient: client)

        let draft = try await service.extract(rawText: "Worked butterfly sweeps today.")
        #expect(draft.title == "Butterfly sweep")
    }

    @Test
    func missingToolCallThrowsNoToolCallReturned() async throws {
        let client = MockLLMClient(response: response(content: [.text("I have a question first.")]))
        let service = DefaultExtractionUseCase(llmClient: client)

        await #expect(throws: ExtractionError.noToolCallReturned) {
            try await service.extract(rawText: "Worked butterfly sweeps today.")
        }
    }

    @Test
    func malformedToolInputThrowsInvalidDraft() async throws {
        let input = JSONValue.object(["title": .string("Missing required fields")])
        let client = MockLLMClient(
            response: response(content: [.toolUse(id: "t1", name: ExtractionSchema.toolName, input: input)])
        )
        let service = DefaultExtractionUseCase(llmClient: client)

        await #expect(throws: ExtractionError.self) {
            try await service.extract(rawText: "Worked butterfly sweeps today.")
        }
    }
}
