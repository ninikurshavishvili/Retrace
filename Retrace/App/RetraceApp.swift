import RouteReplay
import SwiftUI

@main
struct RetraceApp: App {
    @State private var store = RouteStore(folder: .documents, sample: .bundledSample)

    var body: some Scene {
        WindowGroup {
            RoutesView()
                .environment(store)
        }
    }
}
