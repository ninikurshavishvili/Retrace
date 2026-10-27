import CoreLocation
import Foundation
import Observation
import RouteReplay

/// Records a walk with RouteReplay's `RouteRecorder` and keeps the numbers the Record screen shows.
///
/// The recorder keeps only accurate points a few meters apart, so `points` is what gets saved.
/// Releasing the model releases the recorder, which stops reading GPS.
@MainActor @Observable final class RecordModel: Identifiable {
    enum State: Equatable {
        case idle
        case recording(startedAt: Date)
        case stopped(startedAt: Date, stoppedAt: Date)
    }

    private(set) var state = State.idle
    /// The points kept so far.
    private(set) var points: [RoutePoint] = []
    /// The distance along the kept points, in meters.
    private(set) var distance: CLLocationDistance = 0
    /// The route ``stop(name:)`` returned, until it's saved or the screen closes.
    private(set) var recordedRoute: RecordedRoute?

    @ObservationIgnored private let recorder: RouteRecorder

    init(recorder: RouteRecorder) {
        self.recorder = recorder
    }

    nonisolated var id: ObjectIdentifier {
        ObjectIdentifier(self)
    }

    var isRecording: Bool {
        if case .recording = state { true } else { false }
    }

    var coordinates: [CLLocationCoordinate2D] {
        points.map { CLLocationCoordinate2D(latitude: $0.latitude, longitude: $0.longitude) }
    }

    /// How long the recording has run at `date`: zero before it starts, and fixed once it stops.
    func duration(at date: Date) -> TimeInterval {
        switch state {
        case .idle:
            0
        case .recording(let startedAt):
            max(0, date.timeIntervalSince(startedAt))
        case .stopped(let startedAt, let stoppedAt):
            stoppedAt.timeIntervalSince(startedAt)
        }
    }

    /// The name the save sheet suggests, such as "Walk · Oct 27, 14:05".
    var suggestedName: String {
        let start: Date
        switch state {
        case .idle: start = .now
        case .recording(let startedAt), .stopped(let startedAt, _): start = startedAt
        }
        let time = start.formatted(.dateTime.month(.abbreviated).day().hour().minute())
        return String(localized: "Walk · \(time)")
    }

    /// Records until ``stop(name:)`` is called or the location stream ends.
    ///
    /// Call it from a task tied to the screen. It does nothing unless the model is idle.
    func start() async {
        guard state == .idle else { return }
        state = .recording(startedAt: .now)
        for await point in await recorder.start() {
            add(point)
        }
    }

    /// Stops recording and returns the route with `name`.
    @discardableResult
    func stop(name: String) async -> RecordedRoute {
        let route = await recorder.stop(name: name)
        if case .recording(let startedAt) = state {
            state = .stopped(startedAt: startedAt, stoppedAt: .now)
        }
        // The recorder's list is complete; the stream may still hold a point or two.
        points = route.points
        distance = RouteStats(route).distance.converted(to: .meters).value
        recordedRoute = route
        return route
    }

    /// The stopped route with a new name, ready to save.
    func route(named name: String) -> RecordedRoute? {
        recordedRoute.map { RecordedRoute(name: name, recordedAt: $0.recordedAt, points: $0.points) }
    }

    /// Goes back to idle after a stop with no points, so the walk can be recorded again.
    func reset() {
        guard recordedRoute?.points.isEmpty ?? true else { return }
        state = .idle
        points = []
        distance = 0
        recordedRoute = nil
    }

    /// Stops reading GPS without keeping anything.
    func discard() async {
        _ = await recorder.stop(name: "")
        recordedRoute = nil
    }

    private func add(_ point: RoutePoint) {
        // Points still buffered when the recording stopped are already in the stopped route.
        guard isRecording else { return }
        if let last = points.last {
            distance += point.makeLocation().distance(from: last.makeLocation())
        }
        points.append(point)
    }
}
