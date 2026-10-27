import SwiftUI

/// The big record button: a red circle in a white ring that morphs into a rounded square while recording.
///
/// With Reduce Motion on, it switches shape without the morph.
struct RecordButton: View {
    let isRecording: Bool
    let action: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @Environment(\.isEnabled) private var isEnabled

    init(isRecording: Bool, action: @escaping () -> Void) {
        self.isRecording = isRecording
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            ZStack {
                Circle()
                    .strokeBorder(.white, lineWidth: 4)
                RoundedRectangle(cornerRadius: isRecording ? 8 : 30, style: .continuous)
                    .fill(.red)
                    .frame(width: isRecording ? 30 : 60, height: isRecording ? 30 : 60)
            }
            .frame(width: 76, height: 76)
            .shadow(color: .black.opacity(0.25), radius: 4, y: 1)
            .opacity(isEnabled ? 1 : 0.4)
        }
        .buttonStyle(.plain)
        .animation(reduceMotion ? nil : .spring(duration: 0.35, bounce: 0.3), value: isRecording)
        .accessibilityLabel(isRecording ? "Stop Recording" : "Start Recording")
    }
}

#Preview {
    HStack(spacing: Theme.Spacing.large) {
        RecordButton(isRecording: false) {}
        RecordButton(isRecording: true) {}
        RecordButton(isRecording: false) {}
            .disabled(true)
    }
    .padding()
    .background(.gray)
}
