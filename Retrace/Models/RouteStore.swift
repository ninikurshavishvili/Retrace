import Foundation
import Observation
import RouteReplay

/// The list of routes: the bundled sample first, then the saved routes, newest first.
///
/// Every change is written to the ``RouteFolder`` straight away, on the main actor.
/// Route files are a few kilobytes, so that's fast enough and keeps the store simple.
@MainActor @Observable final class RouteStore {
    private(set) var routes: [SavedRoute]

    private let folder: RouteFolder
    private let sample: SavedRoute

    init(folder: RouteFolder, sample: RecordedRoute) {
        self.folder = folder
        self.sample = SavedRoute(id: SavedRoute.sampleID, route: sample, isSample: true)
        routes = [self.sample]
    }

    /// Reads the saved routes from the folder again. Files that can't be decoded are skipped.
    func load() throws(RetraceError) {
        do {
            let saved = try folder.readAll().map { SavedRoute(id: $0.id, route: $0.route, isSample: false) }
            routes = Self.ordered([sample] + saved)
        } catch {
            throw .loadFailed(error.localizedDescription)
        }
    }

    /// Saves a new route to the folder and adds it to the list.
    @discardableResult
    func add(_ route: RecordedRoute) throws(RetraceError) -> SavedRoute {
        let saved = SavedRoute(id: UUID(), route: route, isSample: false)
        do {
            try folder.write(route, id: saved.id)
        } catch {
            throw .saveFailed(error.localizedDescription)
        }
        routes = Self.ordered(routes + [saved])
        return saved
    }

    /// Reads a `.gpx` or `.json` file, for example one picked in the Files app, and saves it as a new route.
    ///
    /// The original file is only read, never changed.
    @discardableResult
    func importFile(at url: URL) throws(RetraceError) -> SavedRoute {
        let route: RecordedRoute
        do {
            // Files picked outside the app's sandbox can only be read inside a security-scoped access.
            let isAccessing = url.startAccessingSecurityScopedResource()
            defer { if isAccessing { url.stopAccessingSecurityScopedResource() } }
            route = try RecordedRoute(contentsOf: url)
        } catch {
            throw RetraceError(importing: error)
        }
        return try add(route)
    }

    /// Deletes a saved route and its file. The sample is part of the app, so deleting it does nothing.
    func delete(_ route: SavedRoute) throws(RetraceError) {
        guard !route.isSample else { return }
        do {
            try folder.remove(id: route.id)
        } catch {
            throw .deleteFailed(error.localizedDescription)
        }
        routes.removeAll { $0.id == route.id }
    }

    private static func ordered(_ routes: [SavedRoute]) -> [SavedRoute] {
        routes.sorted { lhs, rhs in
            if lhs.isSample != rhs.isSample { return lhs.isSample }
            if lhs.route.recordedAt != rhs.route.recordedAt { return lhs.route.recordedAt > rhs.route.recordedAt }
            // A stable order for routes recorded at the same moment, such as two imports of one file.
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }
}
