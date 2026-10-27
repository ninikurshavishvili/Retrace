import RouteReplay
import SwiftUI
import UniformTypeIdentifiers

/// The root screen: the sample, then the recorded and imported routes, newest first.
struct RoutesView: View {
    @Environment(RouteStore.self) private var store
    @Environment(\.makeRecorder) private var makeRecorder
    @State private var isImporting = false
    // The Record screen is open while this is set; closing it releases the recorder, which stops GPS.
    @State private var recording: RecordModel?
    @State private var presentedError: RetraceError?

    var body: some View {
        NavigationStack {
            List {
                Section {
                    ForEach(store.routes) { route in
                        NavigationLink(value: route) {
                            RouteRow(route: route)
                        }
                        .contextMenu { menuItems(for: route) }
                        .swipeActions {
                            if !route.isSample {
                                deleteButton(for: route)
                            }
                        }
                    }
                } footer: {
                    Text("Record a walk or import a GPX file.")
                }
            }
            .animation(.default, value: store.routes)
            .navigationTitle("Routes")
            .navigationDestination(for: SavedRoute.self) { route in
                ReplayView(route: route)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    addMenu
                }
            }
            .fileImporter(isPresented: $isImporting, allowedContentTypes: [.gpx, .json]) { result in
                importRoute(from: result)
            }
            .fullScreenCover(item: $recording) { model in
                RecordView(model: model)
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
        // On the stack rather than the list, so it runs once and not every time a pushed screen pops.
        .task {
            do throws(RetraceError) {
                try store.load()
            } catch {
                presentedError = error
            }
        }
    }

    private var addMenu: some View {
        Menu {
            Button("Record a Walk", systemImage: "record.circle") {
                recording = RecordModel(recorder: makeRecorder())
            }
            Button("Import GPX or JSON", systemImage: "square.and.arrow.down") {
                isImporting = true
            }
        } label: {
            Label("Add Route", systemImage: "plus")
        }
    }

    @ViewBuilder
    private func menuItems(for route: SavedRoute) -> some View {
        Section {
            ExportLinks(route: route)
        }
        if !route.isSample {
            Section {
                deleteButton(for: route)
            }
        }
    }

    private func deleteButton(for route: SavedRoute) -> some View {
        Button("Delete", systemImage: "trash", role: .destructive) {
            do throws(RetraceError) {
                try store.delete(route)
            } catch {
                presentedError = error
            }
        }
    }

    private var isShowingError: Binding<Bool> {
        Binding {
            presentedError != nil
        } set: { isShowing in
            if !isShowing { presentedError = nil }
        }
    }

    private func importRoute(from result: Result<URL, any Error>) {
        switch result {
        case .success(let url):
            do throws(RetraceError) {
                try store.importFile(at: url)
            } catch {
                presentedError = error
            }
        case .failure(let error):
            presentedError = .unreadableFile(error.localizedDescription)
        }
    }
}

#Preview("Routes") {
    RoutesView()
        .environment(RouteStore.preview())
        .previewLocation()
}

#Preview("Only the sample") {
    RoutesView()
        .environment(RouteStore.preview(withRoutes: false))
        .previewLocation()
}

#Preview("Load error") {
    RoutesView()
        .environment(RouteStore.previewFailingToLoad())
        .previewLocation()
}
