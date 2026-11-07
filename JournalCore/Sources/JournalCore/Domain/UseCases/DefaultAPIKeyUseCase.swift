public struct DefaultAPIKeyUseCase: APIKeyUseCase {
    private let store: any APIKeyStore

    public init(store: any APIKeyStore) {
        self.store = store
    }

    public func hasSavedKey() throws -> Bool {
        try store.loadAPIKey()?.isEmpty == false
    }

    public func save(apiKey: String) throws {
        try store.save(apiKey: apiKey)
    }

    public func removeKey() throws {
        try store.deleteAPIKey()
    }
}
