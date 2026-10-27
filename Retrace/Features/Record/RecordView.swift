import MapKit
import RouteReplay
import SwiftUI
import UIKit

/// Records a walk: a map that follows you and draws the path, live numbers, and the record button.
///
/// Recording runs only while this screen is open and Retrace is in front, so the screen stays on
/// while recording and a banner says so.
struct RecordView: View {
    let model: RecordModel

    @Environment(RouteStore.self) private var store
    @Environment(LocationPermission.self) private var permission
    @Environment(\.dismiss) private var dismiss
    @Environment(\.openURL) private var openURL
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    @State private var position = MapCameraPosition.userLocation(followsHeading: false, fallback: .automatic)
    // Turning this on starts the task that runs the recording, so closing the screen ends it.
    @State private var wantsToRecord = false
    @State private var isShowingSaveSheet = false
    @State private var isConfirmingCancel = false

    var body: some View {
        Group {
            if permission.isDenied {
                locationOff
            } else {
                recordingScreen
            }
        }
        .task {
            // The system prompt appears only while the status is undecided.
            if permission.status == .notDetermined {
                permission.request()
            }
        }
        .task(id: wantsToRecord) {
            guard wantsToRecord else { return }
            await model.start()
        }
        .onChange(of: model.isRecording) { _, isRecording in
            // iOS stops sending locations once Retrace is in the background, so keep the screen on.
            UIApplication.shared.isIdleTimerDisabled = isRecording
            AccessibilityNotification.Announcement(
                isRecording ? String(localized: "Recording started") : String(localized: "Recording stopped")
            )
            .post()
        }
        .onDisappear {
            UIApplication.shared.isIdleTimerDisabled = false
        }
        .sheet(isPresented: $isShowingSaveSheet) {
            saveSheet
        }
        .confirmationDialog("Discard this walk?", isPresented: $isConfirmingCancel, titleVisibility: .visible) {
            Button("Discard Walk", role: .destructive) {
                discardAndClose()
            }
            Button(model.isRecording ? "Keep Recording" : "Cancel", role: .cancel) {}
        } message: {
            Text("The points recorded so far will be lost.")
        }
    }

    // MARK: - Screens

    private var recordingScreen: some View {
        Map(position: $position) {
            UserAnnotation()
            if model.points.count > 1 {
                MapPolyline(coordinates: model.coordinates)
                    .stroke(Color.accentColor, style: StrokeStyle(lineWidth: 5, lineCap: .round, lineJoin: .round))
            }
        }
        .mapControls {
            MapUserLocationButton()
            MapCompass()
        }
        .safeAreaInset(edge: .top) {
            VStack(spacing: Theme.Spacing.xSmall) {
                hud
                notice
            }
            .padding(.horizontal, Theme.Spacing.medium)
        }
        .safeAreaInset(edge: .bottom) {
            controls
        }
    }

    private var locationOff: some View {
        ContentUnavailableView {
            Label("Location is off", systemImage: "location.slash")
        } description: {
            Text("Retrace needs your location to record a walk. Turn it on in Settings.")
        } actions: {
            Button("Open Settings", action: openSettings)
            Button("Close") {
                dismiss()
            }
        }
    }

    // MARK: - Parts

    private var hud: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            LazyVGrid(columns: hudColumns, alignment: .leading, spacing: Theme.Spacing.small) {
                StatTile(title: "Duration", value: StatFormat.duration(model.duration(at: context.date), width: .narrow))
                StatTile(title: "Distance", value: StatFormat.distance(model.distance))
                StatTile(title: "Points", value: model.points.count.formatted())
                StatTile(title: "Accuracy", value: model.points.last.map { StatFormat.accuracy($0.horizontalAccuracy) } ?? "—")
            }
        }
        .card()
    }

    // Two columns at accessibility text sizes, so the numbers stay readable.
    private var hudColumns: [GridItem] {
        let count = dynamicTypeSize.isAccessibilitySize ? 2 : 4
        return Array(repeating: GridItem(.flexible(), spacing: Theme.Spacing.small, alignment: .topLeading), count: count)
    }

    @ViewBuilder
    private var notice: some View {
        if model.isRecording {
            Label("Keep Retrace open. Recording stops in the background.", systemImage: "info.circle")
                .font(.footnote)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(Theme.Spacing.small)
                .background(.regularMaterial, in: RoundedRectangle(cornerRadius: Theme.Radius.thumbnail, style: .continuous))
        } else if !permission.isAuthorized {
            NoticeCard(
                title: "Allow location to record",
                message: "Retrace uses your location only while you record a walk.",
                systemImage: "location",
                buttonTitle: "Allow Location",
                action: permission.request
            )
        } else if !permission.isPrecise {
            NoticeCard(
                title: "Precise Location is off",
                message: "Retrace needs your exact position to draw the walk. Turn on Precise Location in Settings.",
                systemImage: "location.circle",
                buttonTitle: "Open Settings",
                action: openSettings
            )
        }
    }

    private var controls: some View {
        HStack {
            Button("Cancel", action: cancelTapped)
                .padding(.horizontal, Theme.Spacing.medium)
                .padding(.vertical, Theme.Spacing.xSmall)
                .background(.regularMaterial, in: Capsule())
                .frame(maxWidth: .infinity)
            RecordButton(isRecording: model.isRecording, action: recordTapped)
                .disabled(!canRecord)
            // Balances the Cancel button, so the record button stays centered.
            Color.clear
                .frame(maxWidth: .infinity, maxHeight: 1)
        }
        .padding(.bottom, Theme.Spacing.small)
    }

    @ViewBuilder
    private var saveSheet: some View {
        if let route = model.recordedRoute {
            SaveRouteSheet(route: route) { name throws(RetraceError) in
                guard let named = model.route(named: name) else { return }
                try store.add(named)
                dismiss()
            } onKeepRecording: {
                isShowingSaveSheet = false
                model.reset()
                wantsToRecord = true
            } onDiscard: {
                dismiss()
            }
        }
    }

    // MARK: - Actions

    private var canRecord: Bool {
        guard permission.isAuthorized, permission.isPrecise else { return false }
        return model.state == .idle || model.isRecording
    }

    private func recordTapped() {
        if model.isRecording {
            Task {
                await model.stop(name: model.suggestedName)
                wantsToRecord = false
                isShowingSaveSheet = true
            }
        } else {
            wantsToRecord = true
        }
    }

    private func cancelTapped() {
        if model.points.isEmpty {
            discardAndClose()
        } else {
            isConfirmingCancel = true
        }
    }

    private func discardAndClose() {
        Task {
            await model.discard()
            dismiss()
        }
    }

    private func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            openURL(url)
        }
    }
}

/// A small card over the map that explains why recording can't start yet, with one action.
private struct NoticeCard: View {
    let title: LocalizedStringKey
    let message: LocalizedStringKey
    let systemImage: String
    let buttonTitle: LocalizedStringKey
    let action: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.xxSmall) {
            Label(title, systemImage: systemImage)
                .font(.subheadline.weight(.semibold))
            Text(message)
                .font(.footnote)
                .foregroundStyle(.secondary)
            Button(buttonTitle, action: action)
                .font(.subheadline)
                .padding(.top, Theme.Spacing.xxSmall)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .card()
    }
}

#Preview("Ready") {
    RecordView(model: .preview)
        .environment(RouteStore.preview())
        .previewLocation()
}

#Preview("Location not asked yet") {
    RecordView(model: .preview)
        .environment(RouteStore.preview())
        .previewLocation(.notDetermined)
}

#Preview("Precise Location off") {
    RecordView(model: .preview)
        .environment(RouteStore.preview())
        .previewLocation(accuracy: .reducedAccuracy)
}

#Preview("Location off") {
    RecordView(model: .preview)
        .environment(RouteStore.preview())
        .previewLocation(.denied)
}
