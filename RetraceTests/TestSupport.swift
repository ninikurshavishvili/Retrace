import Foundation
import RouteReplay

enum TestRoutes {
    static let start = Date(timeIntervalSince1970: 1_792_576_800)

    /// A walk north from Freedom Square, one point every `interval` seconds, 0.001° of latitude apart.
    ///
    /// Points use whole-second times, 5 m accuracy and no speed or course, so they survive a GPX round trip unchanged.
    static func walk(
        name: String = "Test walk",
        recordedAt: Date = start,
        pointCount: Int = 3,
        interval: TimeInterval = 10
    ) -> RecordedRoute {
        let points = (0..<pointCount).map { index in
            RoutePoint(
                latitude: 41.6934 + Double(index) * 0.001,
                longitude: 44.8015,
                altitude: 450 + Double(index),
                horizontalAccuracy: 5,
                timestamp: recordedAt.addingTimeInterval(Double(index) * interval)
            )
        }
        return RecordedRoute(name: name, recordedAt: recordedAt, points: points)
    }
}

/// A new, empty folder in the temporary directory.
func makeTemporaryDirectory() throws -> URL {
    let url = URL.temporaryDirectory.appending(
        path: "RetraceTests-\(UUID().uuidString)",
        directoryHint: .isDirectory
    )
    try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    return url
}

/// The test bundle, which holds the files in `Fixtures/`.
final class TestBundle {
    static var bundle: Bundle { Bundle(for: TestBundle.self) }
}
