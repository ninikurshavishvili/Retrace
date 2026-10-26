import CoreTransferable
import Foundation
import RouteReplay
import UniformTypeIdentifiers

/// Writes routes to files for the share sheet.
nonisolated enum RouteExporter {
    /// Writes the route to `<directory>/<safe name>.gpx` or `.json` and returns the file's URL.
    ///
    /// An earlier export with the same name is replaced.
    static func temporaryFile(
        for route: RecordedRoute,
        format: RouteFileFormat,
        in directory: URL = .temporaryDirectory
    ) throws -> URL {
        let url = directory
            .appending(path: fileName(for: route.name), directoryHint: .notDirectory)
            .appendingPathExtension(format.fileExtension)
        try route.save(to: url, format: format)
        return url
    }

    /// Turns a route name into a file name without an extension.
    ///
    /// Path separators, `:` and other characters that file systems or the share sheet reject
    /// become "-". Leading and trailing spaces and dots are removed, so the file is never hidden.
    /// A name with nothing left becomes "Route".
    static func fileName(for name: String) -> String {
        let unsafe = CharacterSet(charactersIn: #"/\:?%*|"<>"#)
            .union(.controlCharacters)
            .union(.newlines)
        let replaced = String(String.UnicodeScalarView(
            name.unicodeScalars.map { unsafe.contains($0) ? "-" : $0 }
        ))
        let trimmed = replaced.trimmingCharacters(in: CharacterSet.whitespaces.union(CharacterSet(charactersIn: ".")))
        return trimmed.isEmpty ? "Route" : String(trimmed.prefix(maximumNameLength))
    }

    /// Long enough for any real name, well under the 255-byte file name limit.
    private static let maximumNameLength = 80
}

extension RouteFileFormat {
    nonisolated var fileExtension: String {
        switch self {
        case .gpx: "gpx"
        case .json: "json"
        }
    }
}

/// A route the share sheet can send as a file.
///
/// The file is written by ``RouteExporter`` only when the user picks a destination,
/// so showing a share button never touches the disk.
nonisolated struct RouteFile: Transferable {
    let route: RecordedRoute
    let format: RouteFileFormat

    static var transferRepresentation: some TransferRepresentation {
        FileRepresentation(exportedContentType: .gpx) { file in
            SentTransferredFile(try RouteExporter.temporaryFile(for: file.route, format: .gpx))
        }
        .exportingCondition { $0.format == .gpx }

        FileRepresentation(exportedContentType: .json) { file in
            SentTransferredFile(try RouteExporter.temporaryFile(for: file.route, format: .json))
        }
        .exportingCondition { $0.format == .json }
    }
}
