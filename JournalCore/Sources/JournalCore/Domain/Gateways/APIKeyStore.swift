/// Secrets gateway for the user's Claude API key. `KeychainStore` is the only
/// implementation, but nothing above this protocol depends on Keychain/Security
/// directly — swapping storage later (or faking it in a test) doesn't ripple upward.
public protocol APIKeyStore: Sendable {
    func save(apiKey: String) throws
    func loadAPIKey() throws -> String?
    func deleteAPIKey() throws
}

extension APIKeyStore {
    /// Convenience for gateways that need the key or a typed failure, rather than
    /// an optional. `DirectClaudeClient` uses this.
    public func requireAPIKey() throws -> String {
        guard let key = try loadAPIKey() else {
            throw LLMClientError.missingAPIKey
        }
        return key
    }
}
