import Foundation
import RouteReplay
import Testing
@testable import Retrace

struct RetraceErrorTests {
    @Test func routeFileErrorsBecomePlainMessages() {
        #expect(
            RetraceError(importing: RouteFileError.invalidGPX("<trkpt> has no lat attribute.", line: 7)).errorDescription
                == "This GPX file can't be read: <trkpt> has no lat attribute (line 7)."
        )
        #expect(RetraceError(importing: RouteFileError.noPoints).errorDescription == "This file has no points to replay.")
        #expect(
            RetraceError(importing: RouteFileError.unsupportedFileExtension("txt")).errorDescription
                == "Retrace opens .gpx and .json files, not .txt."
        )
    }

    @Test func aDecodingErrorMeansTheJSONIsNotARoute() {
        #expect(throws: DecodingError.self) {
            try RecordedRoute(jsonData: Data(#"{"hello": "world"}"#.utf8))
        }
        let error = DecodingError.dataCorrupted(.init(codingPath: [], debugDescription: "Bad"))

        #expect(RetraceError(importing: error) == .notARoute)
        #expect(RetraceError.notARoute.errorDescription == "This JSON file isn't a RouteReplay route.")
    }

    @Test func otherErrorsKeepTheirDescription() {
        let error = CocoaError(.fileReadNoPermission)

        #expect(RetraceError(importing: error) == .unreadableFile(error.localizedDescription))
    }
}
