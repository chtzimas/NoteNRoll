import Foundation

/// `LLMClient` implementation that calls the Claude Messages API straight from the
/// device over HTTPS. No third-party SDK — just `URLSession` and `Codable`. A
/// `ProxyClaudeClient` can implement the same protocol later if the app is ever
/// distributed with a server fronting the key.
public struct DirectClaudeClient: LLMClient {
    public static let defaultBaseURL = URL(string: "https://api.anthropic.com/v1/messages")!
    public static let defaultAnthropicVersion = "2023-06-01"

    private let transport: HTTPTransport
    private let baseURL: URL
    private let anthropicVersion: String
    private let apiKeyStore: any APIKeyStore

    public init(
        transport: HTTPTransport = URLSession.shared,
        baseURL: URL = DirectClaudeClient.defaultBaseURL,
        anthropicVersion: String = DirectClaudeClient.defaultAnthropicVersion,
        apiKeyStore: any APIKeyStore
    ) {
        self.transport = transport
        self.baseURL = baseURL
        self.anthropicVersion = anthropicVersion
        self.apiKeyStore = apiKeyStore
    }

    public func send(_ request: MessageRequest) async throws -> MessageResponse {
        let apiKey = try apiKeyStore.requireAPIKey()

        var urlRequest = URLRequest(url: baseURL)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "content-type")
        urlRequest.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        urlRequest.setValue(anthropicVersion, forHTTPHeaderField: "anthropic-version")

        do {
            urlRequest.httpBody = try JSONEncoder().encode(request)
        } catch {
            throw LLMClientError.decoding("Failed to encode request: \(error)")
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await transport.send(urlRequest)
        } catch {
            throw LLMClientError.network(error.localizedDescription)
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw LLMClientError.network("Response was not an HTTP response")
        }

        guard (200..<300).contains(httpResponse.statusCode) else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw LLMClientError.http(status: httpResponse.statusCode, body: body)
        }

        do {
            return try JSONDecoder().decode(MessageResponse.self, from: data)
        } catch {
            throw LLMClientError.decoding("Failed to decode response: \(error)")
        }
    }
}
