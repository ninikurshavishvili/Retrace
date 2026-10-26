import UniformTypeIdentifiers

extension UTType {
    /// GPS Exchange Format, declared as an imported type in Info.plist (conforms to `public.xml`).
    nonisolated static let gpx = UTType(importedAs: "com.topografix.gpx")
}
