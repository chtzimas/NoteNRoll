import Testing
@testable import Features

@MainActor
@Suite
struct YouViewModelTests {
    @Test
    func refreshKeyStatusReflectsUseCase() async throws {
        let useCase = FakeAPIKeyUseCase()
        useCase.savedKey = "sk-ant-test"
        let viewModel = YouViewModel(apiKeyUseCase: useCase)

        viewModel.refreshKeyStatus()

        #expect(viewModel.savedKeyPresent == true)
    }

    @Test
    func saveClearsInputAndUpdatesStatus() async throws {
        let useCase = FakeAPIKeyUseCase()
        let viewModel = YouViewModel(apiKeyUseCase: useCase)
        viewModel.apiKeyInput = "sk-ant-test"

        viewModel.save()

        #expect(viewModel.apiKeyInput.isEmpty)
        #expect(viewModel.savedKeyPresent == true)
        #expect(useCase.savedKey == "sk-ant-test")
        #expect(viewModel.statusMessage == "Saved.")
    }

    @Test
    func removeClearsSavedKey() async throws {
        let useCase = FakeAPIKeyUseCase()
        useCase.savedKey = "sk-ant-test"
        let viewModel = YouViewModel(apiKeyUseCase: useCase)
        viewModel.refreshKeyStatus()

        viewModel.remove()

        #expect(viewModel.savedKeyPresent == false)
        #expect(useCase.savedKey == nil)
    }

    @Test
    func saveFailureSurfacesErrorMessage() async throws {
        let useCase = FakeAPIKeyUseCase()
        useCase.throwOnSave = true
        let viewModel = YouViewModel(apiKeyUseCase: useCase)
        viewModel.apiKeyInput = "sk-ant-test"

        viewModel.save()

        #expect(viewModel.statusMessage?.contains("Couldn't save") == true)
    }
}
