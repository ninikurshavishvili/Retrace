import Foundation
import RouteReplay
import Testing
@testable import Retrace

struct RouteStatsTests {
    @Test func twoPointsAThousandthOfADegreeOfLatitudeApartAreAbout111Meters() {
        let stats = RouteStats(TestRoutes.walk(pointCount: 2))

        #expect(abs(stats.distance.converted(to: .meters).value - 111) <= 1)
    }

    @Test func durationIsTheTimeFromTheFirstPointToTheLast() {
        let stats = RouteStats(TestRoutes.walk(pointCount: 4, interval: 12.5))

        #expect(stats.duration == 37.5)
        #expect(stats.pointCount == 4)
    }

    @Test func averageSpeedIsDistanceOverDuration() throws {
        let stats = RouteStats(TestRoutes.walk(pointCount: 3, interval: 50))
        let speed = try #require(stats.averageSpeed)

        #expect(abs(speed.converted(to: .metersPerSecond).value - stats.distance.converted(to: .meters).value / 100) < 0.000_001)
    }

    @Test func aSinglePointHasNoDistanceAndNoSpeed() {
        let stats = RouteStats(TestRoutes.walk(pointCount: 1))

        #expect(stats.distance.value == 0)
        #expect(stats.duration == 0)
        #expect(stats.averageSpeed == nil)
        #expect(stats.pointCount == 1)
    }
}
