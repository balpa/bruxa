# v1 smoke test

Run this once on a paired iPhone + Apple Watch before declaring v1 complete.

## Setup
1. Install BruxaApp on iPhone (Series 6+ Watch paired, watchOS 10+).
2. Install BruxaWatch on Apple Watch.
3. Open BruxaApp on iPhone → read the wellness disclosure → tap "I understand".
4. Tap "Grant sleep + heart rate access" → approve HealthKit sheet (both scopes).
5. Open BruxaWatch → confirm StatusView shows "Bruxa" + "Jaw indicators tonight: 0".

## Overnight dogfood
1. Confirm iOS Sleep is configured (Health → Browse → Sleep → Schedule).
2. Wear the Watch overnight.
3. In the morning:
   - Tap the Watch app, tap "Log this morning", tap one of Yes/No/Unsure.
   - Open BruxaApp on iPhone, pull to refresh.
   - Confirm "Arousal events" and "Jaw activity indicator" show a count (may be 0 — that is acceptable for v1 because the heuristic detector is conservative).
   - Confirm "Your self-report" shows the value you logged on the Watch.

## What v1 verifies
- HealthKit dual-scope authorization (sleep + HR) works on device.
- WatchConnectivity sync ships episodes from Watch to iPhone overnight.
- ArousalDetector runs on the Watch at sleep end and persists HR-arousal events.
- BandPassJawActivityDetector runs in real time during sleep and writes any flagged windows.
- Self-report write from Watch → CoreData → readable on iPhone.
- DisclosureView is shown only on first launch and persists acceptance via @AppStorage.

## What v1 deliberately does NOT verify
- Restless Minutes (placeholder card; computation lands in v1.1 over a longer raw-sample retention window).
- Bedside Mode microphone (v1.1 Premium).
- EMG-splint pairing (v2).
- Accuracy of the jaw-activity indicator (the heuristic is unvalidated — the bootstrap dataset from self-reports is how v2 earns calibration).
