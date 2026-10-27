import CoreLocation
import Foundation
import RouteReplay
import Testing
@testable import Retrace

@MainActor
struct WalkTrackerTests {
    @Test func countsEveryUpdateAndMatchesTheRouteDistance() async {
        let route = TestRoutes.walk(pointCount: 5, interval: 10)
        let tracker = WalkTracker(provider: ReplayLocationProvider(route: route, speed: 1_000))

        await tracker.start()

        #expect(tracker.updateCount == route.points.count)
        #expect(abs(tracker.distance - RouteStats(route).distance.converted(to: .meters).value) < 0.001)
        #expect(tracker.lastLocation?.coordinate.latitude == route.points.last?.latitude)
        #expect(tracker.firstDate != nil)
        #expect(tracker.elapsed > 0)
        #expect(tracker.speed != nil)
    }

    @Test func invalidLocationsCountAsUpdatesButAddNoDistance() async {
        let walk = TestRoutes.walk(pointCount: 3)
        let invalid = RoutePoint(latitude: 41.80, longitude: 44.90, horizontalAccuracy: -1, timestamp: TestRoutes.start)
        let route = RecordedRoute(
            name: "With an invalid fix",
            recordedAt: TestRoutes.start,
            points: [walk.points[0], invalid, walk.points[1], walk.points[2]]
        )
        let tracker = WalkTracker(provider: ReplayLocationProvider(route: route, speed: 1_000))

        await tracker.start()

        #expect(tracker.updateCount == 4)
        #expect(abs(tracker.distance - RouteStats(walk).distance.converted(to: .meters).value) < 0.001)
    }

    @Test func beforeAnyUpdateThereIsNoSpeed() {
        let tracker = WalkTracker(provider: ReplayLocationProvider(route: TestRoutes.walk()))

        #expect(tracker.updateCount == 0)
        #expect(tracker.elapsed == 0)
        #expect(tracker.speed == nil)
    }

    @Test(.timeLimit(.minutes(1)))
    func startReturnsWhenItsTaskIsCancelled() async {
        let provider = ReplayLocationProvider(route: TestRoutes.walk(), speed: 1_000, loop: true)
        let tracker = WalkTracker(provider: provider)
        let task = Task { await tracker.start() }

        while tracker.updateCount == 0 {
            await Task.yield()
        }
        task.cancel()

        // Returns only once the loop has ended; a looping replay would otherwise run until the time limit.
        await task.value
    }
}
