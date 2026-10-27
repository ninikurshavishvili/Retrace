import CoreLocation
import Observation

/// The app's When In Use location permission.
///
/// iOS 17 delivers no live locations until the app has asked, so the Live source calls
/// ``request()`` before it starts.
@MainActor @Observable final class LocationPermission: NSObject, CLLocationManagerDelegate {
    private(set) var status: CLAuthorizationStatus

    @ObservationIgnored private let manager = CLLocationManager()
    @ObservationIgnored private let isFixed: Bool

    override init() {
        isFixed = false
        status = manager.authorizationStatus
        super.init()
        manager.delegate = self
    }

    /// A permission that stays at `status` and never shows the system prompt, for previews.
    init(fixedStatus status: CLAuthorizationStatus) {
        isFixed = true
        self.status = status
        super.init()
    }

    var isAuthorized: Bool {
        status == .authorizedWhenInUse || status == .authorizedAlways
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

    nonisolated func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        // The manager was made on the main actor, so Core Location calls back on the main thread.
        MainActor.assumeIsolated {
            status = self.manager.authorizationStatus
        }
    }
}
