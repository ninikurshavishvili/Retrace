import CoreLocation
import Foundation
import RouteReplay
import Testing
@testable import Retrace

@MainActor
struct RecordModelTests {
    @Test func recordsAReplayWithoutItsBadPointAndStopsWithTheName() async {
        let walk = TestRoutes.walk(pointCount: 4)
        let badFix = RoutePoint(latitude: 41.80, longitude: 44.90, horizontalAccuracy: 100, timestamp: TestRoutes.start)
        let replay = RecordedRoute(
            name: "With a bad fix",
            recordedAt: TestRoutes.start,
            points: [walk.points[0], walk.points[1], badFix, walk.points[2], walk.points[3]]
        )
        let model = RecordModel(recorder: RouteRecorder(provider: ReplayLocationProvider(route: replay, speed: 1_000)))

        // Returns once the replay has sent its last point.
        await model.start()
        let route = await model.stop(name: "Morning walk")

        #expect(route.name == "Morning walk")
        // Replayed points carry the current time, so compare where they are.
        #expect(route.points.map(\.latitude) == walk.points.map(\.latitude))
        #expect(model.points == route.points)
        #expect(abs(model.distance - RouteStats(walk).distance.converted(to: .meters).value) < 0.001)
        #expect(model.recordedRoute == route)
    }

    @Test(.timeLimit(.minutes(1)))
    func goesFromIdleToRecordingToStopped() async {
        let replay = ReplayLocationProvider(route: TestRoutes.walk(pointCount: 5), speed: 1_000, loop: true)
        let model = RecordModel(recorder: RouteRecorder(provider: replay))
        #expect(model.state == .idle)
        #expect(model.duration(at: .now) == 0)

        let recording = Task { await model.start() }
        while model.points.count < 2 {
            await Task.yield()
        }
        #expect(model.isRecording)

        let route = await model.stop(name: "Loop")
        // Stopping ends the recorder's stream, so the recording task finishes.
        await recording.value

        guard case .stopped = model.state else {
            Issue.record("Expected the model to be stopped, but it's \(model.state).")
            return
        }
        #expect(!model.isRecording)
        #expect(route.points.count >= 2)
        // The duration stops counting.
        #expect(model.duration(at: .now) == model.duration(at: .now.addingTimeInterval(3_600)))
    }

    @Test func renamingKeepsThePointsAndTheStartTime() async {
        let model = RecordModel(recorder: RouteRecorder(provider: ReplayLocationProvider(route: TestRoutes.walk(), speed: 1_000)))
        #expect(model.route(named: "Anything") == nil)

        await model.start()
        let route = await model.stop(name: model.suggestedName)
        let renamed = model.route(named: "Evening walk")

        #expect(route.name.hasPrefix("Walk · "))
        #expect(renamed?.name == "Evening walk")
        #expect(renamed?.points == route.points)
        #expect(renamed?.recordedAt == route.recordedAt)
    }

    @Test func aStopWithNoPointsCanStartOver() async {
        let empty = RecordedRoute(name: "Empty", recordedAt: TestRoutes.start, points: [])
        let model = RecordModel(recorder: RouteRecorder(provider: ReplayLocationProvider(route: empty)))

        await model.start()
        let route = await model.stop(name: "Nothing yet")
        model.reset()

        #expect(route.points.isEmpty)
        #expect(model.state == .idle)
        #expect(model.recordedRoute == nil)
    }

    @Test func aStopWithPointsIsNotReset() async {
        let model = RecordModel(recorder: RouteRecorder(provider: ReplayLocationProvider(route: TestRoutes.walk(), speed: 1_000)))

        await model.start()
        await model.stop(name: "Walk")
        model.reset()

        #expect(model.recordedRoute != nil)
        #expect(model.points.count == 3)
    }
}
