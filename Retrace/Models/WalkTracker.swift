import CoreLocation
import Foundation
import Observation
import RouteReplay

/// The "your app" stand-in on the Replay screen: it tracks a walk from any ``LocationProvider``.
///
/// It only knows the protocol, so it can't tell a replay from real GPS. Replayed locations are
/// stamped with the current time, so at 10x it sees ten times the real speed, as a real app would.
@MainActor @Observable final class WalkTracker {
    /// The sum of the distances between consecutive valid locations, in meters.
    private(set) var distance: CLLocationDistance = 0
    /// The time of the first update.
    private(set) var firstDate: Date?
    /// The most recent update, valid or not.
    private(set) var lastLocation: CLLocation?
    private(set) var updateCount = 0

    /// The time from the first update to the last.
    var elapsed: TimeInterval {
        guard let firstDate, let lastLocation else { return 0 }
        return lastLocation.timestamp.timeIntervalSince(firstDate)
    }

    /// The average speed so far in meters per second, or `nil` before any time has passed.
    var speed: CLLocationSpeed? {
        elapsed > 0 ? distance / elapsed : nil
    }

    @ObservationIgnored private let provider: any LocationProvider
    // A location with a negative accuracy is invalid, so distance is measured from the last valid one.
    @ObservationIgnored private var lastValidLocation: CLLocation?

    init(provider: any LocationProvider) {
        self.provider = provider
    }

    /// Tracks locations until the provider's stream ends or the calling task is cancelled.
    func start() async {
        for await location in provider.locations() {
            record(location)
        }
    }

    private func record(_ location: CLLocation) {
        if firstDate == nil {
            firstDate = location.timestamp
        }
        if location.horizontalAccuracy >= 0 {
            if let lastValidLocation {
                distance += location.distance(from: lastValidLocation)
            }
            lastValidLocation = location
        }
        lastLocation = location
        updateCount += 1
    }
}
