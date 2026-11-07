import Foundation
import Testing
@testable import JournalCore

private struct StubTransport: HTTPTransport {
    var statusCode: Int
    var body: Data

    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        let response = HTTPURLResponse(
            url: request.url!,
            statusCode: statusCode,
            httpVersion: "HTTP/1.1",
            headerFields: nil
        )!
        return (body, response)
    }
}

private struct FailingTransport: HTTPTransport {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        throw URLError(.notConnectedToInternet)
    }
}

private struct FakeAPIKeyStore: APIKeyStore {
    var key: String?
    func save(apiKey: String) throws {}
    func loadAPIKey() throws -> String? { key }
    func deleteAPIKey() throws {}
}

@Suite
struct DirectClaudeClientTests {
    private func makeRequest() -> MessageRequest {
        MessageRequest(
            model: "claude-haiku-4-5-20251001",
            maxTokens: 256,
            messages: [.user("hello")]
        )
    }

    @Test
    func decodesSuccessfulToolUseResponse() async throws {
        let body = """
        {
            "id": "msg_123",
            "model": "claude-haiku-4-5-20251001",
            "role": "assistant",
            "content": [
                {"type": "tool_use", "id": "tool_1", "name": "extract_training_entry", "input": {"title": "Test"}}
            ],
            "stop_reason": "tool_use",
            "usage": {"input_tokens": 10, "output_tokens": 5}
        }
        """
        let client = DirectClaudeClient(
            transport: StubTransport(statusCode: 200, body: Data(body.utf8)),
            apiKeyStore: FakeAPIKeyStore(key: "test-key")
        )

        let response = try await client.send(makeRequest())
        let input = response.toolUseInput(named: "extract_training_entry")
        #expect(input != nil)
        if case .object(let fields)? = input {
            #expect(fields["title"] == .string("Test"))
        } else {
            Issue.record("Expected an object input")
        }
    }

    @Test
    func nonSuccessStatusThrowsHTTPError() async throws {
        let client = DirectClaudeClient(
            transport: StubTransport(statusCode: 401, body: Data(#"{"error": "unauthorized"}"#.utf8)),
            apiKeyStore: FakeAPIKeyStore(key: "bad-key")
        )

        await #expect(throws: LLMClientError.self) {
            try await client.send(makeRequest())
        }
    }

    @Test
    func malformedBodyThrowsDecodingError() async throws {
        let client = DirectClaudeClient(
            transport: StubTransport(statusCode: 200, body: Data("not json".utf8)),
            apiKeyStore: FakeAPIKeyStore(key: "test-key")
        )

        await #expect(throws: LLMClientError.self) {
            try await client.send(makeRequest())
        }
    }

    @Test
    func transportFailureThrowsNetworkError() async throws {
        let client = DirectClaudeClient(
            transport: FailingTransport(),
            apiKeyStore: FakeAPIKeyStore(key: "test-key")
        )

        await #expect(throws: LLMClientError.self) {
            try await client.send(makeRequest())
        }
    }

    @Test
    func missingAPIKeyPropagatesBeforeAnyRequest() async throws {
        let client = DirectClaudeClient(
            transport: FailingTransport(),
            apiKeyStore: FakeAPIKeyStore(key: nil)
        )

        await #expect(throws: LLMClientError.self) {
            try await client.send(makeRequest())
        }
    }
}
