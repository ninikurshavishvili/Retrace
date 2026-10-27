# Ideas (after v1)

Anything outside the v1 scope in APP_PLAN.md §3 goes here, so v1 can ship.

## From the plan
- Accounts, cloud sync, sharing routes between users
- Editing, trimming, renaming or merging routes
- Background recording (RouteReplay v2)
- Apple Watch, iPad layout, widgets
- Settings, onboarding, App Store release
- Analytics, crash reporting

## Noticed while building
- Sort by when a route was added, not when it was recorded. An imported GPX file from years ago lands below newer walks today, not at the top.
- Open `.gpx` and `.json` files sent from other apps ("Open in Retrace") by declaring document types.
- Draw a start dot and an end dot on route thumbnails, like the app icon.
- Thin out very long routes before drawing their thumbnails.
- Start the Record map zoomed in on the walker. Following the user's location keeps MapKit's default zoom, which shows a few kilometers.

## For RouteReplay
- `RouteDebugMap` draws its line and dot in fixed blue. Using the tint would let Retrace show its Trail accent.
- `RouteDebugMap`'s "n / total" counts the points it received, so it trails the real playhead when the map starts listening after another consumer (the tracker panel shows a few more updates). Showing the player's own index would fix it.
- When a looping replay starts over, a tracker sees a jump from the last point back to the first, which adds about a route's length to its distance.
