# Foundation smoke test

Run this once on a paired iPhone + Apple Watch before declaring the foundation plan complete.

## Setup
1. Install BruxaApp on the iPhone (Series 6 or newer Watch paired, watchOS 10+).
2. Install BruxaWatch on the Apple Watch.
3. Open BruxaApp → tap "Grant sleep access" → approve in the HealthKit sheet.
4. Open BruxaWatch → confirm the StatusView shows "Idle".

## Overnight dogfood
1. Make sure iOS Sleep is configured (Health → Browse → Sleep → Schedule).
2. Wear the Watch to bed.
3. In the morning:
   - BruxaWatch StatusView still shows "Idle" or "Recording" (it should be Idle after wake).
   - Open BruxaApp on the iPhone, pull to refresh. The "Recorded episodes" count should be 0 (the detector is the stub — this is expected).

## What this verifies
- HealthKit permission flow works on device.
- WatchConnectivity session activates and the daily flush executes without crashing.
- CoreMotion does not crash the app overnight.
- CoreData store is created on both sides without migration errors.

## What this does NOT verify (yet)
- Episode detection accuracy (detector is a stub — covered by future Detection plan).
- Battery usage (must be measured in a closed beta; baseline this run vs. a control night without the app).
- UI quality for reports (covered by future Reporting plan).
