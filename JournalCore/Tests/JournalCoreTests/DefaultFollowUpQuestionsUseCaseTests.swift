import Foundation
import Testing
@testable import JournalCore

private struct MockLLMClient: LLMClient {
    var response: MessageResponse
    func send(_ request: MessageRequest) async throws -> MessageResponse { response }
}

@Suite
struct DefaultFollowUpQuestionsUseCaseTests {
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
    func returnsQuestionsFromForcedToolCall() async throws {
        let input = JSONValue.object([
            "questions": .array([.string("Which grip?"), .string("Which side?")])
        ])
        let client = MockLLMClient(
            response: response(content: [.toolUse(id: "t1", name: FollowUpSchema.toolName, input: input)])
        )
        let useCase = DefaultFollowUpQuestionsUseCase(llmClient: client)

        let questions = try await useCase.generateQuestions(rawText: "Worked butterfly sweeps, lost the grip.")
        #expect(questions == ["Which grip?", "Which side?"])
    }

    @Test
    func emptyQuestionsIsAValidResult() async throws {
        let input = JSONValue.object(["questions": .array([])])
        let client = MockLLMClient(
            response: response(content: [.toolUse(id: "t1", name: FollowUpSchema.toolName, input: input)])
        )
        let useCase = DefaultFollowUpQuestionsUseCase(llmClient: client)

        let questions = try await useCase.generateQuestions(rawText: "Clear, complete note.")
        #expect(questions.isEmpty)
    }

    @Test
    func truncatesToAtMostThreeQuestions() async throws {
        let input = JSONValue.object([
            "questions": .array([.string("Q1"), .string("Q2"), .string("Q3"), .string("Q4")])
        ])
        let client = MockLLMClient(
            response: response(content: [.toolUse(id: "t1", name: FollowUpSchema.toolName, input: input)])
        )
        let useCase = DefaultFollowUpQuestionsUseCase(llmClient: client)

        let questions = try await useCase.generateQuestions(rawText: "A note.")
        #expect(questions == ["Q1", "Q2", "Q3"])
    }

    @Test
    func missingToolCallThrowsNoToolCallReturned() async throws {
        let client = MockLLMClient(response: response(content: [.text("No tool call here.")]))
        let useCase = DefaultFollowUpQuestionsUseCase(llmClient: client)

        await #expect(throws: FollowUpQuestionsError.noToolCallReturned) {
            try await useCase.generateQuestions(rawText: "A note.")
        }
    }

    @Test
    func malformedToolInputThrowsInvalidResponse() async throws {
        let input = JSONValue.object(["wrongKey": .string("oops")])
        let client = MockLLMClient(
            response: response(content: [.toolUse(id: "t1", name: FollowUpSchema.toolName, input: input)])
        )
        let useCase = DefaultFollowUpQuestionsUseCase(llmClient: client)

        await #expect(throws: FollowUpQuestionsError.self) {
            try await useCase.generateQuestions(rawText: "A note.")
        }
    }
}
