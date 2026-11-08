import SwiftUI

/// The Journal tab's root: owns the `NavigationStack` and the single
/// `.navigationDestination` handler that resolves every `JournalRoute` via the
/// coordinator. Composition root constructs the coordinator; this view just
/// wires it to SwiftUI's navigation.
public struct JournalCoordinatorView: View {
    @ObservedObject private var coordinator: JournalCoordinator

    public init(coordinator: JournalCoordinator) {
        self.coordinator = coordinator
    }

    public var body: some View {
        NavigationStack(path: $coordinator.path) {
            JournalListView(viewModel: coordinator.listViewModel)
                .navigationDestination(for: JournalRoute.self) { route in
                    coordinator.destination(for: route)
                }
        }
    }
}
