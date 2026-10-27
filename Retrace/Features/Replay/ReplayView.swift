import RouteReplay
import SwiftUI

/// Replays a route on a map, with a "Your app" tracker that listens to the same replay.
struct ReplayView: View {
    let route: SavedRoute

    // One replay per screen. The map and the tracker both listen to it, and its shared
    // playhead keeps them in step: pausing the map pauses the tracker.
    @State private var player: ReplayLocationProvider

    init(route: SavedRoute) {
        self.route = route
        _player = State(initialValue: ReplayLocationProvider(route: route.route, speed: 10, loop: true))
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                RouteDebugMap(player: player)
                    .containerRelativeFrame(.vertical) { height, _ in height * 0.55 }
                TrackerPanel(player: player)
                    .padding(Theme.Spacing.medium)
            }
        }
        .scrollBounceBehavior(.basedOnSize)
        .background(Color(.systemGroupedBackground))
        .navigationTitle(route.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Menu {
                    ExportLinks(route: route)
                } label: {
                    Label("Share", systemImage: "square.and.arrow.up")
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        ReplayView(route: .previewSample)
    }
    .previewLocation()
}
