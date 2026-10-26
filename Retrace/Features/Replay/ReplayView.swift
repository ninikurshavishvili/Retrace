import CoreLocation
import MapKit
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
                map
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

    // Draws the route until RouteReplay ships RouteDebugMap(player:), which takes this place
    // and adds the moving dot and the play, restart and speed controls.
    private var map: some View {
        let coordinates = route.route.points.map {
            CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude)
        }
        let bounds = MKPolyline(coordinates: coordinates, count: coordinates.count).boundingMapRect
        // A margin around the route, and at least a few hundred meters for very short routes.
        let margin = max(bounds.width, bounds.height) * 0.15 + 300
        return Map(initialPosition: .rect(bounds.insetBy(dx: -margin, dy: -margin))) {
            MapPolyline(coordinates: coordinates)
                .stroke(Color.accentColor, lineWidth: 5)
        }
    }
}

#Preview {
    NavigationStack {
        ReplayView(route: .previewSample)
    }
    .previewLocation()
}
