import Foundation
import RouteReplay

/// A failure the user sees in an alert, with a plain message (APP_PLAN.md §9).
nonisolated enum RetraceError: LocalizedError, Equatable {
    case invalidGPX(String, line: Int)
    case noPoints
    case unsupportedFileExtension(String)
    case notARoute
    case unreadableFile(String)
    case loadFailed(String)
    case saveFailed(String)
    case deleteFailed(String)

    /// Maps an error from reading a route file to the message the user sees.
    init(importing error: any Error) {
        switch error {
        case let error as RetraceError:
            self = error
        case RouteFileError.invalidGPX(let message, let line):
            self = .invalidGPX(message, line: line)
        case RouteFileError.noPoints:
            self = .noPoints
        case RouteFileError.unsupportedFileExtension(let fileExtension):
            self = .unsupportedFileExtension(fileExtension)
        case is DecodingError:
            self = .notARoute
        default:
            self = .unreadableFile(error.localizedDescription)
        }
    }

    /// A short alert title.
    var title: String {
        switch self {
        case .invalidGPX, .noPoints, .unsupportedFileExtension, .notARoute, .unreadableFile:
            String(localized: "Can't Import File")
        case .loadFailed:
            String(localized: "Can't Load Routes")
        case .saveFailed:
            String(localized: "Can't Save Route")
        case .deleteFailed:
            String(localized: "Can't Delete Route")
        }
    }

    var errorDescription: String? {
        switch self {
        case .invalidGPX(let message, let line):
            // RouteReplay's messages end with a period; the line number goes before ours.
            let message = message.hasSuffix(".") ? String(message.dropLast()) : message
            return String(localized: "This GPX file can't be read: \(message) (line \(line)).")
        case .noPoints:
            return String(localized: "This file has no points to replay.")
        case .unsupportedFileExtension(let fileExtension) where fileExtension.isEmpty:
            return String(localized: "Retrace opens .gpx and .json files.")
        case .unsupportedFileExtension(let fileExtension):
            return String(localized: "Retrace opens .gpx and .json files, not .\(fileExtension).")
        case .notARoute:
            return String(localized: "This JSON file isn't a RouteReplay route.")
        case .unreadableFile(let reason):
            return String(localized: "Couldn't open the file. \(reason)")
        case .loadFailed(let reason):
            return String(localized: "Couldn't load your routes. \(reason)")
        case .saveFailed(let reason):
            return String(localized: "Couldn't save the route. \(reason)")
        case .deleteFailed(let reason):
            return String(localized: "Couldn't delete the route. \(reason)")
        }
    }
}
