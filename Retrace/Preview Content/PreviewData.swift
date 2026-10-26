import CoreLocation
import Foundation
import RouteReplay
import SwiftUI

// Previews compile in every configuration, so this file isn't wrapped in `#if DEBUG`.
// It's a few small values, and nothing outside previews uses them.

extension RecordedRoute {
    /// A loop of about 2 km around Vake Park, recorded two days ago.
    static let previewLoop: RecordedRoute = {
        let start = Date.now.addingTimeInterval(-2 * 24 * 60 * 60)
        let points = (0...120).map { step in
            let angle = Double(step) / 120 * 2 * .pi
            return RoutePoint(
                latitude: 41.7105 + 0.0028 * sin(angle),
                longitude: 44.7470 + 0.0045 * cos(angle) * (1 + 0.25 * sin(3 * angle)),
                horizontalAccuracy: 5,
                timestamp: start.addingTimeInterval(Double(step) * 12)
            )
        }
        return RecordedRoute(name: "Vake Park loop", recordedAt: start, points: points)
    }()

    /// A route with one point, imported yesterday.
    static let previewSinglePoint = RecordedRoute(
        name: "Dropped pin",
        recordedAt: Date.now.addingTimeInterval(-24 * 60 * 60),
        points: [
            RoutePoint(latitude: 41.6938, longitude: 44.8015, horizontalAccuracy: 5, timestamp: .now)
        ]
    )
}

extension SavedRoute {
    static let previewSample = SavedRoute(id: SavedRoute.sampleID, route: .bundledSample, isSample: true)
}

extension RouteStore {
    /// A store in a new temporary folder, with the sample and, unless `withRoutes` is false, two made-up routes.
    static func preview(withRoutes: Bool = true) -> RouteStore {
        let folder = RouteFolder(
            url: .temporaryDirectory.appending(path: "RetracePreview-\(UUID().uuidString)", directoryHint: .isDirectory)
        )
        let store = RouteStore(folder: folder, sample: .bundledSample)
        if withRoutes {
            _ = try? store.add(.previewLoop)
            _ = try? store.add(.previewSinglePoint)
        }
        return store
    }

    /// A store whose folder can't be created, so `load()` fails and the view shows its error alert.
    static func previewFailingToLoad() -> RouteStore {
        RouteStore(folder: RouteFolder(url: URL(filePath: "/dev/null/Routes")), sample: .bundledSample)
    }
}

extension View {
    /// Location for previews: a permission fixed at `status`, and Live replaced by a replay of the
    /// sample, so no preview ever needs real GPS or shows the system prompt.
    func previewLocation(_ status: CLAuthorizationStatus = .authorizedWhenInUse) -> some View {
        environment(LocationPermission(fixedStatus: status))
            .environment(\.makeLiveProvider, Factory("Sample replay") {
                ReplayLocationProvider(route: .bundledSample, speed: 10, loop: true)
            })
    }
}
