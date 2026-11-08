import SwiftUI
import Features

struct RootTabView: View {
    @EnvironmentObject private var environment: AppEnvironment

    var body: some View {
        TabView {
            JournalCoordinatorView(coordinator: environment.journalCoordinator)
                .tabItem { Label("Journal", systemImage: "book.closed") }

            AskPlaceholderView()
                .tabItem { Label("Ask", systemImage: "bubble.left.and.bubble.right") }

            LogCoordinatorView(coordinator: environment.logCoordinator)
                .tabItem { Label("Log", systemImage: "mic.circle.fill") }

            InsightsPlaceholderView()
                .tabItem { Label("Insights", systemImage: "chart.line.uptrend.xyaxis") }

            YouView(viewModel: environment.youViewModel)
                .tabItem { Label("You", systemImage: "person") }
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(AppEnvironment())
}
