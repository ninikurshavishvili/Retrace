import CoreLocation
import RouteReplay
import SwiftUI
import UIKit

/// The "Your app" card on the Replay screen: a ``WalkTracker`` fed by the replay or by real GPS.
struct TrackerPanel: View {
    enum Source: Hashable {
        case replay
        case live
    }

    /// The screen's replay, shared with the map so both see the same point.
    let player: ReplayLocationProvider

    @Environment(LocationPermission.self) private var permission
    @Environment(\.makeLiveProvider) private var makeLiveProvider
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @Environment(\.openURL) private var openURL
    @State private var source: Source
    @State private var tracker: WalkTracker?

    init(player: ReplayLocationProvider, source: Source = .replay) {
        self.player = player
        _source = State(initialValue: source)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            VStack(alignment: .leading, spacing: Theme.Spacing.xxSmall) {
                Text("Your app")
                    .font(.headline)
                Text("This panel only knows `LocationProvider`. It can't tell the replay from real GPS.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Picker("Source", selection: $source) {
                Text("Replay").tag(Source.replay)
                Text("Live").tag(Source.live)
            }
            .pickerStyle(.segmented)

            if canTrack {
                stats
            } else {
                permissionMessage
            }
        }
        .card()
        // A new tracker for every source, so switching starts from zero. Leaving the screen
        // cancels the task, which ends the tracker's stream.
        .task(id: Run(source: source, canTrack: canTrack)) {
            await track()
        }
    }

    private var canTrack: Bool {
        source == .replay || permission.isAuthorized
    }

    private var stats: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            LazyVGrid(columns: columns, alignment: .leading, spacing: Theme.Spacing.small) {
                StatTile(title: "Distance", value: tracker.map { StatFormat.distance($0.distance) } ?? "—")
                StatTile(title: "Elapsed", value: tracker.map { StatFormat.duration($0.elapsed, width: .narrow) } ?? "—")
                StatTile(title: "Speed", value: tracker?.speed.map(StatFormat.speed) ?? "—")
                StatTile(title: "Updates", value: tracker.map { $0.updateCount.formatted() } ?? "—")
            }
            Text(coordinate)
                .font(.footnote.monospaced())
                .foregroundStyle(.secondary)
        }
    }

    // One column at accessibility text sizes, so the numbers stay readable.
    private var columns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 1 : 2
        return Array(repeating: GridItem(.flexible(), spacing: Theme.Spacing.small, alignment: .topLeading), count: count)
    }

    private var coordinate: String {
        guard let location = tracker?.lastLocation else {
            return String(localized: "Waiting for the first location…")
        }
        return StatFormat.coordinate(location.coordinate)
    }

    private var permissionMessage: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xSmall) {
            if permission.isDenied {
                Label("Location is off for Retrace", systemImage: "location.slash")
                    .font(.subheadline.weight(.semibold))
                Text("Turn it on in Settings to track where you are. Replay works without it.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        openURL(url)
                    }
                }
            } else {
                Label("Live uses this iPhone's location", systemImage: "location.fill")
                    .font(.subheadline.weight(.semibold))
                Text("Retrace asks once. Replay works without it.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                Button("Allow Location") {
                    permission.request()
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func track() async {
        tracker = nil
        guard canTrack else { return }
        let tracker = WalkTracker(provider: source == .replay ? player : makeLiveProvider())
        self.tracker = tracker
        await tracker.start()
    }

    private struct Run: Equatable {
        let source: Source
        let canTrack: Bool
    }
}

#Preview("Replay") {
    TrackerPanel(player: ReplayLocationProvider(route: .bundledSample, speed: 10, loop: true))
        .padding()
        .previewLocation()
}

#Preview("Live, as a replay") {
    TrackerPanel(player: ReplayLocationProvider(route: .bundledSample, speed: 10, loop: true), source: .live)
        .padding()
        .previewLocation()
}

#Preview("Live, not asked yet") {
    TrackerPanel(player: ReplayLocationProvider(route: .bundledSample), source: .live)
        .padding()
        .previewLocation(.notDetermined)
}

#Preview("Live, denied") {
    TrackerPanel(player: ReplayLocationProvider(route: .bundledSample), source: .live)
        .padding()
        .previewLocation(.denied)
}
