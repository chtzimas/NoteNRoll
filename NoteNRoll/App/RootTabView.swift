import SwiftUI

struct RootTabView: View {
    var body: some View {
        TabView {
            JournalListView()
                .tabItem { Label("Journal", systemImage: "book.closed") }

            AskPlaceholderView()
                .tabItem { Label("Ask", systemImage: "bubble.left.and.bubble.right") }

            LogEntryView()
                .tabItem { Label("Log", systemImage: "mic.circle.fill") }

            InsightsPlaceholderView()
                .tabItem { Label("Insights", systemImage: "chart.line.uptrend.xyaxis") }

            YouView()
                .tabItem { Label("You", systemImage: "person") }
        }
    }
}

#Preview {
    RootTabView()
        .environmentObject(AppEnvironment())
}
