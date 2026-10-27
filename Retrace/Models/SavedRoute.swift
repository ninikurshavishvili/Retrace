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

    /// The name, or "Untitled Route" for a route saved without one.
    var displayName: String {
        name.isEmpty ? String(localized: "Untitled Route") : name
    }

    static let sampleID = UUID(uuidString: "5A3B1E00-0000-4000-8000-000000000001")!

    static func == (lhs: SavedRoute, rhs: SavedRoute) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
