import SwiftUI

/// The Log tab's root: wires `LogEntryView` to its coordinator and owns the
/// follow-up sheet (with its own small internal `NavigationStack`, since a
/// pending entry can still push through to `DraftReviewView` from there).
public struct LogCoordinatorView: View {
    @ObservedObject private var coordinator: LogCoordinator

    public init(coordinator: LogCoordinator) {
        self.coordinator = coordinator
    }

    public var body: some View {
        LogEntryView(viewModel: coordinator.formViewModel, onEntrySaved: coordinator.entrySaved)
            .sheet(item: $coordinator.presentedEntry, onDismiss: { coordinator.sheetPath = [] }) { entry in
                NavigationStack(path: $coordinator.sheetPath) {
                    coordinator.followUpView(for: entry)
                        .navigationDestination(for: LogRoute.self) { route in
                            coordinator.destination(for: route)
                        }
                }
            }
    }
}
