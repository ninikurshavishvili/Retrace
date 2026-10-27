import RouteReplay
import SwiftUI

/// "Export as GPX" and "Export as JSON", for a Share menu or a row's context menu.
struct ExportLinks: View {
    let route: SavedRoute

    var body: some View {
        ShareLink(
            item: RouteFile(route: route.route, format: .gpx),
            preview: SharePreview(route.displayName)
        ) {
            Label("Export as GPX", systemImage: "square.and.arrow.up")
        }
        ShareLink(
            item: RouteFile(route: route.route, format: .json),
            preview: SharePreview(route.displayName)
        ) {
            Label("Export as JSON", systemImage: "square.and.arrow.up")
        }
    }
}
