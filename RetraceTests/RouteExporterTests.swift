import Foundation
import RouteReplay
import Testing
@testable import Retrace

struct RouteExporterTests {
    @Test(arguments: [RouteFileFormat.gpx, .json])
    func theFileHasTheRightExtensionAndDecodesToTheSamePoints(format: RouteFileFormat) throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }
        let route = TestRoutes.walk(name: "Rustaveli walk", pointCount: 5)

        let url = try RouteExporter.temporaryFile(for: route, format: format, in: directory)
        let decoded = try RecordedRoute(contentsOf: url)

        #expect(url.lastPathComponent == "Rustaveli walk.\(format.fileExtension)")
        #expect(decoded.name == route.name)
        #expect(decoded.points == route.points)
    }

    @Test func exportingAgainReplacesTheEarlierFile() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        _ = try RouteExporter.temporaryFile(for: TestRoutes.walk(pointCount: 2), format: .json, in: directory)
        let url = try RouteExporter.temporaryFile(for: TestRoutes.walk(pointCount: 3), format: .json, in: directory)

        #expect(try RecordedRoute(contentsOf: url).points.count == 3)
        #expect(try FileManager.default.contentsOfDirectory(atPath: directory.path(percentEncoded: false)).count == 1)
    }

    @Test(arguments: [
        ("Walk · Oct 25, 14:05", "Walk · Oct 25, 14-05"),
        ("Tbilisi/Mtatsminda", "Tbilisi-Mtatsminda"),
        (#"a\b?c*d|e"f<g>h%i"#, "a-b-c-d-e-f-g-h-i"),
        ("Line\nbreak", "Line-break"),
        ("  .hidden walk.  ", "hidden walk"),
        ("", "Route"),
        ("   ", "Route"),
        ("..", "Route"),
    ])
    func unsafeNamesAreCleaned(name: String, expected: String) {
        #expect(RouteExporter.fileName(for: name) == expected)
    }

    @Test func aCleanedNameStaysInTheGivenDirectory() throws {
        let directory = try makeTemporaryDirectory()
        defer { try? FileManager.default.removeItem(at: directory) }

        let url = try RouteExporter.temporaryFile(for: TestRoutes.walk(name: "../up/and:out"), format: .gpx, in: directory)

        #expect(url.deletingLastPathComponent().standardizedFileURL == directory.standardizedFileURL)
        #expect(url.lastPathComponent == "-up-and-out.gpx")
    }

    @Test func veryLongNamesAreShortened() {
        #expect(RouteExporter.fileName(for: String(repeating: "a", count: 500)).count == 80)
    }
}
