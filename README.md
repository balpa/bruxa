# Bruxa

Apple Watch app that records overnight wrist motion and reports sleep bruxism (jaw-clenching) episodes. An iPhone companion app shows the detailed report.

> **Status:** v1 in development. Heuristic band-pass jaw-activity detector + HR-arousal detection landed. Morning report shows restless minutes, arousal events, and jaw activity indicator. Not a medical device — see the [re-scoped design](docs/superpowers/specs/2026-05-12-bruxa-rescoped-design.md).

## What it does

- Listens to HealthKit sleep state on the Watch and only records while the user is asleep.
- Buffers 50 Hz accelerometer + gyroscope data into 30-second windows.
- Runs each window through an `EpisodeDetector` and persists detected episodes locally (CoreData).
- Tracks HR-spike arousal events during sleep using HealthKit heart rate samples.
- Syncs episode batches from Watch to iPhone over WatchConnectivity (in progress).
- Captures a morning self-report (jaw soreness yes/no/unsure) via the Watch app.
- Renders a per-night report with episode count, intensity, timeline, and sleep-stage overlay (planned).

All processing is on-device; nothing is uploaded.

## Project layout

```
app/
  Bruxa.xcworkspace        Open this in Xcode
  project.yml              xcodegen source of truth (regenerates Bruxa.xcodeproj)
  BruxaCore/               Swift Package — all domain logic and platform adapters
  BruxaApp/                iPhone companion target (SwiftUI shell)
  BruxaWatch/              Apple Watch target (SwiftUI shell)
  BruxaAppTests/           iOS test target
  BruxaWatchTests/         watchOS test target

docs/superpowers/
  specs/                   Product/design specs
  plans/                   Implementation plans (TDD task lists)

scripts/
  compile-model.sh         Recompiles BruxaModel.xcdatamodeld → BruxaModel.momd
```

## Build

Requirements: Xcode 26+, Swift 6.3+, [xcodegen](https://github.com/yonaskolb/XcodeGen).

```bash
# Generate the Xcode project from project.yml
cd app
xcodegen generate
open Bruxa.xcworkspace
```

## Test

The bulk of the code lives in `BruxaCore` and is verified by `swift test` on macOS — no simulator runtimes required.

```bash
cd app/BruxaCore
swift test
```

## Editing the CoreData model

Swift Package Manager doesn't auto-compile `.xcdatamodeld`, so the repo ships the pre-compiled `BruxaModel.momd`. After editing the model in Xcode, regenerate it:

```bash
./scripts/compile-model.sh
```

## Design docs

- Design spec: [`docs/superpowers/specs/2026-05-11-bruxism-watch-app-design.md`](docs/superpowers/specs/2026-05-11-bruxism-watch-app-design.md)
- Foundation plan: [`docs/superpowers/plans/2026-05-11-foundation.md`](docs/superpowers/plans/2026-05-11-foundation.md)

## License

TBD.
