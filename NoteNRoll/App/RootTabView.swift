import SwiftUI

struct RootTabView: View {
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        TabView {
            JournalListView(entryUseCase: environment.entryUseCase, extractionUseCase: environment.extractionUseCase)
                .tabItem { Label("Journal", systemImage: "book.closed") }

            AskPlaceholderView()
                .tabItem { Label("Ask", systemImage: "bubble.left.and.bubble.right") }

            LogEntryView(extractionUseCase: environment.extractionUseCase, entryUseCase: environment.entryUseCase)
                .tabItem { Label("Log", systemImage: "mic.circle.fill") }

            InsightsPlaceholderView()
                .tabItem { Label("Insights", systemImage: "chart.line.uptrend.xyaxis") }

            YouView(apiKeyUseCase: environment.apiKeyUseCase)
                .tabItem { Label("You", systemImage: "person") }
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(AppEnvironment())
}
