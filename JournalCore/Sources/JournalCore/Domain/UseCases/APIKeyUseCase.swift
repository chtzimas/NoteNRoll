/// What the You tab needs to manage the Claude API key. Wraps `APIKeyStore` —
/// Presentation code never talks to Keychain directly.
public protocol APIKeyUseCase: Sendable {
    func hasSavedKey() throws -> Bool
    func save(apiKey: String) throws
    func removeKey() throws
}
