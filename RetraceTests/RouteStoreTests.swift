import Foundation
import RouteReplay
import Testing
@testable import Retrace

@MainActor
final class RouteStoreTests {
    private let directory: URL
    private let folder: RouteFolder

    init() throws {
        directory = try makeTemporaryDirectory()
        folder = RouteFolder(url: directory.appending(path: "Routes", directoryHint: .isDirectory))
    }

    deinit {
        try? FileManager.default.removeItem(at: directory)
    }

    @Test func addWritesAFileThatLoadReadsBackSampleFirstThenNewestFirst() throws {
        let store = makeStore()
        let older = try store.add(TestRoutes.walk(name: "Older", recordedAt: TestRoutes.start))
        let newer = try store.add(TestRoutes.walk(name: "Newer", recordedAt: TestRoutes.start.addingTimeInterval(3_600)))

        #expect(Set(savedFileNames()) == ["\(older.id.uuidString).json", "\(newer.id.uuidString).json"])

        let reloaded = makeStore()
        try reloaded.load()

        #expect(reloaded.routes.map(\.id) == [SavedRoute.sampleID, newer.id, older.id])
        #expect(reloaded.routes.map(\.route) == [store.routes[0].route, newer.route, older.route])
        #expect(reloaded.routes.map(\.isSample) == [true, false, false])
    }

    @Test func loadSkipsFilesThatAreNotRoutes() throws {
        let store = makeStore()
        let saved = try store.add(TestRoutes.walk())
        try Data("not json".utf8).write(to: folder.fileURL(for: UUID()))
        try Data("{}".utf8).write(to: folder.url.appending(path: "notes.json"))

        let reloaded = makeStore()
        try reloaded.load()

        #expect(reloaded.routes.map(\.id) == [SavedRoute.sampleID, saved.id])
    }

    @Test func deleteRemovesTheFile() throws {
        let store = makeStore()
        let kept = try store.add(TestRoutes.walk(name: "Kept"))
        let deleted = try store.add(TestRoutes.walk(name: "Deleted"))

        try store.delete(deleted)

        #expect(store.routes.map(\.id) == [SavedRoute.sampleID, kept.id])
        #expect(savedFileNames() == ["\(kept.id.uuidString).json"])
    }

    @Test func theSampleCannotBeDeleted() throws {
        let store = makeStore()
        let sample = try #require(store.routes.first)

        try store.delete(sample)

        #expect(store.routes == [sample])
        #expect(sample.isSample)
    }

    @Test func importingTheGPXFixtureAddsARoute() throws {
        let store = makeStore()
        let url = try #require(TestBundle.bundle.url(forResource: "VakePark", withExtension: "gpx"))
        let original = try Data(contentsOf: url)

        let imported = try store.importFile(at: url)

        #expect(imported.name == "VakePark")
        #expect(imported.route.points.count == 4)
        #expect(imported.stats.duration == 90)
        #expect(store.routes.map(\.id) == [SavedRoute.sampleID, imported.id])
        #expect(savedFileNames() == ["\(imported.id.uuidString).json"])
        #expect(try Data(contentsOf: url) == original)
    }

    @Test(arguments: [
        ("Broken.gpx", "<gpx><trk><trkseg>"),
        ("Empty.gpx", #"<gpx version="1.1" xmlns="http://www.topografix.com/GPX/1/1"></gpx>"#),
        ("NotARoute.json", #"{"hello": "world"}"#),
        ("Notes.txt", "Walked to the river."),
    ])
    func importingABadFileThrowsAndLeavesNoFileBehind(fileName: String, contents: String) throws {
        let store = makeStore()
        let url = directory.appending(path: fileName)
        try Data(contents.utf8).write(to: url)

        #expect(throws: RetraceError.self) {
            try store.importFile(at: url)
        }
        #expect(savedFileNames().isEmpty)
        #expect(store.routes.map(\.id) == [SavedRoute.sampleID])
    }

    // MARK: - Helpers

    private func makeStore() -> RouteStore {
        RouteStore(folder: folder, sample: TestRoutes.walk(name: "Sample"))
    }

    private func savedFileNames() -> [String] {
        (try? FileManager.default.contentsOfDirectory(atPath: folder.url.path(percentEncoded: false))) ?? []
    }
}
