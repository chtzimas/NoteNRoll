import Foundation

public enum LLMClientError: Error, Sendable, Equatable {
    case network(String)
    case http(status: Int, body: String)
    case decoding(String)
    case missingAPIKey
}

/// Everything that talks to Claude goes through this protocol, never `URLSession`
/// directly, so a `ProxyClaudeClient` can replace `DirectClaudeClient` later without
/// touching call sites. Deliberately generic — every agent (extraction today, Recall,
/// Weekly reviewer and Planner later) sends a `MessageRequest` and gets a
/// `MessageResponse`.
public protocol LLMClient: Sendable {
    func send(_ request: MessageRequest) async throws -> MessageResponse
}
