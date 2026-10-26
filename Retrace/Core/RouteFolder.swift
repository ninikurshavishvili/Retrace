import Foundation
import OSLog
import RouteReplay

/// The folder that stores routes, one `<uuid>.json` file per route.
///
/// Route files are a few kilobytes, so they're read and written synchronously on the caller's
/// actor (the main actor, through `RouteStore`). That's fast enough and keeps the code simple.
nonisolated struct RouteFolder: Sendable {
    let url: URL

    init(url: URL) {
        self.url = url
    }

    /// `Documents/Routes`. The Files app shows it under On My iPhone › Retrace.
    static var documents: RouteFolder {
        RouteFolder(url: .documentsDirectory.appending(path: "Routes", directoryHint: .isDirectory))
    }

    func fileURL(for id: UUID) -> URL {
        url.appending(path: "\(id.uuidString).json", directoryHint: .notDirectory)
    }

    /// Reads every route in the folder, creating the folder if needed.
    ///
    /// Files that aren't named `<uuid>.json` or can't be decoded are skipped and logged,
    /// so one bad file doesn't hide the others.
    func readAll() throws -> [(id: UUID, route: RecordedRoute)] {
        try createIfNeeded()
        let files = try FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil,
            options: .skipsHiddenFiles
        )
        return files.compactMap { file in
            let name = file.lastPathComponent
            guard
                file.pathExtension.lowercased() == "json",
                let id = UUID(uuidString: file.deletingPathExtension().lastPathComponent)
            else {
                Self.logger.info("Skipped \(name, privacy: .public): not named <uuid>.json.")
                return nil
            }
            do {
                return (id, try RecordedRoute(contentsOf: file))
            } catch {
                Self.logger.error("Skipped \(name, privacy: .public): \(error.localizedDescription, privacy: .public)")
                return nil
            }
        }
    }

    func write(_ route: RecordedRoute, id: UUID) throws {
        try createIfNeeded()
        try route.save(to: fileURL(for: id), format: .json)
    }

    /// Deletes a route's file. A file that's already gone, for example removed in the Files app, counts as deleted.
    func remove(id: UUID) throws {
        do {
            try FileManager.default.removeItem(at: fileURL(for: id))
        } catch CocoaError.fileNoSuchFile {
            return
        }
    }

    private func createIfNeeded() throws {
        try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true)
    }

    private static let logger = Logger(subsystem: "com.ninikurshavishvili.Retrace", category: "RouteFolder")
}
