import SwiftUI

// Features declares macOS as a supported platform purely so `swift test` can run
// the view-model tests on the command line without an iOS simulator — the UI
// itself is iOS-only. These two modifiers have no macOS equivalent, so they're
// gated out rather than dropping macOS support package-wide.
extension View {
    @ViewBuilder
    func inlineNavigationBarTitleIfAvailable() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }

    @ViewBuilder
    func numberPadKeyboardIfAvailable() -> some View {
        #if os(iOS)
        self.keyboardType(.numberPad)
        #else
        self
        #endif
    }
}
