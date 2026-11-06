import SwiftUI

struct AskPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Ask",
                systemImage: "bubble.left.and.bubble.right",
                description: Text("Search and citations over your journal arrive in milestone 3.")
            )
            .navigationTitle("Ask")
        }
    }
}
