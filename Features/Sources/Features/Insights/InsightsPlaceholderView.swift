import SwiftUI

public struct InsightsPlaceholderView: View {
    public init() {}

    public var body: some View {
        NavigationStack {
            ContentUnavailableView(
                "Insights",
                systemImage: "chart.line.uptrend.xyaxis",
                description: Text("Weekly reviews and pattern detection arrive in milestone 5.")
            )
            .navigationTitle("Insights")
        }
        .logScreenAppearance("\(Self.self)")
    }
}
