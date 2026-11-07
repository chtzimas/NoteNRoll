import Foundation

/// The seam `DirectClaudeClient` talks through instead of `URLSession` directly, so
/// tests can inject a stub transport without touching the network.
public protocol HTTPTransport: Sendable {
    func send(_ request: URLRequest) async throws -> (Data, URLResponse)
}

extension URLSession: HTTPTransport {
    public func send(_ request: URLRequest) async throws -> (Data, URLResponse) {
        try await data(for: request)
    }
}
