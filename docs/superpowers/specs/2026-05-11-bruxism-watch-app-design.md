# Bruxism Tracker — Apple Watch App Design

**Date:** 2026-05-11
**Status:** Draft, pending user review

## 1. Summary

An Apple Watch app that uses accelerometer and gyroscope data overnight, processed by an on-device CoreML model, to detect sleep bruxism (teeth grinding / jaw clenching) episodes and produce a detailed morning report on a companion iPhone app.

**Positioning:** Wellness tracker — explicitly not a medical diagnostic device. Tagline direction: *"Collect data before your next dental visit."*

**Target audience:** Adults who suspect or know they grind their teeth at night. Reachable through r/Bruxism, r/dentistry, dental hygienist outreach.

**Hardware/software requirements:** Apple Watch Series 6 or newer (for sleep tracking and adequate sensor sampling), watchOS 10+, paired iPhone with iOS 17+.

## 2. MVP Scope

### In v1

- Background overnight recording (Watch, no user interaction once enabled)
- Morning Watch summary: episode count, total jaw-activity duration, intensity score (1–10)
- iPhone companion report:
  - Per-night timeline graph (episode intensity over the night)
  - Sleep stage overlay (REM / Core / Deep) pulled from HealthKit
  - 7-day and 30-day trend graphs
- Onboarding with 3–7 night personal calibration period
- Local-only storage; no cloud sync ("your data never leaves your device")

### Deferred to v2

- Active intervention (gentle haptic to break episodes mid-sleep) — premium IAP
- Trigger correlation (caffeine, late meals, stress) — requires substantial HealthKit dietary integration plus manual logging
- Dental visit PDF export — premium IAP
- Apple Watch Ultra-specific features — not relevant to this app

## 3. Architecture

### Component map

```
Apple Watch (watchOS)
├── SleepSessionManager        — observes HealthKit sleep state, gates recording
├── SensorRecorder (CoreMotion)— accel + gyro @ 50Hz, 30s windows
├── BruxismDetector (CoreML)   — per-window inference: episode boolean + intensity
└── MorningSummaryView         — minimal "open phone for details" screen

iPhone Companion (iOS)
├── ReportGenerator            — syncs Watch episodes, joins with HealthKit sleep stages
├── ReportView (SwiftUI Charts)— timeline, trends, sleep stage overlays
└── Onboarding & Calibration   — first-3-nights feedback flow
```

### Data flow per night

```
Sleep onset (HealthKit signal)
    ↓
SensorRecorder starts: 50Hz accel + gyro
    ↓ (every 30s window)
Buffer fills → band-pass filter (5–15 Hz, the bruxism frequency band) → normalize
    ↓
CoreML inference → { isEpisode: Bool, intensity: 0..1 }
    ↓ (if isEpisode)
Append to local DB: timestamp, duration, intensity
    ↓
Sleep end (HealthKit signal)
    ↓
WatchConnectivity pushes episodes to iPhone
    ↓
iPhone ReportGenerator joins with sleep stages and renders report
```

### Permissions

- HealthKit read: sleep analysis (required), heart rate (optional, v1.1)
- CoreMotion: background workout/motion mode on Watch
- User notifications: morning summary delivery

### Storage

- Watch: rolling 24-hour episode log (CoreData or SQLite)
- iPhone: full history (CoreData)
- No cloud — privacy is a marketing pillar

## 4. Detection Pipeline and ML Model

### Training (pre-launch, founder-driven pilot)

1. **Reference hardware** for ground-truth labels: EMG splint (e.g., Bruxoff / BruxApp class device, ~$100–150). This sits in the mouth during sleep and records masseter activity timestamps and intensity — gold standard for bruxism episode labelling.

2. **Data collection plan (contingent — see Open Questions):**
   - Self: 14 nights with watch + EMG splint
   - 2–3 volunteers: 7 nights each
   - Target: ~30–50 labelled nights, several hundred hours of paired sensor data

3. **Labelling:** EMG episode timestamps mapped onto 30-second windows of watch sensor data, producing per-window binary labels and intensity targets.

4. **Model:**
   - Architecture: 1D-CNN + LSTM hybrid (6-channel input: 3-axis accel + 3-axis gyro) or a small transformer
   - Target size: < 2 MB (Core ML deployable to Apple Watch)
   - Heads: binary episode classification + intensity regression
   - Training: PyTorch on macOS, exported via Core ML Tools
   - Target metrics: sensitivity ≥ 80%, specificity ≥ 90%

### Inference (on device, overnight)

- Sample at 50 Hz, buffer 30-second windows
- Pre-process: band-pass 5–15 Hz, normalize
- CoreML inference produces `{ episode: Bool, intensity: 0..1 }`
- Episodes persist locally; non-episode windows are discarded (privacy + storage)

### Calibration

- The shipped CoreML model is fixed. Personalization happens at the *threshold* layer: each user's classification threshold drifts based on their morning feedback during nights 1–3.
- Day 1–3: model labelled "learning" in UI; each morning the user is asked "did you feel like you ground your teeth last night?" with answers `yes / no / not sure`. Thresholds adjust accordingly.
- Day 4 onwards: full reports unlocked.

## 5. Onboarding Flow

1. Welcome screen (iPhone): single sentence on what the app does and the privacy stance.
2. HealthKit permission request for sleep analysis.
3. Watch companion install reminder.
4. Quick check: is iOS Sleep mode set up? If not, deep-link to Health app with a one-line explanation.
5. First-night setup: instructions to wear the watch to bed.
6. Morning of day 1: raw report rendered + onboarding card explaining the calibration period.
7. Days 1–3: each morning collects a single-tap feedback (`yes / no / not sure`).
8. Day 4: "ready" state, full reports and 7-day trends become available.

## 6. Monetization

**Freemium with subscription:**

- **Free tier**
  - Overnight tracking
  - Morning summary (episode count, timeline)
  - 7-day history

- **Premium ($4.99/month or $39.99/year)**
  - Unlimited history (free tier capped at 7 days)
  - Monthly trend reports
  - HRV and heart rate correlation analysis (sleep stage overlay is already free)
  - v2: active intervention (haptic prompts during episodes)
  - v2: PDF export for dental visits
  - v2: trigger correlation analysis

**Trial:** 14 days of full premium access on first install.

**Comparable price points:** Sleep Cycle (~$30/year), AutoSleep (one-time $4.99). This app is positioned narrower and more specific than either, justifying a subscription model.

## 7. Risks and Open Questions

| Risk / Question | Impact | Mitigation |
|---|---|---|
| **Dataset feasibility** — uncertain whether public datasets and self-collected pilot can produce a workable model | If ML path fails, v1 either slips or falls back to a heuristic detector | Literature review (see Task #9) — outcome dictates whether to proceed with EMG-splint pilot or pivot to heuristic MVP with opt-in user-feedback bootstrap |
| **Battery drain** — 50 Hz continuous overnight motion sampling | Estimated 8–12% per night; user complaints likely if higher | Measure during closed beta; if too high, drop to 25 Hz and re-validate model performance |
| **False positives from non-bruxism wrist motion** — rolling over, scratching, etc. | Erodes user trust quickly | Per-user threshold calibration; mark low-confidence episodes separately in the report |
| **Users who don't wear the watch overnight** — many people charge at night | No data → no value | Weekly nudge during the first month to wear the watch overnight |
| **App Store review — medical claims** | Rejection or forced repositioning | Strict language discipline: track / monitor / awareness, never diagnose / treat / cure |
| **Apple sleep stage accuracy** is closer to 70% than 90% in practice | Sleep stage overlays could mislead users | Label correlations as "approximate"; never make clinical claims |
| **Cold start — no users** | No marketing budget | Niche community outreach: r/Bruxism, r/dentistry, dental hygienist forums; targeted Reddit AMA after a small private beta |

### Decision parking lot — dataset path

Two viable paths remain open, pending the literature review:

- **Path A — EMG-splint pilot:** Founder buys reference EMG hardware, collects 14+ labelled nights, plus volunteer nights. Yields a real per-user-baseline CoreML model. Slower, costs ~$100–150 + 2–3 weeks of discipline, but produces a defensible product.
- **Path B — Heuristic MVP with bootstrap:** Ship v1 with a band-pass + threshold heuristic, position accuracy honestly ("good not perfect"), collect opt-in user feedback to label real data, train a model for v2 once ~500 user-nights are accumulated. Faster to launch, risks early-user churn from accuracy issues.

A decision between A and B is required before any implementation work begins.

## 8. Success Criteria (post-launch)

- **3-month post-launch targets:** ≥ 1,000 installs; ≥ 5% free→paid conversion.
- **Model stability:** average night-over-night episode count variance for a stable user < 20%.
- **Qualitative:** at least 5 App Store reviews mentioning real dentist / hygienist feedback.

## 9. Next Steps

1. Complete literature review on bruxism datasets and wrist-motion correlations (Task #9).
2. Decide between dataset Path A and Path B.
3. Move to implementation planning via the writing-plans skill.
