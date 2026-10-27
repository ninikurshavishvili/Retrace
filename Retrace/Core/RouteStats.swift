import CoreLocation
import Foundation
import RouteReplay

/// Distance, duration and point count of a route.
nonisolated struct RouteStats: Equatable {
    /// The sum of the distances between consecutive points.
    let distance: Measurement<UnitLength>
    /// The time from the first point to the last.
    let duration: TimeInterval
    let pointCount: Int

    /// The distance divided by the duration, or `nil` when the duration is zero.
    var averageSpeed: Measurement<UnitSpeed>? {
        guard duration > 0 else { return nil }
        return Measurement(value: distance.converted(to: .meters).value / duration, unit: .metersPerSecond)
    }

    init(_ route: RecordedRoute) {
        // The same locations a replay sends, altitude included, so Core Location measures them
        // exactly as it does for an app tracking the replay.
        let locations = route.points.map { $0.makeLocation() }
        let meters = zip(locations, locations.dropFirst()).reduce(0) { total, pair in
            total + pair.1.distance(from: pair.0)
        }
        distance = Measurement(value: meters, unit: .meters)
        if let first = route.points.first, let last = route.points.last {
            duration = last.timestamp.timeIntervalSince(first.timestamp)
        } else {
            duration = 0
        }
        pointCount = route.points.count
    }

    /// The distance in the user's locale, such as "1.2 km" or "0.7 mi".
    var formattedDistance: String {
        StatFormat.distance(distance.converted(to: .meters).value)
    }

    /// The duration with at most two units, such as "14 min, 5 sec" or "1 hr, 2 min".
    var formattedDuration: String {
        StatFormat.duration(duration)
    }
}
