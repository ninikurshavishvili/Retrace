import CoreLocation
import Observation

/// The app's When In Use location permission.
///
/// iOS 17 delivers no live locations until the app has asked, so the Live source calls
/// ``request()`` before it starts.
@MainActor @Observable final class LocationPermission: NSObject, CLLocationManagerDelegate {
    private(set) var status: CLAuthorizationStatus
    private(set) var accuracy: CLAccuracyAuthorization

    @ObservationIgnored private let manager = CLLocationManager()
    @ObservationIgnored private let isFixed: Bool

    override init() {
        isFixed = false
        status = manager.authorizationStatus
        accuracy = manager.accuracyAuthorization
        super.init()
        manager.delegate = self
    }

    /// A permission that stays at `status` and `accuracy` and never shows the system prompt, for previews.
    init(fixedStatus status: CLAuthorizationStatus, accuracy: CLAccuracyAuthorization = .fullAccuracy) {
        isFixed = true
        self.status = status
        self.accuracy = accuracy
        super.init()
    }

    var isAuthorized: Bool {
        status == .authorizedWhenInUse || status == .authorizedAlways
    }

    /// Whether the user left Precise Location on. Without it, positions are only accurate to a few
    /// kilometers, so the recorder would skip every one.
    var isPrecise: Bool {
        accuracy == .fullAccuracy
    }

    /// Denied by the user, or restricted, for example by parental controls. Only Settings can change it.
    var isDenied: Bool {
        status == .denied || status == .restricted
    }

    /// Shows the system prompt. It only appears while the status is `.notDetermined`.
    func request() {
        guard !isFixed else { return }
        manager.requestWhenInUseAuthorization()
    }

    // Also called when the user turns Precise Location on or off.
    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // The manager was made on the main actor, so Core Location calls back on the main thread.
        MainActor.assumeIsolated {
            status = self.manager.authorizationStatus
            accuracy = self.manager.accuracyAuthorization
        }
    }
}
