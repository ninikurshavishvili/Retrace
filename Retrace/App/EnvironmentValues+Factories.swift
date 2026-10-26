import RouteReplay
import SwiftUI

extension EnvironmentValues {
    /// Makes the provider behind the tracker's Live source.
    ///
    /// The app uses real GPS. Previews replace it with a replay, so even Live needs no
    /// permission there, and no app code changes.
    @Entry var makeLiveProvider: Factory<any LocationProvider> = Factory("Live GPS") { LiveLocationProvider() }
}

/// Makes a value on demand, such as a location provider, and can be compared, so it can live in
/// the environment. Call it like a function: `makeLiveProvider()`.
///
/// SwiftUI compares environment values to decide what to redraw. Closures can't be compared,
/// so a factory compares by name instead: give each one its own name.
struct Factory<Product>: Equatable, Sendable {
    let name: String
    private let make: @MainActor @Sendable () -> Product

    init(_ name: String, make: @escaping @MainActor @Sendable () -> Product) {
        self.name = name
        self.make = make
    }

    @MainActor func callAsFunction() -> Product {
        make()
    }

    static func == (lhs: Factory, rhs: Factory) -> Bool {
        lhs.name == rhs.name
    }
}
