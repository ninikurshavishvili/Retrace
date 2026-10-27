import CoreLocation
import Foundation

/// Formats distances, durations and speeds in the user's locale, for list rows and stat tiles.
nonisolated enum StatFormat {
    /// "1.2 km", "350 m" or "0.7 mi".
    static func distance(_ meters: CLLocationDistance) -> String {
        Measurement(value: meters, unit: UnitLength.meters)
            .formatted(.measurement(width: .abbreviated, usage: .road))
    }

    /// At most two units: "14 min, 5 sec" when abbreviated, "14m 5s" when narrow.
    static func duration(
        _ seconds: TimeInterval,
        width: Duration.UnitsFormatStyle.UnitWidth = .abbreviated
    ) -> String {
        Duration.seconds(seconds).formatted(
            .units(allowed: [.hours, .minutes, .seconds], width: width, maximumUnitCount: 2)
        )
    }

    /// "5.0 km/h" or "3.1 mph", with one decimal.
    static func speed(_ metersPerSecond: CLLocationSpeed) -> String {
        Measurement(value: metersPerSecond, unit: UnitSpeed.metersPerSecond)
            .converted(to: .kilometersPerHour)
            .formatted(.measurement(
                width: .abbreviated,
                usage: .general,
                numberFormatStyle: .number.precision(.fractionLength(1))
            ))
    }

    /// "±5 m", the radius a position could be off by.
    static func accuracy(_ meters: CLLocationAccuracy) -> String {
        let radius = Measurement(value: meters.rounded(), unit: UnitLength.meters)
            .formatted(.measurement(width: .abbreviated, usage: .asProvided))
        return String(localized: "±\(radius)")
    }

    /// "41.69340, 44.80150", always with a period and five decimals (about a meter).
    static func coordinate(_ coordinate: CLLocationCoordinate2D) -> String {
        String(format: "%.5f, %.5f", coordinate.latitude, coordinate.longitude)
    }
}
