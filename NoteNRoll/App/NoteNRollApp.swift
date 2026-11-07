import SwiftUI

@main
struct NoteNRollApp: App {
    @StateObject private var environment = AppEnvironment()

    var body: some Scene {
        WindowGroup {
            RootTabView()
                .environmentObject(environment)
        }
    }
}
