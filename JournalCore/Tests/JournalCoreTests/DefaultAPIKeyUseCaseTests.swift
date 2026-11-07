import Testing
@testable import JournalCore

private final class FakeAPIKeyStore: APIKeyStore, @unchecked Sendable {
    var storedKey: String?

    func save(apiKey: String) throws { storedKey = apiKey }
    func loadAPIKey() throws -> String? { storedKey }
    func deleteAPIKey() throws { storedKey = nil }
}

@Suite
struct DefaultAPIKeyUseCaseTests {
    @Test
    func hasSavedKeyReflectsStoreState() throws {
        let store = FakeAPIKeyStore()
        let useCase = DefaultAPIKeyUseCase(store: store)

        #expect(try useCase.hasSavedKey() == false)

        try useCase.save(apiKey: "sk-ant-test")
        #expect(try useCase.hasSavedKey() == true)

        try useCase.removeKey()
        #expect(try useCase.hasSavedKey() == false)
    }
}
