import Foundation
import RouteReplay
import SwiftUI

/// A small picture of a route's shape: the path in the accent color on a quiet tile.
struct RouteThumbnail: View {
    let route: RecordedRoute

    var body: some View {
        RouteShape(points: route.points)
            .stroke(.tint, style: StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round))
            .padding(Theme.Spacing.xSmall)
            .frame(width: 56, height: 56)
            .background(
                .fill.quaternary,
                in: RoundedRectangle(cornerRadius: Theme.Radius.thumbnail, style: .continuous)
            )
            .accessibilityHidden(true)
    }
}

/// The outline of a route, scaled to fit its rect with north up.
///
/// Longitude is scaled by the cosine of the latitude, so one unit is about the same distance
/// on both axes and the shape isn't stretched. The aspect ratio is kept and the shape is centered.
nonisolated struct RouteShape: Shape {
    /// The points in a flat projection, with y growing southwards like screen coordinates.
    private let projected: [CGPoint]
    private let bounds: CGRect

    init(points: [RoutePoint]) {
        let latitudes = points.map(\.latitude)
        let middleLatitude = ((latitudes.min() ?? 0) + (latitudes.max() ?? 0)) / 2
        let longitudeScale = cos(middleLatitude * .pi / 180)
        projected = points.map { CGPoint(x: $0.longitude * longitudeScale, y: -$0.latitude) }

        let xs = projected.map(\.x)
        let ys = projected.map(\.y)
        let minX = xs.min() ?? 0
        let minY = ys.min() ?? 0
        bounds = CGRect(x: minX, y: minY, width: (xs.max() ?? 0) - minX, height: (ys.max() ?? 0) - minY)
    }

    func path(in rect: CGRect) -> Path {
        guard let first = projected.first else { return Path() }

        // A route that's a single point, or a straight north-south or east-west line,
        // has no size on one axis, so only the other axis decides the scale.
        let widthScale = bounds.width > 0 ? rect.width / bounds.width : .infinity
        let heightScale = bounds.height > 0 ? rect.height / bounds.height : .infinity
        let scale = min(widthScale, heightScale).isFinite ? min(widthScale, heightScale) : 0

        func place(_ point: CGPoint) -> CGPoint {
            CGPoint(
                x: rect.midX + (point.x - bounds.midX) * scale,
                y: rect.midY + (point.y - bounds.midY) * scale
            )
        }

        var path = Path()
        path.move(to: place(first))
        // With a round line cap, a single point draws as a dot.
        path.addLines(projected.count > 1 ? projected.dropFirst().map(place) : [place(first)])
        return path
    }
}

#Preview(traits: .sizeThatFitsLayout) {
    HStack(spacing: Theme.Spacing.small) {
        RouteThumbnail(route: .sample)
        RouteThumbnail(route: .previewLoop)
        RouteThumbnail(route: .previewSinglePoint)
    }
    .padding()
}
