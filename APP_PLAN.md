# Retrace: app plan

**Retrace** is the companion iOS app for [RouteReplay](https://github.com/ninikurshavishvili/RouteReplay). Record a walk once, then replay it anywhere.

Updated Oct 25, 2026. This is the full spec. Each milestone at the end is one chat and one PR, with a prompt to paste.

---

## 1. Name and identity

| | |
| --- | --- |
| **Name** | **Retrace**: you record a walk, then retrace it on a map at any speed. It's short and memorable, and it says what the app does. |
| Alternatives | Trailback · Footprints · WalkBack · Replay Lab |
| Tagline | *Record a walk once. Replay it anywhere.* |
| Repo | `github.com/ninikurshavishvili/Retrace` (public, MIT) |
| Local folder | `~/Developer/Retrace`. **Not on the Desktop**: iCloud sync there breaks code signing for builds. |
| Bundle ID | `com.ninikurshavishvili.Retrace` |
| App icon | One continuous orange trail curving across an off-white tile, with a small dot at its start and a filled dot at its end, like a route being replayed. Make dark and tinted variants in Icon Composer. |

## 2. Purpose

1. **Getting real data:** a Swift package can't run on a phone or ask for location permission. Retrace records real walks, so the package gets real routes and a real sample.
2. **Showcase:** the README GIF, the screen recordings and the LinkedIn posts come from Retrace. It shows other developers what RouteReplay does in 30 seconds.
3. **Dogfooding:** Retrace depends on RouteReplay from GitHub, exactly like an outside developer would. Awkward API shows up here first.
4. **Portfolio:**
   - Dependency injection
   - Swift 6 concurrency
   - SwiftUI and MapKit
   - File handling and Swift Testing

**Who it's for:** you while building, and iOS developers who want to see RouteReplay working before adopting it.
**Non-goal:** it's not a consumer fitness app, and it won't go on the App Store in v1.

## 3. Scope

| In v1 | Not in v1 (park in `IDEAS.md`) |
| --- | --- |
| A route list: the bundled sample, plus your recorded and imported routes | Accounts, cloud sync, sharing between users |
| Import `.gpx` / `.json` from Files; export GPX or JSON through the share sheet | Editing, trimming or merging routes |
| Replay: RouteReplay's `RouteDebugMap` plus a "Your app" tracker panel | Background recording (RouteReplay v2) |
| A Live / Replay switch: the same tracker fed by real GPS or by the replay | Apple Watch, iPad layout, widgets |
| Record a walk in the foreground: live map path, stats, then name and save it | Settings, onboarding, App Store release (TestFlight is optional) |
| Routes visible in the Files app, so they're easy to AirDrop to a Mac | Analytics, crash reporting |

## 4. User flows

1. **First launch:** the Routes list shows the sample "Rustaveli walk". Tap it, and Replay plays it at 10x. No permission is asked, and it works in the simulator.
2. **Import:** **+** → Import → pick an Xcode `.gpx` file → it appears at the top of the list → tap it to replay.
3. **Live vs Replay:** on Replay, flip the tracker from Replay to Live. On a device it asks for When In Use permission and then tracks real GPS. The same `WalkTracker` code runs both ways.
4. **Record** (on a device):
   - **+** → Record. The map follows you, with a big record button.
   - Walk. The path draws behind you, with live stats.
   - Stop, name the walk, and save it. It appears in the list.
5. **Export:** on Replay, tap Share and choose GPX or JSON. Send it with AirDrop to your Mac, then into the package as the new sample route.

## 5. Screens

### 5.1 Routes (root)
- A `NavigationStack` with the large title "Routes".
- **Toolbar:** a **+** `Menu` with:
  - Record a walk (`record.circle`)
  - Import GPX or JSON (`square.and.arrow.down`)
- **List rows** (`RouteRow`):
  - Left: `RouteThumbnail`, 56×56 with corner radius 12. It draws the route shape in the accent color on a quiet background.
  - Middle:
    - the route name in `.headline`
    - a second line in `.subheadline`, secondary color, for example "Oct 21 · 1.2 km · 14 min"
    - a "Sample" capsule badge on the sample route
  - Swipe to delete. The sample has no swipe action.
- **Order:** the sample is always first, then the other routes, newest first.
- **Footer hint:** "Record a walk or import a GPX file."
- **Errors** show in an `.alert` with a plain message (see §9).

### 5.2 Replay (push from a row)
- The navigation title is the route name. The toolbar has a **Share** `Menu` (`square.and.arrow.up`) with "Export as GPX" and "Export as JSON".
- **Top, about 60% of the height:** `RouteDebugMap(player:)` from RouteReplay, which gives the route line, moving dot, play/pause, restart and the 1x–50x picker.
- **Bottom: `TrackerPanel`**, a material card:
  - A header "Your app" with a caption: "This panel only knows `LocationProvider`. It can't tell the replay from real GPS."
  - A segmented `Picker` called Source: **Replay | Live**.
  - A 2×2 grid of `StatTile`s:
    - Distance
    - Elapsed
    - Speed
    - Updates
  - The last coordinate in `.footnote.monospaced()`.
  - In Live mode with no permission, an inline message with an "Allow location" or "Open Settings" button.
- **Wiring:** one `ReplayLocationProvider(route:speed: 10, loop: true)` per screen. The map and the tracker both listen to it. RouteReplay's shared playhead keeps them in sync, so pausing the map pauses the tracker.

### 5.3 Record (full-screen cover)
- A full-screen `Map`:
  - `UserAnnotation()`
  - a `MapPolyline` of the kept points, in the accent color at 5 pt
  - camera `.userLocation(followsHeading: false, fallback: .automatic)`
- **Top HUD,** a material card with:
  - Duration, updating every second through `TimelineView(.periodic)`
  - Distance
  - Points kept
  - Accuracy of the last point
- **Bottom: `RecordButton`,** 76 pt.
  - Idle: a red circle inside a white ring.
  - Recording: a rounded red square, morphing with a spring animation.
  - A "Cancel" button sits to its left; it asks for confirmation if any points were recorded.
- **While recording:** `UIApplication.shared.isIdleTimerDisabled = true`. A banner says "Keep Retrace open. Recording stops in the background."
- **Stop** shows `SaveRouteSheet` (medium detent):
  - A name field, pre-filled with "Walk · Oct 25, 14:05" and the text selected.
  - A summary line.
  - Save (prominent) and Discard (destructive, with confirmation).
  - Save is disabled with 0 points: "No points yet. Walk a bit further."
- **Permission denied:** a `ContentUnavailableView` titled "Location is off" with an "Open Settings" button.

### 5.4 States checklist
- **Every screen:** loading (if any), empty, error and permission-denied states.
- **Previews:** every view has at least one `#Preview` that uses replay only, so no permission is ever needed in previews.

## 6. Design system

The app is native first: standard SwiftUI controls, SF Symbols, system materials and Dynamic Type. Building with the current SDK gives it the current system look for free (including Liquid Glass on iOS 26+). Don't hand-roll glass effects.

| Token | Value |
| --- | --- |
| **Accent "Trail"** | Light `#C2410C`, dark `#FB923C`, in an `AccentColor` asset with both appearances |
| Use the accent for | Route lines, the current-location dot, icons, and links on plain backgrounds. **Never as a fill behind text.** |
| Record | `Color.red` (system), with a white SF Symbol on it |
| Backgrounds | `systemGroupedBackground` for lists, `.regularMaterial` for cards and HUDs |
| Spacing | 4 · 8 · 12 · 16 · 24 · 32 |
| Corner radius | 12 for thumbnails, 20 for cards (`.continuous`) |
| Type | Titles use system text styles. Stat values use `.title2.weight(.semibold).monospacedDigit()`. Stat labels use `.caption` in uppercase, secondary. Coordinates use `.footnote.monospaced()`. |
| Symbols | `plus`, `record.circle`, `square.and.arrow.down`, `square.and.arrow.up`, `play.fill`, `pause.fill`, `arrow.counterclockwise`, `location.fill`, `figure.walk`, `map` |

**Accessibility (contrast checked):**
- `#C2410C` on white is 5.2:1, and `#FB923C` on black is 9.1:1. Both pass WCAG AA for text on plain backgrounds.
- Because of that, accent text only ever sits on plain backgrounds, never on accent fills.
- Dynamic Type works up to the accessibility sizes: the stat grid becomes one column there.
- VoiceOver gets labels on icon-only buttons. "Recording started" and "Recording stopped" are announced.
- With Reduce Motion on, the record button doesn't morph.

**Components** live in `DesignSystem/`:
- `Theme`: spacing and radius constants, plus a `.card()` view modifier.
- `StatTile(title:value:)`
- `RouteThumbnail(route:)`: a `Shape`. It normalizes the coordinates into its rect, scales longitude by `cos(latitude)` so shapes aren't stretched, and keeps the aspect ratio.
- `RecordButton(isRecording:action:)`
- `Badge(text:)`

## 7. Architecture

SwiftUI and Observation, organised by feature, with no third-party dependencies. Views stay thin. State lives in `@Observable` models, and the location work happens in RouteReplay's actors.

```text
┌──────────── Features (SwiftUI views) ────────────┐
│ RoutesView · ReplayView · TrackerPanel ·          │
│ RecordView · SaveRouteSheet                       │
└───────────────┬───────────────────────────────────┘
                ▼
┌──────── Models (@Observable, MainActor) ─────────┐
│ RouteStore · WalkTracker · RecordModel ·          │
│ LocationPermission                                │
└───────────────┬───────────────────────────────────┘
                ▼
┌────────────── Core (plain Swift) ────────────────┐
│ RouteFolder (file I/O) · RouteStats ·             │
│ RouteExporter · UTType+GPX                        │
└───────────────┬───────────────────────────────────┘
                ▼
        RouteReplay package
        (LocationProvider, LiveLocationProvider,
         ReplayLocationProvider, RouteRecorder,
         RecordedRoute, RouteDebugMap)
```

**Dependency injection.** This is the point of the whole app:
- `RetraceApp` builds `RouteStore` and `LocationPermission`, and injects them with `.environment(_:)`.
- Factories are environment values made with `@Entry`:
  ```swift
  extension EnvironmentValues {
      @Entry var makeLiveProvider: @MainActor () -> any LocationProvider = { LiveLocationProvider() }
      @Entry var makeRecorder: @MainActor () -> RouteRecorder = { RouteRecorder() }   // after package C
  }
  ```
- Previews override `makeLiveProvider` with `{ ReplayLocationProvider(route: .sample, speed: 10, loop: true) }`. Even "Live" mode in a preview is a replay, so no permission is needed and nothing in the app code changes.

**Concurrency:**
- Swift 6 language mode with complete checking. If the project has *Default Actor Isolation = MainActor* (the default for new projects in Xcode 26+), keep it, and mark pure helpers `nonisolated` where needed.
- File I/O works on small JSON files (a few KB), so it runs on the main actor. That's simpler, and fast enough; the code should say so in a comment.
- Long-running work is tied to view lifetimes through `.task` / `.task(id:)`, so leaving a screen cancels its streams. No `Task.detached`, and no stored tasks without cancelling them.

**`LocationPermission`** (`@MainActor @Observable`, an `NSObject` acting as `CLLocationManagerDelegate`):
- It has `status` and `request()`.
- The manager is created on the main actor. The nonisolated delegate callback reads `manager.authorizationStatus` and updates `status` inside `MainActor.assumeIsolated { }`.
- iOS 17 needs an explicit request before `liveUpdates()` delivers anything.

## 8. Data and files

```swift
struct SavedRoute: Identifiable, Hashable {    // Hashable and == by id only
    let id: UUID                               // the file name; the sample uses a fixed id
    let route: RecordedRoute                   // from RouteReplay
    let isSample: Bool
    var stats: RouteStats { RouteStats(route) }
}

struct RouteStats {
    let distance: Measurement<UnitLength>      // sum of the distances between consecutive points
    let duration: TimeInterval                 // last timestamp minus first
    let pointCount: Int
    var averageSpeed: Measurement<UnitSpeed>?  // nil when the duration is 0
}

@MainActor @Observable final class RouteStore {
    private(set) var routes: [SavedRoute]      // sample first, then newest `recordedAt` first
    init(folder: RouteFolder, sample: RecordedRoute)
    func load() throws
    @discardableResult func add(_ route: RecordedRoute) throws -> SavedRoute
    @discardableResult func importFile(at url: URL) throws -> SavedRoute  // security-scoped, then saved as JSON
    func delete(_ route: SavedRoute) throws    // the sample can't be deleted
}
```

**Files and formats:**
- **Storage:** `Documents/Routes/<uuid>.json`, written with RouteReplay's `route.save(to:format: .json)`. Everything is re-read on launch, and files that can't be decoded are skipped and logged.
- **Files app:** set `UIFileSharingEnabled` and `LSSupportsOpeningDocumentsInPlace` to YES, so the folder shows under *On My iPhone › Retrace*. That's the easiest way to get a recorded walk onto a Mac.
- **Import:**
  - `.fileImporter(allowedContentTypes: [.gpx, .json])` gives a URL.
  - Call `startAccessingSecurityScopedResource()`, read it with `RecordedRoute(contentsOf:)`, call `stop…`, then `add`.
  - The original file is never modified.
- **Export:** `RouteExporter.temporaryFile(for:format:) throws -> URL`.
  - It writes `tmp/<safe name>.gpx` or `.json`.
  - Characters like `/` and `:` are replaced, and the name falls back to "Route".
  - The result goes to `ShareLink(item: url)`.
- **GPX type:** declare an imported type `com.topografix.gpx`, conforming to `public.xml`, with extension `gpx` and MIME `application/gpx+xml`. In code: `extension UTType { static let gpx = UTType(importedAs: "com.topografix.gpx") }`.
- **Sample route:**
  - Until RouteReplay ships `RecordedRoute.sample` (package A), copy the package's `Tests/RouteReplayTests/Fixtures/RustaveliWalk.gpx` into the app as `SampleWalk.gpx` and load it from `Bundle.main`.
  - After package A, switch to `.sample` and delete the copy.
- **Distances and times** use `Measurement` and `Duration` formatting: `.measurement(width: .abbreviated, usage: .road)`, and `.units(allowed: [.hours, .minutes, .seconds], width: .abbreviated)`. They follow the user's locale.

**`WalkTracker`** (`@MainActor @Observable`), the "your app" stand-in:
```swift
init(provider: any LocationProvider)
private(set) var distance: CLLocationDistance       // adds distance(from:) between consecutive locations, ignoring accuracy < 0
private(set) var firstDate: Date?, lastLocation: CLLocation?, updateCount: Int
var elapsed: TimeInterval { get }                   // lastLocation.timestamp - firstDate
var speed: CLLocationSpeed? { get }                 // distance / elapsed
func start() async                                  // for await over provider.locations(); returns when the stream ends or is cancelled
```
Replayed locations are stamped with "now". At 10x, the tracker sees 10x speed, just like a real app would. That's intended, and the panel caption explains it.

**`RecordModel`** (after package C) wraps `RouteRecorder`:
- State: `idle → recording(startedAt) → stopped`.
- It has `points: [RoutePoint]` and `distance`.
- `start()` checks permission first, then runs `for await point in await recorder.start()`.
- `stop(name:)` returns the `RecordedRoute`, and the view passes it to `store.add`.

## 9. Errors

Wrap failures in `RetraceError: LocalizedError` and show them in one `.alert`:

| Source | Message |
| --- | --- |
| `RouteFileError.invalidGPX(msg, line:)` | "This GPX file can't be read: *msg* (line *n*)." |
| `RouteFileError.noPoints` | "This file has no points to replay." |
| `RouteFileError.unsupportedFileExtension(ext)` | "Retrace opens .gpx and .json files, not .*ext*." |
| `DecodingError` | "This JSON file isn't a RouteReplay route." |
| A write or delete fails | "Couldn't save the route. *localizedDescription*" |
| Permission denied or restricted | No alert. Show the inline state with "Open Settings" (`UIApplication.openSettingsURLString`). |

## 10. RouteReplay API used, and when it's ready

| API | Status in the package |
| --- | --- |
| `RecordedRoute`, `init(contentsOf:)`, `save(to:format:)`, `RouteFileError` | ✅ on `main` |
| `LocationProvider`, `LiveLocationProvider`, `ReplayLocationProvider` | ✅ on `main` |
| `RecordedRoute.sample`, `RouteDebugMap(player:)` | Package A |
| `RouteReplayTesting.ImmediateClock` (for app tests) | Package B |
| `RouteRecorder(provider:minimumDistance:maximumAccuracy:)`, `start() -> AsyncStream<RoutePoint>`, `stop(name:) -> RecordedRoute` | Package C |

## 11. Project setup (you, in Xcode, about 10 minutes)

1. Create a GitHub repo `Retrace` with a README, the MIT license and the Swift `.gitignore`. Clone it to `~/Developer/Retrace`.
2. Xcode → New → Project → iOS App:
   - Product Name `Retrace`, interface SwiftUI, testing system **Swift Testing**, no Core Data.
   - Save it into `~/Developer/Retrace` and untick "Create Git repository", because the clone already is one.
3. **Target settings:**
   - Deployment iOS 17.0, iPhone only.
   - Swift Language Version 6, Strict Concurrency Complete.
   - Keep "Default Actor Isolation = MainActor" if it's offered.
4. File → Add Package Dependencies → `https://github.com/ninikurshavishvili/RouteReplay.git`, rule **Branch: main**. Add the `RouteReplay` product to the app target. After package B, add `RouteReplayTesting` to the **test target only**.
5. **Info** tab:
   - `NSLocationWhenInUseUsageDescription` = "Retrace uses your location while you record a walk, so you can replay it later."
   - `UIFileSharingEnabled` = YES and `LSSupportsOpeningDocumentsInPlace` = YES.
   - An Imported Type Identifier for `com.topografix.gpx` (§8).
6. **Signing:** your Apple ID team, so it runs on your iPhone.
7. Copy this file into the repo root as `APP_PLAN.md`, then commit "Initial project".
8. **Working on both repos at once:** drag your local `RouteReplay` folder into Retrace's project navigator. Xcode uses that local copy instead of the GitHub one until you remove it. Remove it before committing.

## 12. Folder structure

```text
Retrace/
├── Retrace.xcodeproj
├── Retrace/
│   ├── App/             RetraceApp.swift, EnvironmentValues+Factories.swift
│   ├── DesignSystem/    Theme.swift, StatTile.swift, RouteThumbnail.swift, RecordButton.swift, Badge.swift
│   ├── Core/            RouteFolder.swift, RouteStats.swift, RouteExporter.swift, UTType+GPX.swift, RetraceError.swift
│   ├── Models/          RouteStore.swift, SavedRoute.swift, WalkTracker.swift, LocationPermission.swift, RecordModel.swift
│   ├── Features/
│   │   ├── Routes/      RoutesView.swift, RouteRow.swift
│   │   ├── Replay/      ReplayView.swift, TrackerPanel.swift
│   │   └── Record/      RecordView.swift, SaveRouteSheet.swift
│   ├── Resources/       Assets.xcassets (AccentColor, AppIcon), SampleWalk.gpx (until package A)
│   └── Preview Content/ PreviewData.swift (in-memory RouteStore, sample routes)
├── RetraceTests/        RouteStatsTests, RouteStoreTests, RouteExporterTests, WalkTrackerTests, RecordModelTests, Fixtures/
├── APP_PLAN.md
├── IDEAS.md
├── README.md
└── LICENSE
```

## 13. Testing (Swift Testing, no UI tests in v1)

- **`RouteStatsTests`:**
  - Two points 0.001° of latitude apart are about 111 m (allow ±1 m).
  - The duration matches the timestamps.
  - A single point gives zero distance and a nil speed.
- **`RouteStoreTests`** use a temporary `RouteFolder`:
  - `add` creates a file, and `load` reads it back in the right order.
  - `delete` removes the file.
  - The sample can't be deleted.
  - Importing the GPX fixture adds a route.
  - A bad file throws and leaves no file behind.
- **`RouteExporterTests`:**
  - The temp file has the right extension and decodes back to the same points.
  - Unsafe names are cleaned.
- **`WalkTrackerTests`:**
  - Use `ReplayLocationProvider(route: known, clock: ImmediateClock())`, or `speed: 1_000` until package B.
  - When the stream ends, `updateCount == points.count` and the distance matches `RouteStats`.
- **`RecordModelTests`** (M3): record from a `ReplayLocationProvider` that includes one bad-accuracy point. Stopping returns the kept points with the given name.
- **Run with:** `xcodebuild test -scheme Retrace -destination 'platform=iOS Simulator,name=iPhone 18 Pro'`, with no warnings.

## 14. Milestones

| # | What gets built | Needs | Done when |
| --- | --- | --- | --- |
| **M0** | The project as in §11–12. Theme and AccentColor. `RoutesView` showing the sample from `SampleWalk.gpx`. README skeleton. | — | It runs in the simulator and shows the sample row |
| **M1** | `RouteFolder`, `RouteStore`, `SavedRoute`, `RouteStats`, `RouteThumbnail`, `RouteRow`, import, delete, `RouteExporter`, the error alert, plus tests | — | You can import an Xcode GPX, see its stats, delete it, and export the sample as GPX through the share sheet. Tests are green. |
| **M2** | `ReplayView`, `TrackerPanel`, `WalkTracker`, `LocationPermission`, the Live/Replay switch, previews, `WalkTrackerTests`. Switch to `RecordedRoute.sample`. | Package A (B for instant tests) | The map and the tracker stay in step from 1x to 50x. Live works on a phone, and the simulator works without permission. |
| **M3** | `RecordView`, `RecordModel`, `SaveRouteSheet`, idle timer, Files app sharing, `RecordModelTests`. Record a real Tbilisi walk and AirDrop the JSON to the package as its new sample. | Package C | A walk recorded on the phone replays in the app and in RouteReplay |
| **M4** | App icon, accessibility pass, all empty and error states, screenshots, a GIF and the README | — | The README is ready to link from RouteReplay and LinkedIn |

**README for Retrace (M4):**
- The tagline and a GIF.
- What it shows, with a link to RouteReplay.
- Run it in the simulator (replay only, no permission), and run it on a phone to record.
- The architecture diagram from §7.
- How the Live/Replay switch shows dependency injection.
- The tech list: SwiftUI, MapKit, Observation, Swift 6, Swift Testing.

## 15. Interview talking points

- "The tracker panel only knows `LocationProvider`. I flip one switch, and the same code runs on real GPS or on a replay. That's dependency injection you can see."
- "Previews override one environment factory, so even Live mode in a preview is a replay. No permission, and no device."
- "The map and the tracker share one replay playhead. Pausing one pauses both, because the replay is an actor with a single playback task."

## 16. Prompts for each milestone

**M0 + M1** (first chat, after you've done §11 in Xcode):
> Read `APP_PLAN.md` in this repo. Retrace is the companion app for my RouteReplay Swift package. Implement milestones **M0 and M1** exactly as specified: §6 design system, §7 architecture, §8 data and files, §9 errors, §12 folders, §13 tests for these parts. The project, package dependency and Info.plist entries from §11 are already set up. Use SwiftUI, iOS 17, Swift 6 strict concurrency, no third-party dependencies. Run `xcodebuild test -scheme Retrace -destination 'platform=iOS Simulator,name=iPhone 18 Pro'` with no warnings. Commit on a branch `feature/routes-list`. Don't push.

**M2** (after RouteReplay package A is merged):
> Read `APP_PLAN.md`. Implement milestone **M2** (§5.2 Replay, §7 dependency injection and `LocationPermission`, §8 `WalkTracker`, its tests and previews), and switch the sample to `RecordedRoute.sample`. Branch `feature/replay`. Run the tests and commit. Don't push.

**M3** (after RouteReplay package C is merged):
> Read `APP_PLAN.md`. Implement milestone **M3** (§5.3 Record, `RecordModel`, `SaveRouteSheet`, Files app sharing, `RecordModelTests`). Branch `feature/record`. Run the tests and commit. Don't push.
