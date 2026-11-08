import SwiftUI
import os

private let screenLogger = Logger(subsystem: "com.notenroll.app", category: "ScreenAppearance")

extension View {
    /// Logs to the console whenever this screen becomes the one currently on
    /// screen — pure debugging aid, nothing user-facing. Visible in Xcode's
    /// console or `log stream` under the "ScreenAppearance" category.
    func logScreenAppearance(_ name: String) -> some View {
        onAppear { screenLogger.debug("\(name, privacy: .public) appeared") }
    }
}
