import SwiftUI

struct InsightsPlaceholderView: View {
    var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Insights",
                systemImage: "chart.line.uptrend.xyaxis",
                description: Text("Weekly reviews and pattern detection arrive in milestone 5.")
            )
            .navigationTitle("Insights")
        }
    }
}
