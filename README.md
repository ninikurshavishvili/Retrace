# Retrace

*Record a walk once. Replay it anywhere.*

Retrace is the companion iOS app for [RouteReplay](https://github.com/ninikurshavishvili/RouteReplay), a Swift package that replays recorded GPS routes as if they were live. Retrace records real walks, replays them on a map, and shows a "your app" panel that can't tell the replay from real GPS.

<!-- M4: GIF of the Replay screen here. -->

## Status

| Milestone | What | State |
| --- | --- | --- |
| M0 | Project setup, design tokens, route list with the bundled sample | Done |
| M1 | Saved routes, import `.gpx` / `.json`, delete, export through the share sheet | Done |
| M2 | Replay screen, tracker panel, Live / Replay switch | In progress: the tracker works; the map waits for RouteReplay's `RouteDebugMap` |
| M3 | Record a walk, then name and save it | Waits for RouteReplay's `RouteRecorder` |
| M4 | App icon, accessibility pass, screenshots, this README | — |

## Run it

Requirements: Xcode 26 or later, iOS 17 or later. RouteReplay comes from GitHub (branch `main`) through Swift Package Manager.

1. Open `Retrace.xcodeproj`.
2. Pick an iPhone simulator and run the `Retrace` scheme.

The route list opens with a sample walk along Rustaveli Avenue in Tbilisi. Nothing needs location permission in the simulator.

To import a route, tap **+** → **Import GPX or JSON** and pick a file, such as a GPX file from Xcode's location simulation. Long-press a route to export it as GPX or JSON. Saved routes are in the Files app under **On My iPhone › Retrace › Routes**.

## Tests

```bash
xcodebuild test -scheme Retrace -destination 'platform=iOS Simulator,name=iPhone 18 Pro'
```

The tests use Swift Testing and cover route stats, the route store (with a temporary folder), export and error messages.

## How it's built

SwiftUI and Observation, Swift 6 with complete concurrency checking, no third-party dependencies.

```text
Retrace/
├── App/            RetraceApp: builds the RouteStore and injects it into the environment
├── DesignSystem/   Theme tokens, Badge, RouteThumbnail
├── Core/           RouteFolder (file I/O), RouteStats, RouteExporter, UTType+GPX, RetraceError
├── Models/         RouteStore, SavedRoute
├── Features/       Routes, Replay (Record arrives in M3)
├── Resources/      Assets, SampleWalk.gpx
└── Preview Content/ Preview data: a store in a temporary folder
```

<!-- M4: architecture diagram and how the Live / Replay switch shows dependency injection (APP_PLAN.md §7). -->

The full plan is in [APP_PLAN.md](APP_PLAN.md).

## License

MIT. See [LICENSE](LICENSE).
