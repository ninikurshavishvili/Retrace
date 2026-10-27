import RouteReplay
import SwiftUI

/// Names a recorded walk and saves it, or throws it away.
struct SaveRouteSheet: View {
    let route: RecordedRoute
    let onSave: (String) throws(RetraceError) -> Void
    let onKeepRecording: () -> Void
    let onDiscard: () -> Void

    @State private var name: String
    @State private var isConfirmingDiscard = false
    @State private var presentedError: RetraceError?

    /// - Parameter route: The stopped recording. Its name is suggested as the walk's name.
    init(
        route: RecordedRoute,
        onSave: @escaping (String) throws(RetraceError) -> Void,
        onKeepRecording: @escaping () -> Void,
        onDiscard: @escaping () -> Void
    ) {
        self.route = route
        self.onSave = onSave
        self.onKeepRecording = onKeepRecording
        self.onDiscard = onDiscard
        _name = State(initialValue: route.name)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    NameField(text: $name)
                } footer: {
                    Text(route.points.isEmpty ? String(localized: "No points yet. Walk a bit further.") : summary)
                }
                if route.points.isEmpty {
                    Section {
                        Button("Keep Recording", action: onKeepRecording)
                    }
                }
            }
            .navigationTitle("Save Walk")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Discard", role: .destructive, action: discardTapped)
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                }
            }
            .confirmationDialog("Discard this walk?", isPresented: $isConfirmingDiscard, titleVisibility: .visible) {
                Button("Discard Walk", role: .destructive, action: onDiscard)
            } message: {
                Text("It won't be saved.")
            }
            .alert(
                presentedError?.title ?? "",
                isPresented: isShowingError,
                presenting: presentedError
            ) { _ in
                Button("OK") {}
            } message: { error in
                Text(error.errorDescription ?? "")
            }
        }
        .presentationDetents([.medium])
        // Swiping the sheet away would lose the walk without asking.
        .interactiveDismissDisabled()
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        !route.points.isEmpty && !trimmedName.isEmpty
    }

    private var summary: String {
        let stats = RouteStats(route)
        let points = String(localized: "\(stats.pointCount) points")
        return [stats.formattedDistance, stats.formattedDuration, points].joined(separator: " · ")
    }

    private var isShowingError: Binding<Bool> {
        Binding {
            presentedError != nil
        } set: { isShowing in
            if !isShowing { presentedError = nil }
        }
    }

    private func save() {
        do throws(RetraceError) {
            try onSave(trimmedName)
        } catch {
            presentedError = error
        }
    }

    private func discardTapped() {
        if route.points.isEmpty {
            onDiscard()
        } else {
            isConfirmingDiscard = true
        }
    }
}

/// The name field. On iOS 18 and later the suggested name starts selected, so typing replaces it.
private struct NameField: View {
    @Binding var text: String

    var body: some View {
        if #available(iOS 18, *) {
            SelectedNameField(text: $text)
        } else {
            TextField("Name", text: $text)
        }
    }
}

@available(iOS 18, *)
private struct SelectedNameField: View {
    @Binding var text: String
    @State private var selection: TextSelection?
    @FocusState private var isFocused: Bool

    var body: some View {
        TextField("Name", text: $text, selection: $selection)
            .focused($isFocused)
            .onAppear {
                isFocused = true
            }
            // Focusing puts the cursor at the end, so select the name only once the field has focus.
            .onChange(of: isFocused) { _, isFocused in
                if isFocused {
                    selection = TextSelection(range: text.startIndex..<text.endIndex)
                }
            }
    }
}

#Preview("A walk") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            SaveRouteSheet(route: .previewLoop, onSave: { _ in }, onKeepRecording: {}, onDiscard: {})
        }
}

#Preview("No points") {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            SaveRouteSheet(
                route: RecordedRoute(name: "Walk · Oct 27, 14:05", recordedAt: .now, points: []),
                onSave: { _ in },
                onKeepRecording: {},
                onDiscard: {}
            )
        }
}
