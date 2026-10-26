import Foundation
import RouteReplay

/// A route in the list: the bundled sample, or one stored in a ``RouteFolder``.
///
/// Two saved routes are equal when they have the same ID.
nonisolated struct SavedRoute: Identifiable, Hashable {
    /// The file name in the route folder. The sample always uses ``sampleID``.
    let id: UUID
    let route: RecordedRoute
    let isSample: Bool
    /// Worked out once here, because every list row shows it.
    let stats: RouteStats

    init(id: UUID, route: RecordedRoute, isSample: Bool) {
        self.id = id
        self.route = route
        self.isSample = isSample
        stats = RouteStats(route)
    }

    var name: String { route.name }

    static let sampleID = UUID(uuidString: "5A3B1E00-0000-4000-8000-000000000001")!

    static func == (lhs: SavedRoute, rhs: SavedRoute) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

extension RecordedRoute {
    /// A walk along Rustaveli Avenue in Tbilisi, from `SampleWalk.gpx` in the app bundle.
    ///
    /// The file is a copy of RouteReplay's test fixture `RustaveliWalk.gpx`. Replace it with
    /// `RecordedRoute.sample` once the package ships one.
    nonisolated static let bundledSample: RecordedRoute = {
        guard
            let url = Bundle.main.url(forResource: "SampleWalk", withExtension: "gpx"),
            let route = try? RecordedRoute(contentsOf: url)
        else {
            preconditionFailure("SampleWalk.gpx is missing from the app bundle or can't be read.")
        }
        return route
    }()
}
