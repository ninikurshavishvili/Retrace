import Foundation
import RouteReplay
import SwiftUI

/// A row in the Routes list: thumbnail, name, and "Oct 21 · 1.2 km · 14 min".
struct RouteRow: View {
    let route: SavedRoute

    var body: some View {
        HStack(spacing: Theme.Spacing.small) {
            RouteThumbnail(route: route.route)
            VStack(alignment: .leading, spacing: Theme.Spacing.xxSmall) {
                // Baseline alignment keeps the badge on the first line when a long name wraps.
                HStack(alignment: .firstTextBaseline, spacing: Theme.Spacing.xSmall) {
                    Text(route.name.isEmpty ? String(localized: "Untitled Route") : route.name)
                        .font(.headline)
                        .lineLimit(2)
                    if route.isSample {
                        Badge(text: "Sample")
                    }
                }
                Text(summary)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, Theme.Spacing.xxSmall)
        .accessibilityElement(children: .combine)
    }

    private var summary: String {
        [
            route.route.recordedAt.formatted(.dateTime.month(.abbreviated).day()),
            route.stats.formattedDistance,
            route.stats.formattedDuration,
        ]
        .joined(separator: " · ")
    }
}

#Preview {
    List {
        RouteRow(route: .previewSample)
        RouteRow(route: SavedRoute(id: UUID(), route: .previewLoop, isSample: false))
        RouteRow(route: SavedRoute(id: UUID(), route: .previewSinglePoint, isSample: false))
    }
}
